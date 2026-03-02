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
        assert len(rows) == 1
