"""Enhancement route — receives OCR data and returns AI-corrected prescription fields."""
import logging
from fastapi import APIRouter, HTTPException

from app.models.schemas import EnhanceRequest, EnhanceResponse
from app.services.ai_service import enhance_prescription
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1", tags=["enhance"])


@router.post("/enhance", response_model=EnhanceResponse)
async def enhance(request: EnhanceRequest) -> EnhanceResponse:
    """
    Receive the raw OCR extraction result and return AI-enhanced corrections.

    The backend sends this after calling the OCR service so the AI can fix
    garbled medication names, extract missing patient info, parse dates, etc.
    """
    if not settings.OPENROUTER_API_KEY:
        raise HTTPException(status_code=503, detail="AI service not configured: missing API key")

    try:
        enhanced, model_used = await enhance_prescription(request.ocr_result)
        logger.info(
            f"Enhancement complete via {model_used}: {len(enhanced.medications)} medications corrected, "
            f"patient={'found' if enhanced.patient and enhanced.patient.name else 'not found'}"
        )
        return EnhanceResponse(
            success=True,
            enhanced=enhanced,
            model=model_used,
        )
    except RuntimeError as e:
        # Known operational errors (rate limit, HTTP errors) — not a bug
        logger.warning(f"AI enhancement unavailable: {e}")
        return EnhanceResponse(
            success=False,
            model=settings.OPENROUTER_MODEL,
            error=str(e),
        )
    except Exception as e:
        logger.error(f"Unexpected enhancement error: {e}", exc_info=True)
        return EnhanceResponse(
            success=False,
            model=settings.OPENROUTER_MODEL,
            error=str(e),
        )


@router.get("/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "ok",
        "model": settings.OPENROUTER_MODEL,
        "api_key_set": bool(settings.OPENROUTER_API_KEY),
    }
