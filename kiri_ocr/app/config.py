"""Configuration for Kiri-OCR service."""
from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    PORT: int = 8003
    MAX_UPLOAD_SIZE_MB: int = 10
    AUTO_ACCEPT_THRESHOLD: float = 0.80
    FLAG_REVIEW_THRESHOLD: float = 0.60
    MAX_IMAGE_DIMENSION: int = 4000
    # Optional HuggingFace token — eliminates the "unauthenticated requests" warning
    # and gives higher download rate limits.  Get one free at huggingface.co/settings/tokens
    HF_TOKEN: Optional[str] = None

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
