"""Pydantic models for Dynamic Universal v2.0 schema - API response format."""
from pydantic import BaseModel, Field
from typing import Optional, List, Any, Dict


class BBox(BaseModel):
    coordinates: Optional[List[int]] = None


class ImageMetadata(BaseModel):
    width: int = 0
    height: int = 0
    format: str = "unknown"
    dpi: int = 200
    file_size_bytes: int = 0


class ExtractionInfo(BaseModel):
    extracted_at: str = ""
    ocr_engine: str = "tesseract_5.0_khmer"
    confidence_score: float = 0.0
    preprocessing_applied: List[str] = Field(default_factory=list)
    image_metadata: ImageMetadata = Field(default_factory=ImageMetadata)


class LanguagesDetected(BaseModel):
    primary: str = "khmer"
    secondary: List[str] = Field(default_factory=lambda: ["english"])
    mixed_content: bool = True


class Metadata(BaseModel):
    extraction_info: ExtractionInfo = Field(default_factory=ExtractionInfo)
    prescription_id: Optional[str] = None
    version: str = "2.0"
    languages_detected: LanguagesDetected = Field(default_factory=LanguagesDetected)
    prescription_type: str = "outpatient"
    validation_status: str = "validated"


class ExtractionSummary(BaseModel):
    total_medications: int = 0
    confidence_score: float = 0.0
    needs_review: bool = False
    fields_needing_review: List[str] = Field(default_factory=list)
    processing_time_ms: float = 0.0
    engines_used: List[str] = Field(default_factory=lambda: ["tesseract"])


class ExtractionResponse(BaseModel):
    """API response model for POST /api/v1/extract."""
    success: bool = True
    data: Dict[str, Any] = Field(default_factory=dict)
    extraction_summary: ExtractionSummary = Field(default_factory=ExtractionSummary)


class ErrorResponse(BaseModel):
    """API error response model."""
    success: bool = False
    error: str = ""
    message: str = ""
    supported_formats: List[str] = Field(default_factory=lambda: ["image/png", "image/jpeg", "image/jpg", "image/webp", "application/pdf"])


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "healthy"
    version: str = "1.0.0"
    ocr_engine: str = "tesseract"
    tesseract_version: str = ""
    languages_available: List[str] = Field(default_factory=list)
    models_loaded: bool = True


class ConfigResponse(BaseModel):
    """Configuration response."""
    auto_accept_threshold: float = 0.80
    flag_review_threshold: float = 0.60
    max_upload_size_mb: int = 10
    tesseract_lang: str = "khm+eng+fra"
    max_image_dimension: int = 2000
