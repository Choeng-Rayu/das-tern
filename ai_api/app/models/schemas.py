"""Pydantic schemas for AI API request and response models."""
from typing import Dict, Any, List, Optional
from pydantic import BaseModel


# --------------------------------------------------------------------------- #
# Request                                                                       #
# --------------------------------------------------------------------------- #

class EnhanceRequest(BaseModel):
    """
    Payload sent from the backend after OCR extraction.
    Contains the full Dynamic Universal v2.0 OCR result so the AI can
    read raw text + current (possibly garbled) extractions and correct them.
    """
    ocr_result: Dict[str, Any]  # Full OCR response (success, data, extraction_summary)


# --------------------------------------------------------------------------- #
# Response — corrected fields the backend will merge into the OCR output       #
# --------------------------------------------------------------------------- #

class CorrectedMedication(BaseModel):
    item_number: int
    corrected_brand_name: Optional[str] = None
    corrected_generic_name: Optional[str] = None
    strength: Optional[str] = None
    was_corrected: bool = False


class CorrectedPatient(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None  # "M" or "F"
    patient_id: Optional[str] = None


class EnhancedData(BaseModel):
    medications: List[CorrectedMedication] = []
    patient: Optional[CorrectedPatient] = None
    prescriber_name: Optional[str] = None
    diagnoses: List[str] = []
    prescription_date: Optional[str] = None  # ISO date string YYYY-MM-DD


class EnhanceResponse(BaseModel):
    success: bool
    enhanced: Optional[EnhancedData] = None
    model: str
    raw_ai_response: Optional[str] = None  # For debugging
    error: Optional[str] = None
