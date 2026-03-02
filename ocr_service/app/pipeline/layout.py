"""Layout analysis for prescription images using OpenCV."""
import cv2
import logging
import numpy as np
from dataclasses import dataclass, field
from typing import List, Optional, Tuple, Dict

from app.config import settings

logger = logging.getLogger(__name__)


@dataclass
class CellInfo:
    """Represents a single cell in the medication table."""
    row: int
    col: int
    bbox: Tuple[int, int, int, int]  # x1, y1, x2, y2
    content_type: str = "unknown"  # item_number, medication_name, duration, instructions, morning, midday, afternoon, evening


@dataclass
class TableRegion:
    """Detected medication table."""
    bbox: Tuple[int, int, int, int]
    rows: List[List[CellInfo]] = field(default_factory=list)
    num_rows: int = 0
    num_cols: int = 0
    header_row: Optional[List[CellInfo]] = None


@dataclass
class LayoutResult:
    """Full layout analysis result."""
    image_size: Tuple[int, int] = (0, 0)
    header_region: Optional[Tuple[int, int, int, int]] = None
    patient_region: Optional[Tuple[int, int, int, int]] = None
    clinical_region: Optional[Tuple[int, int, int, int]] = None
    table: Optional[TableRegion] = None
    footer_region: Optional[Tuple[int, int, int, int]] = None
    signature_region: Optional[Tuple[int, int, int, int]] = None
    date_region: Optional[Tuple[int, int, int, int]] = None


COLUMN_TYPES = [
    "item_number", "medication_name", "duration", "instructions",
    "morning", "midday", "afternoon", "evening"
]


def detect_lines(gray: np.ndarray, direction: str = "horizontal") -> List[Tuple[int, int, int, int]]:
    """Detect horizontal or vertical lines using morphological operations."""
    if direction == "horizontal":
        kernel_size = (max(gray.shape[1] // 15, 1), 1)
    else:
        kernel_size = (1, max(gray.shape[0] // 15, 1))

    # Threshold
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, kernel_size)
    detected = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel, iterations=2)

    contours, _ = cv2.findContours(detected, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    lines = []
    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        if direction == "horizontal" and w > gray.shape[1] * 0.3:
            lines.append((x, y, x + w, y + h))
        elif direction == "vertical" and h > gray.shape[0] * 0.05:
            lines.append((x, y, x + w, y + h))

    # Sort: horizontal by y, vertical by x
    if direction == "horizontal":
        lines.sort(key=lambda l: l[1])
    else:
        lines.sort(key=lambda l: l[0])

    return lines


def find_table_region(gray: np.ndarray) -> Optional[Tuple[int, int, int, int]]:
    """Find the medication table region by detecting grid structure.

    Attempts multiple strategies to find the table.
    NOTE: Searches only the upper 82% of the image to avoid detecting
    footer/stamp areas at the bottom as the medication table.
    """
    h, w = gray.shape
    # Limit search zone to upper 82% — hospital stamps and "please return" notes
    # are typically at the bottom and would cause false positives
    search_h = int(h * settings.TABLE_SEARCH_HEIGHT_RATIO)
    search_gray = gray[:search_h, :]

    # Strategy 1: Morphological line detection in search zone
    h_lines = detect_lines(search_gray, "horizontal")
    v_lines = detect_lines(search_gray, "vertical")

    if len(h_lines) >= 3 and len(v_lines) >= 2:
        y_min = min(l[1] for l in h_lines)
        y_max = max(l[3] for l in h_lines)
        x_min = min(l[0] for l in v_lines)
        x_max = max(l[2] for l in v_lines)
        return (x_min, y_min, x_max, y_max)

    # Strategy 2: Use only horizontal lines
    if len(h_lines) >= 3:
        y_min = min(l[1] for l in h_lines)
        y_max = max(l[3] for l in h_lines)
        return (0, y_min, w, y_max)

    # Strategy 3: Contour-based — find large rectangular area in search zone
    for thresh_val in [0, 128, 160]:
        if thresh_val == 0:
            _, binary = cv2.threshold(search_gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        else:
            _, binary = cv2.threshold(search_gray, thresh_val, 255, cv2.THRESH_BINARY_INV)

        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        best = None
        best_area = 0
        for cnt in contours:
            x, y, cw, ch = cv2.boundingRect(cnt)
            area = cw * ch
            # Must be wide enough and tall enough, and not touching the very bottom of search zone
            if (cw > w * 0.4 and ch > h * 0.10 and area > best_area
                    and (y + ch) < search_h * 0.97):
                best = (x, y, x + cw, y + ch)
                best_area = area
        if best:
            return best

    # Strategy 4: Text-density scan in search zone
    _, binary = cv2.threshold(search_gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    row_sums = np.sum(binary, axis=1).astype(np.float32)
    kernel_size = max(search_h // 20, 3)
    row_sums_smooth = np.convolve(row_sums, np.ones(kernel_size) / kernel_size, mode='same')
    threshold_val = float(np.max(row_sums_smooth)) * 0.15
    dense = row_sums_smooth > threshold_val
    dense_rows = np.where(dense)[0]
    if len(dense_rows) > 0:
        return (0, int(dense_rows[0]), w, int(dense_rows[-1]))

    return None


def _detect_column_boundaries(table_img: np.ndarray) -> List[int]:
    """Detect column boundaries dynamically from vertical lines in the table image.

    Uses the same detect_lines() function used elsewhere for consistency, then
    extracts x-positions of detected vertical lines as column boundaries.

    Returns a list of x-positions (relative to table_img) representing column boundaries,
    or an empty list if insufficient lines are detected.
    """
    th, tw = table_img.shape

    # Use the established detect_lines function that has proven to work
    v_lines = detect_lines(table_img, "vertical")
    if len(v_lines) < 2:
        return []

    # Extract x-center of each vertical line
    x_centers = []
    for x1, y1, x2, y2 in v_lines:
        cx = (x1 + x2) // 2
        x_centers.append(cx)

    x_centers = sorted(set(x_centers))

    # Merge close x-values (noise from thick lines)
    min_gap = max(int(tw * settings.MIN_COLUMN_GAP_RATIO), 3)
    merged = [x_centers[0]]
    for cx in x_centers[1:]:
        if cx - merged[-1] > min_gap:
            merged.append(cx)

    # Build boundary list with 0 and tw as endpoints
    boundaries = [0]
    for cx in merged:
        if cx > min_gap and cx < tw - min_gap:
            boundaries.append(cx)
    # Need at least 3 boundaries (2 columns) to be useful
    if len(boundaries) < 3:
        return []

    return boundaries


def _estimate_row_count_from_density(table_img: np.ndarray) -> int:
    """Estimate the number of rows in a table from horizontal text-density peaks.

    Returns estimated row count (minimum 2, meaning 1 header + 1 data row).
    """
    th, tw = table_img.shape
    _, binary = cv2.threshold(table_img, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    # Sum pixels per row to get horizontal density profile
    row_sums = np.sum(binary, axis=1).astype(np.float32)
    if float(np.max(row_sums)) == 0:
        return 3  # fallback

    # Smooth the profile to reduce noise
    kernel_size = max(th // 40, 3)
    if kernel_size % 2 == 0:
        kernel_size += 1
    smoothed = np.convolve(row_sums, np.ones(kernel_size) / kernel_size, mode='same')

    # Find peaks (text rows) — threshold at configured fraction of max
    peak_threshold = float(np.max(smoothed)) * settings.TEXT_DENSITY_PEAK_THRESHOLD
    is_text = smoothed > peak_threshold

    # Count transitions from non-text to text (each is a row)
    row_count = 0
    in_text = False
    for val in is_text:
        if val and not in_text:
            row_count += 1
            in_text = True
        elif not val:
            in_text = False

    return max(row_count, 2)


def extract_table_cells(gray: np.ndarray, table_bbox: Tuple[int, int, int, int]) -> TableRegion:
    """Extract individual cells from the table region.

    Dynamically detects column boundaries from vertical lines.
    Falls back to equal-width columns based on estimated column count.
    Row boundaries come from horizontal lines or text-density estimation.
    """
    x1, y1, x2, y2 = table_bbox
    table_img = gray[y1:y2, x1:x2]
    th, tw = table_img.shape

    # --- Dynamic column detection ---
    col_boundaries = _detect_column_boundaries(table_img)
    if len(col_boundaries) >= 3:
        x_positions = col_boundaries
        logger.info(f"  extract_table_cells: {len(x_positions) - 1} columns detected from vertical lines")
    else:
        # Fallback: estimate column count from text regions, default to equal-width
        # Most prescription tables have 5-10 columns
        est_cols = 8  # reasonable default for medication tables
        col_width = tw // est_cols
        x_positions = [i * col_width for i in range(est_cols)] + [tw]
        logger.info(f"  extract_table_cells: no lines detected, using {est_cols} equal-width columns")
    x_positions[-1] = tw  # ensure last column reaches edge

    # --- Dynamic row detection ---
    h_lines = detect_lines(table_img, "horizontal")
    if len(h_lines) >= 3:
        y_positions = sorted(set([0] + [l[1] for l in h_lines] + [l[3] for l in h_lines] + [th]))
        y_positions = _merge_close_values(y_positions, threshold=settings.TABLE_MERGE_THRESHOLD)
        logger.info(f"  extract_table_cells: {len(y_positions) - 1} rows from horizontal lines")
    else:
        # Estimate row count from text density
        estimated_row_count = _estimate_row_count_from_density(table_img)
        y_positions = [int(i * th / estimated_row_count) for i in range(estimated_row_count + 1)]
        y_positions[-1] = th
        logger.info(f"  extract_table_cells: estimated {estimated_row_count} rows from text density")

    num_cols = len(x_positions) - 1
    num_rows = len(y_positions) - 1

    table = TableRegion(bbox=table_bbox, num_cols=num_cols, num_rows=num_rows)

    for row_idx in range(num_rows):
        row_cells = []
        for col_idx in range(num_cols):
            cell_x1 = x_positions[col_idx] + x1
            cell_y1 = y_positions[row_idx] + y1
            cell_x2 = x_positions[col_idx + 1] + x1
            cell_y2 = y_positions[row_idx + 1] + y1

            col_type = COLUMN_TYPES[col_idx] if col_idx < len(COLUMN_TYPES) else "unknown"

            cell = CellInfo(
                row=row_idx,
                col=col_idx,
                bbox=(cell_x1, cell_y1, cell_x2, cell_y2),
                content_type=col_type
            )
            row_cells.append(cell)

        if row_idx == 0:
            table.header_row = row_cells
        else:
            table.rows.append(row_cells)

    return table


def _merge_close_values(values: List[int], threshold: int = 0) -> List[int]:
    """Merge values that are within threshold of each other."""
    if not values:
        return []
    if threshold <= 0:
        threshold = settings.TABLE_MERGE_THRESHOLD
    merged = [values[0]]
    for v in values[1:]:
        if v - merged[-1] > threshold:
            merged.append(v)
    return merged


# ---------------------------------------------------------------------------
# BBox dataclass + TableRowReconstructor — bbox-based row grouping
# ---------------------------------------------------------------------------

@dataclass
class BBox:
    """A bounding box with [x, y, w, h] convention."""
    x: int
    y: int
    w: int
    h: int
    text: str = ""
    confidence: float = 0.0
    meta: Optional[Dict] = None

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

    def to_dict(self) -> Dict:
        return {
            "text": self.text,
            "x": self.x, "y": self.y, "w": self.w, "h": self.h,
            "bbox": [self.x, self.y, self.x + self.w, self.y + self.h],
            "confidence": self.confidence,
            **(self.meta or {}),
        }


class TableRowReconstructor:
    """Reconstruct table rows from OCR bounding boxes using Y-axis alignment.

    Two boxes belong to the same row when:
        |center_y(box_a) - center_y(box_b)| <= tolerance

    Tolerance is either fixed (ROW_Y_TOLERANCE) or adaptive:
        max(ROW_Y_TOLERANCE, avg_box_height * factor)
    """

    def __init__(
        self,
        tolerance: Optional[int] = None,
        adaptive: Optional[bool] = None,
        adaptive_factor: Optional[float] = None,
    ):
        self.base_tolerance: int = tolerance if tolerance is not None else settings.ROW_Y_TOLERANCE
        self.adaptive: bool = adaptive if adaptive is not None else settings.ROW_Y_TOLERANCE_ADAPTIVE
        self.adaptive_factor: float = (
            adaptive_factor if adaptive_factor is not None
            else settings.ROW_Y_TOLERANCE_ADAPTIVE_FACTOR
        )

    def cluster_into_rows(self, boxes: List[BBox]) -> List[List[BBox]]:
        """Group boxes into rows by center-Y alignment.

        Uses median center-Y as row representative (resists outlier drift).
        Returns rows sorted top→bottom, each row sorted left→right.
        """
        if not boxes:
            return []

        tolerance = self._compute_tolerance(boxes)
        sorted_boxes = sorted(boxes, key=lambda b: b.cy)

        rows: List[List[BBox]] = []
        current_row: List[BBox] = [sorted_boxes[0]]

        for box in sorted_boxes[1:]:
            row_rep_y = self._row_representative_y(current_row)
            if abs(box.cy - row_rep_y) <= tolerance:
                current_row.append(box)
            else:
                rows.append(current_row)
                current_row = [box]

        if current_row:
            rows.append(current_row)

        for row in rows:
            row.sort(key=lambda b: b.x)
        rows.sort(key=lambda r: self._row_representative_y(r))
        return rows

    def cluster_word_dicts(self, words: List[Dict]) -> List[List[Dict]]:
        """Group raw word dicts (from OCR engine) into rows of word dicts."""
        if not words:
            return []

        boxes = [
            BBox(
                x=w["x"], y=w["y"], w=w["w"], h=w["h"],
                text=w.get("text", ""),
                confidence=w.get("confidence", w.get("conf", 0) / 100.0 if "conf" in w else 0.0),
                meta={k: v for k, v in w.items() if k not in ("x", "y", "w", "h", "text", "confidence")},
            )
            for w in words
        ]

        grouped = self.cluster_into_rows(boxes)

        result: List[List[Dict]] = []
        for row in grouped:
            row_dicts = []
            for b in row:
                d = {
                    "text": b.text,
                    "x": b.x, "y": b.y, "w": b.w, "h": b.h,
                    "bbox": [b.x, b.y, b.x2, b.y2],
                    "confidence": b.confidence,
                }
                if b.meta:
                    d.update(b.meta)
                row_dicts.append(d)
            result.append(row_dicts)
        return result

    def _compute_tolerance(self, boxes: List[BBox]) -> float:
        if not self.adaptive or not boxes:
            return float(self.base_tolerance)
        avg_h = sum(b.h for b in boxes) / len(boxes)
        adaptive_tol = avg_h * self.adaptive_factor
        return max(float(self.base_tolerance), adaptive_tol)

    @staticmethod
    def _row_representative_y(row: List[BBox]) -> float:
        """Median center-Y — more robust than mean against outlier drift."""
        centers = sorted(b.cy for b in row)
        n = len(centers)
        if n % 2 == 1:
            return centers[n // 2]
        return (centers[n // 2 - 1] + centers[n // 2]) / 2.0


def _estimate_grid(table_bbox: Tuple[int, int, int, int], gray: np.ndarray) -> TableRegion:
    """Estimate a grid when line detection fails.

    Uses text-density analysis to estimate row count and equal-width column
    estimation (no hardcoded format assumptions).
    """
    x1, y1, x2, y2 = table_bbox
    tw = x2 - x1
    th = y2 - y1

    table_img = gray[y1:y2, x1:x2]

    # Estimate rows from text density
    estimated_row_count = _estimate_row_count_from_density(table_img)
    logger.info(f"  _estimate_grid: estimated {estimated_row_count} rows from density")

    # Try to detect columns from any partial vertical lines
    col_boundaries = _detect_column_boundaries(table_img)
    if len(col_boundaries) >= 3:
        n_cols = len(col_boundaries) - 1
        col_positions = [x1 + b for b in col_boundaries]
        logger.info(f"  _estimate_grid: {n_cols} columns detected from partial lines")
    else:
        # Equal-width columns — estimate column count from aspect ratio
        # Wider tables likely have more columns
        aspect = tw / max(th, 1)
        if aspect > 3.0:
            n_cols = 8
        elif aspect > 2.0:
            n_cols = 6
        elif aspect > 1.0:
            n_cols = 5
        else:
            n_cols = 4
        col_width = tw // n_cols
        col_positions = [x1 + i * col_width for i in range(n_cols)] + [x2]
        logger.info(f"  _estimate_grid: no lines, using {n_cols} equal-width columns (aspect={aspect:.1f})")

    col_positions[-1] = x2

    row_height = th // estimated_row_count
    row_positions = [y1 + i * row_height for i in range(estimated_row_count + 1)]
    row_positions[-1] = y2

    table = TableRegion(bbox=table_bbox, num_cols=n_cols, num_rows=estimated_row_count)

    for row_idx in range(estimated_row_count):
        row_cells = []
        for col_idx in range(n_cols):
            cell_x1 = col_positions[col_idx]
            cell_y1 = row_positions[row_idx]
            cell_x2 = col_positions[col_idx + 1] if col_idx + 1 < len(col_positions) else x2
            cell_y2 = row_positions[row_idx + 1] if row_idx + 1 < len(row_positions) else y2

            col_type = COLUMN_TYPES[col_idx] if col_idx < len(COLUMN_TYPES) else "unknown"
            cell = CellInfo(row=row_idx, col=col_idx, bbox=(cell_x1, cell_y1, cell_x2, cell_y2), content_type=col_type)
            row_cells.append(cell)

        if row_idx == 0:
            table.header_row = row_cells
        else:
            table.rows.append(row_cells)

    return table


def analyze_layout(gray: np.ndarray, color: np.ndarray) -> LayoutResult:
    """Full layout analysis of a prescription image.

    Region detection adapts based on table position when available,
    rather than using fixed hardcoded percentages.
    """
    h, w = gray.shape
    result = LayoutResult(image_size=(w, h))

    # Table detection first — its position anchors other regions
    table_bbox = find_table_region(gray)
    if table_bbox:
        result.table = extract_table_cells(gray, table_bbox)
        tb_y1 = table_bbox[1]  # table top
        tb_y2 = table_bbox[3]  # table bottom

        # Header region: from top to just above the table
        header_bottom = max(int(tb_y1 * 0.5), int(h * 0.05))
        result.header_region = (0, 0, w, header_bottom)

        # Patient region: between header and table top
        patient_top = max(header_bottom - int(h * 0.03), 0)
        result.patient_region = (0, patient_top, w, tb_y1)

        # Clinical region: overlaps with patient area (wider search)
        clinical_top = max(int(tb_y1 * 0.4), 0)
        result.clinical_region = (0, clinical_top, w, tb_y1)

        # Footer region: from table bottom to image bottom
        footer_top = min(tb_y2, h - 10)
        result.footer_region = (0, footer_top, w, h)

        # Signature: right half of footer area
        sig_top = max(footer_top - int(h * 0.05), tb_y2)
        result.signature_region = (w // 2, sig_top, w, min(int(h * 0.95), h))

        # Date: center-right area near footer
        date_top = max(footer_top - int(h * 0.10), tb_y2)
        result.date_region = (int(w * 0.3), date_top, w, min(int(h * 0.85), h))

    else:
        # No table detected — use proportional defaults (adaptive to image size)
        result.header_region = (0, 0, w, int(h * 0.15))
        result.patient_region = (0, int(h * 0.10), w, int(h * 0.30))
        result.clinical_region = (0, int(h * 0.20), w, int(h * 0.38))

        # Fallback table: cover the middle portion of the image
        estimated_bbox = (int(w * 0.01), int(h * 0.25), int(w * 0.99), int(h * 0.85))
        result.table = _estimate_grid(estimated_bbox, gray)

        result.footer_region = (0, int(h * 0.75), w, h)
        result.signature_region = (w // 2, int(h * 0.70), w, int(h * 0.85))
        result.date_region = (int(w * 0.4), int(h * 0.60), w, int(h * 0.75))

    return result

    return result
