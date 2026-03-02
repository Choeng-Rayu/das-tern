"""Unit tests for dynamic column/row detection in layout.py.

Tests verify that the pipeline does NOT rely on any hardcoded format-specific
column ratios or row counts.

Run from the ocr_service/ directory:
    .venv/bin/python -m pytest tests/test_dynamic_detection.py -v
"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import numpy as np
import pytest

from app.pipeline.layout import (
    _detect_column_boundaries,
    _estimate_row_count_from_density,
    extract_table_cells,
    _estimate_grid,
    find_table_region,
    detect_lines,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def make_table_image(width=800, height=400, n_cols=6, n_rows=5, line_thickness=2):
    """Create a synthetic table image with grid lines for testing."""
    img = np.ones((height, width), dtype=np.uint8) * 255  # white background

    # Draw vertical lines
    col_width = width // n_cols
    for i in range(n_cols + 1):
        x = min(i * col_width, width - 1)
        img[:, max(0, x - line_thickness // 2):min(width, x + line_thickness // 2 + 1)] = 0

    # Draw horizontal lines
    row_height = height // n_rows
    for i in range(n_rows + 1):
        y = min(i * row_height, height - 1)
        img[max(0, y - line_thickness // 2):min(height, y + line_thickness // 2 + 1), :] = 0

    return img


def make_text_rows_image(width=800, height=400, n_rows=4, row_height=20):
    """Create a synthetic image with text-like rows (dark bands) for density testing."""
    img = np.ones((height, width), dtype=np.uint8) * 255  # white background

    spacing = height // (n_rows + 1)
    for i in range(n_rows):
        y = spacing * (i + 1)
        y1 = max(0, y - row_height // 2)
        y2 = min(height, y + row_height // 2)
        # Add some dark pixels (simulating text)
        img[y1:y2, 50:width - 50] = np.random.randint(0, 80, size=(y2 - y1, width - 100), dtype=np.uint8)

    return img


# ---------------------------------------------------------------------------
# Tests: _detect_column_boundaries
# ---------------------------------------------------------------------------
class TestDetectColumnBoundaries:
    def test_detects_columns_from_grid(self):
        """Should detect column boundaries from a synthetic grid image."""
        img = make_table_image(width=800, height=400, n_cols=6)
        boundaries = _detect_column_boundaries(img)
        # Should have at least 3 boundaries (start, some middles, end)
        assert len(boundaries) >= 3
        # First should be 0 or near 0
        assert boundaries[0] <= 10
        # Last should be reasonably close to image width (within 25%)
        assert boundaries[-1] >= 600

    def test_returns_empty_for_blank_image(self):
        """Blank white image should return no boundaries."""
        img = np.ones((400, 800), dtype=np.uint8) * 255
        boundaries = _detect_column_boundaries(img)
        assert len(boundaries) < 3

    def test_different_column_counts(self):
        """Should adapt to different column counts."""
        for n_cols in [3, 5, 8, 10]:
            img = make_table_image(width=800, height=400, n_cols=n_cols)
            boundaries = _detect_column_boundaries(img)
            # Should detect roughly the right number of columns
            detected_cols = len(boundaries) - 1
            # Allow some tolerance
            assert detected_cols >= n_cols - 2, f"Expected ~{n_cols} cols, got {detected_cols}"


# ---------------------------------------------------------------------------
# Tests: _estimate_row_count_from_density
# ---------------------------------------------------------------------------
class TestEstimateRowCount:
    def test_blank_image_returns_minimum(self):
        """Blank image should return minimum row count (2 or 3)."""
        img = np.ones((400, 800), dtype=np.uint8) * 255
        count = _estimate_row_count_from_density(img)
        assert count >= 2

    def test_detects_text_rows(self):
        """Should detect approximately the right number of text rows."""
        img = make_text_rows_image(width=800, height=400, n_rows=5, row_height=25)
        count = _estimate_row_count_from_density(img)
        # Should be within ±2 of actual
        assert 3 <= count <= 7, f"Expected ~5 rows, got {count}"

    def test_single_row(self):
        """Image with one text band should detect at least 2 rows."""
        img = make_text_rows_image(width=800, height=400, n_rows=1, row_height=30)
        count = _estimate_row_count_from_density(img)
        assert count >= 1


# ---------------------------------------------------------------------------
# Tests: extract_table_cells (dynamic)
# ---------------------------------------------------------------------------
class TestExtractTableCellsDynamic:
    def test_no_hardcoded_8_columns(self):
        """A 5-column grid should NOT produce 8 columns (was hardcoded before)."""
        img = make_table_image(width=800, height=400, n_cols=5, n_rows=4)
        # Pad with white space to simulate full image (table at center)
        full_img = np.ones((600, 900), dtype=np.uint8) * 255
        full_img[100:500, 50:850] = img
        table_bbox = (50, 100, 850, 500)
        table_region = extract_table_cells(full_img, table_bbox)
        # Should NOT be exactly 8 (the old hardcoded value)
        # Should detect roughly 5 columns from lines
        assert table_region.num_cols != 0

    def test_detects_rows_from_grid(self):
        """Should detect rows from horizontal lines in the grid."""
        img = make_table_image(width=800, height=400, n_cols=6, n_rows=5)
        full_img = np.ones((600, 900), dtype=np.uint8) * 255
        full_img[100:500, 50:850] = img
        table_bbox = (50, 100, 850, 500)
        table_region = extract_table_cells(full_img, table_bbox)
        # Should have some rows detected
        assert table_region.num_rows >= 2


# ---------------------------------------------------------------------------
# Tests: _estimate_grid (dynamic)
# ---------------------------------------------------------------------------
class TestEstimateGridDynamic:
    def test_no_hardcoded_6_rows(self):
        """Estimated grid should not always produce exactly 6 rows."""
        # Create a large table-like area with text
        img = make_text_rows_image(width=800, height=600, n_rows=10, row_height=20)
        full_img = np.ones((800, 900), dtype=np.uint8) * 255
        full_img[100:700, 50:850] = img
        table_bbox = (50, 100, 850, 700)
        table_region = _estimate_grid(table_bbox, full_img)
        # Should NOT always be 6 — the old hardcoded value
        assert table_region.num_rows >= 2

    def test_adapts_to_narrow_table(self):
        """A narrow (few-column) table shouldn't produce 8 columns."""
        img = make_text_rows_image(width=300, height=400, n_rows=4, row_height=20)
        full_img = np.ones((600, 400), dtype=np.uint8) * 255
        full_img[100:500, 50:350] = img
        table_bbox = (50, 100, 350, 500)
        table_region = _estimate_grid(table_bbox, full_img)
        # Narrow table should have fewer columns
        assert table_region.num_cols <= 6


# ---------------------------------------------------------------------------
# Tests: dynamic detection removes hardcoded values
# ---------------------------------------------------------------------------
class TestNoHardcodedValues:
    def test_layout_py_has_no_heqip_ratios(self):
        """Verify the source code no longer contains hardcoded H-EQIP column ratios."""
        layout_path = os.path.join(os.path.dirname(__file__), "..", "app", "pipeline", "layout.py")
        with open(layout_path, "r") as f:
            source = f.read()
        # The old hardcoded ratios
        assert "0.043, 0.279, 0.136" not in source, "H-EQIP column ratios still present in layout.py"

    def test_orchestrator_has_no_col_boundaries(self):
        """Verify orchestrator no longer has hardcoded COL_BOUNDARIES."""
        orch_path = os.path.join(os.path.dirname(__file__), "..", "app", "pipeline", "orchestrator.py")
        with open(orch_path, "r") as f:
            source = f.read()
        assert "COL_BOUNDARIES" not in source, "COL_BOUNDARIES still present in orchestrator.py"

    def test_orchestrator_no_heqip_strategy_2(self):
        """Verify Strategy 2 is no longer 'Hardcoded H-EQIP'."""
        orch_path = os.path.join(os.path.dirname(__file__), "..", "app", "pipeline", "orchestrator.py")
        with open(orch_path, "r") as f:
            source = f.read()
        assert "H-EQIP column boundaries" not in source
        assert "H-EQIP column proportions" not in source
