#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON_BIN="${1:-/home/rayu/ocr_service/.venv/bin/python}"

if [[ ! -x "${PYTHON_BIN}" ]]; then
  echo "Python interpreter not found or not executable: ${PYTHON_BIN}" >&2
  exit 1
fi

echo "==> Using Python: ${PYTHON_BIN}"
"${PYTHON_BIN}" -m pip install --upgrade pip

echo "==> Installing base OCR service dependencies"
"${PYTHON_BIN}" -m pip install -r "${PROJECT_DIR}/requirements.txt"

echo "==> Installing CPU PyTorch"
"${PYTHON_BIN}" -m pip install --index-url https://download.pytorch.org/whl/cpu torch

echo "==> Installing Kiri-OCR without its GPU-oriented transitive dependencies"
"${PYTHON_BIN}" -m pip install --no-deps kiri-ocr==0.2.15

echo "==> Verifying critical runtime imports"
"${PYTHON_BIN}" - <<'PY'
from importlib import import_module

for module_name in [
    'torch',
    'onnxruntime',
    'kiri_ocr',
    'cv2',
    'huggingface_hub',
    'safetensors',
    'pyclipper',
    'shapely',
]:
    import_module(module_name)

print('Runtime dependency verification passed.')
PY

echo "==> CPU runtime install complete"