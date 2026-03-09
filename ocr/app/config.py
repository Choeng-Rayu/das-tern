"""Configuration for Kiri-OCR service."""
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # File handling
    MAX_UPLOAD_SIZE_MB: int = 10

    # OCR Confidence Thresholds
    AUTO_ACCEPT_THRESHOLD: float = 0.80
    FLAG_REVIEW_THRESHOLD: float = 0.60

    # Image processing
    MAX_IMAGE_DIMENSION: int = 4000

    # Preprocessing
    PREPROCESS_MAX_DIMENSION: int = 3000

    # Layout / row clustering
    ROW_Y_TOLERANCE: int = 15
    ROW_Y_TOLERANCE_ADAPTIVE: bool = True
    ROW_Y_TOLERANCE_ADAPTIVE_FACTOR: float = 0.6

    # Optional HuggingFace token for authenticated requests (higher rate limits)
    HF_TOKEN: Optional[str] = None

settings = Settings()

