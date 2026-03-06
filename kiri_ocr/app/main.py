"""FastAPI application entry point with Kiri-OCR model loading at startup."""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse as _JSONResponse

from app.api.routes import router, set_engine
from app.pipeline.ocr_engine import KiriOCREngine
from app.config import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


class UnicodeJSONResponse(_JSONResponse):
    """JSONResponse that explicitly declares charset=utf-8 for Khmer Unicode safety."""
    media_type = "application/json; charset=utf-8"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load Kiri-OCR model at startup, cleanup on shutdown."""
    logger.info("Starting Kiri-OCR service...")
    logger.info("Loading Kiri-OCR model (mrrtmob/kiri-ocr)...")

    engine = KiriOCREngine()
    set_engine(engine)

    logger.info("Kiri-OCR service ready!")
    yield
    logger.info("Shutting down Kiri-OCR service...")


app = FastAPI(
    title="DAS-TERN Kiri-OCR Service",
    description="OCR Prescription Scanning Service using Kiri-OCR for Cambodian prescriptions (Khmer + English)",
    version="1.0.0",
    lifespan=lifespan,
    default_response_class=UnicodeJSONResponse,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(router)


@app.get("/")
async def root():
    return {
        "service": "DAS-TERN Kiri-OCR Service",
        "version": "1.0.0",
        "model": "mrrtmob/kiri-ocr",
        "docs": "/docs",
        "health": "/api/v1/health",
    }
