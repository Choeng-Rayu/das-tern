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
        # (removes the "unauthenticated" warning and gets higher rate limits)
        from app.config import settings
        if settings.HF_TOKEN:
            os.environ.setdefault("HF_TOKEN", settings.HF_TOKEN)
            logger.info("HuggingFace token configured")

        logger.info("Loading Kiri-OCR model (mrrtmob/kiri-ocr)...")
        start = time.time()
        from kiri_ocr import OCR
        self._ocr = OCR(device="cpu", decode_method="accurate")
        elapsed = time.time() - start
        logger.info(f"Kiri-OCR model loaded in {elapsed:.1f}s")

        # Warm up: run a dummy inference to force the text DETECTOR (detector.onnx)
        # to download and initialise NOW, not on the first real request.
        # Without this the first OCR call takes 10-15 extra seconds.
        self._warmup()

    def _warmup(self) -> None:
        """Force-initialise the detector by running inference on a synthetic image.

        Uses a 320×200 image with horizontal black bars (simulating text lines)
        so the ONNX text detector is actually invoked and its model weights are
        loaded into memory — not just the recognition model.
        """
        logger.info("Warming up detector (pre-loading detector.onnx)...")
        start = time.time()
        try:
            # White background with 6 dark horizontal bars that mimic text lines
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
            logger.info(f"Detector warmed up in {elapsed:.1f}s — subsequent requests will not cold-start")
        except Exception as e:
            # Non-fatal — first real request still works, just with one-time cold-start
            logger.warning(f"Warmup skipped ({e})")

    def extract(self, image_bytes: bytes) -> Tuple[str, List[LineResult]]:
        """Run OCR on raw image bytes.

        Returns:
            (full_text, line_results) where full_text is the concatenated text
            and line_results is a list of per-line LineResult objects.
        """
        start = time.time()

        # Load and normalise image — preserve original resolution.
        # Kiri-OCR's beam-search recogniser is the bottleneck (not the detector),
        # and accuracy drops significantly at lower resolutions for Khmer text.
        img = Image.open(io.BytesIO(image_bytes))
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

        logger.info(
            f"Kiri-OCR extracted {len(line_results)} lines in {elapsed_ms:.0f}ms"
        )
        return full_text, line_results
