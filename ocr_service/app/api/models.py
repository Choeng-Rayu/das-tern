"""Pydantic models for API request/response validation."""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any


class ExtractionSummary(BaseModel):
    total_medications: int = 0
    confidence_score: float = 0.0
    needs_review: bool = False
    fields_needing_review: List[str] = Field(default_factory=list)
    processing_time_ms: float = 0.0
    engines_used: List[str] = Field(default_factory=lambda: ["tesseract"])


class ExtractionResponse(BaseModel):
    success: bool = True
    data: Dict[str, Any] = Field(default_factory=dict)
    extraction_summary: ExtractionSummary = Field(default_factory=ExtractionSummary)


class ErrorResponse(BaseModel):
    success: bool = False
    error: str = ""
    message: str = ""
    supported_formats: Optional[List[str]] = None


class HealthResponse(BaseModel):
    status: str = "healthy"
    version: str = "1.0.0"
    ocr_engine: str = "tesseract"
    tesseract_version: str = ""
    languages_available: List[str] = Field(default_factory=list)
    models_loaded: bool = True


class ConfigResponse(BaseModel):
    auto_accept_threshold: float = 0.80
    flag_review_threshold: float = 0.60
    max_upload_size_mb: int = 10
    tesseract_lang: str = "khm+eng+fra"
    max_image_dimension: int = 2000
