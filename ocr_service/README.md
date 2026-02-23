# DAS-TERN OCR Service

A Python microservice that extracts structured JSON from Cambodian prescription images. Designed to handle mixed **Khmer / English / French** printed text, grid-based medication tables, and varied hospital formats used across Cambodia's H-EQIP healthcare network.

---

## Table of Contents

- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Architecture Overview](#architecture-overview)
- [Layer-by-Layer Deep Dive](#layer-by-layer-deep-dive)
  - [Layer 0 — HTTP Transport (FastAPI)](#layer-0--http-transport-fastapi)
  - [Layer 1 — Image Preprocessing (OpenCV)](#layer-1--image-preprocessing-opencv)
  - [Layer 2 — Layout Analysis (OpenCV Morphology)](#layer-2--layout-analysis-opencv-morphology)
  - [Layer 3 — OCR Engine (Tesseract)](#layer-3--ocr-engine-tesseract)
  - [Layer 4 — Hybrid Table Processing](#layer-4--hybrid-table-processing)
  - [Layer 5 — Post-Processing](#layer-5--post-processing)
  - [Layer 6 — Output Formatting (Dynamic Universal v2.0)](#layer-6--output-formatting-dynamic-universal-v20)
- [Data Flow End-to-End](#data-flow-end-to-end)
- [Output Schema](#output-schema)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Running the Service](#running-the-service)
- [Project Structure](#project-structure)

---

## Overview

The OCR service is a standalone FastAPI microservice. The NestJS backend sends a prescription image as a `multipart/form-data` POST request. The service runs it through a 5-stage pipeline and returns a deeply structured JSON document conforming to the **`cambodia-prescription-universal-v2.0`** schema.

Key design decisions:

| Decision | Reason |
|---|---|
| **Tesseract only** (no PaddleOCR) | PaddleOCR does not support the Khmer script. Tesseract with `khm+eng+fra` language pack is the only viable open-source engine for Khmer. |
| **Hybrid table method** | Pure cell-by-cell OCR fails on dose columns (checkmarks/ticks). A contour-blob approach is used for dose cells instead. |
| **CPU-only** | Deployed on low-cost VPS. No GPU dependency. |
| **Single-engine, multi-PSM** | Tesseract is invoked with different Page Segmentation Modes (PSM) per region type to maximise accuracy. |

---

## Technology Stack

| Component | Library | Purpose |
|---|---|---|
| Web framework | `FastAPI` + `uvicorn` | Async HTTP server |
| Image I/O & processing | `OpenCV` (`cv2`) | Decoding, preprocessing, morphological analysis |
| OCR engine | `pytesseract` → Tesseract 5 | Text recognition (Khmer, English, French) |
| Fuzzy matching | `rapidfuzz` | Medication name matching against drug lexicon |
| Schema validation | `Pydantic v2` | Request/response models |
| Configuration | `pydantic-settings` | `.env` + environment variable loading |

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                     NestJS Backend                       │
│           POST /api/v1/extract  (multipart image)        │
└────────────────────────┬─────────────────────────────────┘
                         │ raw bytes
                         ▼
┌──────────────────────────────────────────────────────────┐
│                  FastAPI  (main.py)                      │
│   • Validates content-type & file size                   │
│   • Delegates to PipelineOrchestrator.extract()          │
└────────────────────────┬─────────────────────────────────┘
                         │
          ┌──────────────▼──────────────┐
          │      PipelineOrchestrator   │
          │  (pipeline/orchestrator.py) │
          │                             │
          │  Step 1 ► Preprocessor      │
          │  Step 2 ► Layout Analyzer   │
          │  Step 3 ► OCR Engine        │
          │  Step 4 ► Post-Processor    │
          │  Step 5 ► Formatter         │
          └──────────────┬──────────────┘
                         │
                         ▼
              { success, data, extraction_summary }
              (Dynamic Universal v2.0 JSON)
```

The orchestrator is the central coordinator. All other modules are stateless functions or lightweight classes injected into it at startup via FastAPI's `lifespan` event.

---

## Layer-by-Layer Deep Dive

### Layer 0 — HTTP Transport (FastAPI)

**File:** [app/main.py](app/main.py) · [app/api/routes.py](app/api/routes.py) · [app/api/models.py](app/api/models.py)

#### Startup

FastAPI uses an `asynccontextmanager` lifespan hook. On startup it:
1. Instantiates `PipelineOrchestrator`, which in turn creates `OCREngine` and `PostProcessor`.
2. `OCREngine.__init__` calls `pytesseract.get_tesseract_version()` — this immediately fails if Tesseract is not installed, making a broken deployment obvious at boot time rather than at the first request.
3. The orchestrator instance is stored in a module-level variable (`_orchestrator`) and injected into the route handler via `set_orchestrator()`.

#### Request Validation (routes.py)

Before anything is passed to the pipeline, the route handler performs three guards:

| Guard | Logic |
|---|---|
| **Content-type** | Accepted: `image/png`, `image/jpeg`, `image/jpg`, `image/webp`, `application/pdf`, `application/octet-stream`. For the generic octet-stream type it also checks the filename extension. |
| **File size** | `len(image_bytes) > MAX_UPLOAD_SIZE_MB * 1024 * 1024` → HTTP 413 |
| **Empty file** | `len(image_bytes) == 0` → HTTP 400 |

The raw bytes are then passed straight to `orchestrator.extract(image_bytes, filename)`.

#### Response Shape

```json
{
  "success": true,
  "data": { "$schema": "cambodia-prescription-universal-v2.0", "prescription": { ... } },
  "extraction_summary": {
    "total_medications": 4,
    "confidence_score": 0.85,
    "needs_review": false,
    "fields_needing_review": [],
    "processing_time_ms": 2340.5,
    "engines_used": ["tesseract"]
  }
}
```

---

### Layer 1 — Image Preprocessing (OpenCV)

**File:** [app/pipeline/preprocessor.py](app/pipeline/preprocessor.py) · [app/utils/image_utils.py](app/utils/image_utils.py)

The preprocessor converts raw bytes into two NumPy arrays — a processed colour image and a processed grayscale image — plus a `QualityReport` that records exactly what transformations were applied.

#### Step-by-step transforms

```
raw bytes
  │
  ▼  cv2.imdecode (IMREAD_COLOR → BGR ndarray)
decode
  │
  ▼  cv2.cvtColor(BGR → GRAY)
grayscale copy for analysis
  │
  ├─► check_blur:       Laplacian variance < BLUR_THRESHOLD (100.0)
  ├─► check_brightness: mean pixel value < MIN_BRIGHTNESS (40) or > MAX_BRIGHTNESS (220)
  └─► detect_skew:      cv2.minAreaRect on dark pixel coordinates → angle
  │
  ▼  apply_denoise:
     cv2.fastNlMeansDenoisingColored (h=10, hForColorComponents=10, templateWindowSize=7, searchWindowSize=21)
     (always applied — removes sensor/compression noise before thresholding)
  │
  ▼  [conditional] apply_clahe:
     Convert BGR → LAB colour space
     Apply CLAHE (clipLimit=2.0, tileGridSize=8×8) on the L channel only
     Convert LAB → BGR
     (applied when is_dark OR is_bright)
  │
  ▼  [conditional] apply_sharpen:
     Unsharp mask: output = 1.5 × original − 0.5 × GaussianBlur(σ=3)
     (applied when is_blurry)
  │
  ▼  [conditional] apply_deskew:
     cv2.getRotationMatrix2D → cv2.warpAffine with INTER_CUBIC + BORDER_REPLICATE
     (applied when |skew_angle| > 0.5°)
  │
  ▼  resize_image:
     Downscale to MAX_IMAGE_DIMENSION (2000 px on longest side) preserving aspect ratio
     (applied when max(h,w) > 2000)
  │
  ▼  to_grayscale again on the processed colour image
  │
  └─► return (processed_color, processed_gray, quality_report)
```

**Why CLAHE on LAB L-channel?** Applying CLAHE directly to BGR would shift the hue of ink and paper. By operating only on the Luminance channel in LAB space, contrast is boosted without distorting colour. This matters for downstream contour detection in the dose-column analysis.

**Why unsharp mask instead of a Laplacian sharpen?** Unsharp mask (`addWeighted`) preserves edges while suppressing ringing artefacts, which makes Tesseract character recognition more reliable on slightly blurry photos taken with a mobile camera.

---

### Layer 2 — Layout Analysis (OpenCV Morphology)

**File:** [app/pipeline/layout.py](app/pipeline/layout.py)

Layout analysis answers: *where on this image are the header, patient block, clinical block, medication table, and footer?*

#### Heuristic region assignment

For the non-table regions, the layout uses fixed proportional bands of the image height — these work reliably because Cambodian H-EQIP prescription forms follow a standardised layout:

| Region | y-range (% of height) |
|---|---|
| Header | 0 – 15% |
| Patient info | 12 – 30% |
| Clinical info | 22 – 38% |
| Footer | 75 – 100% |
| Signature | 70 – 85% (right half) |
| Date | 60 – 75% (right 60%) |

#### Table detection (`find_table_region`)

The medication table is the complex element. The algorithm has two modes:

**Primary mode — morphological line detection:**
```
grayscale  ──►  Otsu threshold (THRESH_BINARY_INV)
                │
  horizontal    │  kernel = (image_width/15, 1)    → Morphological OPEN → contours
  vertical      │  kernel = (1, image_height/15)   → Morphological OPEN → contours
                │
  filter: horizontal contours where width > 30% of image width
          vertical  contours where height > 5% of image height
                │
  table bbox = bounding rect of all surviving lines
```

**Fallback mode — contour area scan:**
If fewer than 3 horizontal lines or 2 vertical lines are found, the algorithm scans all external contours for the largest rectangle whose width exceeds 50% of image width and height exceeds 15% of image height.

#### Cell extraction (`extract_table_cells`)

Once the table bounding box is known, cells are split using:

- **Columns:** Hard-coded H-EQIP proportions `[4.3%, 27.9%, 13.6%, 11.1%, 8.0%, 9.4%, 15.3%, 10.4%]` for the 8 known columns (`item_number`, `medication_name`, `duration`, `instructions`, `morning`, `midday`, `afternoon`, `evening`). These proportions were derived from annotated ground-truth images.
- **Rows:** Re-run horizontal line detection inside the table crop. If fewer than 3 lines are found, it falls back to equally-spaced estimation (1 header + 5 data rows).

Each cell is represented as a `CellInfo(row, col, bbox, content_type)` dataclass.

---

### Layer 3 — OCR Engine (Tesseract)

**File:** [app/pipeline/ocr_engine.py](app/pipeline/ocr_engine.py)

`OCREngine` is a thin wrapper around `pytesseract`. Its main job is to select the right **language pack** and **Page Segmentation Mode (PSM)** per region type, then return an `OCRResult(text, confidence, engine, bbox, needs_review, language)`.

#### PSM selection strategy

| Region / content_type | PSM | Lang | Reasoning |
|---|---|---|---|
| Dose cell (morning/midday/afternoon/evening/item_number) | `10` — single character | `eng` | Dose columns contain only `1`, `-`, or simple fractions |
| Medication name | `6` — assume a uniform block of text | `eng` | Names are Latin-script multiword tokens |
| Duration, instructions | `7` — treat as single line | `khm+eng+fra` | Contains Khmer numerals + Khmer unit words |
| Header, patient, footer | `7` | `khm+eng+fra` | Mixed-language freeform text |

#### Dose cell pre-processing

For dose and item-number cells, an extra preparation step trims 15% of both width and height from all four sides before running OCR. This removes the grid lines printed at the cell border, which would otherwise be detected as strokes and cause misclassification.

#### Character whitelist for dose cells

```
-c tessedit_char_whitelist=0123456789-/
```

This tells Tesseract to only emit digits, hyphens, and slashes — completely eliminating false positive letters from the limited visual vocabulary of a dose cell.

#### Upscaling small crops

Any crop shorter than 50 px is upscaled with `cv2.INTER_CUBIC` to a minimum height of 50 px. Tesseract's default training data performs best at font sizes equivalent to roughly 30–50 px character height; below that, recognition accuracy degrades significantly.

#### Confidence scoring

`pytesseract.image_to_data` returns a per-word confidence in `[0, 100]`. The engine computes the mean of all word confidences, then divides by 100 to produce a normalised `[0.0, 1.0]` score. Words with `conf <= 0` (which Tesseract uses for structural blocks like paragraphs) are excluded from the mean.

A result is marked `needs_review = True` when `confidence < FLAG_REVIEW_THRESHOLD` (default 0.60).

---

### Layer 4 — Hybrid Table Processing

**File:** [app/pipeline/orchestrator.py](app/pipeline/orchestrator.py) — `_process_table_hybrid`, `_analyze_dose_column`, `_cluster_words_by_y`, `_map_words_to_columns`

The dose columns (`morning`, `midday`, `afternoon`, `evening`) on Cambodian H-EQIP prescriptions are filled with hand-drawn ticks or printed `1` marks. Pure character OCR on these cells is unreliable because:

1. The marks are often stylistically inconsistent.
2. Grid lines at column edges bleed into the character region.
3. Paper folds or creases can produce spurious ink patterns.

The hybrid approach therefore splits the table into two subsystems:

#### Subsystem A — Text Column Strip OCR

Columns 0–3 (`item_number` through `instructions`) are concatenated into a horizontal strip and OCR'd in one pass using PSM 4 (single column of text). This gives word tokens with absolute pixel coordinates `(x, y, w, h)` from `image_to_data`.

```python
config = '--oem 1 --psm 4'
data = pytesseract.image_to_data(strip_crop, lang='eng', config=config, output_type=DICT)
```

Words are then **clustered into rows** by y-proximity (threshold: 25 px):
- Sort all words by `y`.
- Walk through sorted words; if the next word's `y` is within 25 px of the current group's mean `y`, append it to the group.
- Otherwise, start a new group.

Each word group is then **mapped to columns** by comparing the word's horizontal centre (`x + w/2`) against the pre-computed column boundaries `col_x[]`. Only rows whose `medication_name` column contains ≥ 3 characters are kept as valid medication rows.

**Duration re-OCR per row**: After row identification, the duration column is re-OCR'd individually per row with PSM 7 and `khm+eng` to correctly read Khmer numeral + day-unit text (e.g., `14 ថ្ងៃ`).

#### Subsystem B — Dose Column Contour Detection

Each of the four dose columns is processed independently as a full vertical strip:

```
1. Extract strip: gray_img[ty1:ty2, col_x1:col_x2]

2. Trim 30% from left and right edges → remove vertical grid lines

3. Binary threshold: cv2.threshold(inner, 160, 255, THRESH_BINARY_INV)
   (dark ink on white → white blobs on black)

4. Remove horizontal grid lines:
   h_kernel = getStructuringElement(MORPH_RECT, (inner_width*2//3, 1))
   h_lines  = morphologyEx(binary, MORPH_OPEN, h_kernel)
   binary   = subtract(binary, h_lines)

5. Find contours: findContours(binary, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE)

6. Filter blobs: area >= 12 pixels AND height >= 3 pixels

7. Fold/crease artifact filter:
   - A paper fold creates a vertical line of blobs clustered near the
     left edge (x < 30% of inner width) that spans most medication rows.
   - If left-edge blobs cover (num_rows−1) or more rows AND center-region
     blobs also exist for those rows → remove left-edge blobs (the
     centre blobs are the real marks).
   - If no centre blobs exist at all → the left-edge blobs are pure fold
     artefacts and are removed entirely.

8. Map blobs to rows:
   For each medication row centre y-coordinate, find all blobs within
   ±30 px. If their combined area >= 15 px² → row value = "1" (dose taken)
   else → "-" (no dose).
```

This contour approach is robust to variations in how `1` or a tick is hand-drawn, because it only asks "is there significant ink in this cell?" rather than "what character is this?".

---

### Layer 5 — Post-Processing

**File:** [app/pipeline/postprocessor.py](app/pipeline/postprocessor.py) · [app/utils/text_utils.py](app/utils/text_utils.py) · [app/utils/med_lexicon.py](app/utils/med_lexicon.py)

Post-processing converts raw OCR text strings into semantically typed, validated data structures.

#### Medication name parsing (`parse_medication_name`)

Uses a regex to split a medication text into `(name, strength_value, strength_unit)`:

```
pattern = r'^(.+?)\s+(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|IU|%|mEq|mmol|units?)$'
```

Example: `"Omeprazole 20mg"` → `("Omeprazole", "20", "mg")`.

#### Medication fuzzy matching (`MedLexicon`)

The lexicon files at `data/lexicons/medications_en.txt` and `medications_km.txt` are loaded at startup. Each line in the English file follows the pipe-delimited format:

```
BrandName|GenericName|TherapeuticClass
```

For every extracted medication name, `rapidfuzz.process.extractOne` is called with `scorer=fuzz.ratio` and `score_cutoff=85`. This returns the best matching brand name, its generic equivalent, and its therapeutic class (e.g., `"Proton pump inhibitor"`). If no match exceeds the threshold, the raw OCR'd name is used as-is.

#### Duration parsing (`parse_duration`)

1. Converts Khmer numerals to Arabic (`០` → `0`, etc.).
2. Extracts an integer with `r'(\d+)'`.
3. Detects unit: checks for Khmer week word `សប្ដាហ៍`, month word `ខែ`, or their English equivalents. Weeks are immediately converted to days (×7). Finds the Khmer suffix `រួសាប់` meaning "until finished" and stores it as a `note`.

#### Dose value parsing (`parse_dose_value`)

Handles: integers (`1`, `2`), fractions (`½`, `¼`, `⅓`), slash fractions (`1/2`), mixed fractions (`1 1/2`), and dash/empty meaning "no dose". Returns `(numeric_float, is_enabled_bool)`.

#### Schedule construction

For each medication row, the four time-slot dose values are assembled into a `time_slots` list. The number of enabled slots determines `times_per_day` and `interval_hours = 24 / times_per_day`. Total quantity is calculated as `total_daily_dose × duration_days` when both are available.

#### Route detection

A set of regex patterns scans the instructions text for route keywords (`PO`, `IV`, `IM`, `SC`, `topical`, `inhaled`). Defaults to `"PO"` (oral) when no match is found.

#### Food timing inference

Based on the matched `therapeutic_class`, a lookup table infers whether the medication should be taken before, with, or after meals (e.g., proton pump inhibitors → before meals; NSAIDs → after meals).

---

### Layer 6 — Output Formatting (Dynamic Universal v2.0)

**File:** [app/pipeline/formatter.py](app/pipeline/formatter.py) · [app/models/dynamic_schema.py](app/models/dynamic_schema.py) · [schemas/dynamic_v2.schema.json](schemas/dynamic_v2.schema.json)

The formatter assembles all the post-processed fragments into the canonical `cambodia-prescription-universal-v2.0` JSON document.

#### Top-level envelope

```json
{
  "success": true,
  "data": {
    "$schema": "cambodia-prescription-universal-v2.0",
    "prescription": { ... }
  },
  "extraction_summary": { ... }
}
```

#### `prescription` object sections

| Key | Source | Description |
|---|---|---|
| `metadata` | orchestrator + quality_report | OCR engine, timestamp (UTC+7), preprocessing steps applied, image dimensions, overall confidence |
| `healthcare_facility` | `PostProcessor.process_header()` | Hospital name in Khmer/English, H-EQIP system detection, facility type |
| `patient` | `PostProcessor.process_patient_info()` | Patient ID (regex `[A-Z]{2,5}\d{5,}`), age, gender (Khmer/English/French variants) |
| `prescription_details` | `PostProcessor.process_footer()` | Issue date (ISO 8601), visit type, department |
| `clinical_information` | `PostProcessor.process_clinical_info()` | Diagnoses, vital signs, allergies |
| `medications.items[]` | `_process_table_hybrid()` → `PostProcessor.process_medication_row()` | Full per-medication structure (see below) |
| `prescriber` | footer post-processing | Name, signature detected flag |
| `pharmacy_information` | static defaults | Dispensing status (always `false` at extraction time) |
| `digital_verification` | static defaults | QR/barcode/blockchain fields for future use |

#### Per-medication item structure

Each entry in `medications.items[]` contains:

```
item_number
medication.name     { brand_name, generic_name, local_name, full_text }
medication.strength { value, numeric, unit }
medication.form     { value: "tablet" }
medication.route    { value: "PO", description: "Oral" }
dosing.duration     { value: days, unit, text_original, khmer_text, note }
dosing.schedule     { type, frequency { times_per_day, interval_hours }, time_slots[] }
dosing.total_quantity
dosing.daily_totals
instructions        { timing_with_food, special_instructions { english, khmer } }
dispensing
clinical_notes      { therapeutic_class, indication }
```

#### `extraction_summary`

The summary is computed from the assembled result dict:

- `total_medications` — `len(medications.items)`
- `confidence_score` — currently `0.85` (static default; per-field scoring is a planned improvement)
- `needs_review` — `true` if any field's confidence fell below `FLAG_REVIEW_THRESHOLD`
- `processing_time_ms` — wall-clock time from orchestrator entry to formatter exit
- `engines_used` — `["tesseract"]`

---

## Data Flow End-to-End

```
POST /api/v1/extract
  │
  │  raw bytes (image/png, image/jpeg, …)
  ▼
[routes.py] validate content-type, size, non-empty
  │
  │  bytes
  ▼
[orchestrator.py] extract()  ─── start timer
  │
  │  bytes
  ▼
[preprocessor.py] preprocess_image()
  │   decode bytes → ndarray (BGR)
  │   quality check (blur, brightness, skew)
  │   denoise → CLAHE? → sharpen? → deskew? → resize
  │
  │  (color_ndarray, gray_ndarray, QualityReport)
  ▼
[layout.py] analyze_layout()
  │   heuristic band regions for header/patient/clinical/footer
  │   morphological line detection → table bbox
  │   H-EQIP column proportions → CellInfo list
  │
  │  LayoutResult { header_region, patient_region, table, … }
  ▼
[ocr_engine.py] ocr_region() × N regions
  │   crop region  →  upscale if < 50px  →  PSM + lang selection
  │   pytesseract.image_to_data → word list → mean confidence
  │
  │  OCRResult { text, confidence } per region
  │
  │  (separately for table)
  ▼
[orchestrator.py] _process_table_hybrid()
  │   Strip OCR (PSM 4) → word tokens → cluster by y → map to columns
  │   Re-OCR duration per row (PSM 7, khm+eng)
  │   Dose columns: binary threshold → remove grid lines (morph OPEN)
  │                 contour detection → blob area → map to rows → "1" / "-"
  │
  │  raw_row_dicts [ { medication_name, duration, morning, … } ]
  ▼
[postprocessor.py]
  │   process_header()        → facility dict
  │   process_patient_info()  → patient dict
  │   process_clinical_info() → clinical dict
  │   process_footer()        → date, prescriber_name
  │   process_medication_row() per row:
  │     parse_medication_name → (name, strength_val, strength_unit)
  │     MedLexicon.match_medication (rapidfuzz) → brand, generic, class
  │     parse_duration → (days, unit, note)
  │     parse_dose_value × 4 → [(numeric, enabled)]
  │     build time_slots, frequency, total_quantity
  │     detect_route, guess_food_timing
  │
  │  structured Python dicts
  ▼
[formatter.py] build_dynamic_universal()
  │   assemble $schema envelope
  │   embed metadata, facility, patient, clinical, medications, prescriber
  │   build_extraction_summary()
  │
  │  stop timer → processing_time_ms
  ▼
{ "success": true, "data": { prescription }, "extraction_summary": { … } }
  │
  ▼
FastAPI serialises to JSON → HTTP 200
```

---

## Output Schema

The full JSON Schema is defined in [schemas/dynamic_v2.schema.json](schemas/dynamic_v2.schema.json).

Key validation rules:
- `success` (boolean) — always present.
- `extraction_summary.confidence_score` — float in `[0.0, 1.0]`.
- `prescription.medications.items[]` — array; each item fully typed.
- All optional string fields use `nullable_string` (`string | null`).
- All bounding-box fields are `[x1, y1, x2, y2]` integer arrays or `null`.

---

## Configuration

All settings live in [app/config.py](app/config.py) and are loaded from environment variables prefixed with `OCR_` or from a `.env` file.

| Variable | Default | Description |
|---|---|---|
| `OCR_HOST` | `0.0.0.0` | Bind address |
| `OCR_PORT` | `8000` | Bind port |
| `OCR_MAX_UPLOAD_SIZE_MB` | `10` | Maximum file size |
| `OCR_AUTO_ACCEPT_THRESHOLD` | `0.80` | Confidence above which no review is flagged |
| `OCR_FLAG_REVIEW_THRESHOLD` | `0.60` | Confidence below which fields are flagged for review |
| `OCR_BLUR_THRESHOLD` | `100.0` | Laplacian variance below which image is considered blurry |
| `OCR_MAX_IMAGE_DIMENSION` | `2000` | Longest edge pixel cap before downscale |
| `OCR_CLAHE_CLIP_LIMIT` | `2.0` | CLAHE clip limit for contrast enhancement |
| `OCR_TESSERACT_LANG` | `khm+eng+fra` | Default Tesseract language string |
| `OCR_TESSERACT_OEM` | `1` | OCR Engine Mode (1 = LSTM neural net only) |
| `OCR_TESSERACT_PSM` | `6` | Default Page Segmentation Mode |
| `OCR_MED_NAME_MATCH_THRESHOLD` | `85` | Minimum rapidfuzz score for lexicon match |

---

## API Reference

### `POST /api/v1/extract`

Upload a prescription image and receive structured JSON.

**Request:** `multipart/form-data`, field name `file`  
**Accepted formats:** PNG, JPEG, WebP, PDF  
**Max size:** 10 MB (configurable)

**Success response (HTTP 200):**
```json
{
  "success": true,
  "data": { "$schema": "cambodia-prescription-universal-v2.0", "prescription": { ... } },
  "extraction_summary": {
    "total_medications": 4,
    "confidence_score": 0.85,
    "needs_review": false,
    "fields_needing_review": [],
    "processing_time_ms": 1890.3,
    "engines_used": ["tesseract"]
  }
}
```

**Error responses:**

| HTTP | `error` | Cause |
|---|---|---|
| 400 | `empty_file` | Zero-byte upload |
| 413 | `file_too_large` | Exceeds size limit |
| 422 | `unsupported_format` | File type not accepted |
| 500 | `extraction_failed` | Unhandled pipeline exception |
| 503 | `service_unavailable` | Orchestrator not initialised |

### `GET /api/v1/health`

Returns Tesseract version, available language packs, and whether the orchestrator is loaded.

### `GET /api/v1/config`

Returns the current effective configuration thresholds.

---

## Running the Service

```bash
# Install system dependency
sudo apt-get install tesseract-ocr tesseract-ocr-khm tesseract-ocr-fra

# Install Python dependencies
pip install -r requirements.txt

# Start the service
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Interactive API docs
open http://localhost:8000/docs
```

---

## Project Structure

```
ocr_service/
├── app/
│   ├── main.py               # FastAPI app, lifespan startup
│   ├── config.py             # Pydantic Settings (env vars)
│   ├── api/
│   │   ├── routes.py         # HTTP route handlers
│   │   └── models.py         # Pydantic request/response models
│   ├── pipeline/
│   │   ├── orchestrator.py   # Central coordinator (5-step pipeline)
│   │   ├── preprocessor.py   # OpenCV image enhancement
│   │   ├── layout.py         # Region detection, table cell extraction
│   │   ├── ocr_engine.py     # Tesseract wrapper (PSM + lang routing)
│   │   ├── postprocessor.py  # Text → structured data (names, dates, doses)
│   │   └── formatter.py      # Assemble Dynamic Universal v2.0 response
│   ├── models/
│   │   ├── dynamic_schema.py # Pydantic models for Dynamic v2.0 schema
│   │   └── static_schema.py  # Pydantic models for raw bbox format (debug)
│   └── utils/
│       ├── image_utils.py    # OpenCV helper functions + QualityReport
│       ├── text_utils.py     # Regex parsers (dose, duration, date, name)
│       └── med_lexicon.py    # rapidfuzz medication lexicon matcher
├── data/
│   └── lexicons/
│       ├── medications_en.txt  # BrandName|GenericName|TherapeuticClass
│       └── medications_km.txt  # Khmer medication names
├── schemas/
│   ├── dynamic_v2.schema.json  # Full JSON Schema for API output
│   └── static_v1.schema.json   # JSON Schema for debug bbox format
├── tests/
│   ├── conftest.py
│   ├── test_pipeline_e2e.py
│   └── test_postprocessor.py
└── requirements.txt
```
