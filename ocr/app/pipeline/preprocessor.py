"""Image preprocessing pipeline for OCR.

Performs quality assessment and enhancement:
- Decode raw bytes → OpenCV BGR
- Grayscale conversion
- Quality checks (blur, brightness)
- Denoise
- CLAHE contrast enhancement
- Sharpen (if blurry)
- Deskew (if skewed)
- Resize to max dimension
"""
import logging
from dataclasses import dataclass, field
from typing import List, Tuple

import cv2
import numpy as np

logger = logging.getLogger(__name__)


@dataclass
class QualityReport:
    """Image quality assessment report."""
    is_blurry: bool = False
    blur_score: float = 0.0
    is_dark: bool = False
    is_bright: bool = False
    mean_brightness: float = 0.0
    skew_angle: float = 0.0
    needs_deskew: bool = False
    original_size: Tuple[int, int] = (0, 0)
    processed_size: Tuple[int, int] = (0, 0)
    preprocessing_applied: List[str] = field(default_factory=list)


@dataclass
class PreprocessResult:
    """Result of image preprocessing."""
    color: np.ndarray  # BGR enhanced image
    gray: np.ndarray   # Grayscale enhanced image
    quality: QualityReport


def decode_image(image_bytes: bytes) -> np.ndarray:
    """Decode raw image bytes to OpenCV BGR array."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Failed to decode image from bytes")
    return img


def _check_blur(gray: np.ndarray, threshold: float = 100.0) -> Tuple[bool, float]:
    score = cv2.Laplacian(gray, cv2.CV_64F).var()
    return score < threshold, float(score)


def _check_brightness(gray: np.ndarray) -> Tuple[bool, bool, float]:
    mean_b = float(np.mean(gray))
    return mean_b < 40, mean_b > 220, mean_b


def _detect_skew(gray: np.ndarray) -> Tuple[float, bool]:
    coords = np.column_stack(np.where(gray < 128))
    if len(coords) < 100:
        return 0.0, False
    rect = cv2.minAreaRect(coords)
    angle = rect[-1]
    if angle < -45:
        angle = 90 + angle
    elif angle > 45:
        angle = angle - 90
    needs = abs(angle) > 0.5
    return float(angle), needs


def _denoise(img: np.ndarray) -> np.ndarray:
    if len(img.shape) == 3:
        return cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)
    return cv2.fastNlMeansDenoising(img, None, 10, 7, 21)


def _clahe(img: np.ndarray) -> np.ndarray:
    if len(img.shape) == 2:
        cl = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        return cl.apply(img)
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l_ch, a_ch, b_ch = cv2.split(lab)
    cl = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l_ch = cl.apply(l_ch)
    lab = cv2.merge([l_ch, a_ch, b_ch])
    return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)


def _sharpen(img: np.ndarray) -> np.ndarray:
    gaussian = cv2.GaussianBlur(img, (0, 0), 3)
    return cv2.addWeighted(img, 1.5, gaussian, -0.5, 0)


def _deskew(img: np.ndarray, angle: float) -> np.ndarray:
    if abs(angle) < 0.5:
        return img
    h, w = img.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    return cv2.warpAffine(img, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)


def _resize(img: np.ndarray, max_dim: int = 3000) -> np.ndarray:
    h, w = img.shape[:2]
    if max(h, w) <= max_dim:
        return img
    scale = max_dim / max(h, w)
    return cv2.resize(img, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)


def crop_region(img: np.ndarray, bbox: Tuple[int, int, int, int]) -> np.ndarray:
    """Crop region from image: bbox = (x1, y1, x2, y2)."""
    x1, y1, x2, y2 = bbox
    h, w = img.shape[:2]
    return img[max(0, y1):min(h, y2), max(0, x1):min(w, x2)]


def preprocess(image_bytes: bytes, max_dimension: int = 3000) -> PreprocessResult:
    """Full preprocessing pipeline. Returns enhanced color + gray images."""
    color = decode_image(image_bytes)
    quality = QualityReport(original_size=(color.shape[1], color.shape[0]))
    applied = quality.preprocessing_applied

    gray = cv2.cvtColor(color, cv2.COLOR_BGR2GRAY) if len(color.shape) == 3 else color.copy()

    # Quality checks
    quality.is_blurry, quality.blur_score = _check_blur(gray)
    quality.is_dark, quality.is_bright, quality.mean_brightness = _check_brightness(gray)
    quality.skew_angle, quality.needs_deskew = _detect_skew(gray)

    # Denoise
    color = _denoise(color)
    applied.append("denoise")

    # CLAHE contrast enhancement
    color = _clahe(color)
    applied.append("clahe")

    # Sharpen if blurry
    if quality.is_blurry:
        color = _sharpen(color)
        applied.append("sharpen")

    # Deskew if needed
    if quality.needs_deskew:
        color = _deskew(color, quality.skew_angle)
        applied.append(f"deskew({quality.skew_angle:.1f}°)")

    # Resize
    color = _resize(color, max_dimension)
    applied.append("resize")

    # Final grayscale from enhanced color
    gray = cv2.cvtColor(color, cv2.COLOR_BGR2GRAY) if len(color.shape) == 3 else color.copy()
    quality.processed_size = (color.shape[1], color.shape[0])

    logger.info("Preprocessing done: %s, size %s→%s", applied, quality.original_size, quality.processed_size)
    return PreprocessResult(color=color, gray=gray, quality=quality)

