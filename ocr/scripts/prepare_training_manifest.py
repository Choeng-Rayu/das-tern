#!/usr/bin/env python3
"""Create a JSONL annotation template for prescription OCR training."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def build_record(image_path: Path, base_dir: Path) -> dict:
    rel = image_path.relative_to(base_dir)
    return {
        "image_path": str(rel),
        "split": "train",
        "language_hint": ["km", "en", "fr"],
        "transcription_full": "",
        "patient": {
            "name": "",
            "age": "",
            "gender": "",
            "code": "",
        },
        "diagnoses": [],
        "medications": [
            {
                "name": "",
                "strength": "",
                "quantity": "",
                "form": "",
                "morning": "",
                "midday": "",
                "evening": "",
                "night": "",
                "duration_days": "",
                "instructions": "",
            }
        ],
        "notes": "",
        "verified": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a JSONL template for OCR training labels.")
    parser.add_argument("--images", type=Path, required=True, help="Folder containing prescription images")
    parser.add_argument("--output", type=Path, required=True, help="Output JSONL file path")
    parser.add_argument("--split", choices=["train", "val", "test"], default="train")
    args = parser.parse_args()

    image_dir = args.images.resolve()
    output_path = args.output.resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    images = sorted(p for p in image_dir.rglob("*") if p.is_file() and p.suffix.lower() in IMAGE_EXTS)
    if not images:
        raise SystemExit(f"No images found in {image_dir}")

    with output_path.open("w", encoding="utf-8") as f:
        for image_path in images:
            record = build_record(image_path, image_dir)
            record["split"] = args.split
            f.write(json.dumps(record, ensure_ascii=False) + "\n")

    print(f"Wrote {len(images)} template rows to {output_path}")
    print("Next step: fill the blank fields manually or with an annotation tool.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())