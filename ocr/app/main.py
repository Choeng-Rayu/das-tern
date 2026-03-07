"""FastAPI application entry point for the Kiri-OCR service."""
import logging
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse as _JSONResponse

from app.api.routes import router, set_engine, set_orchestrator
from app.config import settings
from app.pipeline.ocr_engine import KiriOCREngine
from app.pipeline.orchestrator import PipelineOrchestrator

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger(__name__)


class UnicodeJSONResponse(_JSONResponse):
    media_type = "application/json; charset=utf-8"


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting OCR service...")
    engine = KiriOCREngine()
    set_engine(engine)
    orchestrator = PipelineOrchestrator(
        engine, max_dimension=settings.PREPROCESS_MAX_DIMENSION,
    )
    set_orchestrator(orchestrator)
    logger.info("OCR service ready (orchestrator pipeline active)")
    yield
    logger.info("Shutting down OCR service...")


app = FastAPI(
    title="DAS-TERN OCR Service",
    description="Prescription OCR service powered by Kiri-OCR for Khmer + English prescriptions.",
    version="1.0.0",
    lifespan=lifespan,
    default_response_class=UnicodeJSONResponse,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(router)


@app.get("/")
async def root() -> dict[str, str]:
    return {
        "service": "DAS-TERN OCR Service",
        "version": "1.0.0",
        "model": "mrrtmob/kiri-ocr",
        "docs": "/docs",
        "health": "/api/v1/health",
    }


if __name__ == "__main__":
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=False)