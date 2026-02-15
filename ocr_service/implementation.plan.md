# OCR Prescription Scanning Service — Implementation Plan

> **Version**: 1.0  
> **Created**: 2026-02-15  
> **Status**: Ready for Implementation  
> **Stack**: Python 3.10+ | FastAPI | PaddleOCR | Tesseract | OpenCV  

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [Critical Findings](#critical-findings)
- [Architecture](#architecture)
- [Technology Decisions](#technology-decisions)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Pipeline Design](#pipeline-design)
- [Output Format](#output-format)
- [API Design](#api-design)
- [Testing Strategy](#testing-strategy)
- [Performance Targets](#performance-targets)
- [Integration with Backend](#integration-with-backend)
- [Implementation Tasks](#implementation-tasks)
- [Future Improvements](#future-improvements)

---

## Executive Summary

Build a Python OCR microservice at `ocr_service/` that extracts structured JSON from Cambodian prescription images. The service handles mixed Khmer/English/French text, table-based medication layouts, and varied hospital formats. Output follows the **Dynamic Universal v2.0 schema** (`cambodia-prescription-universal-v2.0`).

**Key characteristics:**
- All open-source (Apache-2.0 compatible)
- Self-hosted, CPU-only (GPU upgrade path available)
- FastAPI REST endpoint for NestJS backend integration
- Target: < 4 seconds per image on 4-core CPU
- Handles printed text (handwriting support planned for future)

---

## Critical Findings

These findings were validated through deep research and correct errors in the original design document (`prompt.ocr.md`):

| Original Assumption | Reality | Impact |
|---------------------|---------|--------|
| PaddleOCR supports Khmer | **PaddleOCR does NOT support Khmer** (PP-OCRv5 covers 106 languages, Khmer not included) | Must use Tesseract for Khmer text |
| Kiri OCR exists as Khmer fallback | **Kiri OCR does NOT exist** (khmerlang org has no OCR repo) | Removed from pipeline |
| Surya OCR as alternative | **Surya is GPL-3.0 + commercial restrictions** (<$2M revenue limit) | Excluded per open-source preference |
| EasyOCR as option | **EasyOCR does NOT support Khmer** (80+ languages, no `km`) | Not viable |
| Single OCR engine | **Dual-engine approach required** | PaddleOCR for English + Tesseract for Khmer |

### Language Distribution Analysis (from test prescriptions)

| Content Type | Language | OCR Engine | Count |
|-------------|----------|-----------|-------|
| Medication names | English (Latin script) | PaddleOCR PP-OCRv5 | ~4-10 per prescription |
| Dosage values | Numeric | PaddleOCR (trivial) | ~16-40 cells |
| Patient ID, dates | English + numeric | PaddleOCR | ~5 fields |
| Column headers | Khmer | Template matching (skip OCR) | 8 fixed |
| Section labels | Khmer | Tesseract `khm` | ~10 labels |
| Duration units | Mixed (numeric + Khmer "ថ្ងៃ") | Both engines | ~4-10 fields |
| Footer/prescriber | Khmer + English | Both engines | ~5 fields |
| Hospital name | Khmer + English | Both engines | 2 fields |

**Key insight**: The most critical data (medication names, doses, quantities) is ALL in English/Latin script — PaddleOCR handles this perfectly. Khmer text is mainly structural labels with predictable patterns, making template matching + Tesseract adequate.

---

## Architecture

```
[Flutter App] --upload image--> [NestJS Backend :3001]
                                       |
                              HTTP POST (multipart)
                                       |
                              [FastAPI OCR Service :8000]
                                       |
                         ┌─────────────┴─────────────┐
                         |                           |
                    Preprocessor                 Config
                    (OpenCV)                  (thresholds,
               blur/denoise/deskew/           model paths)
               CLAHE/resize                        |
                         |                         |
                  Layout Analyzer ─────────────────┘
              (PP-StructureV3 table
               detection + OpenCV
               line fallback)
                         |
           ┌─────────────┴─────────────┐
           |                           |
     Table Cells                 Header / Footer
     PaddleOCR PP-OCRv5         Tesseract khm+eng+fra
     (English med names,        (Khmer labels,
      numbers, doses)            prescriber title,
           |                     footer notes)
           |                           |
           └─────────────┬─────────────┘
                         |
                   Post-Processor
              (normalize text,
               fuzzy med lexicon match,
               dosing schedule calc,
               Khmer numeral conversion)
                         |
                   Format Transformer
              (raw OCR → Static bbox
               → Dynamic Universal v2.0)
                         |
                   Schema Validator
              (JSON Schema validation)
                         |
                   API Response
              (Dynamic Universal v2.0 JSON)
                         |
                  [NestJS Backend]
              (maps to Prisma models,
               stores in PostgreSQL)
```

### Request Flow

1. Flutter app captures/uploads prescription image to NestJS backend
2. NestJS backend forwards image to OCR service via `POST /api/v1/extract`
3. OCR service preprocesses image (OpenCV: blur fix, contrast, deskew)
4. Layout analyzer detects table, header, footer regions (PP-StructureV3)
5. Per-region OCR: PaddleOCR for English/numeric, Tesseract for Khmer
6. Post-processor normalizes text, matches medication names, calculates dosing
7. Formatter produces Dynamic Universal v2.0 JSON
8. Response returned to NestJS backend
9. Backend maps JSON to Prescription + Medication[] Prisma models
10. Backend stores in PostgreSQL, returns structured data to Flutter

---

## Technology Decisions

| Component | Technology | Version | License | Why |
|-----------|-----------|---------|---------|-----|
| **API Framework** | FastAPI | ≥0.104 | MIT | Async, auto-docs, Pydantic built-in, fastest Python framework |
| **English/Latin OCR** | PaddleOCR PP-OCRv5 | 3.4.0 | Apache-2.0 | 106 languages, 2M param recognition, fast on CPU (~1.75s) |
| **Table Detection** | PaddleOCR PP-StructureV3 | 3.4.0 | Apache-2.0 | Best open-source table detector, Markdown/JSON output |
| **Khmer OCR** | Tesseract 5.x | 5.x | Apache-2.0 | Only viable FOSS Khmer engine (`khm.traineddata` available) |
| **Image Processing** | OpenCV | ≥4.8 | Apache-2.0 | Industry standard, comprehensive preprocessing |
| **Fuzzy Matching** | RapidFuzz | ≥3.0 | MIT | Fast Levenshtein for med name matching |
| **Validation** | Pydantic v2 | ≥2.0 | MIT | Type-safe schema validation |
| **ASGI Server** | Uvicorn | ≥0.24 | BSD | Production ASGI server |

### Rejected Technologies

| Technology | Reason for Rejection |
|-----------|---------------------|
| Kiri OCR | Does not exist |
| Surya OCR | GPL-3.0 license + commercial restrictions |
| EasyOCR | No Khmer language support |
| GOT-OCR2.0 | Requires CUDA, no Khmer support, 580M params too heavy for CPU |
| MMOCR | Archived/unmaintained, no Khmer support |
| Google Cloud Vision | Cloud-only (user requires self-hosted) |
| Flask | Inferior to FastAPI (no async, no auto-docs, no Pydantic) |

---

## Project Structure

```
ocr_service/
├── app/
│   ├── __init__.py
│   ├── main.py                     # FastAPI app entry, model loading at startup
│   ├── config.py                   # Settings: thresholds, model paths, timeouts
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes.py               # POST /api/v1/extract, GET /health
│   │   └── models.py              # Pydantic request/response models
│   ├── pipeline/
│   │   ├── __init__.py
│   │   ├── orchestrator.py         # Main pipeline coordinator
│   │   ├── preprocessor.py         # OpenCV image enhancement
│   │   ├── layout.py               # Table/region detection
│   │   ├── ocr_engine.py           # PaddleOCR + Tesseract wrapper
│   │   ├── postprocessor.py        # Text normalization, lexicon, dosing
│   │   └── formatter.py            # Raw → Static → Dynamic Universal
│   ├── models/
│   │   ├── __init__.py
│   │   ├── static_schema.py        # Pydantic: static bbox format (debug)
│   │   └── dynamic_schema.py       # Pydantic: dynamic universal v2.0 (API)
│   └── utils/
│       ├── __init__.py
│       ├── image_utils.py           # OpenCV helper functions
│       ├── text_utils.py            # Khmer/English normalization, numeral conversion
│       └── med_lexicon.py           # Medication name fuzzy matcher
├── data/
│   ├── lexicons/
│   │   ├── medications_en.txt       # 200+ common drug names (English)
│   │   ├── medications_km.txt       # Khmer pharmacy terms
│   │   └── column_headers.json      # Known Khmer table header templates
│   └── models/                      # Auto-downloaded OCR weights (.gitignored)
├── schemas/
│   ├── static_v1.schema.json        # JSON Schema for static bbox format
│   └── dynamic_v2.schema.json       # JSON Schema for universal v2.0
├── tests/
│   ├── __init__.py
│   ├── conftest.py                  # Fixtures: test images, ground truth loader
│   ├── test_preprocessor.py         # Blur, deskew, contrast tests
│   ├── test_layout.py               # Table detection, cell extraction tests
│   ├── test_ocr_engine.py           # OCR accuracy per engine tests
│   ├── test_postprocessor.py        # Med name splitting, dose calc tests
│   └── test_pipeline_e2e.py         # Regression tests vs ground truth
├── test_space/                      # Existing test data (preserved)
│   ├── images_for_test/
│   │   ├── image.png
│   │   ├── image1.png
│   │   └── image2.png
│   ├── results/
│   │   ├── final.result.format.expected.json    # Canonical schema definition
│   │   ├── prescription_image_1_dynamic_populated.json  # Ground truth
│   │   ├── prescription_image_1_static_with_bbox.json   # Debug reference
│   │   ├── FORMAT_COMPARISON.md
│   │   ├── README.md
│   │   └── archived/               # Superseded formats
│   │       ├── prescription.dynamic.format.json  # v1.0 (superseded by v2.0)
│   │       └── result.already.defined.json       # Legacy reminder format
│   └── scription_for_test/
│       └── README.md
├── requirements.txt
├── requirements-dev.txt
├── pyproject.toml
├── Makefile
├── implementation.plan.md           # This file
├── prompt.ocr.md                    # Original design notes (reference only)
└── README.md
```

---

## Dependencies

### requirements.txt

```
# API
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
python-multipart>=0.0.6

# OCR Engines
paddlepaddle>=2.6.0          # PaddlePaddle CPU
paddleocr>=2.9.0             # PaddleOCR with PP-OCRv5

# Image Processing
opencv-python-headless>=4.8.0
Pillow>=10.0.0
numpy>=1.24.0

# Khmer OCR (Tesseract wrapper)
pytesseract>=0.3.10

# Text & Validation
rapidfuzz>=3.0.0             # Fuzzy string matching
pydantic>=2.0.0              # Schema validation
jsonschema>=4.0.0            # JSON Schema validation

# Utilities
python-dotenv>=1.0.0
```

### requirements-dev.txt

```
pytest>=7.0.0
pytest-asyncio>=0.21.0
httpx>=0.24.0                # Async test client for FastAPI
coverage>=7.0.0
```

### System Dependencies (apt)

```bash
# Tesseract OCR with Khmer, English, French language data
sudo apt-get install -y tesseract-ocr tesseract-ocr-khm tesseract-ocr-eng tesseract-ocr-fra

# OpenCV system dependency
sudo apt-get install -y libgl1-mesa-glx libglib2.0-0
```

---

## Pipeline Design

### Step 1: Image Preprocessing (`app/pipeline/preprocessor.py`)

```
Input: raw image bytes
  │
  ├── Load image (cv2.imdecode)
  ├── Convert to RGB + grayscale
  ├── Quality Check:
  │     ├── Blur detection (Laplacian variance, threshold: 100.0)
  │     ├── Brightness check (mean pixel 40-220 range)
  │     └── Skew detection (minAreaRect angle)
  ├── Enhancement (if needed):
  │     ├── Denoise (fastNlMeansDenoisingColored)
  │     ├── Contrast (CLAHE on LAB L-channel, clipLimit=2.0, grid=8x8)
  │     ├── Sharpen (unsharp mask if blurry)
  │     └── Deskew (warpAffine rotation correction)
  ├── Resize (max dimension 2000px, preserve aspect ratio)
  │
Output: processed image (numpy array) + QualityReport
```

### Step 2: Layout Analysis (`app/pipeline/layout.py`)

```
Input: preprocessed image
  │
  ├── Primary: PaddleOCR PP-StructureV3
  │     ├── Detect table regions
  │     ├── Detect text blocks
  │     └── Detect headers/footers
  │
  ├── Fallback: OpenCV Line Detection
  │     ├── Hough transform (horizontal + vertical lines)
  │     ├── Find intersections → build cell grid
  │     └── Sort cells by row/column position
  │
  ├── Region Classification:
  │     ├── Header region (top 15% of image)
  │     ├── Patient info region (below header, above table)
  │     ├── Medication table (detected table bbox)
  │     ├── Footer region (bottom 20% of image)
  │     ├── Signature area (bottom-right quadrant)
  │     └── QR code region (if detected)
  │
  ├── Column Identification (for medication table):
  │     ├── Position order mapping (left→right):
  │     │   [item_number, medication_name, duration, instructions,
  │     │    morning, midday, afternoon, evening]
  │     └── Template match headers against column_headers.json
  │
Output: LayoutResult (region bboxes, table cells, column mapping)
```

### Step 3: OCR Engine (`app/pipeline/ocr_engine.py`)

```
Input: cropped region image + expected_content type
  │
  ├── Engine Selection:
  │     ├── english/latin → PaddleOCR PP-OCRv5 (use_angle_cls=True, lang='en')
  │     ├── numeric → PaddleOCR (digit recognition)
  │     ├── khmer → Tesseract (lang='khm+eng+fra', oem=1, psm=6)
  │     └── mixed → run BOTH, merge best confidence
  │
  ├── Language Auto-Detection:
  │     ├── U+1780–U+17FF range → Khmer script detected
  │     ├── U+0020–U+007F → ASCII/English
  │     └── Mixed → both engines
  │
  ├── Column Header Shortcut:
  │     ├── Known headers in column_headers.json
  │     ├── Fuzzy match (rapidfuzz, threshold 80%)
  │     └── Skip OCR for matched templates
  │
  ├── Confidence Classification:
  │     ├── ≥ 0.80 → auto-accept
  │     ├── 0.60–0.80 → accept + flag for review
  │     └── < 0.60 → mark needs_review: true
  │
Output: CellResult (text, confidence, engine_used, bbox, needs_review)
```

### Step 4: Post-Processing (`app/pipeline/postprocessor.py`)

```
Input: array of CellResult from all regions
  │
  ├── Medication Name Parsing:
  │     ├── Split "Butylscopolamine 10mg" → name + strength
  │     ├── Regex: ^(.+?)\s+(\d+(?:\.\d+)?\s*(?:mg|g|ml|mcg|IU|%))$
  │     └── Fuzzy match against medications_en.txt (threshold 85%)
  │
  ├── Duration Parsing:
  │     ├── Regex: (\d+)\s*(ថ្ងៃ|days?|weeks?|សប្ដាហ៍)
  │     ├── Khmer numeral conversion: ០១២៣៤៥៦៧៨៩ → 0123456789
  │     └── Detect "រួសាប់" annotation = "until finished"
  │
  ├── Dose Value Parsing:
  │     ├── "1" → 1.0, "1/2" → 0.5, "½" → 0.5
  │     ├── "-" or "" → 0 (disabled)
  │     └── enabled = (dose > 0)
  │
  ├── Schedule Construction:
  │     ├── Map columns to 4 time slots:
  │     │   morning (06:00-08:00), midday (11:00-12:00),
  │     │   afternoon (17:00-18:00), evening (20:00-22:00)
  │     ├── times_per_day = count(enabled slots)
  │     └── total_quantity = daily_dose × duration_days
  │
  ├── Route Detection:
  │     └── Pattern match: PO/oral/IV/IM + Khmer equivalents
  │
Output: structured prescription data (Python dicts)
```

### Step 5: Format Transformation (`app/pipeline/formatter.py`)

```
Input: structured prescription data
  │
  ├── Static BBox Format (internal/debug):
  │     └── Every field has {value, bbox, confidence, engine_used}
  │
  ├── Dynamic Universal v2.0 (API response):
  │     ├── header_section → healthcare_facility
  │     ├── patient_section → patient.identification + personal_info
  │     ├── clinical_section → clinical_information.diagnoses
  │     ├── medication_table → medications.table_structure + items[]
  │     ├── footer_section → prescriber + footer_information
  │     ├── Auto-compute: medications.summary
  │     └── Add: metadata.extraction_info
  │
  ├── Schema Validation:
  │     └── Validate against schemas/dynamic_v2.schema.json
  │
Output: ExtractionResult (dynamic_json, static_json, quality_report, needs_review[])
```

---

## Output Format

### Canonical Format: Dynamic Universal v2.0

The single production format. Schema defined in `test_space/results/final.result.format.expected.json`.

**Top-level structure:**
```
prescription
├── metadata
│   ├── extraction_info (engine, confidence, preprocessing, image_metadata)
│   ├── prescription_id, version
│   ├── languages_detected (primary, secondary, mixed_content)
│   ├── prescription_type (outpatient|inpatient|emergency|...)
│   └── validation_status (pending|validated|rejected)
├── healthcare_facility
│   ├── name (english, khmer, french + bbox)
│   ├── facility_code, facility_type
│   ├── logo (detected, bbox, logo_text)
│   └── system_name, contact, accreditation
├── patient
│   ├── identification (patient_id, reference_number, medical_record)
│   ├── personal_info (name, dob, age, gender)
│   ├── contact, insurance, classification
├── prescription_details
│   ├── dates (issue_date, issue_datetime, expiry)
│   ├── prescription_number
│   └── visit_information (type, department, location)
├── clinical_information
│   ├── diagnoses[] (diagnosis, ICD codes, type, status)
│   ├── symptoms[], allergies
│   ├── vital_signs, history
├── medications
│   ├── table_structure (detected, bbox, column_headers with time_slots)
│   ├── items[] (per medication):
│   │   ├── medication (name, strength, form, route)
│   │   ├── dosing (duration, schedule with time_slots[], total_quantity)
│   │   ├── instructions (food timing, special, warnings)
│   │   ├── dispensing (substitution, refills, priority)
│   │   └── clinical_notes (indication, therapeutic_class)
│   └── summary (total_count, controlled_substances, antibiotics, max_duration)
├── prescriber (name, credentials, signature, stamp, contact)
├── pharmacy_information
├── additional_information (follow_up, referral, lab_tests, notes)
├── digital_verification (qr_code, barcode, digital_signature)
├── footer_information (hospital_footer, disclaimers)
└── raw_extraction_data (full_text, confidence_by_section, processing_flags)
```

### Format Consolidation

| Format | File | Status | Purpose |
|--------|------|--------|---------|
| **Dynamic Universal v2.0** | `final.result.format.expected.json` | **Canonical** | Schema definition |
| **Dynamic Populated** | `prescription_image_1_dynamic_populated.json` | **Ground truth** | E2E test baseline |
| **Static BBox** | `prescription_image_1_static_with_bbox.json` | **Debug** | OCR debugging/training |
| Dynamic v1.0 | `prescription.dynamic.format.json` | **Archived** | Superseded by v2.0 |
| Legacy Reminder | `result.already.defined.json` | **Archived** | Superseded |

---

## API Design

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/extract` | API Key | Extract prescription from image → Dynamic Universal v2.0 |
| `POST` | `/api/v1/extract/debug` | API Key | Same but returns both static + dynamic formats |
| `GET` | `/api/v1/health` | None | Health check with model load status |
| `GET` | `/api/v1/config` | API Key | Current thresholds and engine versions |

### POST /api/v1/extract

**Request:** `multipart/form-data`
- `file`: image file (PNG, JPEG, PDF) — max 10MB

**Response:** `200 OK`
```json
{
  "success": true,
  "data": { /* Dynamic Universal v2.0 JSON */ },
  "extraction_summary": {
    "total_medications": 4,
    "confidence_score": 0.94,
    "needs_review": false,
    "fields_needing_review": [],
    "processing_time_ms": 2850,
    "engines_used": ["paddleocr", "tesseract"]
  }
}
```

**Error Response:** `422 Unprocessable Entity`
```json
{
  "success": false,
  "error": "unsupported_format",
  "message": "File format not supported. Use PNG, JPEG, or PDF.",
  "supported_formats": ["image/png", "image/jpeg", "application/pdf"]
}
```

### Configuration

```python
# app/config.py
class Settings:
    # API
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    MAX_UPLOAD_SIZE_MB: int = 10
    REQUEST_TIMEOUT_S: int = 30
    API_KEY: str = ""  # from env

    # OCR Confidence Thresholds
    AUTO_ACCEPT_THRESHOLD: float = 0.80
    FLAG_REVIEW_THRESHOLD: float = 0.60
    MANUAL_REVIEW_THRESHOLD: float = 0.60

    # Preprocessing
    BLUR_THRESHOLD: float = 100.0
    MAX_IMAGE_DIMENSION: int = 2000
    CLAHE_CLIP_LIMIT: float = 2.0
    CLAHE_GRID_SIZE: tuple = (8, 8)

    # OCR Engines
    PADDLE_LANG: str = "en"
    PADDLE_USE_GPU: bool = False
    PADDLE_ENABLE_MKLDNN: bool = True
    TESSERACT_LANG: str = "khm+eng+fra"
    TESSERACT_OEM: int = 1
    TESSERACT_PSM: int = 6

    # Fuzzy Matching
    MED_NAME_MATCH_THRESHOLD: int = 85
```

---

## Testing Strategy

### Unit Tests

| Test File | What it Tests |
|-----------|--------------|
| `test_preprocessor.py` | Blur detection, deskew, contrast enhancement, resize |
| `test_layout.py` | Table detection, row/column count, column header identification |
| `test_ocr_engine.py` | English text accuracy, Khmer text recognition, mixed text engine selection |
| `test_postprocessor.py` | Med name splitting, duration parsing, dose calculation, Khmer numeral conversion |
| `test_pipeline_e2e.py` | Full pipeline vs ground truth JSONs |

### E2E Regression Tests

Use `prescription_image_1_dynamic_populated.json` as ground truth for `image.png`.

**Field comparison rules:**
- Text fields: normalized comparison (strip whitespace, case-insensitive for English)
- Numeric fields: exact match
- Bbox fields: tolerance ±15px per coordinate
- Confidence: must be ≥ ground truth - 0.10

**Pass criteria:**
- ≥ 90% field accuracy overall
- ≥ 95% accuracy for medication name, dose, and duration fields
- All medications detected (no missing items)
- Correct time slot mapping (morning/midday/afternoon/evening)

### Continuous Improvement Loop

```
Run pipeline on test image
        │
   Compare vs ground truth
        │
   ┌────┴────┐
   │ Pass?   │
   │ ≥90%    │
   ├─ YES ───┤──→ Done ✓
   │         │
   └─ NO ────┘
        │
   Analyze failures:
        ├── Preprocessing issue? → Adjust OpenCV params
        ├── Table detection miss? → Tune layout detection
        ├── OCR wrong text? → Adjust engine selection/thresholds
        └── Post-processing error? → Fix parsing regex/lexicon
        │
   Re-run pipeline → loop until pass
```

---

## Performance Targets

| Metric | Target | How |
|--------|--------|-----|
| End-to-end extraction | < 4 seconds | Pipeline optimization |
| PaddleOCR inference | ~1.75s (mobile model) | MKL-DNN, mobile variant |
| Tesseract inference | ~0.5s (targeted cells) | PSM 6, single block, cells only |
| Preprocessing | ~0.3s | In-memory, no temp files |
| Post-processing | ~0.2s | Regex + dictionary lookup |
| Model loading | ~3s (one-time at startup) | Singleton pattern, warm in memory |
| Memory usage | < 2GB | Mobile model variants |

### CPU Optimization Techniques

1. **PaddleOCR**: `enable_mkldnn=True`, mobile model variant (2M params)
2. **Tesseract**: `--oem 1 --psm 6`, run on targeted cells only (not full image)
3. **Environment**: `OMP_NUM_THREADS` = available CPU cores
4. **No disk I/O**: all processing in-memory (numpy arrays, no temp files)
5. **Singleton models**: loaded once at startup, kept warm in memory
6. **Future**: ONNX Runtime with INT8 quantization available as upgrade path

---

## Integration with Backend

### NestJS Backend Changes Required

1. **New module**: `ocr` module in `backend_nestjs/src/modules/`
2. **OcrService**: HTTP client to call `POST http://localhost:8000/api/v1/extract`
3. **OcrController**: `POST /api/v1/prescriptions/scan` — accepts image upload from Flutter
4. **Flow**:
   - Flutter uploads image to NestJS
   - NestJS forwards to OCR service
   - OCR returns Dynamic Universal v2.0 JSON
   - NestJS maps JSON to `CreatePrescriptionDto` + `CreateMedicationDto[]`
   - NestJS creates Prescription + Medications in PostgreSQL via Prisma
   - NestJS returns structured prescription data to Flutter
5. **Validation**: if `needs_review: true`, set `prescription.validation_status = "pending"`

### Backend Mapping (OCR → Prisma)

| OCR Field | Prisma Model.Field |
|-----------|-------------------|
| `prescriber.name.full_name` | `Prescription.patientName` (via doctor lookup) |
| `patient.personal_info.gender.value` | `Prescription.patientGender` |
| `patient.personal_info.age.value` | `Prescription.patientAge` |
| `clinical_information.diagnoses[0].diagnosis.english` | `Prescription.symptoms` |
| `medications.items[n].medication.name.brand_name` | `Medication.medicineName` |
| `medications.items[n].medication.name.local_name` | `Medication.medicineNameKhmer` |
| `medications.items[n].dosing.schedule.time_slots[morning]` | `Medication.morningDosage` |
| `medications.items[n].dosing.schedule.time_slots[midday]` | `Medication.daytimeDosage` |
| `medications.items[n].dosing.schedule.time_slots[evening]` | `Medication.nightDosage` |

---

## Implementation Tasks

### Phase 1: Project Setup & Infrastructure

- [ ] **Task 1.1**: Create project scaffolding (directory structure, `__init__.py` files)
- [ ] **Task 1.2**: Create `requirements.txt` and `requirements-dev.txt`
- [ ] **Task 1.3**: Create `pyproject.toml` with project metadata
- [ ] **Task 1.4**: Create `Makefile` with common commands (install, test, run, lint)
- [ ] **Task 1.5**: Create `app/config.py` with Settings class (Pydantic BaseSettings)
- [ ] **Task 1.6**: Install system dependencies (Tesseract + language data)
- [ ] **Task 1.7**: Install Python dependencies and verify imports
- [ ] **Task 1.8**: Create `.gitignore` for `data/models/`, `__pycache__/`, `.env`

### Phase 2: Core Pipeline Modules

- [ ] **Task 2.1**: Implement `app/utils/image_utils.py` — OpenCV helpers (blur check, CLAHE, denoise, deskew, resize)
- [ ] **Task 2.2**: Implement `app/utils/text_utils.py` — Khmer/English normalization, numeral conversion, Unicode detection
- [ ] **Task 2.3**: Implement `app/pipeline/preprocessor.py` — Full preprocessing pipeline (quality check + enhance)
- [ ] **Task 2.4**: Write `tests/test_preprocessor.py` — Unit tests for preprocessing functions
- [ ] **Task 2.5**: Implement `app/pipeline/layout.py` — PP-StructureV3 table detection + OpenCV fallback
- [ ] **Task 2.6**: Write `tests/test_layout.py` — Table detection tests on test images
- [ ] **Task 2.7**: Implement `app/pipeline/ocr_engine.py` — Dual-engine OCR (PaddleOCR + Tesseract)
- [ ] **Task 2.8**: Write `tests/test_ocr_engine.py` — Per-engine accuracy tests
- [ ] **Task 2.9**: Implement `app/pipeline/postprocessor.py` — Text normalization, parsing, schedule construction
- [ ] **Task 2.10**: Write `tests/test_postprocessor.py` — Med name splitting, duration parsing, dose calculation tests

### Phase 3: Data & Lexicons

- [ ] **Task 3.1**: Create `data/lexicons/medications_en.txt` — 200+ common drug names
- [ ] **Task 3.2**: Create `data/lexicons/medications_km.txt` — Khmer pharmacy terms
- [ ] **Task 3.3**: Create `data/lexicons/column_headers.json` — Known table header templates
- [ ] **Task 3.4**: Implement `app/utils/med_lexicon.py` — Fuzzy matching loader + matcher
- [ ] **Task 3.5**: Archive superseded formats to `test_space/results/archived/`

### Phase 4: Output Schema & Formatting

- [ ] **Task 4.1**: Implement `app/models/static_schema.py` — Pydantic models for static bbox format
- [ ] **Task 4.2**: Implement `app/models/dynamic_schema.py` — Pydantic models for Dynamic Universal v2.0
- [ ] **Task 4.3**: Create `schemas/static_v1.schema.json` — JSON Schema validator
- [ ] **Task 4.4**: Create `schemas/dynamic_v2.schema.json` — JSON Schema validator
- [ ] **Task 4.5**: Implement `app/pipeline/formatter.py` — Static → Dynamic transformation
- [ ] **Task 4.6**: Test schema validation against existing ground truth JSONs

### Phase 5: Pipeline Orchestrator

- [ ] **Task 5.1**: Implement `app/pipeline/orchestrator.py` — Full pipeline coordinator
- [ ] **Task 5.2**: Implement error handling and fallback strategies
- [ ] **Task 5.3**: Write `tests/test_pipeline_e2e.py` — End-to-end regression tests
- [ ] **Task 5.4**: Run pipeline on `image.png` and compare with ground truth
- [ ] **Task 5.5**: Tune pipeline until ≥ 90% field accuracy achieved
- [ ] **Task 5.6**: Generate ground truths for `image1.png` and `image2.png`
- [ ] **Task 5.7**: Run pipeline on all 3 images and verify accuracy

### Phase 6: API & Server

- [ ] **Task 6.1**: Implement `app/api/models.py` — Request/response Pydantic models
- [ ] **Task 6.2**: Implement `app/api/routes.py` — FastAPI endpoints
- [ ] **Task 6.3**: Implement `app/main.py` — FastAPI app with startup model loading
- [ ] **Task 6.4**: Add CORS, request size limit, timeout middleware
- [ ] **Task 6.5**: Write API integration tests with httpx
- [ ] **Task 6.6**: Test `POST /api/v1/extract` with all 3 test images
- [ ] **Task 6.7**: Verify health check endpoint and error responses

### Phase 7: Performance & Optimization

- [ ] **Task 7.1**: Benchmark end-to-end extraction time per image
- [ ] **Task 7.2**: Optimize model loading (singleton pattern, lazy init)
- [ ] **Task 7.3**: Enable MKL-DNN for PaddleOCR
- [ ] **Task 7.4**: Optimize Tesseract calls (cells only, appropriate PSM)
- [ ] **Task 7.5**: Verify memory usage stays under 2GB
- [ ] **Task 7.6**: Achieve < 4 second target on test images

### Phase 8: Documentation & Cleanup

- [ ] **Task 8.1**: Update `ocr_service/README.md` with setup and usage instructions
- [ ] **Task 8.2**: Update `FORMAT_COMPARISON.md` to reflect consolidation
- [ ] **Task 8.3**: Final test suite run — all tests passing
- [ ] **Task 8.4**: Code review and cleanup

### Phase 9: Backend Integration (Future — requires NestJS changes)

- [ ] **Task 9.1**: Create NestJS `ocr` module with OcrService
- [ ] **Task 9.2**: Add image upload endpoint to prescriptions controller
- [ ] **Task 9.3**: Implement OCR → Prisma model mapping
- [ ] **Task 9.4**: Integration test: Flutter → NestJS → OCR → PostgreSQL
- [ ] **Task 9.5**: Handle `needs_review` flag in prescription status

---

## Future Improvements

### Short-term (after MVP)

1. **PDF support**: Multi-page prescription PDF extraction
2. **Batch processing**: Process multiple images in single request
3. **Caching**: Redis cache for recently processed prescriptions (hash-based dedup)
4. **Confidence tuning**: Adjust thresholds based on real-world accuracy data

### Medium-term

1. **Fine-tuned Khmer model**: Train Tesseract on prescription-specific Khmer text
2. **ONNX optimization**: Export PaddleOCR to ONNX + INT8 quantization for 2x CPU speedup
3. **Handwriting recognition**: Support handwritten medication notes
4. **Multi-format support**: Handle different hospital prescription layouts (beyond H-EQIP)
5. **Drug interaction database**: Cross-reference extracted medications for interactions

### Long-term

1. **GPU acceleration**: Deploy with CUDA for 10x speedup
2. **Custom Khmer OCR model**: Train dedicated Khmer medical OCR on labeled prescription data
3. **FHIR integration**: Map output to HL7 FHIR MedicationRequest resources
4. **Real-time verification**: WebSocket-based live OCR feedback during image capture
5. **Multi-country support**: Extend to Thai, Vietnamese, Myanmar prescription formats

---

## Appendix: Ground Truth Reference

### Test Image 1 (`image.png`) — Expected Extraction

**Hospital**: Khmer-Soviet Friendship Hospital (មន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត)  
**System**: H-EQIP  
**Patient ID**: HAKF1354164  
**Gender**: Female (ស្រី)  
**Age**: 19 years  
**Diagnosis**: Chronic Cystitis  
**Date**: 15/06/2025 14:20  
**Prescriber**: Sry Heng (handwritten signature)

| # | Medication | Strength | Duration | Morning (6-8) | Midday (11-12) | Afternoon (5-6) | Evening (8-10) | Daily Total |
|---|-----------|----------|----------|---------------|----------------|-----------------|----------------|-------------|
| 1 | Butylscopolamine | 10mg | 14 days | 1 | - | 1 | - | 2 |
| 2 | Celcoxx (Celecoxib) | 100mg | 14 days (រួសាប់) | 1 | - | 1 | - | 2 |
| 3 | Omeprazole | 20mg | 14 days | 1 | - | 1 | - | 2 |
| 4 | Multivitamine | — | 21 days | 1 | 1 | 1 | - | 3 |
