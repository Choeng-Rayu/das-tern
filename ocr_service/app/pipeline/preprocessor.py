"""Image preprocessing pipeline for OCR optimization."""
import cv2
import numpy as np
from typing import Tuple
from app.utils.image_utils import (
    load_image_from_bytes, to_grayscale, check_blur, check_brightness,
    detect_skew, apply_denoise, apply_clahe, apply_sharpen, apply_deskew,
    resize_image, QualityReport
)
from app.config import settings


def preprocess_image(image_bytes: bytes) -> Tuple[np.ndarray, np.ndarray, QualityReport]:
    """Full preprocessing pipeline.

    Returns: (processed_color, processed_gray, quality_report)
    """
    image = load_image_from_bytes(image_bytes)
    report = QualityReport()
    report.original_size = (image.shape[1], image.shape[0])

    gray = to_grayscale(image)

    # Quality checks
    report.is_blurry, report.blur_score = check_blur(gray, settings.BLUR_THRESHOLD)
    report.is_dark, report.is_bright, report.mean_brightness = check_brightness(
        gray, settings.MIN_BRIGHTNESS, settings.MAX_BRIGHTNESS
    )
    report.skew_angle, report.needs_deskew = detect_skew(gray)

    # Apply enhancements as needed
    processed = image.copy()

    # Denoise
    processed = apply_denoise(processed)
    report.preprocessing_applied.append("denoise")

    # Contrast enhancement
    if report.is_dark or report.is_bright:
        processed = apply_clahe(processed, settings.CLAHE_CLIP_LIMIT, settings.CLAHE_GRID_SIZE)
        report.preprocessing_applied.append("contrast_enhancement")

    # Sharpen if blurry
    if report.is_blurry:
        processed = apply_sharpen(processed)
        report.preprocessing_applied.append("sharpen")

    # Deskew
    if report.needs_deskew:
        processed = apply_deskew(processed, report.skew_angle)
        report.preprocessing_applied.append("deskew")

    # Resize
    processed = resize_image(processed, settings.MAX_IMAGE_DIMENSION)
    report.processed_size = (processed.shape[1], processed.shape[0])

    processed_gray = to_grayscale(processed)

    return processed, processed_gray, report
