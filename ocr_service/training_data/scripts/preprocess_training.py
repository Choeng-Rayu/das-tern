#!/usr/bin/env python3
"""Preprocess training images and crop annotated regions for Tesseract training.

Usage:
    python scripts/preprocess_training.py [--images-dir raw_images/] [--annotations-dir annotations/] [--output-dir preprocessed/]

This script:
1. Loads raw prescription images from raw_images/
2. Applies the OCR pipeline preprocessor (denoise, contrast, deskew)
3. Crops individual regions based on annotation bboxes
4. Saves cropped regions paired with their .gt.txt ground truth
"""
import argparse
import json
import os
import sys

# Add parent directories to path for imports
TRAINING_DATA_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OCR_SERVICE_DIR = os.path.dirname(TRAINING_DATA_DIR)
sys.path.insert(0, OCR_SERVICE_DIR)

import cv2
import numpy as np


def load_image(path: str) -> np.ndarray:
    """Load image from file path."""
    img = cv2.imread(path)
    if img is None:
        raise FileNotFoundError(f"Cannot load image: {path}")
    return img


def preprocess_image(image: np.ndarray) -> np.ndarray:
    """Apply basic preprocessing matching the OCR pipeline."""
    try:
        from app.utils.image_utils import (
            apply_denoise, apply_clahe, to_grayscale,
            check_blur, apply_sharpen
        )
        from app.config import settings

        gray = to_grayscale(image)

        # Denoise
        image = apply_denoise(image)

        # CLAHE contrast enhancement
        image = apply_clahe(image, settings.CLAHE_CLIP_LIMIT, settings.CLAHE_GRID_SIZE)

        # Sharpen if blurry
        is_blurry, _ = check_blur(gray, settings.BLUR_THRESHOLD)
        if is_blurry:
            image = apply_sharpen(image)

        return image
    except ImportError:
        # Fallback: basic OpenCV preprocessing if pipeline not available
        print("  [warn] Pipeline imports unavailable, using basic preprocessing")
        denoised = cv2.fastNlMeansDenoisingColored(image, None, 10, 10, 7, 21)
        lab = cv2.cvtColor(denoised, cv2.COLOR_BGR2LAB)
        l_channel = lab[:, :, 0]
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        lab[:, :, 0] = clahe.apply(l_channel)
        return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)


def crop_region(image: np.ndarray, bbox: list) -> np.ndarray | None:
    """Crop a region from image using [x1, y1, x2, y2] bbox."""
    if not bbox or len(bbox) != 4:
        return None
    x1, y1, x2, y2 = [int(v) for v in bbox]
    h, w = image.shape[:2]
    x1 = max(0, min(x1, w))
    y1 = max(0, min(y1, h))
    x2 = max(0, min(x2, w))
    y2 = max(0, min(y2, h))
    if x2 <= x1 or y2 <= y1:
        return None
    return image[y1:y2, x1:x2]


def process_annotation(
    image: np.ndarray,
    annotation: dict,
    image_id: str,
    output_dir: str,
) -> int:
    """Crop all annotated regions and save as training pairs."""
    os.makedirs(output_dir, exist_ok=True)
    regions = annotation.get("annotation", {}).get("regions", {})
    saved = 0

    # Process each region type
    for region_name, region_data in regions.items():
        bbox = region_data.get("bbox")
        if not bbox:
            continue

        cropped = crop_region(image, bbox)
        if cropped is None:
            continue

        # Save the full region crop
        region_filename = f"{image_id}_{region_name}.png"
        cv2.imwrite(os.path.join(output_dir, region_filename), cropped)
        saved += 1

        # For medication table, also crop individual cells
        if region_name == "medication_table":
            table_bbox = bbox
            table_w = table_bbox[2] - table_bbox[0]
            table_h = table_bbox[3] - table_bbox[1]
            col_boundaries = region_data.get("column_boundaries", [])

            for row in region_data.get("rows", []):
                row_num = row.get("row_number", 0)
                row_bbox = row.get("bbox")

                cells = row.get("cells", {})
                for cell_name, cell_data in cells.items():
                    cell_bbox = cell_data.get("bbox")
                    if cell_bbox:
                        cell_crop = crop_region(image, cell_bbox)
                        if cell_crop is not None:
                            cell_filename = f"{image_id}_r{row_num}_{cell_name}.png"
                            cv2.imwrite(os.path.join(output_dir, cell_filename), cell_crop)
                            saved += 1

    return saved


def main():
    parser = argparse.ArgumentParser(description="Preprocess training images and crop regions")
    parser.add_argument(
        "--images-dir",
        default=os.path.join(TRAINING_DATA_DIR, "raw_images"),
        help="Directory containing raw prescription images",
    )
    parser.add_argument(
        "--annotations-dir",
        default=os.path.join(TRAINING_DATA_DIR, "annotations"),
        help="Directory containing annotation JSON files",
    )
    parser.add_argument(
        "--output-dir",
        default=os.path.join(TRAINING_DATA_DIR, "preprocessed"),
        help="Directory to save preprocessed/cropped images",
    )
    parser.add_argument(
        "--test-images",
        action="store_true",
        help="Also process images from test_space/images_for_test/",
    )
    args = parser.parse_args()

    annotation_files = sorted(
        f for f in os.listdir(args.annotations_dir) if f.endswith(".json")
    ) if os.path.isdir(args.annotations_dir) else []

    if not annotation_files:
        print("No annotation files found.")
        sys.exit(0)

    total_crops = 0
    for ann_file in annotation_files:
        ann_path = os.path.join(args.annotations_dir, ann_file)
        image_id = os.path.splitext(ann_file)[0]

        with open(ann_path, "r", encoding="utf-8") as f:
            annotation = json.load(f)

        image_file = annotation.get("annotation", {}).get("image_file", "")

        # Try to find the image
        image_path = os.path.join(args.images_dir, image_file)
        if not os.path.exists(image_path) and args.test_images:
            # Fallback: check test_space
            test_path = os.path.join(OCR_SERVICE_DIR, "test_space", "images_for_test", image_file)
            if os.path.exists(test_path):
                image_path = test_path

        if not os.path.exists(image_path):
            print(f"  [skip] Image not found: {image_file}")
            continue

        print(f"Processing {ann_file} -> {image_file}...")
        image = load_image(image_path)

        # Preprocess
        processed = preprocess_image(image)

        # Save full preprocessed image
        full_output = os.path.join(args.output_dir, f"{image_id}_full.png")
        os.makedirs(args.output_dir, exist_ok=True)
        cv2.imwrite(full_output, processed)

        # Crop and save regions
        count = process_annotation(processed, annotation, image_id, args.output_dir)
        print(f"  -> {count} region crops saved")
        total_crops += count

    print(f"\nDone. Total: {total_crops} cropped regions in {args.output_dir}")


if __name__ == "__main__":
    main()
