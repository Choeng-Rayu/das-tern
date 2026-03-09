"""
AI LLM Service - Ollama-based API
Handles OCR correction and chatbot functionality using Ollama
"""

import os
import sys
import json
import logging
from datetime import datetime
from contextlib import asynccontextmanager
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

# Load .env file BEFORE any application module imports, because those modules
# read env vars (LLM_PROVIDER, OPENROUTER_API_KEY, etc.) at import time.
try:
    from dotenv import load_dotenv as _load_dotenv
    _load_dotenv()
except ImportError:
    pass  # python-dotenv not installed — rely on shell environment

# Safety and validation imports
try:
    from .safety.language import detect_language
    from .safety.medical import is_diagnosis_request, is_drug_advice_request, get_safe_refusal
    from .features.prescription.validator import validate_prescription
    from .features.prescription.enhancer import enhance_prescription
    from .core.model_loader import get_model_info, load_model
except ImportError:
    try:
        from app.safety.language import detect_language
        from app.safety.medical import is_diagnosis_request, is_drug_advice_request, get_safe_refusal
        from app.features.prescription.validator import validate_prescription
        from app.features.prescription.enhancer import enhance_prescription
        from app.core.model_loader import get_model_info, load_model
    except ImportError:
        def detect_language(text): return "en"
        def is_diagnosis_request(text): return False
        def is_drug_advice_request(text): return False
        def get_safe_refusal(request_type): return "Please consult a healthcare professional."
        def validate_prescription(data): return {"warnings": [], "errors": [], "safe": True}
        def enhance_prescription(data, **kwargs): return data
        def get_model_info(): return {"is_loaded": False, "model": "unknown"}
        def load_model(): return False

# Configure structured logging (uses LOG_LEVEL + optional LOG_FILE env vars)
try:
    from .core.logging_config import setup_logging, set_request_id, generate_request_id
except ImportError:
    from app.core.logging_config import setup_logging, set_request_id, generate_request_id

_log_file = os.getenv("LOG_FILE")  # e.g. /tmp/ai-llm-service.log
setup_logging(
    log_level=os.getenv("LOG_LEVEL", "INFO"),
    log_file=_log_file,
    service_name="ai-llm-service",
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting AI Service...")
    # Note: Using Ollama for inference, no local model loading needed
    yield
    logger.info("Shutting down AI Service...")

# Initialize FastAPI
app = FastAPI(
    title="DasTern AI LLM Service",
    description="Prescription enhancement and medical AI using LLaMA",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)


# Request/Response Models

class OCRCorrectionRequest(BaseModel):
    """Request for OCR text correction"""
    raw_text: str
    language: Optional[str] = "en"
    context: Optional[Dict[str, Any]] = None


class OCRCorrectionResponse(BaseModel):
    """Response with corrected OCR text"""
    corrected_text: str
    confidence: float
    language: str
    changes_made: List[str] = []
    metadata: Optional[Dict[str, Any]] = None


class EnhanceRequest(BaseModel):
    """Request for prescription enhancement"""
    ocr_data: Dict[str, Any]
    language: Optional[str] = None


class EnhanceResponse(BaseModel):
    """Response with enhanced prescription"""
    success: bool
    ai_enhanced: bool
    data: Dict[str, Any]
    prescription_summary: Optional[str] = None
    validation: Optional[Dict[str, Any]] = None


class ValidateRequest(BaseModel):
    """Request for prescription validation"""
    prescription_data: Dict[str, Any]


class ChatRequest(BaseModel):
    """Request for chatbot interaction"""
    message: str
    prescription_context: Optional[Dict[str, Any]] = None
    language: Optional[str] = None


class ChatResponse(BaseModel):
    """Chatbot response"""
    message: str
    is_safe_response: bool
    detected_language: str


class ParsePrescriptionRequest(BaseModel):
    """Request to parse raw OCR text into structured prescription"""
    raw_text: str
    language: Optional[str] = "en"


class DosageSchedule(BaseModel):
    """Dosage schedule for a medication"""
    morning: int = 0
    noon: int = 0
    evening: int = 0
    night: int = 0


class MedicationData(BaseModel):
    """Structured medication data"""
    name: str
    strength: Optional[str] = None
    form: str = "tablet"
    schedule: DosageSchedule
    total_quantity: Optional[int] = None
    duration_days: Optional[int] = None
    notes: Optional[str] = None


class PatientData(BaseModel):
    """Patient information"""
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    medical_id: Optional[str] = None


class VitalsData(BaseModel):
    """Vital signs"""
    bp: Optional[str] = None
    pulse: Optional[int] = None
    temperature: Optional[float] = None


class DoctorData(BaseModel):
    """Doctor information"""
    name: Optional[str] = None


class StructuredPrescription(BaseModel):
    """Complete structured prescription"""
    prescription_id: Optional[str] = None
    date: Optional[str] = None
    hospital: Optional[str] = None
    patient: PatientData
    diagnosis_text: Optional[str] = None
    medications: list[MedicationData]
    vitals: Optional[VitalsData] = None
    doctor: DoctorData


class ReminderData(BaseModel):
    """Reminder for a single medication dose"""
    medication_name: str
    strength: Optional[str] = None
    time: str
    time_slot: str
    dose: int
    message_en: str
    message_kh: str


class ParsePrescriptionResponse(BaseModel):
    """Response with parsed prescription data"""
    success: bool
    ai_parsed: bool
    prescription: Optional[StructuredPrescription] = None
    reminders: list[ReminderData] = []
    error: Optional[str] = None


@app.on_event("startup")
async def startup_event():
    """Initialize model on startup."""
    logger.info("=" * 60)
    logger.info("Initializing AI LLM Service...")
    logger.info(f"  LLM_PROVIDER  : {os.getenv('LLM_PROVIDER', 'ollama')}")
    logger.info(f"  OPENROUTER_MODEL: {os.getenv('OPENROUTER_MODEL', 'google/gemma-3-4b-it:free')}")
    logger.info(f"  OPENROUTER_KEY  : {'SET (' + os.getenv('OPENROUTER_API_KEY', '')[:12] + '...)' if os.getenv('OPENROUTER_API_KEY') else 'NOT SET'}")
    logger.info(f"  LOG_LEVEL     : {os.getenv('LOG_LEVEL', 'INFO')}")
    logger.info(f"  LOG_FILE      : {os.getenv('LOG_FILE', 'stdout only')}")
    logger.info("=" * 60)
    try:
        load_model()
        info = get_model_info()
        logger.info(f"Model initialisation complete: provider={info.get('provider')}, model={info.get('model_name')}, ready={info.get('is_loaded')}")
    except Exception as e:
        logger.warning(f"Model not available at startup: {e}")


@app.get("/")
async def root():
    """Root endpoint"""
    model_info = get_model_info()
    return {
        "service": "AI LLM Service",
        "status": "running",
        "provider": model_info.get("provider", "unknown"),
        "model": model_info.get("model_name", "unknown"),
        "capabilities": ["ocr_correction", "chatbot"]
    }

@app.post("/api/v1/correct", response_model=OCRCorrectionResponse)
async def correct_ocr(request: OCRCorrectionRequest):
    """
    Correct OCR text using the configured LLM provider.

    Args:
        request: OCR correction request with raw text

    Returns:
        Corrected text with confidence score
    """
    try:
        from .core.generation import generate as _generate
        from .core.model_loader import get_model_info

        logger.info(f"Received OCR correction request for language: {request.language}")

        prompt = (
            f"Fix OCR errors in this {request.language} text. "
            f"Return only the corrected text without explanations.\n\n"
            f"Original text:\n{request.raw_text}\n\nCorrected text:"
        )

        corrected_text = _generate(prompt=prompt, temperature=0.2) or request.raw_text
        info = get_model_info()

        return OCRCorrectionResponse(
            corrected_text=corrected_text.strip(),
            confidence=0.85,
            language=request.language,
            changes_made=[],
            metadata={"provider": info.get("provider"), "model": info.get("model_name"), "service": "ai-llm-service"},
        )

    except Exception as e:
        logger.error(f"Error in OCR correction: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/correct-ocr")
async def correct_ocr_simple(request: dict):
    """
    Simple OCR correction endpoint for backend integration
    
    Args:
        request: Dict with 'text' and optional 'language'
        
    Returns:
        Dict with corrected_text and confidence
    """
    try:
        text = request.get("text", "")
        language = request.get("language", "en")
        
        if not text:
            raise HTTPException(status_code=400, detail="No text provided")
        
        logger.info(f"Correcting OCR text (length: {len(text)})")
        
        try:
            from .core.generation import generate as _generate
        except ImportError:
            from app.core.generation import generate as _generate
        
        prompt = (
            f"Fix OCR errors in this {language} medical text. "
            f"Return only the corrected text without explanations.\n\nOriginal text:\n{text}\n\nCorrected text:"
        )
        corrected = _generate(prompt=prompt, temperature=0.2) or text
        result = {
            "corrected_text": corrected.strip(),
            "confidence": 0.85,
            "corrections_made": 1 if corrected.strip() != text else 0
        }
        
        return {
            "corrected_text": result.get("corrected_text", text),
            "confidence": result.get("confidence", 0.0),
            "corrections_made": result.get("corrections_made", 0)
        }
        
    except Exception as e:
        error_msg = str(e) if str(e) else repr(e)
        logger.error(f"Error in OCR correction: {error_msg}", exc_info=True)
        # Return original text if correction fails
        return {
            "corrected_text": request.get("text", ""),
            "confidence": 0.5,
            "corrections_made": 0,
            "error": error_msg
        }


@app.post("/api/v1/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Chat with medical assistant
    
    Args:
        request: Chat request with message
        
    Returns:
        AI assistant response
    """
    try:
        logger.info(f"Received chat request: {request.message[:50]}...")
        
        try:
            from .core.generation import generate as _generate
        except ImportError:
            from app.core.generation import generate as _generate
        
        response_text = _generate(
            prompt=request.message,
            system_prompt="You are a helpful medical assistant for prescription queries. Answer clearly and safely.",
            temperature=0.3
        ) or "I'm unable to respond right now. Please try again."
        
        result = {
            "message": response_text,
            "is_safe_response": True,
            "detected_language": detect_language(request.message)
        }
        
        return ChatResponse(**result)
        
    except Exception as e:
        logger.error(f"Error in chat: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/prescription/process")
async def process_prescription(request: dict):
    """
    Process prescription OCR data for mobile app integration
    - Enhances OCR accuracy
    - Generates clean, structured JSON for reminder creation
    - Extracts complete medical information for history
    
    Args:
        request: Dict with 'raw_ocr_json' containing OCR data
        
    Returns:
        Structured prescription data with medications and patient info
    """
    try:
        from .core.ollama_client import OllamaClient
        from .features.prescription.processor import PrescriptionProcessor
        
        raw_ocr_json = request.get("raw_ocr_json", {})
        if not raw_ocr_json:
            raise HTTPException(status_code=400, detail="No OCR data provided")
        
        # Initialize processor
        ollama_client = OllamaClient()
        processor = PrescriptionProcessor(ollama_client)
        
        # Process prescription
        result = processor.process_prescription(raw_ocr_json)
        
        return result
        
    except Exception as e:
        logger.error(f"Error processing prescription: {str(e)}")
        return {
            "patient_info": {"name": "", "id": "", "age": None, "gender": "", "hospital_code": ""},
            "medical_info": {"diagnosis": "", "doctor": "", "date": "", "department": ""},
            "medications": [],
            "success": False,
            "error": str(e)
        }

@app.post("/api/v1/prescription/enhance-and-generate-reminders")
async def enhance_and_generate_reminders(request: dict):
    """
    Enhanced prescription processing with automatic reminder generation
    - Processes OCR text using AI
    - Extracts structured prescription data
    - Generates medication reminders with notifications
    - Returns complete data for database insertion
    
    Args:
        request: Dict with:
            - 'ocr_data': OCR output (raw text or structured)
            - 'base_date': Optional start date (YYYY-MM-DD, default: today)
            - 'patient_id': Optional patient identifier
            
    Returns:
        Complete prescription data with generated reminders
    """
    try:
        from .core.ollama_client import OllamaClient
        from .features.prescription.processor import PrescriptionProcessor
        from .features.prescription.enhancer import enhance_prescription
        from .features.prescription.reminder_generator import generate_reminders_from_prescription
        
        ocr_data = request.get("ocr_data", {})
        base_date = request.get("base_date")
        patient_id = request.get("patient_id", "")
        
        if not ocr_data:
            raise HTTPException(status_code=400, detail="No OCR data provided")
        
        logger.info(f"Processing prescription for reminder generation (patient: {patient_id})")
        
        # Step 1: Enhance prescription using AI
        enhanced_result = enhance_prescription(ocr_data)
        
        if not enhanced_result.get("success"):
            logger.warning("AI enhancement failed, attempting basic processing")
            # Fallback to basic processor
            ollama_client = OllamaClient()
            processor = PrescriptionProcessor(ollama_client)
            enhanced_result = {
                "success": True,
                "extracted_data": processor.process_prescription(ocr_data),
                "ai_enhanced": False
            }
        
        # Step 2: Extract prescription data
        prescription_data = enhanced_result.get("extracted_data", {})
        
        if not prescription_data or not prescription_data.get("medications"):
            return {
                "success": False,
                "error": "No medications found in prescription",
                "prescription": prescription_data,
                "reminders": [],
                "metadata": {
                    "ai_enhanced": enhanced_result.get("ai_enhanced", False),
                    "processing_timestamp": datetime.now().isoformat()
                }
            }
        
        # Step 3: Generate reminders
        reminder_result = generate_reminders_from_prescription(prescription_data, base_date)
        
        # Step 4: Build complete response
        response = {
            "success": True,
            "prescription": reminder_result["prescription"],
            "reminders": reminder_result["reminders"],
            "validation": reminder_result["validation"],
            "metadata": {
                "ai_enhanced": enhanced_result.get("ai_enhanced", False),
                "extraction_method": enhanced_result.get("extraction_method", "basic"),
                "model_used": enhanced_result.get("metadata", {}).get("model_used", "unknown"),
                "confidence_score": enhanced_result.get("metadata", {}).get("confidence", 0.0),
                "language_detected": enhanced_result.get("metadata", {}).get("language", "unknown"),
                "processing_timestamp": datetime.now().isoformat(),
                "total_reminders": reminder_result["metadata"]["total_reminders"],
                **reminder_result["metadata"]
            }
        }
        
        logger.info(f"✅ Successfully generated {response['metadata']['total_reminders']} reminders")
        return response
        
    except Exception as e:
        logger.error(f"Error in enhance and generate reminders: {str(e)}", exc_info=True)
        return {
            "success": False,
            "error": str(e),
            "prescription": {},
            "reminders": [],
            "metadata": {
                "processing_timestamp": datetime.now().isoformat()
            }
        }


@app.post("/api/v1/enhance")
async def enhance_v1(request: dict):
    """
    POST /api/v1/enhance
    =====================
    Called by the NestJS backend (ocr.service.ts) after OCR extraction.
    Accepts the full OCR result and returns AI-corrected medication names,
    patient info, diagnoses, prescriber name, and prescription date.

    Request body:
        { "ocr_result": <OcrExtractionResponse JSON> }

    Response body:
        {
            "success": true,
            "ai_enhanced": true,          # true = LLM ran, false = raw OCR fallback
            "enhanced": {
                "medications": [...],
                "patient": {...},
                "prescriber_name": "...",
                "diagnoses": [...],
                "prescription_date": "2024-01-01"
            }
        }
    """
    req_id = set_request_id()
    logger.info(f"[ENHANCE:{req_id}] ── /api/v1/enhance request received ──────────────────────")

    try:
        ocr_result = request.get("ocr_result", {})
        if not ocr_result:
            logger.warning(f"[ENHANCE:{req_id}] No ocr_result in request body")
            return {"success": False, "ai_enhanced": False, "enhanced": None, "error": "No ocr_result provided"}

        # ── Log raw OCR input structure ──────────────────────────────────────
        top_level_keys = list(ocr_result.keys())
        data_section = ocr_result.get("data", {})
        prescription = data_section.get("prescription", {})
        medications_data = prescription.get("medications", {})
        items = medications_data.get("items", [])
        extraction_summary = ocr_result.get("extraction_summary", {})

        logger.info(
            f"[ENHANCE:{req_id}] Raw OCR input — "
            f"top_keys={top_level_keys}, "
            f"medications={len(items)}, "
            f"confidence={extraction_summary.get('confidence_score', 'N/A')}, "
            f"needs_review={extraction_summary.get('needs_review', 'N/A')}"
        )
        logger.debug(
            f"[ENHANCE:{req_id}] OCR input (first 600 chars): "
            f"{str(ocr_result)[:600]}"
        )

        # ── Extract raw text for LLM processing ─────────────────────────────
        text_parts = []

        logger.info(f"[ENHANCE:{req_id}] Found {len(items)} medication items — extracting text fields")
        for item in items:
            med = item.get("medication", {})
            name_info = med.get("name", {})
            brand = name_info.get("brand_name") or name_info.get("full_text", "")
            generic = name_info.get("generic_name", "")
            strength = med.get("strength", {})
            strength_text = f"{strength.get('numeric', '')} {strength.get('unit', '')}".strip()
            text_parts.append(f"Medication: {brand} / {generic} {strength_text}")
            logger.debug(f"[ENHANCE:{req_id}]   item → brand='{brand}' generic='{generic}' strength='{strength_text}'")

        patient = prescription.get("patient", {})
        personal = patient.get("personal_info", {})
        name_info = personal.get("name", {})
        patient_name = name_info.get("full_name") or name_info.get("khmer_name", "")
        if patient_name:
            text_parts.append(f"Patient: {patient_name}")

        prescriber = prescription.get("prescriber", {})
        prescriber_name_info = prescriber.get("name", {})
        prescriber_name = prescriber_name_info.get("full_name", "")
        if prescriber_name:
            text_parts.append(f"Prescriber: {prescriber_name}")

        clinical = prescription.get("clinical_information", {})
        diagnoses_list = clinical.get("diagnoses", [])
        for d in diagnoses_list:
            if isinstance(d, dict):
                diag = d.get("diagnosis", {})
                diag_text = diag.get("english") or diag.get("khmer", "")
                if diag_text:
                    text_parts.append(f"Diagnosis: {diag_text}")

        prescription_details = prescription.get("prescription_details", {})
        dates = prescription_details.get("dates", {})
        issue_date = dates.get("issue_date", {}).get("value")
        if issue_date:
            text_parts.append(f"Date: {issue_date}")

        combined_text = "\n".join(text_parts)
        logger.info(
            f"[ENHANCE:{req_id}] Text extracted for LLM: {len(combined_text)} chars, "
            f"{len(text_parts)} lines"
        )
        logger.debug(f"[ENHANCE:{req_id}] Full combined_text:\n{combined_text}")

        if not combined_text.strip():
            logger.warning(f"[ENHANCE:{req_id}] No extractable text from OCR — returning raw OCR fallback")
            return {
                "success": True,
                "ai_enhanced": False,
                "enhanced": _build_enhanced_from_ocr(prescription, items),
                "error": None,
            }

        # ── Call LLM for medication name correction ──────────────────────────
        try:
            from .core.generation import generate_json
        except ImportError:
            from app.core.generation import generate_json

        enhancement_prompt = f"""You are a medical prescription AI assistant.
Review the following extracted prescription data and correct any OCR errors in medication names,
patient info, and other fields.

EXTRACTED DATA:
{combined_text}

Return a JSON object with this EXACT structure:
{{
    "medications": [
        {{
            "item_number": 1,
            "corrected_brand_name": "corrected name or null if no correction needed",
            "corrected_generic_name": "generic name or null",
            "strength": "dosage like 500mg or null",
            "was_corrected": true or false
        }}
    ],
    "patient": {{
        "name": "corrected name or null",
        "age": number or null,
        "gender": "M or F or null",
        "patient_id": "ID or null"
    }},
    "prescriber_name": "corrected prescriber name or null",
    "diagnoses": ["diagnosis 1", "diagnosis 2"],
    "prescription_date": "YYYY-MM-DD or null"
}}

RULES:
- Correct obvious OCR spelling errors in medication names (e.g., "Amxicillin" -> "Amoxicillin")
- Set was_corrected=true only if you actually changed the name
- If no correction is needed, set was_corrected=false and corrected_brand_name=null
- item_number should match the order of medications (1-based)
- Return valid JSON only"""

        logger.info(
            f"[ENHANCE:{req_id}] Sending to LLM — "
            f"provider={os.getenv('LLM_PROVIDER', 'ollama')}, "
            f"model={os.getenv('OPENROUTER_MODEL') or os.getenv('OLLAMA_MODEL', 'llama3.2:3b')}, "
            f"prompt_chars={len(enhancement_prompt)}"
        )

        ai_result = generate_json(
            prompt=enhancement_prompt,
            system_prompt="You are a medical prescription correction AI. Output valid JSON only.",
            temperature=0.1,
            timeout=60,
        )

        if ai_result:
            logger.info(
                f"[ENHANCE:{req_id}] LLM returned valid JSON — "
                f"medications={len(ai_result.get('medications', []))}, "
                f"patient={ai_result.get('patient') is not None}, "
                f"prescriber='{ai_result.get('prescriber_name')}'"
            )
            enhanced = _merge_enhancement(ai_result, prescription, items)
            return {"success": True, "ai_enhanced": True, "enhanced": enhanced, "error": None}
        else:
            logger.warning(f"[ENHANCE:{req_id}] LLM returned no result — falling back to raw OCR data")
            return {
                "success": True,
                "ai_enhanced": False,
                "enhanced": _build_enhanced_from_ocr(prescription, items),
                "error": None,
            }

    except Exception as e:
        logger.error(f"[ENHANCE:{req_id}] Enhancement exception: {str(e)}", exc_info=True)
        try:
            ocr_result = request.get("ocr_result", {})
            prescription_r = ocr_result.get("data", {}).get("prescription", {})
            items_r = prescription_r.get("medications", {}).get("items", [])
            return {
                "success": True,
                "ai_enhanced": False,
                "enhanced": _build_enhanced_from_ocr(prescription_r, items_r),
                "error": str(e),
            }
        except Exception:
            return {"success": False, "ai_enhanced": False, "enhanced": None, "error": str(e)}


def _build_enhanced_from_ocr(prescription: dict, items: list) -> dict:
    """Build an 'enhanced' object directly from OCR data (no AI correction)."""
    # Patient
    patient = prescription.get("patient", {})
    personal = patient.get("personal_info", {})
    name_info = personal.get("name", {})
    identification = patient.get("identification", {})
    patient_id_info = identification.get("patient_id", {})
    age_info = personal.get("age", {})
    gender_info = personal.get("gender", {})

    # Prescriber
    prescriber = prescription.get("prescriber", {})
    prescriber_name_info = prescriber.get("name", {})

    # Diagnoses
    clinical = prescription.get("clinical_information", {})
    diagnoses_list = clinical.get("diagnoses", [])
    diagnoses = []
    for d in diagnoses_list:
        if isinstance(d, dict):
            diag = d.get("diagnosis", {})
            diag_text = diag.get("english") or diag.get("khmer")
            if diag_text:
                diagnoses.append(diag_text)

    # Prescription date
    prescription_details = prescription.get("prescription_details", {})
    issue_date = prescription_details.get("dates", {}).get("issue_date", {}).get("value")

    # Medications (no corrections — was_corrected=False)
    medications = []
    for i, item in enumerate(items, 1):
        med = item.get("medication", {})
        name_data = med.get("name", {})
        strength_data = med.get("strength", {})
        strength_str = None
        if strength_data.get("numeric") is not None:
            strength_str = f"{strength_data['numeric']} {strength_data.get('unit', '')}".strip()
        medications.append({
            "item_number": i,
            "corrected_brand_name": None,
            "corrected_generic_name": None,
            "strength": strength_str,
            "was_corrected": False,
            # Include original names so NestJS can still read them
            "_ocr_brand_name": name_data.get("brand_name"),
            "_ocr_generic_name": name_data.get("generic_name"),
        })

    return {
        "medications": medications,
        "patient": {
            "name": name_info.get("full_name") or name_info.get("khmer_name"),
            "age": age_info.get("value"),
            "gender": gender_info.get("value") or gender_info.get("english"),
            "patient_id": patient_id_info.get("value"),
        },
        "prescriber_name": prescriber_name_info.get("full_name"),
        "diagnoses": diagnoses,
        "prescription_date": issue_date,
    }


def _merge_enhancement(ai_result: dict, prescription: dict, items: list) -> dict:
    """Merge LLM result with OCR fallback for missing fields."""
    ocr_base = _build_enhanced_from_ocr(prescription, items)

    return {
        "medications": ai_result.get("medications") or ocr_base["medications"],
        "patient": ai_result.get("patient") or ocr_base["patient"],
        "prescriber_name": ai_result.get("prescriber_name") or ocr_base["prescriber_name"],
        "diagnoses": ai_result.get("diagnoses") or ocr_base["diagnoses"],
        "prescription_date": ai_result.get("prescription_date") or ocr_base["prescription_date"],
    }


@app.post("/enhance", response_model=EnhanceResponse)
async def enhance_endpoint(request: EnhanceRequest):
    """
    Enhance OCR prescription data with AI descriptions.
    
    Takes raw OCR output and adds:
    - Medication descriptions
    - Dosage instructions in multiple languages
    - Warnings and safety information
    - Prescription summary
    """
    try:
        ocr_data = request.ocr_data
        
        # Enhance prescription
        enhanced = enhance_prescription(ocr_data)
        
        # Validate enhanced data
        validation = validate_prescription(enhanced)
        
        return EnhanceResponse(
            success=True,
            ai_enhanced=enhanced.get("ai_enhanced", False),
            data=enhanced,
            prescription_summary=enhanced.get("prescription_summary"),
            validation=validation
        )
        
    except Exception as e:
        logger.error(f"Enhancement failed: {e}")
        # Return original data without AI enhancement
        return EnhanceResponse(
            success=True,
            ai_enhanced=False,
            data=request.ocr_data,
            prescription_summary=None,
            validation=None
        )


@app.post("/validate")
async def validate_endpoint(request: ValidateRequest):
    """Validate prescription for safety issues."""
    try:
        validation = validate_prescription(request.prescription_data)
        return validation
    except Exception as e:
        logger.error(f"Validation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Prescription-aware chatbot endpoint.
    
    Can answer questions about a prescription but will not:
    - Diagnose conditions
    - Recommend medications
    - Provide medical advice
    """
    from .core.generation import generate
    
    message = request.message
    detected_lang = detect_language(message)
    
    # Safety checks
    if is_diagnosis_request(message):
        return ChatResponse(
            message=get_safe_refusal("diagnosis"),
            is_safe_response=True,
            detected_language=detected_lang
        )
    
    if is_drug_advice_request(message):
        return ChatResponse(
            message=get_safe_refusal("drug_advice"),
            is_safe_response=True,
            detected_language=detected_lang
        )
    
    # Build context from prescription if provided
    context = ""
    if request.prescription_context:
        meds = request.prescription_context.get("structured_data", {}).get("medications", [])
        if meds:
            context = "Current prescription medications:\n"
            for med in meds:
                context += f"- {med.get('name', 'Unknown')}: {med.get('strength', '')}\n"
    
    # Generate response
    system_prompt = """You are a helpful pharmacy assistant. You can only:
1. Explain what prescribed medications are used for
2. Clarify dosage instructions from prescriptions
3. Remind about general medication safety

You CANNOT:
- Diagnose any condition
- Recommend medications
- Suggest changing dosages
- Provide medical advice

Always recommend consulting a doctor for medical concerns."""

    try:
        response = generate(
            prompt=f"{context}\n\nUser question: {message}",
            system_prompt=system_prompt,
            temperature=0.3
        )
        
        if response:
            return ChatResponse(
                message=response,
                is_safe_response=True,
                detected_language=detected_lang
            )
        else:
            return ChatResponse(
                message="I apologize, but I'm unable to respond right now. Please try again later.",
                is_safe_response=True,
                detected_language=detected_lang
            )
            
    except Exception as e:
        logger.error(f"Chat generation failed: {e}")
        return ChatResponse(
            message="I'm having trouble responding. Please consult your pharmacist or doctor.",
            is_safe_response=True,
            detected_language=detected_lang
        )


# Prompt for parsing prescription from raw OCR text
PARSE_PRESCRIPTION_PROMPT = """You are a medical prescription parser. Parse the following OCR text from a Cambodian prescription image and extract structured data.

The prescription format typically has:
- Header with hospital name, prescription ID, date
- Patient information (name, age, gender, medical ID)
- Diagnosis (store as text only, do NOT interpret)
- Medication table with columns: Medicine Name, Quantity, Morning dose, Noon dose, Evening dose, Night dose
- Vitals (BP, pulse, temperature) if present
- Doctor signature/name

OCR TEXT:
{raw_text}

Extract and return a JSON object with this EXACT structure:
{{
    "prescription_id": "extracted ID or null",
    "date": "YYYY-MM-DD format or null",
    "hospital": "hospital name or null",
    "patient": {{
        "name": "patient name or null",
        "age": number or null,
        "gender": "M/F or null",
        "medical_id": "ID or null"
    }},
    "diagnosis_text": "diagnosis as text only or null",
    "medications": [
        {{
            "name": "medication name (correct spelling)",
            "strength": "dosage like 500mg or null",
            "form": "tablet/capsule/amp/etc",
            "schedule": {{
                "morning": number (0 if not taken),
                "noon": number (0 if not taken),
                "evening": number (0 if not taken),
                "night": number (0 if not taken)
            }},
            "total_quantity": number or null,
            "duration_days": number or null,
            "notes": "special instructions or null"
        }}
    ],
    "vitals": {{
        "bp": "systolic/diastolic or null",
        "pulse": number or null,
        "temperature": number or null
    }} or null,
    "doctor": {{
        "name": "doctor name or null"
    }}
}}

IMPORTANT RULES:
1. Correct common OCR spelling errors in medication names (e.g., "Amxicillin" -> "Amoxicillin")
2. The schedule numbers represent doses, not times. "1 - 1 -" means 1 in morning, 0 at noon, 1 in evening, 0 at night
3. If a dash (-) appears in schedule, it means 0 (no dose at that time)
4. Parse Khmer, English, and French text
5. Store diagnosis as TEXT ONLY - never interpret or suggest treatments
6. Return valid JSON only, no explanations"""


@app.post("/parse-prescription", response_model=ParsePrescriptionResponse)
async def parse_prescription_endpoint(request: ParsePrescriptionRequest):
    """
    Parse raw OCR text into structured prescription data.

    This endpoint uses AI to:
    - Extract prescription metadata (hospital, ID, date, doctor)
    - Extract patient information
    - Parse medication table with dosage schedules
    - Correct OCR spelling errors in medication names
    - Generate reminders based on schedule

    Args:
        request: Raw OCR text and optional language

    Returns:
        Structured prescription data with reminders
    """
    from .core.generation import generate_json

    try:
        raw_text = request.raw_text
        if not raw_text or not raw_text.strip():
            return ParsePrescriptionResponse(
                success=False,
                ai_parsed=False,
                error="No OCR text provided"
            )

        logger.info(f"Parsing prescription from {len(raw_text)} chars of OCR text")

        # Use AI to parse the prescription
        prompt = PARSE_PRESCRIPTION_PROMPT.format(raw_text=raw_text)

        result = generate_json(
            prompt=prompt,
            system_prompt="You are a medical prescription parser. Respond with valid JSON only.",
            temperature=0.1,
            timeout=60
        )

        if not result:
            logger.warning("AI parsing returned no result")
            return ParsePrescriptionResponse(
                success=True,
                ai_parsed=False,
                error="AI could not parse the prescription"
            )

        # Build structured prescription from AI result
        patient_data = result.get("patient", {})
        vitals_data = result.get("vitals")
        doctor_data = result.get("doctor", {})

        medications = []
        for med in result.get("medications", []):
            schedule = med.get("schedule", {})
            medications.append(MedicationData(
                name=med.get("name", "Unknown"),
                strength=med.get("strength"),
                form=med.get("form", "tablet"),
                schedule=DosageSchedule(
                    morning=int(schedule.get("morning", 0) or 0),
                    noon=int(schedule.get("noon", 0) or 0),
                    evening=int(schedule.get("evening", 0) or 0),
                    night=int(schedule.get("night", 0) or 0)
                ),
                total_quantity=med.get("total_quantity"),
                duration_days=med.get("duration_days"),
                notes=med.get("notes")
            ))

        prescription = StructuredPrescription(
            prescription_id=result.get("prescription_id"),
            date=result.get("date"),
            hospital=result.get("hospital"),
            patient=PatientData(
                name=patient_data.get("name"),
                age=patient_data.get("age"),
                gender=patient_data.get("gender"),
                medical_id=patient_data.get("medical_id")
            ),
            diagnosis_text=result.get("diagnosis_text"),
            medications=medications,
            vitals=VitalsData(
                bp=vitals_data.get("bp"),
                pulse=vitals_data.get("pulse"),
                temperature=vitals_data.get("temperature")
            ) if vitals_data else None,
            doctor=DoctorData(name=doctor_data.get("name"))
        )

        # Generate reminders from medication schedules
        reminders = generate_reminders_from_meds(medications)

        logger.info(f"Parsed prescription with {len(medications)} medications, {len(reminders)} reminders")

        return ParsePrescriptionResponse(
            success=True,
            ai_parsed=True,
            prescription=prescription,
            reminders=reminders
        )

    except Exception as e:
        logger.error(f"Prescription parsing failed: {e}")
        return ParsePrescriptionResponse(
            success=False,
            ai_parsed=False,
            error=str(e)
        )


def generate_reminders_from_meds(medications: list[MedicationData]) -> list[ReminderData]:
    """Generate reminder list from medication schedules."""
    reminders = []

    time_slots = {
        "morning": {"time": "07:00", "kh": "ព្រឹក"},
        "noon": {"time": "11:30", "kh": "ថ្ងៃ"},
        "evening": {"time": "17:30", "kh": "ល្ងាច"},
        "night": {"time": "21:00", "kh": "យប់"},
    }

    for med in medications:
        schedule = med.schedule
        strength_text = f" {med.strength}" if med.strength else ""

        for slot_name, slot_config in time_slots.items():
            dose = getattr(schedule, slot_name, 0)
            if dose and dose > 0:
                reminders.append(ReminderData(
                    medication_name=med.name,
                    strength=med.strength,
                    time=slot_config["time"],
                    time_slot=slot_name,
                    dose=dose,
                    message_en=f"Take {dose} {med.form}{'s' if dose > 1 else ''} of {med.name}{strength_text}",
                    message_kh=f"សូមទទួលថ្នាំ {med.name}{strength_text} ចំនួន {dose} គ្រាប់ ពេល{slot_config['kh']}"
                ))

    # Sort by time
    reminders.sort(key=lambda r: r.time)

    return reminders
