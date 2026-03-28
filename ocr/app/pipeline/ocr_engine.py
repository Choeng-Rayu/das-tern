"""OCR engine wrapper — supports multiple OCR backends (Kiri-OCR, Tesseract)."""
import io
import logging
import os
import tempfile
import time
from abc import ABC, abstractmethod
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


class OCREngine(ABC):
    """Abstract base class for OCR engines."""
    
    @abstractmethod
    def extract(self, image_bytes: bytes) -> Tuple[str, List[LineResult]]:
        """Run OCR on raw image bytes.
        
        Returns:
            (full_text, line_results) where full_text is the concatenated text
            and line_results is a list of per-line LineResult objects.
        """
        pass
    
    @abstractmethod
    def extract_from_pil(self, img: Image.Image) -> Tuple[str, List[LineResult]]:
        """Run OCR on a PIL Image (already preprocessed).
        
        Returns:
            (full_text, line_results)
        """
        pass
    
    @abstractmethod
    def extract_from_numpy(self, img_bgr: np.ndarray) -> Tuple[str, List[LineResult]]:
        """Run OCR on a preprocessed OpenCV BGR numpy array."""
        pass
    
    @property
    @abstractmethod
    def engine_name(self) -> str:
        """Return the name of the OCR engine."""
        pass


class KiriOCREngine(OCREngine):
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

        self._decode_method = (settings.KIRI_DECODE_METHOD or "fast").strip().lower()
        if self._decode_method not in {"fast", "accurate"}:
            logger.warning(
                f"Invalid KIRI_DECODE_METHOD '{settings.KIRI_DECODE_METHOD}', defaulting to 'fast'"
            )
            self._decode_method = "fast"

        self._max_ocr_dimension = max(1, int(settings.KIRI_MAX_OCR_DIMENSION))
        self._png_compress_level = min(9, max(0, int(settings.KIRI_PNG_COMPRESS_LEVEL)))
        self._conf_blend_det = min(1.0, max(0.0, float(settings.KIRI_CONF_BLEND_DET)))
        self._conf_textlen_boost = max(0.0, float(settings.KIRI_CONF_TEXTLEN_BOOST))

        if settings.HF_TOKEN:
            os.environ.setdefault("HF_TOKEN", settings.HF_TOKEN)
            logger.info("HuggingFace token configured")

        logger.info(
            "Loading Kiri-OCR model (mrrtmob/kiri-ocr) "
            f"with decode_method={self._decode_method}..."
        )
        start = time.time()
        from kiri_ocr import OCR
        self._ocr = OCR(device="cpu", det_method="db", decode_method=self._decode_method)
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
            with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
                dummy.save(tmp, format="PNG")
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

    def _downscale_for_ocr(self, img: Image.Image) -> Image.Image:
        """Downscale image for OCR speed when it exceeds configured max dimension."""
        width, height = img.size
        max_dim = max(width, height)

        if max_dim <= self._max_ocr_dimension:
            return img

        scale = self._max_ocr_dimension / float(max_dim)
        new_size = (
            max(1, int(round(width * scale))),
            max(1, int(round(height * scale))),
        )
        resample = Image.Resampling.LANCZOS if hasattr(Image, "Resampling") else Image.LANCZOS
        logger.debug(
            "Downscaling OCR image from %sx%s to %sx%s",
            width,
            height,
            new_size[0],
            new_size[1],
        )
        return img.resize(new_size, resample=resample)

    @staticmethod
    def _text_length_boost(text: str, max_boost: float) -> float:
        """Compute a small confidence boost for medium/long clean text."""
        clean_len = sum(1 for ch in text if ch.isalnum())
        if clean_len < 8 or max_boost <= 0:
            return 0.0

        # Ramp up from 8 chars to 40 chars.
        ratio = min(1.0, (clean_len - 8) / 32.0)
        return max_boost * ratio

    def extract_from_pil(self, img: Image.Image) -> Tuple[str, List[LineResult]]:
        """Run OCR on a PIL Image (already preprocessed).

        Returns:
            (full_text, line_results)
        """
        total_start = time.perf_counter()
        io_ms = 0.0
        ocr_ms = 0.0

        if img.mode != "RGB":
            img = img.convert("RGB")

        img = self._downscale_for_ocr(img)

        io_start = time.perf_counter()
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            img.save(tmp, format="PNG", compress_level=self._png_compress_level)
            tmp_path = tmp.name
        io_ms += (time.perf_counter() - io_start) * 1000

        try:
            ocr_start = time.perf_counter()
            full_text, results = self._ocr.extract_text(tmp_path)
            ocr_ms = (time.perf_counter() - ocr_start) * 1000
        finally:
            io_cleanup_start = time.perf_counter()
            os.unlink(tmp_path)
            io_ms += (time.perf_counter() - io_cleanup_start) * 1000

        total_ms = (time.perf_counter() - total_start) * 1000

        # Convert result dicts to LineResult objects
        line_results = []
        for r in results:
            base_conf = float(r.get("confidence", 0.0) or 0.0)
            conf = base_conf

            det_conf = r.get("det_confidence")
            if det_conf is not None:
                det_conf = float(det_conf)
                conf = ((1.0 - self._conf_blend_det) * base_conf) + (self._conf_blend_det * det_conf)

            text = r.get("text", "")
            conf += self._text_length_boost(text, self._conf_textlen_boost)
            conf = min(1.0, max(0.0, conf))

            line_results.append(LineResult(
                text=text,
                confidence=conf,
                bbox=r.get("box", []),
                line_number=r.get("line_number", 0),
            ))

        logger.info(
            "Kiri-OCR extracted %s lines in %.0fms (ocr=%.0fms, io=%.0fms)",
            len(line_results),
            total_ms,
            ocr_ms,
            io_ms,
        )
        return full_text, line_results

    def extract_from_numpy(self, img_bgr: np.ndarray) -> Tuple[str, List[LineResult]]:
        """Run OCR on a preprocessed OpenCV BGR numpy array."""
        from PIL import Image as _PILImage
        rgb = img_bgr[:, :, ::-1] if len(img_bgr.shape) == 3 else np.stack([img_bgr] * 3, axis=-1)
        pil_img = _PILImage.fromarray(rgb)
        return self.extract_from_pil(pil_img)
    
    @property
    def engine_name(self) -> str:
        """Return the name of the OCR engine."""
        return "kiri-ocr"


class TesseractOCREngine(OCREngine):
    """Wrapper around Tesseract OCR via pytesseract library.
    
    Tesseract supports multiple languages including English and can handle
    mixed-language content. Configure languages via pytesseract.
    """
    
    def __init__(self, lang: str = "eng+script/Khmer"):
        """Initialize Tesseract OCR engine.
        
        Args:
            lang: Tesseract language(s) to use. Examples:
                - "eng" for English only
                - "eng+script/Khmer" for English + Khmer
                - "eng+khm" for English + Khmer (if trained data available)
        """
        logger.info(f"Initializing Tesseract OCR with languages: {lang}")
        start = time.time()
        
        try:
            import pytesseract
            self._pytesseract = pytesseract
            self.lang = lang
            
            # Test Tesseract installation
            version = pytesseract.get_tesseract_version()
            logger.info(f"Tesseract version: {version}")
            
        except ImportError:
            logger.error("pytesseract not installed. Install with: pip install pytesseract")
            raise
        except Exception as e:
            logger.error(f"Failed to initialize Tesseract: {e}")
            raise
        
        elapsed = time.time() - start
        logger.info(f"Tesseract OCR initialized in {elapsed:.1f}s")
    
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
        
        # Get detailed OCR data from Tesseract
        # data contains: level, page_num, block_num, par_num, line_num, word_num,
        #                left, top, width, height, conf, text
        ocr_data = self._pytesseract.image_to_data(
            img, 
            lang=self.lang,
            output_type=self._pytesseract.Output.DICT
        )
        
        # Also get full text
        full_text = self._pytesseract.image_to_string(img, lang=self.lang)
        
        elapsed_ms = (time.time() - start) * 1000
        
        # Group words into lines based on line_num
        lines_dict = {}
        for i in range(len(ocr_data['text'])):
            text = ocr_data['text'][i].strip()
            if not text:  # Skip empty text
                continue
            
            line_num = ocr_data['line_num'][i]
            conf = float(ocr_data['conf'][i]) / 100.0 if ocr_data['conf'][i] != -1 else 0.0
            left = ocr_data['left'][i]
            top = ocr_data['top'][i]
            width = ocr_data['width'][i]
            height = ocr_data['height'][i]
            
            if line_num not in lines_dict:
                lines_dict[line_num] = {
                    'texts': [],
                    'confs': [],
                    'left': left,
                    'top': top,
                    'right': left + width,
                    'bottom': top + height
                }
            
            lines_dict[line_num]['texts'].append(text)
            lines_dict[line_num]['confs'].append(conf)
            lines_dict[line_num]['left'] = min(lines_dict[line_num]['left'], left)
            lines_dict[line_num]['top'] = min(lines_dict[line_num]['top'], top)
            lines_dict[line_num]['right'] = max(lines_dict[line_num]['right'], left + width)
            lines_dict[line_num]['bottom'] = max(lines_dict[line_num]['bottom'], top + height)
        
        # Convert to LineResult objects
        line_results = []
        for line_num in sorted(lines_dict.keys()):
            line_data = lines_dict[line_num]
            line_text = ' '.join(line_data['texts'])
            line_conf = sum(line_data['confs']) / len(line_data['confs']) if line_data['confs'] else 0.0
            
            bbox = [
                line_data['left'],
                line_data['top'],
                line_data['right'] - line_data['left'],  # width
                line_data['bottom'] - line_data['top']   # height
            ]
            
            line_results.append(LineResult(
                text=line_text,
                confidence=line_conf,
                bbox=bbox,
                line_number=line_num,
            ))
        
        logger.info(f"Tesseract extracted {len(line_results)} lines in {elapsed_ms:.0f}ms")
        return full_text, line_results
    
    def extract_from_numpy(self, img_bgr: np.ndarray) -> Tuple[str, List[LineResult]]:
        """Run OCR on a preprocessed OpenCV BGR numpy array."""
        from PIL import Image as _PILImage
        rgb = img_bgr[:, :, ::-1] if len(img_bgr.shape) == 3 else np.stack([img_bgr] * 3, axis=-1)
        pil_img = _PILImage.fromarray(rgb)
        return self.extract_from_pil(pil_img)
    
    @property
    def engine_name(self) -> str:
        """Return the name of the OCR engine."""
        return "tesseract"


def create_ocr_engine() -> OCREngine:
    """Factory function to create the appropriate OCR engine based on configuration.
    
    Returns:
        OCREngine instance (either KiriOCREngine or TesseractOCREngine)
    """
    from app.config import settings
    
    ocr_model = settings.OCR_MODEL.lower()
    
    if ocr_model == "tesseract":
        logger.info("Creating Tesseract OCR engine")
        return TesseractOCREngine()
    elif ocr_model == "kiri-ocr":
        logger.info("Creating Kiri-OCR engine")
        return KiriOCREngine()
    else:
        logger.warning(f"Unknown OCR_MODEL '{ocr_model}', defaulting to Tesseract")
        return TesseractOCREngine()
