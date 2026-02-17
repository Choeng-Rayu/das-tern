"""Layout analysis for prescription images using OpenCV."""
import cv2
import numpy as np
from dataclasses import dataclass, field
from typing import List, Optional, Tuple, Dict


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
    """Find the medication table region by detecting grid structure."""
    h, w = gray.shape

    h_lines = detect_lines(gray, "horizontal")
    v_lines = detect_lines(gray, "vertical")

    if len(h_lines) >= 3 and len(v_lines) >= 2:
        # Table is bounded by outermost lines
        y_min = min(l[1] for l in h_lines)
        y_max = max(l[3] for l in h_lines)
        x_min = min(l[0] for l in v_lines)
        x_max = max(l[2] for l in v_lines)
        return (x_min, y_min, x_max, y_max)

    # Fallback: use contour detection to find large rectangular regions
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Find largest rectangular contour that looks like a table
    best = None
    best_area = 0
    for cnt in contours:
        x, y, cw, ch = cv2.boundingRect(cnt)
        area = cw * ch
        # Table should be wide and reasonably tall
        if cw > w * 0.5 and ch > h * 0.15 and area > best_area:
            best = (x, y, x + cw, y + ch)
            best_area = area

    return best


def extract_table_cells(gray: np.ndarray, table_bbox: Tuple[int, int, int, int]) -> TableRegion:
    """Extract individual cells from the table region.

    Uses known H-EQIP column proportions for reliable column positioning,
    and detected horizontal lines (or estimation) for row splitting.
    """
    x1, y1, x2, y2 = table_bbox
    table_img = gray[y1:y2, x1:x2]
    th, tw = table_img.shape

    # Use known H-EQIP prescription column proportions (from ground truth analysis)
    # Columns: item_number, medication_name, duration, instructions, morning, midday, afternoon, evening
    col_ratios = [0.043, 0.279, 0.136, 0.111, 0.080, 0.094, 0.153, 0.104]
    x_positions = [0]
    for ratio in col_ratios:
        x_positions.append(x_positions[-1] + int(tw * ratio))
    x_positions[-1] = tw  # Ensure last column reaches table edge

    # Detect horizontal lines for row splitting
    h_lines = detect_lines(table_img, "horizontal")
    if len(h_lines) >= 3:
        y_positions = sorted(set([0] + [l[1] for l in h_lines] + [l[3] for l in h_lines] + [th]))
        y_positions = _merge_close_values(y_positions, threshold=15)
    else:
        # Estimate rows: 1 header + 5 data rows
        estimated_row_count = 6
        y_positions = [int(i * th / estimated_row_count) for i in range(estimated_row_count + 1)]
        y_positions[-1] = th

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


def _merge_close_values(values: List[int], threshold: int = 10) -> List[int]:
    """Merge values that are within threshold of each other."""
    if not values:
        return []
    merged = [values[0]]
    for v in values[1:]:
        if v - merged[-1] > threshold:
            merged.append(v)
    return merged


def _estimate_grid(table_bbox: Tuple[int, int, int, int], gray: np.ndarray) -> TableRegion:
    """Estimate a grid when line detection fails."""
    x1, y1, x2, y2 = table_bbox
    tw = x2 - x1
    th = y2 - y1

    # Assume 8 columns with proportions matching H-EQIP prescription format
    col_ratios = [0.043, 0.279, 0.136, 0.111, 0.080, 0.094, 0.153, 0.104]
    col_positions = [x1]
    for ratio in col_ratios:
        col_positions.append(col_positions[-1] + int(tw * ratio))
    col_positions[-1] = x2

    # Estimate rows: 1 header + assume 5 data rows
    estimated_row_count = 6
    row_height = th // estimated_row_count
    row_positions = [y1 + i * row_height for i in range(estimated_row_count + 1)]
    row_positions[-1] = y2

    table = TableRegion(bbox=table_bbox, num_cols=8, num_rows=estimated_row_count)

    for row_idx in range(estimated_row_count):
        row_cells = []
        for col_idx in range(8):
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
    """Full layout analysis of a prescription image."""
    h, w = gray.shape
    result = LayoutResult(image_size=(w, h))

    # Heuristic region detection based on prescription layout
    result.header_region = (0, 0, w, int(h * 0.15))
    result.patient_region = (0, int(h * 0.12), w, int(h * 0.30))
    result.clinical_region = (0, int(h * 0.22), w, int(h * 0.38))

    # Table detection
    table_bbox = find_table_region(gray)
    if table_bbox:
        result.table = extract_table_cells(gray, table_bbox)
    else:
        # Fallback: estimate table region
        estimated_bbox = (int(w * 0.03), int(h * 0.35), int(w * 0.97), int(h * 0.65))
        result.table = _estimate_grid(estimated_bbox, gray)

    # Footer region
    result.footer_region = (0, int(h * 0.75), w, h)
    result.signature_region = (int(w * 0.5), int(h * 0.70), w, int(h * 0.85))
    result.date_region = (int(w * 0.4), int(h * 0.60), w, int(h * 0.75))

    return result
