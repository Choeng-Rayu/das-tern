"""FastAPI route handlers for Kiri-OCR service."""
import io
import time
import logging
from fastapi import APIRouter, UploadFile, File, HTTPException
from PIL import Image

from app.api.models import ExtractionResponse, HealthResponse, ConfigResponse
from app.config import settings
from app.pipeline.formatter import build_dynamic_universal, build_extraction_summary

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1")

# Set by main.py on startup
_engine = None


def set_engine(engine):
    """Set the Kiri-OCR engine (called during app startup)."""
    global _engine
    _engine = engine


ALLOWED_CONTENT_TYPES = {
    "image/png", "image/jpeg", "image/jpg", "image/webp",
    "application/pdf", "application/octet-stream",
}


@router.post("/extract", response_model=ExtractionResponse)
async def extract_prescription(file: UploadFile = File(...)):
    """Extract prescription data from an uploaded image using Kiri-OCR."""
    # Validate file type
    content_type = file.content_type or "application/octet-stream"
    filename = file.filename or "unknown"

    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    valid_extensions = {"png", "jpg", "jpeg", "webp", "pdf"}

    if content_type not in ALLOWED_CONTENT_TYPES and ext not in valid_extensions:
        raise HTTPException(
            status_code=422,
            detail={
                "success": False,
                "error": "unsupported_format",
                "message": "File format not supported. Use PNG, JPG/JPEG, WebP, or PDF.",
                "supported_formats": ["image/png", "image/jpeg", "image/jpg", "image/webp", "application/pdf"],
            },
        )

    # Read file
    image_bytes = await file.read()

    # Check file size
    max_size = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if len(image_bytes) > max_size:
        raise HTTPException(
            status_code=413,
            detail={
                "success": False,
                "error": "file_too_large",
                "message": f"File exceeds {settings.MAX_UPLOAD_SIZE_MB}MB limit.",
            },
        )

    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail={"success": False, "error": "empty_file", "message": "Uploaded file is empty."},
        )

    if _engine is None:
        raise HTTPException(
            status_code=503,
            detail={"success": False, "error": "service_unavailable", "message": "Kiri-OCR model not loaded."},
        )

    start_time = time.time()

    try:
        # Get image dimensions
        img = Image.open(io.BytesIO(image_bytes))
        img_width, img_height = img.size
        img_format = img.format or "unknown"

        # Run Kiri-OCR
        full_text, line_results = _engine.extract(image_bytes)

        # Parse text into structured prescription data
        from app.pipeline.text_parser import parse_prescription
        parsed = parse_prescription(full_text, line_results)

        # Build Dynamic Universal v2.0 response
        processing_time_ms = (time.time() - start_time) * 1000
        data = build_dynamic_universal(
            parsed,
            processing_time_ms=processing_time_ms,
            image_width=img_width,
            image_height=img_height,
            image_format=img_format.lower(),
            file_size_bytes=len(image_bytes),
        )
        summary = build_extraction_summary(data, processing_time_ms)

        logger.info(
            f"Extraction complete: {summary['total_medications']} medications, "
            f"confidence: {summary['confidence_score']:.2f}, "
            f"time: {processing_time_ms:.0f}ms"
        )

        return ExtractionResponse(
            success=True,
            data=data,
            extraction_summary=summary,
        )

    except Exception as e:
        logger.error(f"Extraction failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={
                "success": False,
                "error": "extraction_failed",
                "message": f"OCR extraction failed: {str(e)}",
            },
        )


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy" if _engine else "initializing",
        models_loaded=_engine is not None,
    )


@router.get("/config", response_model=ConfigResponse)
async def get_config():
    """Get current Kiri-OCR service configuration."""
    return ConfigResponse(
        auto_accept_threshold=settings.AUTO_ACCEPT_THRESHOLD,
        flag_review_threshold=settings.FLAG_REVIEW_THRESHOLD,
        max_upload_size_mb=settings.MAX_UPLOAD_SIZE_MB,
        max_image_dimension=settings.MAX_IMAGE_DIMENSION,
    )
