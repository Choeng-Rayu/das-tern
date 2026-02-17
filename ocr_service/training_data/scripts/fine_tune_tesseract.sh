#!/bin/bash
# Fine-tune Tesseract OCR on prescription-specific training data.
#
# Prerequisites:
#   sudo apt-get install tesseract-ocr libtesseract-dev
#   pip install pytesseract
#
# Usage:
#   ./scripts/fine_tune_tesseract.sh [--lang eng] [--model-name prescription_eng]
#
# This script:
#   1. Validates training data (preprocessed images + .gt.txt ground truth)
#   2. Generates .lstmf training files from image+text pairs
#   3. Fine-tunes from the base Tesseract model
#   4. Saves the fine-tuned .traineddata to fine_tuned_models/

set -euo pipefail

# Defaults
LANG="${1:-eng}"
MODEL_NAME="${2:-prescription_${LANG}}"
TRAINING_DATA_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GROUND_TRUTH_DIR="${TRAINING_DATA_DIR}/ground_truth"
PREPROCESSED_DIR="${TRAINING_DATA_DIR}/preprocessed"
OUTPUT_DIR="${TRAINING_DATA_DIR}/fine_tuned_models"
WORK_DIR="${TRAINING_DATA_DIR}/.training_work"

# Tesseract paths
TESSDATA_PREFIX="${TESSDATA_PREFIX:-/usr/share/tesseract-ocr/5/tessdata}"
if [ ! -d "$TESSDATA_PREFIX" ]; then
    TESSDATA_PREFIX="/usr/share/tessdata"
fi

echo "============================================"
echo "Tesseract Fine-Tuning for Prescription OCR"
echo "============================================"
echo "Language:        ${LANG}"
echo "Model name:      ${MODEL_NAME}"
echo "Tessdata:        ${TESSDATA_PREFIX}"
echo "Ground truth:    ${GROUND_TRUTH_DIR}"
echo "Preprocessed:    ${PREPROCESSED_DIR}"
echo "Output:          ${OUTPUT_DIR}"
echo "============================================"
echo

# Step 0: Validate prerequisites
echo "[Step 0] Checking prerequisites..."

if ! command -v tesseract &>/dev/null; then
    echo "ERROR: tesseract not found. Install with: sudo apt-get install tesseract-ocr"
    exit 1
fi

TESS_VERSION=$(tesseract --version 2>&1 | head -1)
echo "  Tesseract: ${TESS_VERSION}"

if [ ! -f "${TESSDATA_PREFIX}/${LANG}.traineddata" ]; then
    echo "ERROR: Base model not found: ${TESSDATA_PREFIX}/${LANG}.traineddata"
    echo "  Install with: sudo apt-get install tesseract-ocr-${LANG}"
    exit 1
fi
echo "  Base model: ${TESSDATA_PREFIX}/${LANG}.traineddata"

# Check for training tools
COMBINE_TESSDATA=$(command -v combine_tessdata 2>/dev/null || echo "")
LSTMTRAINING=$(command -v lstmtraining 2>/dev/null || echo "")

if [ -z "$LSTMTRAINING" ]; then
    echo "WARNING: lstmtraining not found. Install tesseract training tools:"
    echo "  sudo apt-get install tesseract-ocr libtesseract-dev"
    echo ""
    echo "Generating training data files only (no model training)."
    TRAINING_TOOLS_AVAILABLE=false
else
    TRAINING_TOOLS_AVAILABLE=true
    echo "  lstmtraining: $(which lstmtraining)"
fi

# Step 1: Validate and count training pairs
echo
echo "[Step 1] Validating training data..."

GT_FILES=$(find "${GROUND_TRUTH_DIR}" -name "*.gt.txt" 2>/dev/null | wc -l)
if [ "${GT_FILES}" -eq 0 ]; then
    echo "ERROR: No .gt.txt files found in ${GROUND_TRUTH_DIR}"
    echo "  Run: python scripts/generate_ground_truth.py"
    exit 1
fi
echo "  Ground truth files: ${GT_FILES}"

PREPROCESSED_FILES=$(find "${PREPROCESSED_DIR}" -name "*.png" 2>/dev/null | wc -l)
echo "  Preprocessed images: ${PREPROCESSED_FILES}"

# Count matching pairs (image + gt.txt with same base name)
PAIRS=0
for gt_file in "${GROUND_TRUTH_DIR}"/*.gt.txt; do
    base=$(basename "${gt_file}" .gt.txt)
    if [ -f "${PREPROCESSED_DIR}/${base}.png" ]; then
        PAIRS=$((PAIRS + 1))
    fi
done
echo "  Matched pairs: ${PAIRS}"

if [ "${PAIRS}" -eq 0 ]; then
    echo
    echo "No matched image+ground_truth pairs found."
    echo "Ensure preprocessed images and .gt.txt files share the same base name."
    echo "  Example: preprocessed/image_001_med_r1_medication_name.png"
    echo "           ground_truth/image_001_med_r1_medication_name.gt.txt"
    echo
    echo "Steps to create pairs:"
    echo "  1. python scripts/generate_ground_truth.py"
    echo "  2. python scripts/preprocess_training.py --test-images"
    exit 1
fi

# Step 2: Create working directory and generate .lstmf files
echo
echo "[Step 2] Generating LSTM training files..."
mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

# Create training file list
TRAINING_LIST="${WORK_DIR}/training_files.txt"
> "${TRAINING_LIST}"

for gt_file in "${GROUND_TRUTH_DIR}"/*.gt.txt; do
    base=$(basename "${gt_file}" .gt.txt)
    img_file="${PREPROCESSED_DIR}/${base}.png"

    if [ ! -f "${img_file}" ]; then
        continue
    fi

    # Generate .lstmf using tesseract
    lstmf_file="${WORK_DIR}/${base}.lstmf"
    if [ ! -f "${lstmf_file}" ]; then
        # Create a .box file first, then generate lstmf
        tesseract "${img_file}" "${WORK_DIR}/${base}" \
            --tessdata-dir "${TESSDATA_PREFIX}" \
            -l "${LANG}" \
            --psm 7 \
            lstm.train \
            2>/dev/null || true
    fi

    if [ -f "${lstmf_file}" ]; then
        echo "${lstmf_file}" >> "${TRAINING_LIST}"
    fi
done

LSTMF_COUNT=$(wc -l < "${TRAINING_LIST}" 2>/dev/null || echo "0")
echo "  LSTMF files generated: ${LSTMF_COUNT}"

if [ "${LSTMF_COUNT}" -eq 0 ]; then
    echo "WARNING: No LSTMF files could be generated."
    echo "  This may be due to image quality or Tesseract configuration."
    echo "  Training data preparation complete, but model training skipped."
    exit 0
fi

# Step 3: Fine-tune the model
if [ "${TRAINING_TOOLS_AVAILABLE}" = true ]; then
    echo
    echo "[Step 3] Fine-tuning Tesseract model..."

    # Extract LSTM model from base traineddata
    BASE_LSTM="${WORK_DIR}/${LANG}.lstm"
    if [ ! -f "${BASE_LSTM}" ]; then
        combine_tessdata -e "${TESSDATA_PREFIX}/${LANG}.traineddata" "${BASE_LSTM}"
    fi

    # Fine-tune with lstmtraining
    CHECKPOINT="${WORK_DIR}/${MODEL_NAME}_checkpoint"
    lstmtraining \
        --model_output "${CHECKPOINT}" \
        --continue_from "${BASE_LSTM}" \
        --traineddata "${TESSDATA_PREFIX}/${LANG}.traineddata" \
        --train_listfile "${TRAINING_LIST}" \
        --max_iterations 400 \
        --target_error_rate 0.01 \
        2>&1 | tail -20

    # Combine into .traineddata
    FINAL_MODEL="${OUTPUT_DIR}/${MODEL_NAME}.traineddata"
    if ls "${CHECKPOINT}"_checkpoint 1>/dev/null 2>&1; then
        lstmtraining \
            --stop_training \
            --continue_from "${CHECKPOINT}_checkpoint" \
            --traineddata "${TESSDATA_PREFIX}/${LANG}.traineddata" \
            --model_output "${FINAL_MODEL}"

        echo
        echo "Fine-tuned model saved: ${FINAL_MODEL}"
        echo "To use: tesseract image.png output -l ${MODEL_NAME} --tessdata-dir ${OUTPUT_DIR}"
    else
        echo "WARNING: Training did not produce a checkpoint. More training data may be needed."
    fi
else
    echo
    echo "[Step 3] Skipped (training tools not available)"
    echo "  Training data files are ready in: ${WORK_DIR}"
fi

# Step 4: Summary
echo
echo "============================================"
echo "Summary"
echo "============================================"
echo "Ground truth entries:  ${GT_FILES}"
echo "Training pairs:        ${PAIRS}"
echo "LSTMF files:           ${LSTMF_COUNT}"
if [ -f "${OUTPUT_DIR}/${MODEL_NAME}.traineddata" ]; then
    echo "Fine-tuned model:      ${OUTPUT_DIR}/${MODEL_NAME}.traineddata"
fi
echo "============================================"

# Cleanup option
echo
echo "To clean up working files: rm -rf ${WORK_DIR}"
