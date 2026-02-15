"""End-to-end tests for the OCR extraction pipeline.

Run from the ocr_service/ directory:
    .venv/bin/python -m pytest tests/test_pipeline_e2e.py -v
"""
import sys
import os
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest


# ---- Ground truth expectations for image.png ----
EXPECTED_MED_COUNT = 4

EXPECTED_MED_NAMES = [
    "Butylscopolamine",
    "Celcoxx",
    "Omeprazole",
    "Multivitamine",
]

# Each inner list corresponds to one medication's four dose slots
# (morning, midday, afternoon, evening) as they appear in the ground truth.
EXPECTED_DOSES = [
    ["1", "-", "1", "-"],   # Butylscopolamine
    ["1", "-", "1", "-"],   # Celcoxx
    ["1", "-", "1", "-"],   # Omeprazole
    ["1", "1", "1", "-"],   # Multivitamine
]

EXPECTED_DURATIONS = [14, 14, 14, 21]

MAX_PROCESSING_SECONDS = 15


# =========================================================================
# Test: basic extraction succeeds
# =========================================================================
class TestExtractImage1:
    """Tests that run against the cached extraction result for image.png."""

    def test_extract_image1_success(self, extraction_result):
        """Pipeline returns success=True for image.png."""
        assert extraction_result["success"] is True, (
            f"Pipeline failed: {extraction_result.get('message', 'unknown error')}"
        )

    def test_extract_image1_medication_count(self, extraction_result):
        """Exactly 4 medications are detected."""
        meds = extraction_result["data"]["prescription"]["medications"]["items"]
        assert len(meds) == EXPECTED_MED_COUNT, (
            f"Expected {EXPECTED_MED_COUNT} medications, got {len(meds)}"
        )

    def test_extract_image1_medication_names(
        self, extraction_result, ground_truth_medications
    ):
        """All 4 medication brand names match the ground truth."""
        meds = extraction_result["data"]["prescription"]["medications"]["items"]
        extracted_names = [
            m["medication"]["name"]["brand_name"] for m in meds
        ]
        gt_names = [
            m["medication"]["name"]["brand_name"] for m in ground_truth_medications
        ]
        assert extracted_names == gt_names, (
            f"Name mismatch.\n  Expected: {gt_names}\n  Got:      {extracted_names}"
        )

    def test_extract_image1_dose_accuracy(
        self, extraction_result, ground_truth_medications
    ):
        """All 16 dose cells (4 meds x 4 time slots) match the ground truth."""
        meds = extraction_result["data"]["prescription"]["medications"]["items"]
        periods = ["morning", "midday", "afternoon", "evening"]

        mismatches = []
        for med_idx, med in enumerate(meds):
            slots = med["dosing"]["schedule"]["time_slots"]
            gt_slots = ground_truth_medications[med_idx]["dosing"]["schedule"]["time_slots"]
            for slot_idx, period in enumerate(periods):
                extracted_val = slots[slot_idx]["dose"]["value"]
                gt_val = gt_slots[slot_idx]["dose"]["value"]
                if extracted_val != gt_val:
                    med_name = med["medication"]["name"]["brand_name"]
                    mismatches.append(
                        f"  Med {med_idx + 1} ({med_name}) {period}: "
                        f"expected '{gt_val}', got '{extracted_val}'"
                    )

        assert not mismatches, (
            f"{len(mismatches)} dose cell(s) differ from ground truth:\n"
            + "\n".join(mismatches)
        )

    def test_extract_image1_duration_accuracy(
        self, extraction_result, ground_truth_medications
    ):
        """All 4 duration values match the ground truth."""
        meds = extraction_result["data"]["prescription"]["medications"]["items"]
        mismatches = []
        for med_idx, med in enumerate(meds):
            extracted_dur = med["dosing"]["duration"]["value"]
            gt_dur = ground_truth_medications[med_idx]["dosing"]["duration"]["value"]
            if extracted_dur != gt_dur:
                med_name = med["medication"]["name"]["brand_name"]
                mismatches.append(
                    f"  Med {med_idx + 1} ({med_name}): "
                    f"expected {gt_dur} days, got {extracted_dur}"
                )

        assert not mismatches, (
            f"{len(mismatches)} duration(s) differ from ground truth:\n"
            + "\n".join(mismatches)
        )


# =========================================================================
# Test: all three test images process successfully
# =========================================================================
class TestExtractAllImages:

    def test_extract_all_images(self, orchestrator, all_image_bytes):
        """All 3 test images should return success=True."""
        failures = []
        for filename, img_bytes in all_image_bytes:
            result = orchestrator.extract(img_bytes, filename=filename)
            if not result.get("success"):
                failures.append(
                    f"  {filename}: {result.get('message', 'unknown error')}"
                )
        assert not failures, (
            f"{len(failures)} image(s) failed extraction:\n" + "\n".join(failures)
        )


# =========================================================================
# Test: processing time stays under the budget
# =========================================================================
class TestPerformance:

    def test_processing_time(self, orchestrator, image_bytes):
        """Extraction of image.png completes in under 15 seconds."""
        start = time.time()
        result = orchestrator.extract(image_bytes, filename="image.png")
        elapsed = time.time() - start

        assert result["success"] is True, "Pipeline must succeed for timing to be valid"
        assert elapsed < MAX_PROCESSING_SECONDS, (
            f"Processing took {elapsed:.2f}s, exceeds {MAX_PROCESSING_SECONDS}s limit"
        )
