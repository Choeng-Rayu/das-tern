"""Unit tests for TableRowReconstructor — bbox-based row grouping.

Run from the ocr_service/ directory:
    .venv/bin/python -m pytest tests/test_table_row_reconstructor.py -v
"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from app.pipeline.layout import BBox, TableRowReconstructor


# =========================================================================
# Helpers
# =========================================================================

def _make_box(x: int, y: int, w: int = 60, h: int = 20, text: str = "") -> BBox:
    """Shorthand for creating a BBox."""
    return BBox(x=x, y=y, w=w, h=h, text=text)


def _make_word(x: int, y: int, w: int = 60, h: int = 20, text: str = "", conf: int = 90) -> dict:
    """Shorthand for a word dict matching OCR engine format."""
    return {
        "text": text,
        "x": x, "y": y, "w": w, "h": h,
        "conf": conf,
        "bbox": [x, y, x + w, y + h],
        "confidence": conf / 100.0,
    }


# =========================================================================
# BBox dataclass sanity
# =========================================================================

class TestBBox:
    def test_center_coordinates(self):
        b = BBox(x=10, y=20, w=100, h=40)
        assert b.cx == 60.0
        assert b.cy == 40.0

    def test_edges(self):
        b = BBox(x=10, y=20, w=100, h=40)
        assert b.x2 == 110
        assert b.y2 == 60

    def test_to_dict(self):
        b = BBox(x=0, y=0, w=50, h=20, text="hello", confidence=0.9)
        d = b.to_dict()
        assert d["text"] == "hello"
        assert d["bbox"] == [0, 0, 50, 20]
        assert d["confidence"] == 0.9


# =========================================================================
# Basic row clustering
# =========================================================================

class TestClusterIntoRows:
    """Tests for cluster_into_rows with fixed tolerance (non-adaptive)."""

    def test_empty_input(self):
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        assert r.cluster_into_rows([]) == []

    def test_single_box(self):
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        b = _make_box(0, 0)
        rows = r.cluster_into_rows([b])
        assert len(rows) == 1
        assert rows[0] == [b]

    def test_two_boxes_same_row_exact_y(self):
        """Boxes at identical Y → same row."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        b1 = _make_box(0, 100, text="A")
        b2 = _make_box(200, 100, text="B")
        rows = r.cluster_into_rows([b2, b1])  # intentionally reversed
        assert len(rows) == 1
        # Sorted left→right
        assert rows[0][0].text == "A"
        assert rows[0][1].text == "B"

    def test_two_boxes_same_row_within_tolerance(self):
        """|cy1 - cy2| = 8 <= 10 → same row."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        b1 = _make_box(0, 100, h=20, text="A")   # cy = 110
        b2 = _make_box(200, 96, h=20, text="B")   # cy = 106
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1

    def test_two_boxes_different_rows_outside_tolerance(self):
        """|cy1 - cy2| = 30 > 10 → different rows."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        b1 = _make_box(0, 100, h=20, text="A")   # cy = 110
        b2 = _make_box(200, 130, h=20, text="B")  # cy = 140
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 2

    def test_three_rows(self):
        """Three distinct rows with multiple boxes each."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        boxes = [
            _make_box(100, 200, text="R2C2"),
            _make_box(0, 100, text="R1C1"),
            _make_box(200, 100, text="R1C2"),
            _make_box(0, 200, text="R2C1"),
            _make_box(0, 300, text="R3C1"),
            _make_box(300, 300, text="R3C2"),
        ]
        rows = r.cluster_into_rows(boxes)
        assert len(rows) == 3
        # Rows sorted top-to-bottom
        assert rows[0][0].text == "R1C1"
        assert rows[1][0].text == "R2C1"
        assert rows[2][0].text == "R3C1"
        # Each row sorted left-to-right
        assert rows[0][1].text == "R1C2"

    def test_tolerance_boundary_exact(self):
        """Exactly at tolerance boundary → same row."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        b1 = _make_box(0, 100, h=20)  # cy = 110
        b2 = _make_box(100, 100, h=40)  # cy = 120, |110 - 120| = 10
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1

    def test_tolerance_boundary_just_outside(self):
        """One pixel beyond tolerance → different rows."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        b1 = _make_box(0, 100, h=20)    # cy = 110
        b2 = _make_box(100, 101, h=40)  # cy = 121, |110 - 121| = 11 > 10
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 2


# =========================================================================
# Center-Y vs top-Y correctness
# =========================================================================

class TestCenterYAlignment:
    """Verify grouping uses center-Y, not top-Y."""

    def test_different_heights_same_center(self):
        """Two boxes: different heights but same visual center → same row."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        # Box 1: y=90, h=40  → cy = 110
        # Box 2: y=100, h=20 → cy = 110
        b1 = _make_box(0, 90, h=40, text="tall")
        b2 = _make_box(200, 100, h=20, text="short")
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1, "Boxes with same center-Y should be one row"

    def test_same_top_y_different_centers(self):
        """Same top-Y but very different heights → may or may not split depending on centers."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        # Box 1: y=100, h=20  → cy = 110
        # Box 2: y=100, h=100 → cy = 150
        b1 = _make_box(0, 100, h=20, text="small")
        b2 = _make_box(200, 100, h=100, text="huge")
        rows = r.cluster_into_rows([b1, b2])
        # |110 - 150| = 40 > 10
        assert len(rows) == 2, "Same top-Y but different centers should split"


# =========================================================================
# Adaptive tolerance
# =========================================================================

class TestAdaptiveTolerance:
    def test_adaptive_scales_with_box_height(self):
        """When adaptive is on, tolerance scales with avg box height."""
        # avg_h = 40, factor = 0.5 → adaptive_tol = 20, base = 10 → effective = 20
        r = TableRowReconstructor(tolerance=10, adaptive=True, adaptive_factor=0.5)
        # cy1 = 100 + 20 = 120, cy2 = 100 + 16 + 20 = 136
        # |120 - 136| = 16 — within 20 (adaptive) but outside 10 (base)
        b1 = _make_box(0, 100, h=40, text="A")
        b2 = _make_box(200, 116, h=40, text="B")
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1, "Adaptive tolerance should merge these boxes"

    def test_adaptive_uses_max_of_base_and_scaled(self):
        """If avg_h is tiny, base tolerance still applies."""
        # avg_h = 8, factor = 0.5 → adaptive_tol = 4, base = 10 → effective = 10
        r = TableRowReconstructor(tolerance=10, adaptive=True, adaptive_factor=0.5)
        b1 = _make_box(0, 100, h=8, text="A")  # cy = 104
        b2 = _make_box(200, 106, h=8, text="B")  # cy = 110, |104-110| = 6 <= 10
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1

    def test_adaptive_off_ignores_height(self):
        """When adaptive is off, uses only base tolerance."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        b1 = _make_box(0, 100, h=40, text="A")   # cy = 120
        b2 = _make_box(200, 116, h=40, text="B")  # cy = 136, |120-136| = 16 > 10
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 2


# =========================================================================
# Median representative prevents drift
# =========================================================================

class TestMedianRepresentative:
    def test_no_average_drift(self):
        """Adding many slightly-offset boxes doesn't drift the row into merging
        with a distant box (the old average-based bug)."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        # Row 1: boxes at cy ≈ 100
        row1 = [_make_box(i * 80, 90 + (i % 3), h=20, text=f"R1-{i}") for i in range(6)]
        # Row 2: box at cy ≈ 150
        row2_box = _make_box(0, 140, h=20, text="R2")
        rows = r.cluster_into_rows(row1 + [row2_box])
        # All row1 should be together, row2 separate
        assert len(rows) == 2
        row2_texts = [b.text for b in rows[1]]
        assert "R2" in row2_texts


# =========================================================================
# Word-dict interface
# =========================================================================

class TestClusterWordDicts:
    def test_preserves_extra_keys(self):
        """Extra keys in word dicts are preserved after clustering."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        words = [
            _make_word(0, 100, text="hello", conf=95),
            _make_word(200, 100, text="world", conf=88),
        ]
        # Add a custom key
        words[0]["custom_field"] = "keep_me"
        rows = r.cluster_word_dicts(words)
        assert len(rows) == 1
        assert any(w.get("custom_field") == "keep_me" for w in rows[0])

    def test_empty_words(self):
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        assert r.cluster_word_dicts([]) == []

    def test_output_has_bbox_key(self):
        """Each word dict in the output has a [x1, y1, x2, y2] bbox."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        rows = r.cluster_word_dicts([_make_word(10, 20, w=50, h=15)])
        assert rows[0][0]["bbox"] == [10, 20, 60, 35]


# =========================================================================
# Realistic prescription scenario
# =========================================================================

class TestPrescriptionScenario:
    """Simulate a 4-medication prescription with 8 columns."""

    @pytest.fixture
    def prescription_boxes(self) -> list:
        """4 rows, 8 columns each.  Y varies slightly within each row."""
        rows_data = [
            # (base_y, h, texts)
            (100, 22, ["1", "Butylscopolamine 10mg", "14 days", "after meal", "1", "-", "1", "-"]),
            (150, 20, ["2", "Celcoxx 100mg", "14 days", "after meal", "1", "-", "1", "-"]),
            (198, 24, ["3", "Omeprazole 20mg", "14 days", "before meal", "1", "-", "1", "-"]),
            (250, 22, ["4", "Multivitamine", "21 days", "", "1", "1", "1", "-"]),
        ]
        col_xs = [10, 50, 200, 340, 420, 480, 540, 620]
        boxes = []
        for base_y, h, texts in rows_data:
            for i, (col_x, text) in enumerate(zip(col_xs, texts)):
                # Add slight jitter to Y (±3px)
                jitter = (i % 5) - 2
                boxes.append(_make_box(col_x, base_y + jitter, w=70, h=h, text=text))
        return boxes

    def test_four_rows_detected(self, prescription_boxes):
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        rows = r.cluster_into_rows(prescription_boxes)
        assert len(rows) == 4, f"Expected 4 rows, got {len(rows)}"

    def test_eight_columns_per_row(self, prescription_boxes):
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        rows = r.cluster_into_rows(prescription_boxes)
        for i, row in enumerate(rows):
            assert len(row) == 8, f"Row {i} has {len(row)} boxes, expected 8"

    def test_medication_names_in_order(self, prescription_boxes):
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        rows = r.cluster_into_rows(prescription_boxes)
        names = [row[1].text for row in rows]  # col index 1 = medication name
        assert names == [
            "Butylscopolamine 10mg",
            "Celcoxx 100mg",
            "Omeprazole 20mg",
            "Multivitamine",
        ]

    def test_different_x_means_different_column(self, prescription_boxes):
        """All 8 boxes in a row have distinct X positions (different columns)."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        rows = r.cluster_into_rows(prescription_boxes)
        for row in rows:
            x_positions = [b.x for b in row]
            assert len(set(x_positions)) == len(x_positions), "All X positions should be unique within a row"


# =========================================================================
# Edge cases
# =========================================================================

class TestEdgeCases:
    def test_all_boxes_same_y(self):
        """All boxes at the same Y → single row."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        boxes = [_make_box(i * 100, 50, text=str(i)) for i in range(10)]
        rows = r.cluster_into_rows(boxes)
        assert len(rows) == 1
        assert len(rows[0]) == 10

    def test_each_box_separate_row(self):
        """Each box far apart → one row each."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        boxes = [_make_box(0, i * 100, text=str(i)) for i in range(5)]
        rows = r.cluster_into_rows(boxes)
        assert len(rows) == 5

    def test_large_height_variation_in_row(self):
        """Boxes with varying heights but aligned centers stay grouped."""
        r = TableRowReconstructor(tolerance=10, adaptive=False)
        # All centers at cy = 110
        boxes = [
            _make_box(0, 100, h=20),    # cy = 110
            _make_box(100, 95, h=30),   # cy = 110
            _make_box(200, 90, h=40),   # cy = 110
            _make_box(300, 85, h=50),   # cy = 110
        ]
        rows = r.cluster_into_rows(boxes)
        assert len(rows) == 1

    def test_zero_tolerance(self):
        """tolerance=0 only groups boxes with identical center-Y."""
        r = TableRowReconstructor(tolerance=0, adaptive=False)
        b1 = _make_box(0, 100, h=20)   # cy = 110
        b2 = _make_box(100, 100, h=20)  # cy = 110
        b3 = _make_box(200, 101, h=20)  # cy = 111
        rows = r.cluster_into_rows([b1, b2, b3])
        assert len(rows) == 2

    def test_very_large_tolerance(self):
        """Huge tolerance merges everything into one row."""
        r = TableRowReconstructor(tolerance=9999, adaptive=False)
        boxes = [_make_box(i * 100, i * 50) for i in range(5)]
        rows = r.cluster_into_rows(boxes)
        assert len(rows) == 1
