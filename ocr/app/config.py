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

    # OCR Model Selection: "kiri-ocr" or "tesseract"
    OCR_MODEL: str = "tesseract"

    # Kiri-OCR optimization settings
    KIRI_DECODE_METHOD: str = "fast"  # options: fast/accurate
    KIRI_MAX_OCR_DIMENSION: int = 2200  # downscale larger images before OCR
    KIRI_PNG_COMPRESS_LEVEL: int = 3  # lower compress for faster temp save
    KIRI_CONF_BLEND_DET: float = 0.25  # blend detection confidence
    KIRI_CONF_TEXTLEN_BOOST: float = 0.03

settings = Settings()
