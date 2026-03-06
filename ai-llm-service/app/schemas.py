"""
Pydantic schemas shared across the AI LLM Service.
"""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel


# ─── OCR Correction ──────────────────────────────────────────────────────────

class OCRCorrectionRequest(BaseModel):
    """Request for OCR text correction."""
    raw_text: str
    language: Optional[str] = "en"
    context: Optional[Dict[str, Any]] = None


class OCRCorrectionResponse(BaseModel):
    """Response with corrected OCR text."""
    corrected_text: str
    confidence: float
    language: str
    changes_made: List[str] = []
    metadata: Optional[Dict[str, Any]] = None


# ─── Chat ────────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    """Request for chatbot interaction."""
    message: str
    prescription_context: Optional[Dict[str, Any]] = None
    language: Optional[str] = None
    context: Optional[Dict[str, Any]] = None


class ChatResponse(BaseModel):
    """Chatbot response."""
    message: str
    is_safe_response: bool
    detected_language: str


# ─── Reminders ───────────────────────────────────────────────────────────────

class MedicationInfo(BaseModel):
    """Structured information about a single medication."""
    name: str
    dosage: str = ""
    times: List[str] = []
    times_24h: List[str] = []
    repeat: str = "daily"
    duration_days: Optional[int] = None
    notes: str = ""


class ReminderRequest(BaseModel):
    """Request to extract reminders from raw OCR data."""
    raw_ocr_json: Dict[str, Any]


class ReminderResponse(BaseModel):
    """Response containing extracted medication reminders."""
    medications: List[MedicationInfo] = []
    success: bool
    error: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
