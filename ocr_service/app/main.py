"""FastAPI application entry point with model loading at startup."""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router, set_orchestrator
from app.pipeline.orchestrator import PipelineOrchestrator
from app.config import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load OCR models at startup, cleanup on shutdown."""
    logger.info("Starting OCR service...")
    logger.info("Initializing pipeline orchestrator...")

    orchestrator = PipelineOrchestrator()
    set_orchestrator(orchestrator)

    logger.info("OCR service ready!")
    yield
    logger.info("Shutting down OCR service...")


app = FastAPI(
    title="DAS-TERN OCR Service",
    description="OCR Prescription Scanning Service for Cambodian prescriptions",
    version="1.0.0",
    lifespan=lifespan
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
        "service": "DAS-TERN OCR Service",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/api/v1/health"
    }
