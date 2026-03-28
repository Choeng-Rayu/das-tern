"""
Optimized Medical System Prompts for Small Models (Qwen2.5-0.5B)
Designed for fast inference with concise instructions.
"""

# Concise prompt under 500 characters for small model efficiency
MEDICAL_EXTRACTION_SYSTEM_PROMPT_SMALL = """Extract prescription data as JSON.

EXTRACT: patient name, age, gender, medications (name, dose, form, frequency, duration), doctor, date.

IGNORE: addresses, phone numbers, IDs, headers, noise.

FIX OCR ERRORS: paracetamo1→Paracetamol, s00mg→500mg, 1→l in drug names, 0→O in drug names.

ABBREVIATIONS: bd=twice daily, tds=3x daily, od=once daily, tab=tablet, cap=capsule.

OUTPUT: Valid JSON only. No explanations."""


# Even shorter prompt for embedding in Modelfile (under 300 chars)
MODELFILE_SYSTEM_PROMPT = """Extract prescription data as JSON. Include: patient (name, age, gender), medications (name, dose, form, frequency), doctor, date. Fix OCR errors in drug names. Output valid JSON only."""


def build_simple_prompt(raw_ocr_text: str) -> str:
    """Build a minimal prompt for small model inference.
    
    Args:
        raw_ocr_text: Raw OCR text from prescription image
        
    Returns:
        Formatted prompt string for the model
    """
    return f"""{MEDICAL_EXTRACTION_SYSTEM_PROMPT_SMALL}

Prescription text:
{raw_ocr_text}

JSON output:"""


def build_json_schema_prompt(raw_ocr_text: str) -> str:
    """Build prompt with JSON schema hint for better structured output.
    
    Args:
        raw_ocr_text: Raw OCR text from prescription image
        
    Returns:
        Formatted prompt with schema guidance
    """
    schema_hint = """{
  "patient": {"name": "", "age": 0, "gender": ""},
  "medications": [{"name": "", "dose": "", "form": "", "frequency": "", "duration": ""}],
  "doctor": "",
  "date": ""
}"""
    
    return f"""Extract prescription data as JSON matching this schema:
{schema_hint}

Fix OCR errors: paracetamo1→Paracetamol, s00mg→500mg, bd=twice daily, tds=3x daily.

Prescription:
{raw_ocr_text}

JSON:"""
