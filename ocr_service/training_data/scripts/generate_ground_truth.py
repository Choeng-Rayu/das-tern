#!/usr/bin/env python3
"""Generate Tesseract ground truth (.gt.txt) files from annotation JSONs.

Usage:
    python scripts/generate_ground_truth.py [--annotations-dir annotations/] [--output-dir ground_truth/]

Ground truth format:
    For each annotation, creates one .gt.txt file per text region.
    Naming: {image_id}_{region}_{field}.gt.txt
    Content: single line of ground truth text (UTF-8)
    Paired with: cropped image of the same region (in preprocessed/)
"""
import argparse
import json
import os
import sys

TRAINING_DATA_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_annotation(path: str) -> dict:
    """Load annotation JSON file."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def extract_ground_truth_entries(annotation: dict, image_id: str) -> list[dict]:
    """Extract all text entries from an annotation, producing (filename, text) pairs."""
    entries = []
    regions = annotation.get("annotation", {}).get("regions", {})

    # Header text
    header = regions.get("header", {})
    header_text = header.get("text", {})
    for field, value in header_text.items():
        if value:
            entries.append({
                "filename": f"{image_id}_header_{field}",
                "text": value,
                "region": "header",
                "field": field,
                "bbox": header.get("bbox"),
            })

    # Patient info fields
    patient = regions.get("patient_info", {})
    for field, info in patient.get("fields", {}).items():
        value = info.get("value")
        if value is not None:
            entries.append({
                "filename": f"{image_id}_patient_{field}",
                "text": str(value),
                "region": "patient_info",
                "field": field,
                "bbox": info.get("bbox"),
            })

    # Medication table rows
    med_table = regions.get("medication_table", {})
    for row in med_table.get("rows", []):
        row_num = row.get("row_number", 0)
        cells = row.get("cells", {})
        for cell_name, cell_data in cells.items():
            text = cell_data.get("text") or cell_data.get("value")
            if text and text.strip() and text.strip() != "-":
                entries.append({
                    "filename": f"{image_id}_med_r{row_num}_{cell_name}",
                    "text": str(text).strip(),
                    "region": "medication_table",
                    "field": f"row{row_num}_{cell_name}",
                    "bbox": cell_data.get("bbox"),
                })

    # Prescriber
    prescriber = regions.get("prescriber", {})
    if prescriber.get("name"):
        entries.append({
            "filename": f"{image_id}_prescriber_name",
            "text": prescriber["name"],
            "region": "prescriber",
            "field": "name",
            "bbox": prescriber.get("bbox"),
        })

    # Footer
    footer = regions.get("footer", {})
    if footer.get("text"):
        entries.append({
            "filename": f"{image_id}_footer",
            "text": footer["text"],
            "region": "footer",
            "field": "text",
            "bbox": footer.get("bbox"),
        })

    return entries


def write_ground_truth_files(entries: list[dict], output_dir: str) -> int:
    """Write .gt.txt files for each entry. Returns count of files written."""
    os.makedirs(output_dir, exist_ok=True)
    count = 0
    for entry in entries:
        gt_path = os.path.join(output_dir, f"{entry['filename']}.gt.txt")
        with open(gt_path, "w", encoding="utf-8") as f:
            f.write(entry["text"])
        count += 1
    return count


def generate_manifest(entries: list[dict], output_dir: str, image_id: str):
    """Write a manifest JSON listing all ground truth entries for an image."""
    manifest_path = os.path.join(output_dir, f"{image_id}_manifest.json")
    manifest = {
        "image_id": image_id,
        "total_entries": len(entries),
        "entries": [
            {
                "filename": e["filename"],
                "region": e["region"],
                "field": e["field"],
                "has_bbox": e["bbox"] is not None,
            }
            for e in entries
        ],
    }
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description="Generate Tesseract ground truth files from annotations")
    parser.add_argument(
        "--annotations-dir",
        default=os.path.join(TRAINING_DATA_DIR, "annotations"),
        help="Directory containing annotation JSON files",
    )
    parser.add_argument(
        "--output-dir",
        default=os.path.join(TRAINING_DATA_DIR, "ground_truth"),
        help="Directory to write .gt.txt files",
    )
    args = parser.parse_args()

    if not os.path.isdir(args.annotations_dir):
        print(f"Error: annotations directory not found: {args.annotations_dir}")
        sys.exit(1)

    annotation_files = sorted(
        f for f in os.listdir(args.annotations_dir) if f.endswith(".json")
    )

    if not annotation_files:
        print("No annotation JSON files found.")
        sys.exit(0)

    total_entries = 0
    for ann_file in annotation_files:
        ann_path = os.path.join(args.annotations_dir, ann_file)
        image_id = os.path.splitext(ann_file)[0]

        print(f"Processing {ann_file}...")
        annotation = load_annotation(ann_path)
        entries = extract_ground_truth_entries(annotation, image_id)

        count = write_ground_truth_files(entries, args.output_dir)
        generate_manifest(entries, args.output_dir, image_id)

        print(f"  -> {count} ground truth entries written")
        total_entries += count

    print(f"\nDone. Total: {total_entries} ground truth files in {args.output_dir}")


if __name__ == "__main__":
    main()
