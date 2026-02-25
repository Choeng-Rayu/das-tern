"""OCR engine wrapper for Tesseract."""
import cv2
import numpy as np
import pytesseract
from dataclasses import dataclass
from typing import Optional, List, Tuple, Dict
from app.config import settings
from app.utils.text_utils import detect_language, normalize_text
from app.utils.image_utils import crop_region


@dataclass
class OCRResult:
    """Result from OCR on a single region."""
    text: str
    confidence: float
    engine: str
    bbox: Optional[Tuple[int, int, int, int]] = None
    needs_review: bool = False
    language: str = "english"
    words: Optional[List[Dict]] = None  # word-level: [{text, bbox, confidence}]


class OCREngine:
    """Unified OCR engine using Tesseract for all languages."""

    def __init__(self):
        self._verify_tesseract()

    def _verify_tesseract(self):
        """Verify tesseract is available."""
        try:
            pytesseract.get_tesseract_version()
        except Exception as e:
            raise RuntimeError(f"Tesseract not found: {e}")

    def ocr_region(self, image: np.ndarray, bbox: Tuple[int, int, int, int],
                   content_type: str = "mixed", lang: Optional[str] = None) -> OCRResult:
        """Run OCR on a specific image region.

        Args:
            image: Full image (color or grayscale)
            bbox: (x1, y1, x2, y2) region to OCR
            content_type: hint about expected content type
            lang: override language
        """
        cropped = crop_region(image, bbox)
        if cropped.size == 0:
            return OCRResult(text="", confidence=0.0, engine="tesseract", bbox=bbox)

        h, w = cropped.shape[:2]
        if h < 10 or w < 10:
            return OCRResult(text="", confidence=0.0, engine="tesseract", bbox=bbox)

        is_dose_cell = content_type in ("morning", "midday", "afternoon", "evening", "item_number")

        # Track coordinate transform for mapping word bboxes back to image space
        crop_x1, crop_y1 = bbox[0], bbox[1]
        scale_factor = 1.0

        # For dose/number cells: trim borders to remove grid lines
        if is_dose_cell:
            trim_x = max(int(w * 0.15), 3)
            trim_y = max(int(h * 0.15), 3)
            cropped = cropped[trim_y:h - trim_y, trim_x:w - trim_x]
            crop_x1 += trim_x
            crop_y1 += trim_y
            h, w = cropped.shape[:2]
            if h < 5 or w < 5:
                return OCRResult(text="-", confidence=0.5, engine="tesseract", bbox=bbox)

        # Scale up small regions for better recognition
        if h < 50:
            scale_factor = 50 / h
            cropped = cv2.resize(cropped, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_CUBIC)

        # Select language and PSM based on content type
        if lang:
            tess_lang = lang
        elif is_dose_cell:
            tess_lang = settings.TESSERACT_LANG_ENG
        elif content_type == "medication_name":
            tess_lang = settings.TESSERACT_LANG_ENG
        elif content_type in ("duration", "instructions"):
            tess_lang = settings.TESSERACT_LANG
        else:
            tess_lang = settings.TESSERACT_LANG

        if is_dose_cell:
            psm = 10  # Treat as single character
        elif content_type == "medication_name":
            psm = settings.TESSERACT_PSM_BLOCK
        else:
            psm = settings.TESSERACT_PSM_SINGLE_LINE

        # Whitelist for dose cells
        extra_config = ""
        if is_dose_cell:
            extra_config = " -c tessedit_char_whitelist=0123456789-/"

        # Run Tesseract
        text, confidence, words = self._run_tesseract(cropped, tess_lang, psm, extra_config)

        # Map word bboxes from cropped/scaled space to original image coordinates
        for w_entry in words:
            bx1, by1, bx2, by2 = w_entry['bbox']
            if scale_factor != 1.0:
                bx1 = int(bx1 / scale_factor)
                by1 = int(by1 / scale_factor)
                bx2 = int(bx2 / scale_factor)
                by2 = int(by2 / scale_factor)
            w_entry['bbox'] = [bx1 + crop_x1, by1 + crop_y1,
                               bx2 + crop_x1, by2 + crop_y1]

        needs_review = confidence < settings.FLAG_REVIEW_THRESHOLD
        language = detect_language(text)

        return OCRResult(
            text=normalize_text(text),
            confidence=confidence,
            engine="tesseract",
            bbox=bbox,
            needs_review=needs_review,
            language=language,
            words=words,
        )

    def ocr_full_image(self, image: np.ndarray, lang: Optional[str] = None) -> OCRResult:
        """Run OCR on full image."""
        tess_lang = lang or settings.TESSERACT_LANG
        text, confidence, words = self._run_tesseract(image, tess_lang, 3)  # PSM 3 = fully automatic
        return OCRResult(
            text=normalize_text(text),
            confidence=confidence,
            engine="tesseract",
            language=detect_language(text),
            words=words,
        )

    def _run_tesseract(self, image: np.ndarray, lang: str, psm: int, extra_config: str = "") -> Tuple[str, float, List[Dict]]:
        """Run tesseract and return (text, confidence, words)."""
        # Convert to grayscale if needed
        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        else:
            gray = image.copy()

        # Apply adaptive binarization to improve OCR quality — especially helpful
        # for low-contrast or shadow-affected prescription images
        _, gray_bin = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        # Use binarized version only if it has better contrast (fewer mid-gray pixels)
        original_contrast = float(np.std(gray))
        binary_contrast = float(np.std(gray_bin))
        if binary_contrast > original_contrast * 0.8:
            gray = gray_bin

        config = f'--oem {settings.TESSERACT_OEM} --psm {psm}{extra_config}'

        try:
            # Get detailed data for confidence
            data = pytesseract.image_to_data(gray, lang=lang, config=config, output_type=pytesseract.Output.DICT)

            texts = []
            confidences = []
            words = []
            for i, text in enumerate(data['text']):
                conf = int(data['conf'][i])
                if conf > 0 and text.strip():
                    texts.append(text.strip())
                    confidences.append(conf)
                    words.append({
                        'text': text.strip(),
                        'bbox': [
                            int(data['left'][i]),
                            int(data['top'][i]),
                            int(data['left'][i] + data['width'][i]),
                            int(data['top'][i] + data['height'][i]),
                        ],
                        'confidence': conf / 100.0,
                    })

            full_text = ' '.join(texts)
            avg_confidence = sum(confidences) / len(confidences) / 100.0 if confidences else 0.0

            return full_text, avg_confidence, words

        except Exception:
            # Fallback: simple text extraction
            try:
                text = pytesseract.image_to_string(gray, lang=lang, config=config)
                return normalize_text(text), 0.5, []
            except Exception:
                return "", 0.0, []

    def ocr_cells(self, image: np.ndarray, cells: list) -> list:
        """Run OCR on multiple cells (from table). Returns list of OCRResult."""
        results = []
        for cell in cells:
            result = self.ocr_region(image, cell.bbox, cell.content_type)
            results.append(result)
        return results
