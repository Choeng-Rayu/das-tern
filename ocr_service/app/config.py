"""Application configuration using Pydantic Settings."""
from pydantic_settings import BaseSettings
from typing import Tuple
import os


class Settings(BaseSettings):
    # API
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    MAX_UPLOAD_SIZE_MB: int = 10
    REQUEST_TIMEOUT_S: int = 30
    API_KEY: str = ""

    # OCR Confidence Thresholds
    AUTO_ACCEPT_THRESHOLD: float = 0.80
    FLAG_REVIEW_THRESHOLD: float = 0.60

    # Preprocessing
    BLUR_THRESHOLD: float = 100.0
    MAX_IMAGE_DIMENSION: int = 2000
    CLAHE_CLIP_LIMIT: float = 2.0
    CLAHE_GRID_SIZE: Tuple[int, int] = (8, 8)

    # Brightness
    MIN_BRIGHTNESS: int = 40
    MAX_BRIGHTNESS: int = 220

    # OCR Engines
    TESSERACT_LANG: str = "khm+eng+fra"
    TESSERACT_LANG_ENG: str = "eng"
    TESSERACT_OEM: int = 1
    TESSERACT_PSM: int = 6
    TESSERACT_PSM_BLOCK: int = 6
    TESSERACT_PSM_SINGLE_LINE: int = 7

    # Fuzzy Matching
    MED_NAME_MATCH_THRESHOLD: int = 85

    # Table Row Reconstruction
    ROW_Y_TOLERANCE: int = 10  # max |y1 - y2| for two boxes to be in the same row
    ROW_Y_TOLERANCE_ADAPTIVE: bool = True  # auto-scale tolerance based on avg box height
    ROW_Y_TOLERANCE_ADAPTIVE_FACTOR: float = 0.5  # tolerance = max(ROW_Y_TOLERANCE, avg_h * factor)
    TABLE_MERGE_THRESHOLD: int = 15  # merge close y-values in table grid detection

    # Paths
    BASE_DIR: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    @property
    def lexicon_dir(self) -> str:
        return os.path.join(self.BASE_DIR, "data", "lexicons")

    @property
    def test_images_dir(self) -> str:
        return os.path.join(self.BASE_DIR, "test_space", "images_for_test")

    @property
    def test_results_dir(self) -> str:
        return os.path.join(self.BASE_DIR, "test_space", "results")

    model_config = {"env_prefix": "OCR_", "env_file": ".env"}


settings = Settings()
