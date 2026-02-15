"""OCR Service configuration using Pydantic BaseSettings."""

from pydantic_settings import BaseSettings
from typing import Tuple
import os


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # API
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    MAX_UPLOAD_SIZE_MB: int = 10
    REQUEST_TIMEOUT_S: int = 30
    API_KEY: str = ""

    # OCR Confidence Thresholds
    AUTO_ACCEPT_THRESHOLD: float = 0.80
    FLAG_REVIEW_THRESHOLD: float = 0.60
    MANUAL_REVIEW_THRESHOLD: float = 0.60

    # Preprocessing
    BLUR_THRESHOLD: float = 100.0
    MAX_IMAGE_DIMENSION: int = 2000
    CLAHE_CLIP_LIMIT: float = 2.0
    CLAHE_GRID_SIZE: Tuple[int, int] = (8, 8)

    # OCR Engines
    PADDLE_LANG: str = "en"
    PADDLE_USE_GPU: bool = False
    PADDLE_ENABLE_MKLDNN: bool = True
    TESSERACT_LANG: str = "khm+eng+fra"
    TESSERACT_OEM: int = 1
    TESSERACT_PSM: int = 6

    # Fuzzy Matching
    MED_NAME_MATCH_THRESHOLD: int = 85

    # File paths
    BASE_DIR: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    LEXICON_DIR: str = ""
    MODEL_DIR: str = ""

    def model_post_init(self, __context):
        if not self.LEXICON_DIR:
            self.LEXICON_DIR = os.path.join(self.BASE_DIR, "data", "lexicons")
        if not self.MODEL_DIR:
            self.MODEL_DIR = os.path.join(self.BASE_DIR, "data", "models")

    class Config:
        env_prefix = "OCR_"
        env_file = ".env"
        extra = "ignore"


settings = Settings()
