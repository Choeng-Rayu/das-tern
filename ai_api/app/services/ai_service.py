"""OpenRouter AI service — builds prompts from OCR data and calls Gemma-3."""
import json
import logging
import re
from typing import Dict, Any, Optional

import httpx

from app.config import settings
from app.models.schemas import EnhancedData, CorrectedMedication, CorrectedPatient

logger = logging.getLogger(__name__)


# --------------------------------------------------------------------------- #
# Prompt builder                                                                #
# --------------------------------------------------------------------------- #

def _build_prompt(ocr_result: Dict[str, Any]) -> str:
    """
    Extract the most useful signal from the OCR result and build a focused
    enhancement prompt for the language model.
    """
    prescription = ocr_result.get("data", {}).get("prescription", {})
    raw = prescription.get("raw_extraction_data", {})
    full_text = raw.get("full_text") or ""

    # Current medications list (may contain OCR errors)
    med_lines = []
    for item in prescription.get("medications", {}).get("items", []):
        num = item.get("item_number", {}).get("value", "?")
        name = item.get("medication", {}).get("name", {}).get("full_text", "")
        strength = item.get("medication", {}).get("strength", {}).get("value", "")
        dur = item.get("dosing", {}).get("duration", {}).get("value", "")
        med_lines.append(f"  {num}. {name}  strength={strength}  duration={dur}days")

    meds_text = "\n".join(med_lines) if med_lines else "  (none detected)"

    # Current patient info
    personal = prescription.get("patient", {}).get("personal_info", {})
    patient_name = (personal.get("name") or {}).get("full_name", "")
    patient_age = (personal.get("age") or {}).get("value", "")
    patient_gender = (personal.get("gender") or {}).get("value", "")
    patient_id = (
        prescription.get("patient", {})
        .get("identification", {})
        .get("patient_id", {})
        .get("value", "")
    )

    # Diagnoses
    diag_list = prescription.get("clinical_information", {}).get("diagnoses", [])
    diag_text = ", ".join(
        d.get("diagnosis", {}).get("english") or d.get("diagnosis", {}).get("khmer") or ""
        for d in diag_list
        if d.get("diagnosis")
    ) or "(none)"

    # Prescriber
    prescriber_name = (
        prescription.get("prescriber", {}).get("name", {}).get("full_name") or ""
    )

    # Prescription date
    issue_date = (
        prescription.get("prescription_details", {})
        .get("dates", {})
        .get("issue_date", {})
        .get("value", "")
        or ""
    )

    prompt = f"""You are a medical data correction assistant for Cambodian hospital prescriptions.

The following raw OCR text was extracted from a physical prescription form (Khmer/English mixed).
OCR quality is imperfect — medication names may be garbled, patient info may be missing.

## Raw OCR Text (verbatim):
{full_text if full_text else "(no full text available)"}

## Currently Extracted Data (may contain OCR errors):
Medications:
{meds_text}

Patient: name="{patient_name}" age={patient_age} gender="{patient_gender}" id="{patient_id}"
Diagnoses: {diag_text}
Prescriber: "{prescriber_name}"
Date: "{issue_date}"

## Your Task:
Using the raw OCR text as ground truth, correct any OCR errors and return ONLY a valid JSON object.
If you cannot determine a value with confidence, use null.

Return this exact JSON structure (no markdown fences, no explanation):
{{
  "medications": [
    {{
      "item_number": 1,
      "corrected_brand_name": "CorrectName",
      "corrected_generic_name": "GenericName",
      "strength": "100mg",
      "was_corrected": true
    }}
  ],
  "patient": {{
    "name": "Patient Full Name",
    "age": 35,
    "gender": "F",
    "patient_id": "HAKF12345"
  }},
  "prescriber_name": "Dr. Name",
  "diagnoses": ["Diagnosis 1"],
  "prescription_date": "2025-01-15"
}}"""  # noqa: E501

    return prompt


# --------------------------------------------------------------------------- #
# JSON extraction helper                                                        #
# --------------------------------------------------------------------------- #

def _extract_json(text: str) -> Optional[Dict[str, Any]]:
    """Extract JSON from a model response that may contain prose or code fences."""
    # Try direct parse first
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError:
        pass

    # Strip markdown code fences
    stripped = re.sub(r"```(?:json)?", "", text, flags=re.IGNORECASE).strip()
    stripped = stripped.strip("`").strip()
    try:
        return json.loads(stripped)
    except json.JSONDecodeError:
        pass

    # Find first {...} block
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass

    return None


# --------------------------------------------------------------------------- #
# OpenRouter call with model fallback                                           #
# --------------------------------------------------------------------------- #

# Models tried in order when the primary is rate-limited (429).
# First entry always uses settings.OPENROUTER_MODEL so .env controls the primary.
_FALLBACK_MODELS = [
    None,                                 # placeholder → replaced with settings.OPENROUTER_MODEL at call time
    "google/gemma-3-4b-it:free",         # smaller Gemma 3
    "liquid/lfm-2.5-1.2b-instruct:free", # small fast fallback
]


async def call_openrouter(prompt: str) -> tuple[str, str]:
    """
    Send a prompt to OpenRouter and return (raw_model_text, model_used).
    Tries each model in _FALLBACK_MODELS in order; raises RuntimeError only
    when all models are exhausted.
    """
    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json; charset=utf-8",
        "HTTP-Referer": "https://das-tern.local",
        "X-Title": "Das Tern AI Service",
    }

    models_to_try = [settings.OPENROUTER_MODEL] + [m for m in _FALLBACK_MODELS[1:] if m != settings.OPENROUTER_MODEL]
    last_err = "no models tried"

    for model in models_to_try:
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a precise medical data assistant. "
                        "You ONLY output valid JSON objects with no markdown, no code fences, and no prose."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            "temperature": settings.TEMPERATURE,
            "max_tokens": settings.MAX_TOKENS,
        }

        async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT) as client:
            response = await client.post(
                f"{settings.OPENROUTER_BASE_URL}/chat/completions",
                headers=headers,
                json=payload,
            )
            if response.status_code == 429:
                last_err = f"{model} rate-limited (429)"
                logger.warning(f"Model {model} rate-limited, trying next fallback...")
                continue
            if response.status_code >= 400:
                last_err = f"{model} returned HTTP {response.status_code}"
                logger.warning(f"Model {model} error {response.status_code}, trying next fallback...")
                continue
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            if model != settings.OPENROUTER_MODEL:
                logger.info(f"Used fallback model: {model}")
            return content, model

    raise RuntimeError(f"All models exhausted — AI did not respond ({last_err})")


# --------------------------------------------------------------------------- #
# Main enhancement function                                                     #
# --------------------------------------------------------------------------- #

async def enhance_prescription(ocr_result: Dict[str, Any]) -> tuple[EnhancedData, str]:
    """
    Build prompt from OCR result, call OpenRouter, parse and return (enhanced_data, model_used).
    """
    prompt = _build_prompt(ocr_result)
    logger.info(f"Sending enhancement request, primary model: {settings.OPENROUTER_MODEL}")

    raw_text, model_used = await call_openrouter(prompt)
    logger.info(f"Got response from {model_used}")
    logger.debug(f"Raw AI response: {raw_text[:500]}")

    parsed = _extract_json(raw_text)
    if not parsed:
        logger.warning("Could not parse AI response as JSON, returning empty enhancement")
        return EnhancedData(), model_used

    # Build medications list
    medications = []
    for med in parsed.get("medications", []):
        medications.append(
            CorrectedMedication(
                item_number=int(med.get("item_number", 0)),
                corrected_brand_name=med.get("corrected_brand_name"),
                corrected_generic_name=med.get("corrected_generic_name"),
                strength=med.get("strength"),
                was_corrected=bool(med.get("was_corrected", False)),
            )
        )

    # Build patient info
    patient_raw = parsed.get("patient") or {}
    patient = CorrectedPatient(
        name=patient_raw.get("name"),
        age=patient_raw.get("age"),
        gender=patient_raw.get("gender"),
        patient_id=patient_raw.get("patient_id"),
    )

    return EnhancedData(
        medications=medications,
        patient=patient,
        prescriber_name=parsed.get("prescriber_name"),
        diagnoses=parsed.get("diagnoses") or [],
        prescription_date=parsed.get("prescription_date"),
    ), model_used
