"""Pydantic models for API request/response validation."""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any


class ExtractionSummary(BaseModel):
    """Summary of the OCR extraction result."""
    total_medications: int = 0
    confidence_score: float = 0.0
    needs_review: bool = False
    fields_needing_review: List[str] = Field(default_factory=list)
    processing_time_ms: float = 0.0
    engines_used: List[str] = Field(default_factory=lambda: ["kiri-ocr"])


class ExtractionResponse(BaseModel):
    """Standard response for prescription extraction.
    
    This follows the Dynamic Universal v2.0 schema expected by
    the NestJS backend and AI enhancement service.
    """
    success: bool = True
    data: Dict[str, Any] = Field(default_factory=dict)
    extraction_summary: ExtractionSummary = Field(default_factory=ExtractionSummary)


class ErrorResponse(BaseModel):
    """Error response model."""
    success: bool = False
    error: str = ""
    message: str = ""
    supported_formats: Optional[List[str]] = None


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "healthy"
    version: str = "1.0.0"
    ocr_engine: str = "kiri-ocr"
    model_name: str = "mrrtmob/kiri-ocr"
    models_loaded: bool = True


class ConfigResponse(BaseModel):
    """Configuration response."""
    auto_accept_threshold: float = 0.80
    flag_review_threshold: float = 0.60
    max_upload_size_mb: int = 10
    ocr_engine: str = "kiri-ocr"
    max_image_dimension: int = 4000

