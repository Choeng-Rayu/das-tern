"""AI API Service — enhances OCR prescription data using OpenRouter LLM."""
import logging
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse as _JSONResponse

from app.config import settings
from app.routes.enhance import router

logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)


class UnicodeJSONResponse(_JSONResponse):
    """JSONResponse that explicitly declares charset=utf-8 for Khmer Unicode safety."""
    media_type = "application/json; charset=utf-8"


app = FastAPI(
    title="Das Tern AI API",
    description="Enhances OCR-extracted prescription data using LLM via OpenRouter.",
    version="1.0.0",
    default_response_class=UnicodeJSONResponse,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.APP_HOST,
        port=settings.APP_PORT,
        reload=settings.DEBUG,
    )
