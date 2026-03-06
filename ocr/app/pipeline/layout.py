"""Layout analysis for prescription images.

Identifies document regions (header, patient, table, footer) and provides
bounding-box-based row reconstruction for table-aware extraction.
"""
import logging
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

import cv2
import numpy as np

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class BBox:
    """A bounding box with associated text and metadata."""
    x: int
    y: int
    w: int
    h: int
    text: str = ""
    confidence: float = 0.0

    @property
    def cx(self) -> float:
        return self.x + self.w / 2.0

    @property
    def cy(self) -> float:
        return self.y + self.h / 2.0

    @property
    def x2(self) -> int:
        return self.x + self.w

    @property
    def y2(self) -> int:
        return self.y + self.h


@dataclass
class LayoutResult:
    """Result of layout analysis — proportional region boundaries."""
    image_size: Tuple[int, int] = (0, 0)  # (w, h)
    header_region: Optional[Tuple[int, int, int, int]] = None
    patient_region: Optional[Tuple[int, int, int, int]] = None
    clinical_region: Optional[Tuple[int, int, int, int]] = None
    table_region: Optional[Tuple[int, int, int, int]] = None
    footer_region: Optional[Tuple[int, int, int, int]] = None
    date_region: Optional[Tuple[int, int, int, int]] = None
    has_table_lines: bool = False


# ---------------------------------------------------------------------------
# Table Row Reconstructor
# ---------------------------------------------------------------------------

class TableRowReconstructor:
    """Reconstruct table rows from OCR bboxes using Y-axis alignment.

    Two boxes belong to the same row when:
        |center_y(a) - center_y(b)| <= tolerance

    Tolerance adapts to average box height when adaptive=True.
    """

    def __init__(self, tolerance: int = 15, adaptive: bool = True, adaptive_factor: float = 0.6):
        self.base_tolerance = tolerance
        self.adaptive = adaptive
        self.adaptive_factor = adaptive_factor

    def cluster_into_rows(self, boxes: List[BBox]) -> List[List[BBox]]:
        """Group boxes into rows sorted top-to-bottom, each row sorted left-to-right."""
        if not boxes:
            return []

        tol = self._tolerance(boxes)
        sorted_boxes = sorted(boxes, key=lambda b: b.cy)

        rows: List[List[BBox]] = []
        current: List[BBox] = [sorted_boxes[0]]

        for box in sorted_boxes[1:]:
            rep_y = self._rep_y(current)
            if abs(box.cy - rep_y) <= tol:
                current.append(box)
            else:
                rows.append(current)
                current = [box]
        if current:
            rows.append(current)

        for row in rows:
            row.sort(key=lambda b: b.x)
        rows.sort(key=lambda r: self._rep_y(r))
        return rows

    def _tolerance(self, boxes: List[BBox]) -> float:
        if not self.adaptive or not boxes:
            return float(self.base_tolerance)
        avg_h = sum(b.h for b in boxes) / len(boxes)
        return max(float(self.base_tolerance), avg_h * self.adaptive_factor)

    @staticmethod
    def _rep_y(row: List[BBox]) -> float:
        centers = sorted(b.cy for b in row)
        n = len(centers)
        if n % 2 == 1:
            return centers[n // 2]
        return (centers[n // 2 - 1] + centers[n // 2]) / 2.0


# ---------------------------------------------------------------------------
# Layout analysis
# ---------------------------------------------------------------------------

def _detect_table_lines(gray: np.ndarray) -> bool:
    """Detect if the image has clear horizontal/vertical table lines."""
    binary = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                    cv2.THRESH_BINARY_INV, 15, 5)
    h, w = gray.shape

    # Horizontal lines
    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (max(w // 8, 40), 1))
    h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)
    h_count = cv2.countNonZero(h_lines)

    # Vertical lines
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, max(h // 8, 40)))
    v_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, v_kernel)
    v_count = cv2.countNonZero(v_lines)

    has_lines = (h_count > w * 3) and (v_count > h * 2)
    logger.debug("Table line detection: h_pixels=%d, v_pixels=%d, has_lines=%s", h_count, v_count, has_lines)
    return has_lines


def analyze_layout(gray: np.ndarray) -> LayoutResult:
    """Analyze prescription layout and identify document regions.

    Uses proportional heuristics that work across different prescription
    formats (not hardcoded to any specific form).
    """
    h, w = gray.shape
    result = LayoutResult(image_size=(w, h))

    # Proportional region estimates — work for typical prescription layouts
    result.header_region = (0, 0, w, int(h * 0.15))
    result.patient_region = (0, int(h * 0.10), w, int(h * 0.30))
    result.clinical_region = (0, int(h * 0.22), w, int(h * 0.35))
    result.table_region = (0, int(h * 0.28), w, int(h * 0.82))
    result.footer_region = (0, int(h * 0.75), w, h)
    result.date_region = (int(w * 0.4), int(h * 0.55), w, int(h * 0.75))
    result.has_table_lines = _detect_table_lines(gray)

    logger.info("Layout: size=%dx%d, table_lines=%s", w, h, result.has_table_lines)
    return result

