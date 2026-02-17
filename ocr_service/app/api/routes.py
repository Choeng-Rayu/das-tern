"""FastAPI route handlers for OCR service."""
import logging
from fastapi import APIRouter, UploadFile, File, HTTPException
import pytesseract

from app.api.models import ExtractionResponse, ErrorResponse, HealthResponse, ConfigResponse
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1")

# Will be set by main.py on startup
_orchestrator = None


def set_orchestrator(orchestrator):
    """Set the pipeline orchestrator (called during app startup)."""
    global _orchestrator
    _orchestrator = orchestrator


ALLOWED_CONTENT_TYPES = {
    "image/png", "image/jpeg", "image/jpg", "image/webp",
    "application/pdf", "application/octet-stream"
}


@router.post("/extract", response_model=ExtractionResponse)
async def extract_prescription(file: UploadFile = File(...)):
    """Extract prescription data from an uploaded image."""
    # Validate file type
    content_type = file.content_type or "application/octet-stream"
    filename = file.filename or "unknown"

    # Check extension if content_type is generic
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    valid_extensions = {"png", "jpg", "jpeg", "webp", "pdf"}

    if content_type not in ALLOWED_CONTENT_TYPES and ext not in valid_extensions:
        raise HTTPException(
            status_code=422,
            detail={
                "success": False,
                "error": "unsupported_format",
                "message": f"File format not supported. Use PNG, JPG/JPEG, WebP, or PDF.",
                "supported_formats": ["image/png", "image/jpeg", "image/jpg", "image/webp", "application/pdf"]
            }
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
                "message": f"File exceeds {settings.MAX_UPLOAD_SIZE_MB}MB limit."
            }
        )

    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail={"success": False, "error": "empty_file", "message": "Uploaded file is empty."}
        )

    # Run pipeline
    if _orchestrator is None:
        raise HTTPException(
            status_code=503,
            detail={"success": False, "error": "service_unavailable", "message": "OCR pipeline not initialized."}
        )

    result = _orchestrator.extract(image_bytes, filename)

    if not result.get("success", False):
        raise HTTPException(
            status_code=500,
            detail=result
        )

    return result


@router.post("/extract/debug")
async def extract_prescription_debug(file: UploadFile = File(...)):
    """Extract prescription with debug info (includes both static and dynamic formats)."""
    result = await extract_prescription(file)
    return result


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    try:
        tess_version = pytesseract.get_tesseract_version()
        version_str = str(tess_version)
    except Exception:
        version_str = "unknown"

    languages = []
    try:
        langs = pytesseract.get_languages()
        languages = [l for l in langs if l != "osd"]
    except Exception:
        pass

    return HealthResponse(
        status="healthy" if _orchestrator else "initializing",
        tesseract_version=version_str,
        languages_available=languages,
        models_loaded=_orchestrator is not None
    )


@router.get("/config", response_model=ConfigResponse)
async def get_config():
    """Get current OCR service configuration."""
    return ConfigResponse(
        auto_accept_threshold=settings.AUTO_ACCEPT_THRESHOLD,
        flag_review_threshold=settings.FLAG_REVIEW_THRESHOLD,
        max_upload_size_mb=settings.MAX_UPLOAD_SIZE_MB,
        tesseract_lang=settings.TESSERACT_LANG,
        max_image_dimension=settings.MAX_IMAGE_DIMENSION
    )
