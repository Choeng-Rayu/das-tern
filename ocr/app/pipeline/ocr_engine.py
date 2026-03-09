"""Kiri-OCR engine wrapper — loads model once, provides extract method."""
import io
import logging
import os
import tempfile
import time
from dataclasses import dataclass, field
from typing import List, Tuple

import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)


@dataclass
class LineResult:
    """A single OCR text line result."""
    text: str
    confidence: float
    bbox: List[int] = field(default_factory=list)  # [x, y, w, h]
    line_number: int = 0


class KiriOCREngine:
    """Wrapper around the kiri-ocr library.

    The kiri_ocr.OCR.extract_text() returns:
      (full_text: str, results: List[Dict])
    where each result dict has:
      - 'box': [x, y, w, h]
      - 'text': str
      - 'confidence': float (0-1)
      - 'det_confidence': float (0-1)
      - 'line_number': int
    """

    def __init__(self):
        # Set HF_TOKEN before loading so HuggingFace uses authenticated requests
        from app.config import settings
        if settings.HF_TOKEN:
            os.environ.setdefault("HF_TOKEN", settings.HF_TOKEN)
            logger.info("HuggingFace token configured")

        logger.info("Loading Kiri-OCR model (mrrtmob/kiri-ocr)...")
        start = time.time()
        from kiri_ocr import OCR
        self._ocr = OCR(device="cpu", det_method="db", decode_method="accurate")
        elapsed = time.time() - start
        logger.info(f"Kiri-OCR model loaded in {elapsed:.1f}s")

        # Warm up to force detector initialization
        self._warmup()

    def _warmup(self) -> None:
        """Force-initialise the detector by running inference on a synthetic image."""
        logger.info("Warming up detector (pre-loading detector.onnx)...")
        start = time.time()
        try:
            # White background with dark horizontal bars that mimic text lines
            arr = np.full((200, 320, 3), 255, dtype=np.uint8)
            for row_y in range(20, 180, 28):
                arr[row_y:row_y + 10, 20:300] = 30  # dark bar
            dummy = Image.fromarray(arr)
            with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
                dummy.save(tmp, format="JPEG", quality=90)
                tmp_path = tmp.name
            try:
                self._ocr.extract_text(tmp_path)
            finally:
                os.unlink(tmp_path)
            elapsed = time.time() - start
            logger.info(f"Detector warmed up in {elapsed:.1f}s")
        except Exception as e:
            logger.warning(f"Warmup skipped ({e})")

    def extract(self, image_bytes: bytes) -> Tuple[str, List[LineResult]]:
        """Run OCR on raw image bytes.

        Returns:
            (full_text, line_results) where full_text is the concatenated text
            and line_results is a list of per-line LineResult objects.
        """
        img = Image.open(io.BytesIO(image_bytes))
        if img.mode != "RGB":
            img = img.convert("RGB")
        return self.extract_from_pil(img)

    def extract_from_pil(self, img: Image.Image) -> Tuple[str, List[LineResult]]:
        """Run OCR on a PIL Image (already preprocessed).

        Returns:
            (full_text, line_results)
        """
        start = time.time()
        if img.mode != "RGB":
            img = img.convert("RGB")

        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
            img.save(tmp, format="JPEG", quality=95)
            tmp_path = tmp.name

        try:
            full_text, results = self._ocr.extract_text(tmp_path)
        finally:
            os.unlink(tmp_path)

        elapsed_ms = (time.time() - start) * 1000

        # Convert result dicts to LineResult objects
        line_results = []
        for r in results:
            line_results.append(LineResult(
                text=r.get("text", ""),
                confidence=r.get("confidence", 0.0),
                bbox=r.get("box", []),
                line_number=r.get("line_number", 0),
            ))

        logger.info(f"Kiri-OCR extracted {len(line_results)} lines in {elapsed_ms:.0f}ms")
        return full_text, line_results

    def extract_from_numpy(self, img_bgr: np.ndarray) -> Tuple[str, List[LineResult]]:
        """Run OCR on a preprocessed OpenCV BGR numpy array."""
        from PIL import Image as _PILImage
        rgb = img_bgr[:, :, ::-1] if len(img_bgr.shape) == 3 else np.stack([img_bgr] * 3, axis=-1)
        pil_img = _PILImage.fromarray(rgb)
        return self.extract_from_pil(pil_img)

