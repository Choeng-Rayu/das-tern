"""OpenCV image processing utility functions."""
import cv2
import numpy as np
from dataclasses import dataclass, field
from typing import Optional, Tuple, List


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


def load_image_from_bytes(image_bytes: bytes) -> np.ndarray:
    """Load image from raw bytes into numpy array (BGR)."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Failed to decode image from bytes")
    return img


def to_grayscale(image: np.ndarray) -> np.ndarray:
    """Convert BGR image to grayscale."""
    if len(image.shape) == 2:
        return image
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


def check_blur(gray: np.ndarray, threshold: float = 100.0) -> Tuple[bool, float]:
    """Check if image is blurry using Laplacian variance."""
    score = cv2.Laplacian(gray, cv2.CV_64F).var()
    return score < threshold, float(score)


def check_brightness(gray: np.ndarray, min_val: int = 40, max_val: int = 220) -> Tuple[bool, bool, float]:
    """Check brightness. Returns (is_dark, is_bright, mean_brightness)."""
    mean_brightness = float(np.mean(gray))
    return mean_brightness < min_val, mean_brightness > max_val, mean_brightness


def detect_skew(gray: np.ndarray) -> Tuple[float, bool]:
    """Detect skew angle of the image."""
    coords = np.column_stack(np.where(gray < 128))
    if len(coords) < 100:
        return 0.0, False
    rect = cv2.minAreaRect(coords)
    angle = rect[-1]
    if angle < -45:
        angle = 90 + angle
    elif angle > 45:
        angle = angle - 90
    needs_deskew = abs(angle) > 0.5
    return float(angle), needs_deskew


def apply_denoise(image: np.ndarray) -> np.ndarray:
    """Apply non-local means denoising."""
    if len(image.shape) == 3:
        return cv2.fastNlMeansDenoisingColored(image, None, 10, 10, 7, 21)
    return cv2.fastNlMeansDenoising(image, None, 10, 7, 21)


def apply_clahe(image: np.ndarray, clip_limit: float = 2.0, grid_size: Tuple[int, int] = (8, 8)) -> np.ndarray:
    """Apply CLAHE contrast enhancement on LAB L-channel."""
    if len(image.shape) == 2:
        clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=grid_size)
        return clahe.apply(image)
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=grid_size)
    l = clahe.apply(l)
    lab = cv2.merge([l, a, b])
    return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)


def apply_sharpen(image: np.ndarray) -> np.ndarray:
    """Apply unsharp mask sharpening."""
    gaussian = cv2.GaussianBlur(image, (0, 0), 3)
    return cv2.addWeighted(image, 1.5, gaussian, -0.5, 0)


def apply_deskew(image: np.ndarray, angle: float) -> np.ndarray:
    """Deskew image by rotating by the detected angle."""
    if abs(angle) < 0.5:
        return image
    h, w = image.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    return cv2.warpAffine(image, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)


def resize_image(image: np.ndarray, max_dimension: int = 2000) -> np.ndarray:
    """Resize image to max dimension while preserving aspect ratio."""
    h, w = image.shape[:2]
    if max(h, w) <= max_dimension:
        return image
    scale = max_dimension / max(h, w)
    new_w = int(w * scale)
    new_h = int(h * scale)
    return cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)


def adaptive_threshold(gray: np.ndarray) -> np.ndarray:
    """Apply adaptive thresholding for better OCR on varied lighting."""
    return cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
    )


def crop_region(image: np.ndarray, bbox: Tuple[int, int, int, int]) -> np.ndarray:
    """Crop a region from image given bbox (x1, y1, x2, y2)."""
    x1, y1, x2, y2 = bbox
    h, w = image.shape[:2]
    x1 = max(0, x1)
    y1 = max(0, y1)
    x2 = min(w, x2)
    y2 = min(h, y2)
    return image[y1:y2, x1:x2]
