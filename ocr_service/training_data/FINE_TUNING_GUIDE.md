# Tesseract Fine-Tuning Guide for Prescription OCR

Step-by-step guide for fine-tuning Tesseract on Cambodian prescription images.

## Overview

The OCR pipeline uses Tesseract for Khmer text and mixed-language content. Fine-tuning improves accuracy on domain-specific vocabulary (medication names, Khmer medical terms, duration units).

## Prerequisites

```bash
# System packages
sudo apt-get install -y tesseract-ocr tesseract-ocr-khm tesseract-ocr-eng tesseract-ocr-fra
sudo apt-get install -y libtesseract-dev  # training tools

# Python packages
pip install pytesseract opencv-python-headless numpy
```

Verify installation:
```bash
tesseract --version          # Should be 5.x
tesseract --list-langs       # Should include khm, eng, fra
which lstmtraining           # Should be available
which combine_tessdata       # Should be available
```

## Step 1: Collect Training Images

Place prescription images in `training_data/raw_images/`:

```
raw_images/
├── prescription_001.png
├── prescription_002.png
└── ...
```

**Sources:**
- Test images from `test_space/images_for_test/` (copy them over)
- New prescription scans from the mobile app
- Hospital-provided samples

**Quality requirements:**
- Minimum 300 DPI (or at least 960px wide)
- Clear, non-blurry text
- Good contrast (not washed out or too dark)
- Representative of real-world conditions (some noise is OK)

**Minimum dataset sizes:**

| Goal | Minimum Images | Recommended |
|------|---------------|-------------|
| English medication names | 50 | 200+ |
| Khmer text (labels, instructions) | 100 | 500+ |
| Full custom model | 1000+ | 5000+ |

## Step 2: Annotate Images

Create an annotation JSON for each image in `training_data/annotations/`.

Naming convention: For `raw_images/prescription_001.png`, create `annotations/image_001.json`.

See `annotation_format.json` for the schema. Example:

```json
{
  "annotation": {
    "image_file": "prescription_001.png",
    "annotator": "your_name",
    "annotated_at": "2026-02-16T10:00:00+07:00",
    "image_quality": "good",
    "prescription_format": "H-EQIP",
    "regions": {
      "header": {
        "bbox": [0, 0, 959, 180],
        "text": {
          "hospital_name_en": "Khmer-Soviet Friendship Hospital",
          "hospital_name_km": "មន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត",
          "system_name": "H-EQIP"
        }
      },
      "medication_table": {
        "bbox": [0, 400, 959, 850],
        "rows": [
          {
            "row_number": 1,
            "cells": {
              "medication_name": { "text": "Amoxicillin 500mg", "bbox": null }
            }
          }
        ]
      }
    }
  }
}
```

**Priority fields to annotate** (highest impact on accuracy):

1. `medication_name` — Most critical for patient safety
2. Dose values (`morning`, `midday`, `afternoon`, `evening`)
3. `duration` — Treatment length
4. `patient_id` — Identity verification
5. `diagnosis` — Clinical context

**Tips:**
- Use `null` for bboxes if you don't have pixel coordinates
- Focus on text accuracy over bbox precision
- Use the exact text as it appears on the prescription

## Step 3: Generate Ground Truth Files

Run the ground truth generator:

```bash
cd ocr_service/training_data
python scripts/generate_ground_truth.py
```

This creates `.gt.txt` files in `ground_truth/`:
```
ground_truth/
├── image_001_header_hospital_name_en.gt.txt
├── image_001_med_r1_medication_name.gt.txt
├── image_001_med_r1_morning.gt.txt
├── image_001_manifest.json
└── ...
```

Each `.gt.txt` contains one line of ground truth text (UTF-8).

## Step 4: Preprocess and Crop Regions

Run the preprocessing script:

```bash
python scripts/preprocess_training.py --test-images
```

This creates preprocessed image crops in `preprocessed/`:
```
preprocessed/
├── image_001_full.png           # Full preprocessed image
├── image_001_header.png         # Header region crop
├── image_001_medication_table.png  # Table crop
├── image_001_r1_medication_name.png  # Individual cell crops
└── ...
```

The cropped images are paired with `.gt.txt` files by matching base names.

## Step 5: Fine-Tune the Model

### English Medication Names

```bash
./scripts/fine_tune_tesseract.sh eng prescription_eng
```

### Khmer Text

```bash
./scripts/fine_tune_tesseract.sh khm prescription_khm
```

The script:
1. Validates training data pairs
2. Generates LSTM training files (`.lstmf`)
3. Fine-tunes from the base Tesseract model (400 iterations default)
4. Saves the result to `fine_tuned_models/prescription_eng.traineddata`

### Using the Fine-Tuned Model

```bash
# Direct Tesseract usage
tesseract image.png output -l prescription_eng --tessdata-dir fine_tuned_models/

# In the OCR pipeline, update config.py:
# TESSERACT_LANG: str = "prescription_eng"
# and copy the .traineddata to the system tessdata directory:
sudo cp fine_tuned_models/prescription_eng.traineddata /usr/share/tesseract-ocr/5/tessdata/
```

## Step 6: Evaluate Results

After fine-tuning, compare accuracy against your ground truth:

```bash
# Run the OCR pipeline test suite
cd ocr_service
python -m pytest tests/ -v

# Run the full pipeline on test images
python test_space/scription_for_test/test.ocr.perpos.py
```

Compare the OCR output against annotated ground truth. Key metrics:
- **Medication name accuracy**: >= 95% exact match
- **Dose value accuracy**: >= 98% (1, 0.5, - detection)
- **Duration parsing**: >= 90% correct extraction
- **Overall confidence**: target >= 0.85

## Iterative Improvement

```
Annotate more images
    ↓
Generate ground truth
    ↓
Preprocess + crop
    ↓
Fine-tune model
    ↓
Evaluate accuracy
    ↓
If accuracy < target → add more data, focus on failure cases
If accuracy >= target → deploy model
```

### Common Failure Patterns

| Issue | Solution |
|-------|----------|
| Medication name misspelled | Add more examples of that drug to training data |
| Khmer text garbled | Increase Khmer training samples, check image quality |
| Dose "-" read as "1" | Add more dash/empty cell examples |
| Duration units wrong | Add more "គ្រាប់", "ថ្ងៃ" examples |
| Paper fold artifacts | Add fold-affected images to training set |

## Directory Reference

```
training_data/
├── raw_images/              # Original prescription images
├── annotations/             # Per-image annotation JSON files
├── ground_truth/            # Generated .gt.txt files
├── preprocessed/            # Preprocessed + cropped regions
├── fine_tuned_models/       # Output .traineddata files
├── scripts/
│   ├── generate_ground_truth.py   # Annotation → .gt.txt
│   ├── preprocess_training.py     # Image preprocessing + cropping
│   └── fine_tune_tesseract.sh     # Model training script
├── annotation_format.json   # Annotation schema
├── FINE_TUNING_GUIDE.md     # This file
└── README.md                # Overview
```
