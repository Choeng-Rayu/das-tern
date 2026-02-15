# OCR Training Data

Training data space for fine-tuning the Tesseract OCR model on Cambodian prescription images.

## Directory Structure

```
training_data/
├── raw_images/          # Original prescription images (PNG/JPEG)
├── annotations/         # Per-image annotation JSON files
├── ground_truth/        # Tesseract ground truth (.gt.txt) files
├── preprocessed/        # Preprocessed images (from pipeline preprocessor)
├── fine_tuned_models/   # Saved fine-tuned .traineddata files
├── scripts/             # Training and data preparation scripts
├── annotation_format.json   # Annotation schema definition
└── README.md            # This file
```

## Data Preparation Workflow

1. **Collect images** - Place prescription images in `raw_images/`
2. **Annotate** - Create annotation JSON per image in `annotations/`
3. **Generate ground truth** - Run `scripts/generate_ground_truth.py` to create Tesseract `.gt.txt` files
4. **Preprocess** - Run `scripts/preprocess_training.py` to enhance images
5. **Fine-tune** - Run `scripts/fine_tune_tesseract.sh` to train custom model

## Annotation Format

Each annotation file follows the schema in `annotation_format.json`. See that file for the complete field reference.

Example: For `raw_images/prescription_001.png`, create `annotations/prescription_001.json`.

## What to Annotate

Focus on the fields that matter most for accuracy:

| Priority | Field | Why |
|----------|-------|-----|
| Critical | Medication names | Most important OCR target |
| Critical | Dose values (1, 0.5, -) | Determines dosing schedule |
| Critical | Duration values | Treatment length |
| High | Patient ID | Identity verification |
| High | Diagnosis text | Clinical context |
| Medium | Prescriber name | Attribution |
| Low | Hospital headers | Usually template-matched |

## Minimum Dataset Size

| Model Type | Minimum Images | Recommended |
|-----------|---------------|-------------|
| Tesseract fine-tune (Latin/medication names) | 50 | 200+ |
| Tesseract fine-tune (Khmer text) | 100 | 500+ |
| Full custom model | 1000+ | 5000+ |

## Current Test Images

The following images from `test_space/images_for_test/` can be used as starting points:

- `image.png` - 4 medications, clear print, H-EQIP format
- `image1.png` - 3 medications, different layout
- `image2.png` - 5 medications, slightly different format
