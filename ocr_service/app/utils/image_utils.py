"""OpenCV helper functions for the OCR prescription scanning service.

This module provides pure utility functions for image preprocessing,
quality assessment, and geometric correction. All functions operate
on numpy arrays and are stateless.
"""

from typing import List, Tuple

import cv2
import numpy as np


def load_image(image_bytes: bytes) -> np.ndarray:
    """Load an image from raw bytes into a BGR numpy array.

    Decodes an in-memory byte buffer into an OpenCV image using
    ``cv2.imdecode``. This avoids writing temporary files to disk.

    Args:
        image_bytes: Raw image file content (JPEG, PNG, etc.).

    Returns:
        The decoded image as a BGR ``np.ndarray``.

    Raises:
        ValueError: If the byte buffer cannot be decoded into a valid image.
    """
    buf = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(buf, cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(
            "Failed to decode image from the provided bytes. "
            "Ensure the data is a valid image format (JPEG, PNG, etc.)."
        )
    return image


def check_blur(
    image: np.ndarray,
    threshold: float = 100.0,
) -> Tuple[bool, float]:
    """Check whether an image is blurry using the Laplacian variance method.

    A low Laplacian variance indicates a lack of sharp edges, which
    typically corresponds to a blurry or out-of-focus image.

    Args:
        image: Input image (BGR or grayscale).
        threshold: Variance value below which the image is considered
            blurry. The default of 100.0 works well for prescription
            documents scanned at reasonable resolution.

    Returns:
        A tuple of ``(is_blurry, variance)`` where *is_blurry* is
        ``True`` when the variance falls below *threshold*.
    """
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    laplacian = cv2.Laplacian(gray, cv2.CV_64F)
    variance = float(laplacian.var())
    is_blurry = variance < threshold
    return is_blurry, variance


def check_brightness(image: np.ndarray) -> Tuple[bool, float]:
    """Check whether the image brightness is within an acceptable range.

    Converts the image to grayscale and computes the mean pixel
    intensity. Values outside the 40-220 range suggest the image is
    too dark or too bright for reliable OCR.

    Args:
        image: Input image (BGR or grayscale).

    Returns:
        A tuple of ``(is_acceptable, mean_brightness)`` where
        *is_acceptable* is ``True`` when the mean pixel value is
        between 40 and 220 inclusive.
    """
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    mean_brightness = float(gray.mean())
    is_acceptable = 40.0 <= mean_brightness <= 220.0
    return is_acceptable, mean_brightness


def detect_skew(image: np.ndarray) -> float:
    """Detect the skew angle of a document image.

    Uses Canny edge detection followed by ``cv2.minAreaRect`` on the
    largest contour to estimate the rotation angle of the document.

    Args:
        image: Input image (BGR or grayscale).

    Returns:
        The estimated skew angle in degrees. A positive value
        indicates clockwise rotation; negative indicates
        counter-clockwise. Returns ``0.0`` if no meaningful contour
        is found.
    """
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    edges = cv2.Canny(gray, 50, 150, apertureSize=3)

    # Dilate to close small gaps in edge lines.
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
    edges = cv2.dilate(edges, kernel, iterations=1)

    contours, _ = cv2.findContours(
        edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
    )

    if not contours:
        return 0.0

    largest_contour = max(contours, key=cv2.contourArea)

    # minAreaRect requires at least 5 points for a meaningful fit.
    if len(largest_contour) < 5:
        return 0.0

    rect = cv2.minAreaRect(largest_contour)
    angle = rect[-1]

    # Normalise the angle returned by minAreaRect into the range
    # (-45, 45]. Values outside this range indicate that the
    # rectangle's longer side was detected along a different axis.
    if angle < -45.0:
        angle += 90.0
    elif angle > 45.0:
        angle -= 90.0

    return float(angle)


def deskew(image: np.ndarray, angle: float) -> np.ndarray:
    """Correct image skew by rotating around the centre.

    Applies an affine rotation so that text lines become horizontal.
    The output canvas is the same size as the input; border pixels
    created by the rotation are filled with white.

    Args:
        image: Input image (BGR or grayscale).
        angle: Rotation angle in degrees (as returned by
            :func:`detect_skew`). Positive values rotate clockwise.

    Returns:
        The deskewed image with the same dimensions as the input.
    """
    h, w = image.shape[:2]
    center = (w / 2.0, h / 2.0)
    rotation_matrix = cv2.getRotationMatrix2D(center, angle, 1.0)

    # Use white border fill so rotated corners do not introduce dark
    # artifacts near text regions.
    deskewed = cv2.warpAffine(
        image,
        rotation_matrix,
        (w, h),
        flags=cv2.INTER_LINEAR,
        borderMode=cv2.BORDER_CONSTANT,
        borderValue=(255, 255, 255),
    )
    return deskewed


def denoise(image: np.ndarray) -> np.ndarray:
    """Remove noise from a colour image using Non-Local Means Denoising.

    Wraps ``cv2.fastNlMeansDenoisingColored`` with parameters tuned
    for scanned prescription documents where moderate noise is common
    but text edges must be preserved.

    Args:
        image: Input BGR image.

    Returns:
        The denoised BGR image.
    """
    return cv2.fastNlMeansDenoisingColored(
        image,
        None,
        h=10,
        hForColorComponents=10,
        templateWindowSize=7,
        searchWindowSize=21,
    )


def enhance_contrast(
    image: np.ndarray,
    clip_limit: float = 2.0,
    grid_size: Tuple[int, int] = (8, 8),
) -> np.ndarray:
    """Enhance local contrast using CLAHE on the L channel of LAB space.

    Contrast-Limited Adaptive Histogram Equalisation is applied only
    to the luminance channel so that colour information is preserved.

    Args:
        image: Input BGR image.
        clip_limit: CLAHE clip limit controlling contrast amplification.
            Higher values produce stronger contrast but may amplify
            noise.
        grid_size: Size of the grid for histogram equalisation. Smaller
            grids produce more localised enhancement.

    Returns:
        The contrast-enhanced BGR image.
    """
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l_channel, a_channel, b_channel = cv2.split(lab)

    clahe = cv2.createCLAHE(
        clipLimit=clip_limit,
        tileGridSize=grid_size,
    )
    enhanced_l = clahe.apply(l_channel)

    merged = cv2.merge([enhanced_l, a_channel, b_channel])
    result = cv2.cvtColor(merged, cv2.COLOR_LAB2BGR)
    return result


def sharpen(image: np.ndarray) -> np.ndarray:
    """Sharpen an image using the unsharp-mask technique.

    A Gaussian-blurred copy is subtracted from the original to
    isolate high-frequency detail, which is then amplified and added
    back. This makes text edges crisper without introducing excessive
    ringing artifacts.

    Args:
        image: Input image (BGR or grayscale).

    Returns:
        The sharpened image with the same shape and dtype as the input.
    """
    blurred = cv2.GaussianBlur(image, (0, 0), sigmaX=3)
    # unsharp_mask = original + amount * (original - blurred)
    sharpened = cv2.addWeighted(image, 1.5, blurred, -0.5, 0)
    return sharpened


def resize_image(
    image: np.ndarray,
    max_dimension: int = 2000,
) -> np.ndarray:
    """Resize an image so that its largest dimension does not exceed a limit.

    The aspect ratio is preserved. If the image is already within the
    limit, it is returned unchanged (no upscaling).

    Args:
        image: Input image (BGR or grayscale).
        max_dimension: Maximum allowed width or height in pixels.

    Returns:
        The resized image, or the original if no resizing is needed.
    """
    h, w = image.shape[:2]
    current_max = max(h, w)

    if current_max <= max_dimension:
        return image

    scale = max_dimension / current_max
    new_w = int(w * scale)
    new_h = int(h * scale)
    resized = cv2.resize(
        image,
        (new_w, new_h),
        interpolation=cv2.INTER_AREA,
    )
    return resized


def to_grayscale(image: np.ndarray) -> np.ndarray:
    """Convert a BGR image to single-channel grayscale.

    If the image is already single-channel it is returned as-is.

    Args:
        image: Input image (BGR or grayscale).

    Returns:
        A single-channel grayscale image.
    """
    if len(image.shape) == 2:
        return image
    if image.shape[2] == 1:
        return image[:, :, 0]
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


def adaptive_threshold(image: np.ndarray) -> np.ndarray:
    """Apply adaptive thresholding to produce a binary image.

    Useful for isolating table lines, borders, and printed text from
    an uneven background. The input is first converted to grayscale
    and lightly blurred to reduce noise before thresholding.

    Args:
        image: Input image (BGR or grayscale).

    Returns:
        A binary (black-and-white) single-channel image where
        foreground pixels are white (255) and background is black (0).
    """
    gray = to_grayscale(image)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    binary = cv2.adaptiveThreshold(
        blurred,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        blockSize=11,
        C=2,
    )
    return binary


def detect_lines(
    image: np.ndarray,
) -> Tuple[List[np.ndarray], List[np.ndarray]]:
    """Detect horizontal and vertical lines in a document image.

    Applies adaptive thresholding and morphological operations to
    isolate line structures, then uses ``cv2.HoughLinesP`` to find
    individual line segments. Lines are classified as horizontal or
    vertical based on their angle relative to the image axes.

    Args:
        image: Input image (BGR or grayscale).

    Returns:
        A tuple of ``(horizontal_lines, vertical_lines)`` where each
        element is a list of line arrays with shape ``(1, 4)``
        containing ``[x1, y1, x2, y2]`` endpoints. Either list may
        be empty if no lines of that orientation are found.
    """
    binary = adaptive_threshold(image)
    h, w = binary.shape[:2]

    # --- Horizontal lines ---
    horizontal_kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT, (max(w // 30, 1), 1)
    )
    horizontal_mask = cv2.morphologyEx(
        binary, cv2.MORPH_OPEN, horizontal_kernel, iterations=2
    )

    h_lines_raw = cv2.HoughLinesP(
        horizontal_mask,
        rho=1,
        theta=np.pi / 180,
        threshold=80,
        minLineLength=w // 8,
        maxLineGap=20,
    )

    # --- Vertical lines ---
    vertical_kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT, (1, max(h // 30, 1))
    )
    vertical_mask = cv2.morphologyEx(
        binary, cv2.MORPH_OPEN, vertical_kernel, iterations=2
    )

    v_lines_raw = cv2.HoughLinesP(
        vertical_mask,
        rho=1,
        theta=np.pi / 180,
        threshold=80,
        minLineLength=h // 8,
        maxLineGap=20,
    )

    horizontal_lines: List[np.ndarray] = []
    if h_lines_raw is not None:
        for line in h_lines_raw:
            x1, y1, x2, y2 = line[0]
            # Accept lines within ~10 degrees of horizontal.
            if abs(y2 - y1) < abs(x2 - x1) * 0.18:
                horizontal_lines.append(line)

    vertical_lines: List[np.ndarray] = []
    if v_lines_raw is not None:
        for line in v_lines_raw:
            x1, y1, x2, y2 = line[0]
            # Accept lines within ~10 degrees of vertical.
            if abs(x2 - x1) < abs(y2 - y1) * 0.18:
                vertical_lines.append(line)

    return horizontal_lines, vertical_lines


def crop_region(
    image: np.ndarray,
    bbox: List[int],
) -> np.ndarray:
    """Crop a rectangular region from an image.

    Coordinates are clamped to the image boundaries so that
    out-of-bounds values do not raise errors.

    Args:
        image: Input image (BGR or grayscale).
        bbox: Bounding box as ``[x1, y1, x2, y2]`` where
            ``(x1, y1)`` is the top-left corner and ``(x2, y2)`` is
            the bottom-right corner. Values are in pixel coordinates.

    Returns:
        The cropped sub-image.

    Raises:
        ValueError: If the clamped bounding box has zero or negative
            area.
    """
    h, w = image.shape[:2]

    x1 = max(0, int(bbox[0]))
    y1 = max(0, int(bbox[1]))
    x2 = min(w, int(bbox[2]))
    y2 = min(h, int(bbox[3]))

    if x2 <= x1 or y2 <= y1:
        raise ValueError(
            f"Invalid crop region after clamping: "
            f"[{x1}, {y1}, {x2}, {y2}] for image of size {w}x{h}."
        )

    return image[y1:y2, x1:x2].copy()
