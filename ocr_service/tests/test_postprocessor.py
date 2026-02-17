"""Unit tests for text parsing utilities used by the post-processor.

Run from the ocr_service/ directory:
    .venv/bin/python -m pytest tests/test_postprocessor.py -v
"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest

from app.utils.text_utils import parse_medication_name, parse_duration, parse_dose_value


# =========================================================================
# parse_medication_name
# =========================================================================
class TestParseMedicationName:
    """Tests for splitting raw medication text into (name, strength_val, strength_unit)."""

    def test_name_with_strength_mg(self):
        """'Butylscopolamine 10mg' splits into name + '10' + 'mg'."""
        name, val, unit = parse_medication_name("Butylscopolamine 10mg")
        assert name == "Butylscopolamine"
        assert val == "10"
        assert unit == "mg"

    def test_name_with_strength_mg_space(self):
        """Strength with a space before the unit is also accepted."""
        name, val, unit = parse_medication_name("Omeprazole 20 mg")
        assert name == "Omeprazole"
        assert val == "20"
        assert unit == "mg"

    def test_name_with_strength_100mg(self):
        """'Celcoxx 100mg' splits correctly."""
        name, val, unit = parse_medication_name("Celcoxx 100mg")
        assert name == "Celcoxx"
        assert val == "100"
        assert unit == "mg"

    def test_name_without_strength(self):
        """'Multivitamine' has no strength component."""
        name, val, unit = parse_medication_name("Multivitamine")
        assert name == "Multivitamine"
        assert val is None
        assert unit is None

    def test_empty_string(self):
        """Empty input returns empty name and None for strength."""
        name, val, unit = parse_medication_name("")
        assert name == ""
        assert val is None
        assert unit is None


# =========================================================================
# parse_duration
# =========================================================================
class TestParseDuration:
    """Tests for parsing duration text into (days, unit, note)."""

    def test_english_days(self):
        """'14 days' parses to 14 days with no note."""
        days, unit, note = parse_duration("14 days")
        assert days == 14
        assert unit == "days"
        assert note is None

    def test_khmer_days(self):
        """'14 \u1790\u17d2\u1784\u17c3' (Khmer for '14 days') parses to 14 days."""
        days, unit, note = parse_duration("14 \u1790\u17d2\u1784\u17c3")
        assert days == 14
        assert unit == "days"

    def test_khmer_days_until_finished(self):
        """'14 \u1790\u17d2\u1784\u17c3\u179a\u17bd\u179f\u17b6\u1794\u17cb' includes the 'until finished' note."""
        days, unit, note = parse_duration("14 \u1790\u17d2\u1784\u17c3\u179a\u17bd\u179f\u17b6\u1794\u17cb")
        assert days == 14
        assert unit == "days"
        assert note is not None
        assert "until finished" in note

    def test_21_days(self):
        """'21 \u1790\u17d2\u1784\u17c3' parses to 21 days."""
        days, unit, note = parse_duration("21 \u1790\u17d2\u1784\u17c3")
        assert days == 21

    def test_empty_string(self):
        """Empty input returns None days."""
        days, unit, note = parse_duration("")
        assert days is None
        assert unit == "days"


# =========================================================================
# parse_dose_value
# =========================================================================
class TestParseDoseValue:
    """Tests for converting dose cell text to (numeric, is_enabled)."""

    def test_one(self):
        """'1' maps to 1.0, enabled."""
        val, enabled = parse_dose_value("1")
        assert val == 1.0
        assert enabled is True

    def test_dash(self):
        """'-' maps to 0.0, disabled."""
        val, enabled = parse_dose_value("-")
        assert val == 0.0
        assert enabled is False

    def test_half_fraction(self):
        """'1/2' maps to 0.5, enabled."""
        val, enabled = parse_dose_value("1/2")
        assert val == 0.5
        assert enabled is True

    def test_zero(self):
        """'0' is treated as disabled."""
        val, enabled = parse_dose_value("0")
        assert val == 0.0
        assert enabled is False

    def test_empty(self):
        """Empty string is treated as disabled."""
        val, enabled = parse_dose_value("")
        assert val == 0.0
        assert enabled is False

    def test_two(self):
        """'2' maps to 2.0, enabled."""
        val, enabled = parse_dose_value("2")
        assert val == 2.0
        assert enabled is True

    def test_unicode_half(self):
        """Unicode fraction character '\u00bd' maps to 0.5."""
        val, enabled = parse_dose_value("\u00bd")
        assert val == 0.5
        assert enabled is True

    def test_em_dash(self):
        """Em-dash '\u2014' maps to 0.0, disabled."""
        val, enabled = parse_dose_value("\u2014")
        assert val == 0.0
        assert enabled is False
