"""Unit tests for BBox dataclass and TableRowReconstructor.

Run from the ocr_service/ directory:
    .venv/bin/python -m pytest tests/test_table_row_reconstructor.py -v
"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from app.pipeline.layout import BBox, TableRowReconstructor


# ---------------------------------------------------------------------------
# BBox basics
# ---------------------------------------------------------------------------
class TestBBox:
    def test_center_x(self):
        b = BBox(x=10, y=20, w=30, h=40)
        assert b.cx == 25.0

    def test_center_y(self):
        b = BBox(x=10, y=20, w=30, h=40)
        assert b.cy == 40.0

    def test_x2_y2(self):
        b = BBox(x=10, y=20, w=30, h=40)
        assert b.x2 == 40
        assert b.y2 == 60

    def test_to_dict(self):
        b = BBox(x=0, y=0, w=10, h=10, text="hello", confidence=0.9)
        d = b.to_dict()
        assert d["text"] == "hello"
        assert d["bbox"] == [0, 0, 10, 10]
        assert d["confidence"] == 0.9

    def test_meta_merged(self):
        b = BBox(x=0, y=0, w=5, h=5, meta={"extra": 42})
        d = b.to_dict()
        assert d["extra"] == 42


# ---------------------------------------------------------------------------
# TableRowReconstructor — basic grouping
# ---------------------------------------------------------------------------
class TestRowReconstructor:
    def test_empty_input(self):
        r = TableRowReconstructor()
        assert r.cluster_into_rows([]) == []

    def test_single_box(self):
        r = TableRowReconstructor()
        b = BBox(x=0, y=0, w=10, h=10, text="A")
        rows = r.cluster_into_rows([b])
        assert len(rows) == 1
        assert rows[0] == [b]


    def test_two_boxes_same_row(self):
        r = TableRowReconstructor(tolerance=15)
        b1 = BBox(x=0, y=100, w=50, h=20, text="A")
        b2 = BBox(x=60, y=102, w=50, h=20, text="B")
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1
        assert rows[0][0].text == "A"
        assert rows[0][1].text == "B"

    def test_two_boxes_different_rows(self):
        r = TableRowReconstructor(tolerance=10)
        b1 = BBox(x=0, y=0, w=50, h=20, text="A")
        b2 = BBox(x=0, y=100, w=50, h=20, text="B")
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 2

    def test_rows_sorted_top_to_bottom(self):
        r = TableRowReconstructor(tolerance=10)
        b1 = BBox(x=0, y=200, w=50, h=20, text="bottom")
        b2 = BBox(x=0, y=0, w=50, h=20, text="top")
        b3 = BBox(x=0, y=100, w=50, h=20, text="mid")
        rows = r.cluster_into_rows([b1, b2, b3])
        assert len(rows) == 3
        assert rows[0][0].text == "top"
        assert rows[1][0].text == "mid"
        assert rows[2][0].text == "bottom"

    def test_within_row_sorted_left_to_right(self):
        r = TableRowReconstructor(tolerance=15)
        b1 = BBox(x=100, y=50, w=30, h=20, text="right")
        b2 = BBox(x=0, y=50, w=30, h=20, text="left")
        rows = r.cluster_into_rows([b1, b2])
        assert rows[0][0].text == "left"
        assert rows[0][1].text == "right"

    def test_center_y_alignment(self):
        """Two boxes with different y but same center_y should be same row."""
        r = TableRowReconstructor(tolerance=5)
        b1 = BBox(x=0, y=100, w=50, h=20, text="A")  # cy=110
        b2 = BBox(x=60, y=95, w=50, h=30, text="B")  # cy=110
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1

    def test_median_y_prevents_drift(self):
        """Ensure median representative prevents outlier row merging."""
        r = TableRowReconstructor(tolerance=10)
        boxes = [
            BBox(x=0, y=100, w=10, h=10, text="1"),   # cy=105
            BBox(x=20, y=100, w=10, h=10, text="2"),  # cy=105
            BBox(x=40, y=100, w=10, h=10, text="3"),  # cy=105
            BBox(x=60, y=112, w=10, h=10, text="4"),  # cy=117 — |117-105|=12 > 10
        ]
        rows = r.cluster_into_rows(boxes)
        # cy difference 12 > tolerance 10 → should split into 2 rows
        assert len(rows) == 2
        # With larger tolerance, all should merge
        r2 = TableRowReconstructor(tolerance=15)
        rows2 = r2.cluster_into_rows(boxes)
        assert len(rows2) == 1

    def test_adaptive_tolerance(self):
        """Adaptive tolerance should scale with box height."""
        r = TableRowReconstructor(tolerance=5, adaptive=True, adaptive_factor=0.8)
        # boxes with h=20 → adaptive_tol = max(5, 20*0.8) = 16
        b1 = BBox(x=0, y=0, w=50, h=20, text="A")   # cy=10
        b2 = BBox(x=60, y=6, w=50, h=20, text="B")   # cy=16
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1  # 16-10=6 < adaptive_tol=16

    def test_adaptive_disabled(self):
        """When adaptive is off, only base tolerance is used."""
        r = TableRowReconstructor(tolerance=5, adaptive=False)
        b1 = BBox(x=0, y=0, w=50, h=20, text="A")   # cy=10
        b2 = BBox(x=60, y=6, w=50, h=20, text="B")   # cy=16
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 2  # 16-10=6 > 5


# ---------------------------------------------------------------------------
# cluster_word_dicts (dict-based interface)
# ---------------------------------------------------------------------------
class TestClusterWordDicts:
    def test_empty(self):
        r = TableRowReconstructor()
        assert r.cluster_word_dicts([]) == []

    def test_basic_grouping(self):
        r = TableRowReconstructor(tolerance=15)
        words = [
            {"text": "A", "x": 0, "y": 100, "w": 50, "h": 20, "conf": 90},
            {"text": "B", "x": 60, "y": 102, "w": 50, "h": 20, "conf": 90},
            {"text": "C", "x": 0, "y": 200, "w": 50, "h": 20, "conf": 90},
        ]
        rows = r.cluster_word_dicts(words)
        assert len(rows) == 2
        assert rows[0][0]["text"] == "A"
        assert rows[0][1]["text"] == "B"
        assert rows[1][0]["text"] == "C"

    def test_output_has_bbox_key(self):
        r = TableRowReconstructor(tolerance=15)
        words = [{"text": "X", "x": 10, "y": 20, "w": 30, "h": 40, "conf": 95}]
        rows = r.cluster_word_dicts(words)
        assert "bbox" in rows[0][0]
        assert rows[0][0]["bbox"] == [10, 20, 40, 60]


# ---------------------------------------------------------------------------
# Realistic prescription scenario
# ---------------------------------------------------------------------------
class TestRealisticPrescription:
    """Simulates 4 medication rows from a Cambodian prescription."""

    BOXES = [
        # Row 1: Butylscopolamine
        BBox(x=20, y=300, w=15, h=18, text="1"),
        BBox(x=50, y=298, w=180, h=22, text="Butylscopolamine"),
        BBox(x=250, y=300, w=30, h=18, text="10mg"),
        # Row 2: Celcoxx
        BBox(x=20, y=345, w=15, h=18, text="2"),
        BBox(x=50, y=343, w=100, h=22, text="Celcoxx"),
        BBox(x=160, y=345, w=40, h=18, text="200mg"),
        # Row 3: Omeprazole
        BBox(x=20, y=390, w=15, h=18, text="3"),
        BBox(x=50, y=388, w=130, h=22, text="Omeprazole"),
        BBox(x=190, y=390, w=40, h=18, text="20mg"),
        # Row 4: Multivitamine
        BBox(x=20, y=435, w=15, h=18, text="4"),
        BBox(x=50, y=433, w=160, h=22, text="Multivitamine"),
    ]

    def test_four_rows_detected(self):
        r = TableRowReconstructor(tolerance=15)
        rows = r.cluster_into_rows(self.BOXES)
        assert len(rows) == 4

    def test_row_contents(self):
        r = TableRowReconstructor(tolerance=15)
        rows = r.cluster_into_rows(self.BOXES)
        row_texts = [" ".join(b.text for b in row) for row in rows]
        assert "Butylscopolamine" in row_texts[0]
        assert "Celcoxx" in row_texts[1]
        assert "Omeprazole" in row_texts[2]
        assert "Multivitamine" in row_texts[3]

    def test_first_column_is_item_number(self):
        r = TableRowReconstructor(tolerance=15)
        rows = r.cluster_into_rows(self.BOXES)
        item_numbers = [rows[i][0].text for i in range(4)]
        assert item_numbers == ["1", "2", "3", "4"]


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------
class TestEdgeCases:
    def test_overlapping_boxes(self):
        """Boxes that completely overlap in Y should be same row."""
        r = TableRowReconstructor(tolerance=5)
        b1 = BBox(x=0, y=50, w=100, h=30, text="A")   # cy=65
        b2 = BBox(x=110, y=50, w=100, h=30, text="B")  # cy=65
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1

    def test_very_tall_box_adaptive(self):
        """Tall box should increase adaptive tolerance."""
        r = TableRowReconstructor(tolerance=5, adaptive=True, adaptive_factor=0.5)
        # h=60 → adaptive_tol = max(5, 60*0.5) = 30
        b1 = BBox(x=0, y=0, w=50, h=60, text="A")     # cy=30
        b2 = BBox(x=60, y=20, w=50, h=60, text="B")    # cy=50
        rows = r.cluster_into_rows([b1, b2])
        assert len(rows) == 1  # diff=20 < 30

    def test_mixed_heights(self):
        """Mixed height boxes should use average for adaptive tolerance."""
        r = TableRowReconstructor(tolerance=5, adaptive=True, adaptive_factor=0.5)
        # avg_h = (10+50)/2 = 30 → tol = max(5, 30*0.5) = 15
        b1 = BBox(x=0, y=0, w=50, h=10, text="A")     # cy=5
        b2 = BBox(x=60, y=0, w=50, h=50, text="B")     # cy=25
        rows = r.cluster_into_rows([b1, b2])
        # |25-5| = 20 > adaptive_tol=15 → 2 separate rows
        assert len(rows) == 2

    def test_many_boxes_per_row(self):
        """Ensure many boxes can be in a single row."""
        r = TableRowReconstructor(tolerance=10)
        boxes = [BBox(x=i * 30, y=50, w=25, h=15, text=f"w{i}") for i in range(20)]
        rows = r.cluster_into_rows(boxes)
        assert len(rows) == 1
        assert len(rows[0]) == 20

    def test_single_pixel_boxes(self):
        """Degenerate boxes with w=1, h=1."""
        r = TableRowReconstructor(tolerance=5)
        b1 = BBox(x=0, y=0, w=1, h=1, text="a")
        b2 = BBox(x=10, y=0, w=1, h=1, text="b")
        rows = r.cluster_into_rows([b1, b2])

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
