"""FastAPI route handlers for the OCR service.

Supports two modes:
- **Orchestrator mode** (preferred): full pipeline with preprocessing, layout
  analysis, table-aware extraction.
- **Legacy engine mode**: direct engine → parser → formatter (fallback).
"""
import io
import logging
import time

from fastapi import APIRouter, File, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError

from app.api.models import ConfigResponse, ExtractionResponse, HealthResponse
from app.config import settings
from app.pipeline.formatter import build_dynamic_universal, build_extraction_summary
from app.pipeline.text_parser import parse_prescription

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1")
_engine = None
_orchestrator = None

ALLOWED_CONTENT_TYPES = {"image/png", "image/jpeg", "image/jpg", "image/webp"}
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "webp"}


def set_engine(engine) -> None:
    global _engine
    _engine = engine


def set_orchestrator(orchestrator) -> None:
    global _orchestrator
    _orchestrator = orchestrator


@router.post("/extract", response_model=ExtractionResponse)
async def extract_prescription(file: UploadFile = File(...)) -> ExtractionResponse:
    content_type = file.content_type or "application/octet-stream"
    filename = file.filename or "upload"
    extension = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""

    if content_type not in ALLOWED_CONTENT_TYPES and extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=422, detail={
            "success": False,
            "error": "unsupported_format",
            "message": "File format not supported. Use PNG, JPG/JPEG, or WebP.",
            "supported_formats": sorted(ALLOWED_CONTENT_TYPES),
        })
    if _engine is None and _orchestrator is None:
        raise HTTPException(status_code=503, detail={
            "success": False,
            "error": "service_unavailable",
            "message": "Kiri-OCR model not loaded.",
        })

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail={"success": False, "error": "empty_file", "message": "Uploaded file is empty."})
    if len(image_bytes) > settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=413, detail={
            "success": False,
            "error": "file_too_large",
            "message": f"File exceeds {settings.MAX_UPLOAD_SIZE_MB}MB limit.",
        })

    start = time.time()
    try:
        image = Image.open(io.BytesIO(image_bytes))
        width, height = image.size
        image_format = (image.format or extension or "unknown").lower()
    except UnidentifiedImageError as exc:
        raise HTTPException(status_code=422, detail={
            "success": False,
            "error": "invalid_image",
            "message": "Uploaded file is not a readable image.",
        }) from exc

    try:
        # Prefer orchestrator (full pipeline) over direct engine
        if _orchestrator is not None:
            result = _orchestrator.extract(image_bytes, filename=filename)
            if not result.get("success"):
                raise RuntimeError(result.get("message", "Pipeline extraction failed"))

            parsed = result["parsed"]
            processing_time_ms = result["processing_time_ms"]
            pipeline_meta = result.get("pipeline_metadata", {})
        else:
            # Legacy fallback: direct engine → parser
            full_text, line_results = _engine.extract(image_bytes)
            parsed = parse_prescription(full_text, line_results)
            processing_time_ms = (time.time() - start) * 1000
            pipeline_meta = {}

        data = build_dynamic_universal(
            parsed,
            processing_time_ms=processing_time_ms,
            image_width=width,
            image_height=height,
            image_format=image_format,
            file_size_bytes=len(image_bytes),
            preprocessing_applied=pipeline_meta.get("preprocessing_applied", []),
        )
        summary = build_extraction_summary(data, processing_time_ms)
        return ExtractionResponse(success=True, data=data, extraction_summary=summary)
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("OCR extraction failed")
        raise HTTPException(status_code=500, detail={
            "success": False,
            "error": "extraction_failed",
            "message": f"OCR extraction failed: {exc}",
        }) from exc


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    return HealthResponse(status="healthy" if _engine else "initializing", models_loaded=_engine is not None)


@router.get("/config", response_model=ConfigResponse)
async def get_config() -> ConfigResponse:
    return ConfigResponse(
        auto_accept_threshold=settings.AUTO_ACCEPT_THRESHOLD,
        flag_review_threshold=settings.FLAG_REVIEW_THRESHOLD,
        max_upload_size_mb=settings.MAX_UPLOAD_SIZE_MB,
        max_image_dimension=settings.MAX_IMAGE_DIMENSION,
    )