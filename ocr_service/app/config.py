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
    ROW_Y_TOLERANCE: int = 10  # max |cy1 - cy2| for two boxes to be same row
    ROW_Y_TOLERANCE_ADAPTIVE: bool = True  # auto-scale tolerance by avg box height
    ROW_Y_TOLERANCE_ADAPTIVE_FACTOR: float = 0.5  # tolerance = max(base, avg_h * factor)
    TABLE_MERGE_THRESHOLD: int = 15  # merge close y-values in table grid detection

    # Dynamic Column / Row Detection
    MIN_VERTICAL_LINE_SPAN: float = 0.30  # fraction of table height for a vertical line to count
    MIN_COLUMN_GAP_RATIO: float = 0.01  # minimum x-gap (as fraction of table width) to be a column separator
    TEXT_DENSITY_PEAK_THRESHOLD: float = 0.15  # fraction of max density to count as text row
    TABLE_SEARCH_HEIGHT_RATIO: float = 0.82  # fraction of image height to search for table (avoids footer)
    MAX_DOSE_COLUMNS: int = 4  # maximum dose columns to detect (morning, midday, afternoon, evening)

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
