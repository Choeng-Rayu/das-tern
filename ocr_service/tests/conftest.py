"""Shared pytest fixtures for OCR service tests."""
import sys
import os
import json
import pytest

# Ensure the ocr_service package root is importable
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------
BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
IMAGES_DIR = os.path.join(BASE_DIR, "test_space", "images_for_test")
RESULTS_DIR = os.path.join(BASE_DIR, "test_space", "results")

# Test image filenames
TEST_IMAGE_FILES = ["image.png", "image1.png", "image2.png"]

# Ground truth file for image.png (image 1)
GROUND_TRUTH_FILE = os.path.join(
    RESULTS_DIR, "prescription_image_1_dynamic_populated.json"
)


# ---------------------------------------------------------------------------
# Fixtures — test images
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def image_bytes():
    """Load test_space/images_for_test/image.png as raw bytes."""
    path = os.path.join(IMAGES_DIR, "image.png")
    assert os.path.isfile(path), f"Test image not found: {path}"
    with open(path, "rb") as fh:
        return fh.read()


@pytest.fixture(scope="session")
def all_image_bytes():
    """Load all three test images as a list of (filename, bytes) tuples."""
    items = []
    for name in TEST_IMAGE_FILES:
        path = os.path.join(IMAGES_DIR, name)
        assert os.path.isfile(path), f"Test image not found: {path}"
        with open(path, "rb") as fh:
            items.append((name, fh.read()))
    return items


# ---------------------------------------------------------------------------
# Fixtures — ground truth
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def ground_truth():
    """Load ground truth JSON for image.png (image 1).

    Returns the full parsed JSON dict.
    """
    assert os.path.isfile(GROUND_TRUTH_FILE), (
        f"Ground truth file not found: {GROUND_TRUTH_FILE}"
    )
    with open(GROUND_TRUTH_FILE, "r", encoding="utf-8") as fh:
        return json.load(fh)


@pytest.fixture(scope="session")
def ground_truth_medications(ground_truth):
    """Return the list of medication items from the ground truth."""
    return ground_truth["prescription"]["medications"]["items"]


# ---------------------------------------------------------------------------
# Fixtures — pipeline
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def orchestrator():
    """Create a PipelineOrchestrator instance (reused across all tests)."""
    from app.pipeline.orchestrator import PipelineOrchestrator

    return PipelineOrchestrator()


@pytest.fixture(scope="session")
def extraction_result(orchestrator, image_bytes):
    """Run the pipeline once on image.png and cache the result for the session.

    This avoids re-running the expensive OCR for every single test.
    """
    result = orchestrator.extract(image_bytes, filename="image.png")
    return result
