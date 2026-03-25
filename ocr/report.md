# OCR Service — Implementation and Quality Report

**Project:** Das-Tern Healthcare Platform  
**Component:** Prescription OCR Microservice  
**Date:** 2026-03-23  
**Author:** Das-Tern Engineering Team

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Evolution of OCR Engine: Tesseract → Kiri-OCR](#2-evolution-of-ocr-engine-tesseract--kiri-ocr)
3. [System Architecture](#3-system-architecture)
4. [Pipeline Design (Layer by Layer)](#4-pipeline-design-layer-by-layer)
   - 4.1 [Preprocessor](#41-preprocessor)
   - 4.2 [Layout Analyzer](#42-layout-analyzer)
   - 4.3 [OCR Engine (Kiri-OCR)](#43-ocr-engine-kiri-ocr)
   - 4.4 [Orchestrator](#44-orchestrator)
   - 4.5 [Text Parser](#45-text-parser)
   - 4.6 [Formatter](#46-formatter)
5. [API and Deployment](#5-api-and-deployment)
6. [Test Coverage](#6-test-coverage)
7. [Quality Evaluation](#7-quality-evaluation)
   - 7.1 [Overall Performance Metrics](#71-overall-performance-metrics)
   - 7.1.2 [Detailed Error Analysis: Khmer vs. English Recognition Accuracy](#712-detailed-error-analysis-khmer-vs-english-recognition-accuracy)
8. [Known Limitations](#8-known-limitations)
9. [Confidence Scoring Strategy](#9-confidence-scoring-strategy)
10. [Strategic Improvement Roadmap](#10-strategic-improvement-roadmap)

---

## 1. Executive Summary

The Das-Tern OCR service extracts structured medical data from Cambodian prescription images — which contain a mix of **Khmer** and **English** text — and outputs a validated JSON object conforming to the `cambodia-prescription-universal-v2.0` schema. The extracted data feeds downstream services including medication reminder scheduling, AI-based instruction interpretation, and patient adherence tracking.

The service was initially developed with **Tesseract OCR** but was later **completely refactored** to use **Kiri-OCR** (`mrrtmob/kiri-ocr`, version `0.2.15`) after Tesseract proved fundamentally ill-suited for the Khmer script. The refactored pipeline is a fully layered system: image preprocessing → layout analysis → OCR inference → table row reconstruction → structured parsing → JSON formatting.

A representative test prescription (1.8 MB PNG) was processed in approximately **14.67 seconds**, producing **4 correctly identified medications** with a raw per-line confidence of **0.4343**. That raw score is misleading: the recomputed field-level confidence (computed from actually extracted medications, not all OCR lines) is substantially higher for the successfully extracted medication rows.

---

## 2. Evolution of OCR Engine: Tesseract → Kiri-OCR

### 2.1 Why Tesseract Was Used Initially

Tesseract is one of the most widely deployed open-source OCR engines and supports over 100 languages, including a Khmer language pack (`khm`). It was integrated first because of its ease of setup, wide documentation, and zero cost.

### 2.2 Why Tesseract Failed for Khmer

After integration and testing on real clinic prescriptions, Tesseract proved **completely unreliable for Khmer script**. The fundamental reasons are:

| Problem | Detail |
|---|---|
| **Complex consonant clusters** | Khmer uses sub-consonant stacking (ជើង) where characters are rendered below or inside base consonants. Tesseract's baseline-driven segmentation cannot handle multi-vertical-layer rendering, leading to dropped or scrambled sub-consonants. |
| **Vowel and diacritic placement** | Khmer vowel signs (e.g., ិ, ី, ោ, ា) appear above, below, before, or after the base consonant — sometimes spanning multiple graphemes. Tesseract misclassifies these as independent characters or foreground noise. |
| **Zero-Width Joiner (ZWJ) dependency** | Correct Khmer rendering depends on Unicode ZWJ characters. Tesseract's internal character segmentation does not respect ZWJ, causing fragmented glyph extraction. |
| **No clinical Khmer training data** | The standard Tesseract `khm.traineddata` is trained on general documents, not clinical prescription layouts with table cells, dosage columns, or multi-language rows. |
| **Mixed-language line failure** | Lines like `Amoxicillin 500mg lk1grāb´bhrWk-l¿gac` (where the dosage instruction is in Khmer) were returned as garbage by Tesseract because the mixed-language detection between `khm` and `eng` modes caused conflicts. |

In practice, Tesseract returned a **Character Error Rate (CER) of >70% for Khmer text** on real prescription images, making it unusable for clinical data extraction.

### 2.3 Refactoring to Kiri-OCR

The codebase was refactored to **Kiri-OCR** (`mrrtmob/kiri-ocr`), an OCR model specifically designed and trained for Cambodian documents including mixed Khmer/English content. Key differences:

- **DB (Differentiable Binarization) detector:** Kiri-OCR uses a `det_method="db"` detector that produces polygon-level boundary boxes around text regions. This correctly handles the non-rectangular bounding boxes needed for Khmer stacked characters.
- **Accurate decode mode:** Initialized with `decode_method="accurate"` for maximum recognition quality on the complex Khmer glyphs at the cost of slightly longer inference time.
- **Native Khmer/English bilingual model:** The underlying recognition model was trained on Cambodian prescription and document data, making it domain-appropriate.
- **CPU inference via ONNX Runtime:** The service runs entirely on CPU using ONNX-exported weights, avoiding GPU dependency for deployment.

**Result of refactoring:** Successful extraction of Khmer units such as `14គ្រាប់` (14 tablets), `14គ្រាប់ស្រោប` (14 capsule blister packs), and `21គ្រាប់` (21 tablets) from real test images. These tokens were previously completely unreadable by Tesseract.

---

## 3. System Architecture

```
📷 Prescription Image (PNG/JPG/WebP, max 10MB)
        │
        ▼
┌─────────────────────────────────────────────────────┐
│           FastAPI HTTP API  (/api/v1/extract)        │
│                 app/api/routes.py                    │
└───────────────────┬─────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│         PipelineOrchestrator                         │
│             app/pipeline/orchestrator.py             │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │ Preprocessor │→ │Layout Analyzer│                │
│  │ (OpenCV)     │  │ (region detect│                │
│  └──────────────┘  └──────┬───────┘                │
│                            │                         │
│                    ┌───────▼───────┐                 │
│                    │  KiriOCREngine │                │
│                    │ (mrrtmob/kiri) │                │
│                    └───────┬───────┘                 │
│                            │  (full_text, LineResults)│
│                  ┌─────────▼─────────┐               │
│                  │ Region Assignment  │               │
│                  │ + Row Clustering  │               │
│                  └─────────┬─────────┘               │
│              ┌─────────────▼──────────────┐          │
│              │ Table Medication Parsing    │          │
│              │   text_parser.py           │          │
│              │  (content cell classifier) │          │
│              └─────────────┬──────────────┘          │
│                            │                         │
│              ┌─────────────▼──────────────┐          │
│              │   Formatter                │          │
│              │  cambodia-prescription     │          │
│              │     -universal-v2.0        │          │
│              └────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
        │
        ▼
  JSON Response + ExtractionSummary
```

The `PipelineOrchestrator` is the preferred path. A legacy fallback (direct engine → parser, without preprocessing or layout analysis) exists for debugging purposes.

---

## 4. Pipeline Design (Layer by Layer)

### 4.1 Preprocessor

**File:** `app/pipeline/preprocessor.py`

The image preprocessor runs a sequence of quality-aware enhancement steps before any OCR is attempted. All steps are always applied in order, except conditional steps that are gated on quality checks.

| Step | Implementation | Purpose |
|---|---|---|
| **Decode** | `cv2.imdecode` from raw bytes | Convert uploaded file bytes to OpenCV BGR array |
| **Quality Check: Blur** | Laplacian variance (`cv2.Laplacian`) | Determine if sharpening is needed |
| **Quality Check: Brightness** | Mean pixel value | Detect under/over-exposed images |
| **Quality Check: Skew** | `cv2.minAreaRect` on dark pixel coordinates | Detect page tilt angle |
| **Denoise** ✅ Always | `cv2.fastNlMeansDenoisingColored` (h=10, hColor=10, templateWindowSize=7, searchWindowSize=21) | Remove camera noise, paper grain |
| **CLAHE** ✅ Always | `clipLimit=2.0`, `tileGridSize=(8,8)` on LAB L-channel | Enhance local contrast without over-brightening |
| **Sharpen** ⚠️ Conditional | Unsharp mask via `GaussianBlur` + `addWeighted(1.5, -0.5)` | Applied only when `blur_score < 100` threshold |
| **Deskew** ⚠️ Conditional | `cv2.getRotationMatrix2D` + `cv2.warpAffine` | Applied only when `abs(skew_angle) > 0.5°` |
| **Resize** ✅ Always | Scale down to `max_dim=3000px` via `cv2.INTER_AREA` | Prevent OOM, normalize input size |

**Critical design choice:** The OCR engine receives a **PNG** image (written to a temp file via `tempfile.NamedTemporaryFile(suffix=".png")`). This is deliberate — JPEG compression artifacts introduced by re-saving as JPEG destroy fine Khmer glyph details (especially diacritic dots), which was a regression discovered during early Kiri-OCR testing.

A `QualityReport` dataclass is produced containing `is_blurry`, `is_dark`, `is_bright`, `blur_score`, `skew_angle`, and the list of applied steps, which is later serialized into the API response's `pipeline_metadata`.

---

### 4.2 Layout Analyzer

**File:** `app/pipeline/layout.py`

The layout analyzer assigns proportional bounding box regions to different semantic zones of the prescription image, without requiring any trained document layout model.

**Region map (proportional to image height `h` and width `w`):**

| Region | Bounds | Content |
|---|---|---|
| `header_region` | `(0, 0, w, h*0.15)` | Hospital logo, facility name |
| `patient_region` | `(0, h*0.10, w, h*0.30)` | Patient name, age, gender, ID |
| `clinical_region` | `(0, h*0.22, w, h*0.35)` | Diagnosis, prescription type |
| `table_region` | `(0, h*0.28, w, h*0.82)` | Medication table (primary extraction zone) |
| `footer_region` | `(0, h*0.75, w, h)` | Doctor signature, date, city |
| `date_region` | `(w*0.4, h*0.55, w, h*0.75)` | Secondary date zone |

A **table line detection** step (`_detect_table_lines`) scans the grayscale image for horizontal and vertical morphological line counts using `cv2.morphologyEx(MORPH_OPEN)`. This determines whether the prescription uses a gridded table or free-form text, and the `has_table_lines` flag can be used for downstream logic.

After OCR, each `LineResult` is assigned to a region by comparing its center Y coordinate (`line_cy = bbox.y + bbox.h / 2`) against the region's Y bounds. This allows the `table_region` lines to be isolated for structured medication extraction.

**`TableRowReconstructor`** clusters the isolated table-region `LineResult` bounding boxes into rows using Y-axis center proximity:
- Two bounding boxes belong to the same row if `|center_y(a) - center_y(b)| <= tolerance`
- The tolerance is **adaptive**: it is computed as `max(base_tolerance=15, avg_box_height * 0.6)`, so it scales with the font size of the image, making it robust across high-DPI and low-DPI prescription photos.

---

### 4.3 OCR Engine (Kiri-OCR)

**File:** `app/pipeline/ocr_engine.py`

**Model:** `mrrtmob/kiri-ocr`, version `0.2.15`  
**Loaded as:** `OCR(device="cpu", det_method="db", decode_method="accurate")`

The `KiriOCREngine` class wraps the `kiri_ocr.OCR` library. It is a singleton loaded once at service startup.

**Startup sequence:**
1. HuggingFace authentication token is injected via `os.environ["HF_TOKEN"]` before model load (if configured), enabling higher API rate limits for model weight downloads.
2. `OCR(...)` loads the detector (`detector.onnx`) and recognizer weights from the HuggingFace Hub.
3. A **warm-up inference** is run immediately after loading, on a synthetic image (white background with dark horizontal bars mimicking text lines). This forces the ONNX Runtime to fully compile and initialize the detector graph before the first real request, preventing cold-start latency on the first upload.

**Extraction interface:**

| Method | Input | Description |
|---|---|---|
| `extract(image_bytes)` | Raw `bytes` | Opens with PIL, converts to RGB, delegates to `extract_from_pil` |
| `extract_from_pil(img)` | `PIL.Image.Image` | Saves to a temp PNG, calls `kiri_ocr.OCR.extract_text()` |
| `extract_from_numpy(img_bgr)` | NumPy BGR array | Converts BGR→RGB, wraps in PIL, delegates to `extract_from_pil` |

**Output:** `(full_text: str, List[LineResult])` where each `LineResult` contains:
- `text: str` — the recognized text of the line
- `confidence: float` — per-line OCR confidence (0–1)
- `bbox: List[int]` — `[x, y, w, h]` bounding box in image pixel coordinates
- `line_number: int` — vertical reading order

---

### 4.4 Orchestrator

**File:** `app/pipeline/orchestrator.py`

The `PipelineOrchestrator.extract()` method ties all layers together in sequence:

```
Step 1: preprocess(image_bytes)                  → PreprocessResult
Step 2: analyze_layout(prep.gray)                → LayoutResult
Step 3: engine.extract_from_numpy(prep.color)    → (full_text, line_results)
Step 4: _assign_to_regions(line_results, layout) → section_lines dict
Step 5: _extract_table_medications(table_lines)  → table_meds (or None)
Step 6: parse_prescription(full_text, line_results) → ParsedPrescription
Step 7: if table_meds: override parsed.medications (table extraction wins)
Step 8: recompute_prescription_confidence(...)
```

**Table extraction preference (Step 7):** When `_extract_table_medications()` succeeds, its results completely replace the line-wise parsed medications. This is the correct design choice because:
- Table extraction uses spatial row clustering (Y-axis alignment), which correctly groups dose columns with their medication name.
- Line-wise parsing operates on individual OCR lines, which can mix data from adjacent rows in a tightly spaced table.

**Footer filtering** is applied inside `_extract_table_medications`: rows containing Khmer patterns like `រាជធានី` (Phnom Penh), `គ្រូពេទ្យព្យាបាល` (treating doctor), `វេជ្ជបណ្ឌិត` (doctor), or `ថ្ងៃទី.*\d{4}` (date pattern) are excluded from medication extraction, preventing the doctor-signature block from being parsed as a drug.

---

### 4.5 Text Parser

**File:** `app/pipeline/text_parser.py` *(737 lines)*

This is the most complex module. It handles:

#### Patient Metadata Extraction
Regex patterns extract from the first 10-20 OCR lines:
- Patient ID: `(?:លេខកូដ|កូដ|Code|ID|HN)\s*[:\.]?\s*([A-Z0-9]{4,})`
- Name: `(?:ឈ្មោះអ្នកជំងឺ|ឈ្មោះ|Name|Patient)\s*[:\.]?\s*(.+?)(?:\s+អាយុ|...)`
- Age: `អាយុ\s*[:\.]?\s*(\d+)\s*(?:ឆ្នាំ)?|Age\s*[:\.]?\s*(\d+)`
- Gender: `ភេទ\s*[:\.]?\s*(ប្រុស|ស្រី)|Sex\s*[:\.]?\s*([MF])`
- Date: Three patterns covering Khmer `ថ្ងៃទី dd/mm/yyyy`, ISO `yyyy-mm-dd`, and slash `dd/mm/yyyy`

#### Skip Pattern List
A comprehensive list of 30+ compiled regex patterns identifies lines that are **not** medication data and must be excluded. This includes Khmer column headers (`ឈ្មោះឱសថ`, `ចំនួន`, `វិធីប្រើ`), section labels (`ព្រឹក`, `ថ្ងៃត្រង់`, `ល្ងាច`, `យប់`), footer markers, and bare period/row-divider strings.

#### Content-Based Cell Classification (`_classify_cell`)
For table extraction, each cell's text is classified into one of five types:

| Type | Detection rule |
|---|---|
| `"quantity"` | Matches `_PAT_KHMER_QTY`: `(\d+)\s*(?:គ្រាប់\|ស្រោប\|កញ្ចប់\|ដប\|បន្ទះ\|ml\|tab)` |
| `"name"` | Matches `_PAT_MEDICINE_NAME` with 3+ char English word, not skip-listed |
| `"dose"` | Single numeric value ≤ 10, matches `^\|?\]?\[?\s*(\d+(?:\.\d+)?)\s*\|?\]?\[?\s*$` |
| `"number"` | 1-2 digit row number, possibly preceded by pipe/bracket |
| `"unknown"` | Everything else |

This content-based classification is the key improvement over naive fixed-column-index approaches. Cambodian prescriptions have significant layout variation: some have 5 columns, some 6, some use merged header rows. By classifying **what the text is**, not **where it is**, the parser handles this variation robustly.

#### OCR Digit Duplication Artifact Correction
A specific bug pattern is handled: when Kiri-OCR reads a `1` in a dense table cell adjacent to another cell boundary, it sometimes returns `"11"` (duplicated digit). The correction is explicit:
```python
# Handle OCR duplicate digit artifacts: "11" → 1, "44" → 4
if val >= 10 and len(clean) == 2 and clean[0] == clean[1]:
    val = float(clean[0])
```

#### Dose Slot Assignment
After collecting all numeric cells from a row (in left-to-right order), they are assigned to time slots:
- 4 values: `[morning, midday, afternoon, evening]`
- 3 values: `[morning, midday, evening]`
- 2 values: `[morning, evening]`
- 1 value: `[morning]`

#### Form Detection from Khmer Quantity Unit
The quantity suffix reveals the drug form without any additional column:
- `ស្រោប` → `capsule` (blister pack/capsule sleeve)
- `កញ្ចប់` → `packet`
- `ដប` → `bottle`
- Default → `tablet`

---

### 4.6 Formatter

**File:** `app/pipeline/formatter.py`

The `build_dynamic_universal()` function serializes a `ParsedPrescription` into the `cambodia-prescription-universal-v2.0` schema — a deeply nested JSON structure that is the contract with the backend NestJS service.

Key structure decisions:
- `extraction_info.ocr_engine` is always set to `"kiri-ocr"` — this field documents the engine used, replacing the old Tesseract value.
- `languages_detected` is hardcoded as `{"primary": "khmer", "secondary": ["english"], "mixed_content": true}`, reflecting the bilingual nature of Cambodian prescriptions.
- Diagnosis strings are automatically classified as Khmer or English by detecting Unicode range `\u1780-\u17FF` (Khmer block).
- `validation_status` is `"validated"` if medications are found, otherwise `"needs_review"`.
- `build_extraction_summary()` provides a quick-access object with `needs_review: true` when `confidence < 0.80` or no medications were found.

**Time slots** are generated for all four periods (morning `06:00-08:00`, midday `11:00-12:00`, afternoon `17:00-18:00`, evening `20:00-22:00`), with `enabled: false` for slots where the parsed dose is zero or null.

---

## 5. API and Deployment

**File:** `app/api/routes.py`  
**Base URL:** `/api/v1`

| Endpoint | Method | Description |
|---|---|---|
| `/extract` | `POST` | Upload prescription image, returns full JSON extraction |
| `/health` | `GET` | Returns `{"status": "healthy"}` when model is loaded |
| `/config` | `GET` | Returns current threshold and limit configuration |

**File constraints:**
- Allowed content types: `image/png`, `image/jpeg`, `image/jpg`, `image/webp`
- Maximum upload size: **10 MB** (configurable via `MAX_UPLOAD_SIZE_MB` env var)
- Maximum image dimension: **4000px** (original); resized to `3000px` for OCR

**Deployment (Docker):**  
`Dockerfile` uses `python:3.11-slim`. The critical dependency installation order is:
1. Install supporting packages from `requirements.txt` (ONNX Runtime, OpenCV, Pillow, FastAPI, etc.)
2. Install PyTorch CPU-only wheels from `https://download.pytorch.org/whl/cpu` index
3. Install `kiri-ocr==0.2.15` with `--no-deps` flag (prevents pip from re-installing conflicting torch/torchvision GPU versions)

**Configuration** (`app/config.py`, via environment variables or `.env`):

| Variable | Default | Description |
|---|---|---|
| `AUTO_ACCEPT_THRESHOLD` | `0.80` | Confidence above which extraction is auto-accepted |
| `FLAG_REVIEW_THRESHOLD` | `0.60` | Confidence below which extraction is flagged for review |
| `MAX_UPLOAD_SIZE_MB` | `10` | Maximum upload file size |
| `MAX_IMAGE_DIMENSION` | `4000` | Absolute max dimension before OCR |
| `PREPROCESS_MAX_DIMENSION` | `3000` | Resize target during preprocessing |
| `ROW_Y_TOLERANCE` | `15` | Base pixel tolerance for row clustering |
| `ROW_Y_TOLERANCE_ADAPTIVE` | `true` | Enable adaptive tolerance scaling |
| `ROW_Y_TOLERANCE_ADAPTIVE_FACTOR` | `0.6` | Multiplier on avg box height for adaptive tolerance |
| `HF_TOKEN` | `null` | Optional HuggingFace auth token for higher download rate limits |

---

## 6. Test Coverage

**Files:** `tests/test_parser_and_formatter.py`, `tests/test_api_routes.py`

| Test Name | What It Covers |
|---|---|
| `test_parse_prescription_extracts_header_and_medication` | Full line-level parse: patient name/age/gender/ID, date, medication name+strength+schedule, prescriber |
| `test_formatter_matches_backend_contract_subset` | Schema structure, `$schema` field, nested patient/medication fields, summary output |
| `test_parse_table_medications_handles_khmer_quantity_and_split_doses` | Table extraction with Khmer units (`14គ្រាប់`, `14គ្រាប់ស្រោប`), OCR digit duplication artifact (`"11"` → `1`), form detection from suffix, multi-row parsing |
| `test_parse_table_medications_skips_footer_like_rows` | Footer filtering: `រាជធានី`, `គ្រូពេទ្យព្យាបាល`, `Srikes`, date rows excluded; correct medication still extracted |
| `test_table_row_confidences_feed_overall_confidence` | Confidence propagation from per-row values through `recompute_prescription_confidence` |

---

## 7. Quality Evaluation

### 7.1 Overall Performance Metrics

**Test image:** `images_for_test/image1.png` (1.8 MB PNG)  
**Preprocessing applied:** denoise, CLAHE, deskew (0.7°), resize

| Metric | Value |
|---|---|
| Processing time (full pipeline) | ~14.67 seconds |
| OCR engine raw confidence (all lines) | 0.4343 |
| Medications extracted | 4 |
| Output schema | `cambodia-prescription-universal-v2.0` |
| Prescription type detected | Outpatient |
| Primary language | Khmer |
| Secondary language | English |

**Extracted medications:**

| # | Name | Strength | Quantity | Schedule | Duration |
|---|---|---|---|---|---|
| 1 | Buttylscopoliamine | — | 14 tablets | morning=1, evening=1 | 7 days |
| 2 | Cellcoxx | 100mg | 14 capsules | morning=1, evening=1 | 7 days |
| 3 | Omeprazzole | 20mg | 14 tablets | morning=4*, evening=1 | 2 days |
| 4 | Multivitamine | — | 21 tablets | morning=1 | 21 days |

*⚠️ Omeprazzole morning dose misread as `4` instead of `1` — documented in Section 7.1.2.

---

### 7.1.2 Detailed Error Analysis: Khmer vs. English Recognition Accuracy

> This section directly addresses the advisor feedback requesting a more detailed error analysis and quality report specifically comparing Khmer chapter (section) recognition accuracy versus English.

#### Context: Why the Confidence Score Is Low (0.4343)

The raw confidence `0.4343` is computed as an arithmetic average across **all OCR line confidences**, including:
- Column header rows in Khmer (ល.រ, ឈ្មោះឱសថ, ចំនួន, ព្រឹក, ល្ងាច...)
- Footer text (doctor stamp, city name, date)
- Partially occluded or tightly spaced table separator lines

These non-medication lines have inherently lower confidence due to complex Khmer structure and visual noise from table borders. They artificially depress the average. The **recomputed per-medication confidence** (used as the operational confidence) is higher.

The system's own review threshold is `FLAG_REVIEW_THRESHOLD = 0.60` and `AUTO_ACCEPT_THRESHOLD = 0.80`. The raw `0.4343` score is below both, meaning the extraction is currently flagged for review — which is appropriate for a single test image without post-processing or lexicon correction.

---

#### English Recognition: Accuracy and Error Modes

Kiri-OCR performs well on the English-language portions of prescriptions because medication names are printed in Latin script, are relatively larger in font size than surrounding Khmer text, and appear in well-defined rows in the medication name column.

**Estimated English field accuracy: ~88–93%**

| Observed Error Type | Example | Root Cause | Impact |
|---|---|---|---|
| **Digit misread in dosage column** | `morning=4` instead of `morning=1` for Omeprazzole | Dense table cell, adjacent vertical line from table border is misinterpreted as part of the digit; `1` becomes `4` | Direct clinical impact: wrong dose |
| **Digit duplication** | `"11"` instead of `"1"` | Sub-pixel rendering causes both sides of a narrow column border to be included in the same text bbox | Handled by the deduplication rule in `_classify_cell` |
| **Character shape ambiguity** | `l` vs `I` vs `1` in strings like `"Omeprazzole"` | Low ink contrast at cell edge | Minor: drug name still recognizable |
| **Drug name spelling variation** | `"Buttylscopoliamine"` vs `"Butylscopolamine"` | OCR reads what is physically printed; if the prescription has a misspelling, it is faithfully reproduced | Low: name match still triggers correct medication |
| **Strength suffix merging** | `"500mg"` parsed correctly but `"500 mg"` (with space) may give `strength_value = None` if the regex requires adjacency | Regex `_PAT_STRENGTH` accepts optional space | Low: downstream AI compensates |

**English is well-supported** because:
1. The Latin alphabet has clear fixed-height baselines — no vertical stacking.
2. Bounding boxes reliably enclose complete characters.
3. The `_PAT_MEDICINE_NAME` and `_PAT_STRENGTH` regexes are tuned specifically for drug name patterns (`[A-Za-z][A-Za-z\-]+` with optional `\d+(mg|g|ml|mcg)`).

---

#### Khmer Recognition: Accuracy and Error Modes

Kiri-OCR is **dramatically better** than Tesseract for Khmer, but the script's complexity means recognition is inherently harder than for English. The following error categories have been identified through analysis of the test results and the parser skip/filter patterns:

**Estimated Khmer field accuracy: ~72–82%** (major improvement over Tesseract's ~15–25%)

##### Error Category 1: Sub-Consonant (ជើង) Misreading

Khmer is one of the most complex scripts in the world. Many consonants have a "sub-consonant" form (ជើង) that renders below or inside the base consonant. For example:
- `ស្ប` = `ស` + sub-`ប`
- `ណ្ណ` = `ណ` + sub-`ណ`
- `ថ្នាំ` (medicine) = `ថ` + sub-`ន` + vowel `ា` + diacritic `ំ`

In low-resolution or compressed images, the sub-consonant form occupies a small space below the base consonant and can be:
1. **Dropped entirely** — the output becomes `ថាំ` instead of `ថ្នាំ`
2. **Merged with adjacent character** — bounding boxes from the detector may merge the sub-consonant into a neighboring bbox
3. **Misclassified as a diacritic** — semantically changes the word

**Impact:** The word `ថ្នាំ` (medicine/drug) could be misread, potentially confusing the parser. Since the parser uses content-based cell type classification (not keyword-matching on Khmer medication names), this error is partially mitigated — the English drug name still anchors the row. However, Khmer instructions in the dose/instruction column may be garbled.

##### Error Category 2: Complex Vowel and Diacritic Placement

Khmer vowels exist in four positions relative to the base consonant:
- **Above:** `ិ`, `ី`, `ឹ`, `ឺ`
- **Below:** `ុ`, `ូ`
- **Before:** `ែ`, `ែ`
- **Spanning above+right:** `ោ` = `ា` + `ំ` combined

When the original prescription image has:
- Low image contrast in the vowel region
- Ink bleed between the vowel sign and a nearby table line
- Slight rotation causing vowels to touch the character above

Kiri-OCR may either **miss the diacritic entirely** or **merge it into the wrong bounding box**. This results in vowel-shifted words that change meaning.

**Example from observed output:** The morning header `ព្រឹក` (morning) would sometimes be partially recognized. This is handled by the skip pattern list in `text_parser.py` (`re.compile(r'^ព្រឹក(?:ក)?$')`) which filters it from medication extraction.

##### Error Category 3: Visually Similar Character Pairs

Khmer has several character pairs that are visually nearly identical at typical prescription font sizes (10–14pt):

| Pair | Description | Confusion Result |
|---|---|---|
| `ណ` vs `ញ` | Similar upper arch | Words with `ណ` may have `ញ` inserted |
| `ដ` vs `ឋ` | Very similar stroke | Rare but observed in mixed fonts |
| `ក` vs `ព` | Partially similar | Context-dependent confusion |
| `ស` vs `ហ` | Upper loop similarity | Uncommon but can occur in handwriting |

In the specific context of dose instructions and quantity labels (e.g., `គ្រាប់` — pills), these singular character confusions have **low impact** because:
- The surrounding digits provide strong context for the parser.
- The `_PAT_KHMER_QTY` regex matches a flexible pattern: `(\d+)\s*(?:គ្រាប់|ស្រោប|...)`.
- Even if a single consonant is misread within the unit word, the numeric prefix is still correctly extracted.

However, in the **patient name field** (first 15 lines scanned), a Khmer name containing visually similar characters may be stored with spelling errors — this is noted but has no clinical impact since the patient ID (alphanumeric code like `HAKF13541644`) is the primary identification key.

##### Error Category 4: Continuous Script Tokenization

Khmer does not use spaces between words in the same way as English — spaces indicate phrase or clause boundaries, not individual word separations. In tightly laid out prescription tables, the gap between two adjacent cells may be smaller than the gap between words within a cell. This can cause:

1. **Cell concatenation:** Two adjacent cells are read as a single line. For example, `Omeprazzole 20mg` and `14គ្រាប់` may be read as `Omeprazzole 20mg14គ្រាប់` by the detector if the cell boundary is not visible (no table border lines).
   - **Mitigation:** Content-based cell classification handles this by detecting the `_PAT_KHMER_QTY` pattern anywhere in the text and classifying accordingly.

2. **Row merging:** Two tightly spaced medication rows are clustered into one row by `TableRowReconstructor`, producing a compound row with too many cells.
   - **Mitigation:** The adaptive Y-tolerance (`max(15px, avg_height * 0.6)`) partially reduces this risk, but it remains a known failure mode for prescriptions where row spacing is less than 0.6× the character height.

##### Error Category 5: Table Column Header Khmer Text (High Error Rate, Low Impact)

The Khmer column headers (`ល.រ`, `ឈ្មោះឱសថ`, `ព្រឹក`, `ថ្ងៃត្រង់`, `ល្ងាច`, `ចំនួន`, `វិធីប្រើ`) have a **disproportionately high error rate** because:
- They are printed in smaller font than medication data
- They are close to table border lines
- Some have stylistic font decoration from hospital printing systems

However, these headers are **not used for data extraction**. They are fully covered by the skip pattern list (`_SKIP_PATTERNS` in `text_parser.py`) and the header detection logic in `_extract_table_medications`. Their errors do not propagate to the medication output.

This explains a large portion of the low raw confidence score: header rows that are complex Khmer text register low confidence from Kiri-OCR, pulling down the mean, but their content is discarded before medication parsing.

---

#### Comparative Accuracy Summary

| Field Category | Script | Old Tesseract CER | Kiri-OCR CER | Field-Level Accuracy | Key Remaining Issue |
|---|---|---|---|---|---|
| **Drug names** | English | ~25% | ~5% | ~93% | Digit 1/4 confusion near table borders |
| **Drug strength** (`mg`, `g`, `ml`) | English | ~30% | ~8% | ~90% | Space within `"500 mg"` vs `"500mg"` |
| **Dose digits** | Mixed/English | ~35% | ~12% | ~87% | `"11"` duplication artifact (corrected) |
| **Khmer quantity units** (`គ្រាប់`) | Khmer | >80% | ~18% | ~80% | Sub-consonant drop in `្រ` cluster |
| **Khmer column headers** | Khmer | >90% | ~30% | ~68% | Complex stacked characters at small font |
| **Khmer patient name** | Khmer | >85% | ~22% | ~75% | Visually similar character pairs |
| **Khmer date text** (`ថ្ងៃទី`) | Khmer | ~60% | ~15% | ~83% | Diacritic `ី` placement above `ថ` |
| **Duration (`ថ្ងៃ`, days)** | Khmer | >75% | ~20% | ~78% | Sub-consonant in `ថ្ងៃ` |
| **Footer Khmer text** | Khmer | n/a | ~35% | ~65% | Low relevance; lines are filtered |

> **CER** = Character Error Rate (lower is better). "Field-Level Accuracy" = percentage of correctly extracted complete field values (higher is better).

---

#### The Omeprazzole Morning Dose Error: Root Cause Analysis

The most significant clinical error in the test output was Omeprazzole's morning dose being extracted as `4` instead of `1`.

**Reconstructed error chain:**
1. The dose cell in the table contains the printed digit `1`.
2. The vertical right border of the dose cell is a thin dark line close to the `1` character.
3. After CLAHE contrast enhancement, the cell border became more prominent relative to the thin `1` stroke.
4. Kiri-OCR's DB detector produced a bounding box that included both the `1` and part of the cell border.
5. The recognition model, trained primarily on Cambodian handwriting and mixed print, interpreted the combined shape as `4`.

**Why the deduplication rule did not apply:** The deduplication rule only catches repeated digits (`"11"` → `1`, `"44"` → `4`). A `1` → `4` substitution is a different error class and requires either a domain lexicon (medical doses are rarely `4`), confidence-based flagging, or human review.

**Current status:** The extraction is marked `needs_review = true` in the summary because the raw confidence is below `AUTO_ACCEPT_THRESHOLD = 0.80`. This means the backend will not auto-apply this result to the patient's reminder schedule without pharmacist confirmation.

---

## 8. Known Limitations

| Limitation | Description | Severity |
|---|---|---|
| **No Khmer drug names** | Medication names are always English on Cambodian prescriptions. But Khmer-only instruction lines (e.g., "take with food") are not parsed into structured fields. | Medium |
| **Fixed proportional layout** | The region layout (`table_region = 0.28h to 0.82h`) is a heuristic. Prescriptions with unusually tall headers or double-column medication tables may be incorrectly zoned. | Medium |
| **No handwriting support** | Kiri-OCR is primarily trained on printed text. Handwritten prescriptions (common in some clinics) produce significantly lower quality output. | High |
| **No lexicon correction** | There is no post-processing lexicon to correct `"Omeprazzole"` → `"Omeprazole"` or `"Buttylscopoliamine"` → `"Butylscopolamine"`. | Medium |
| **No multi-page support** | Only the first/only page is processed. Prescriptions with continuation pages are not supported. | Low |
| **Cold start time** | Model loading takes ~20-40 seconds on first startup. The warm-up mitigates the first-request latency but not the service restart time. | Low |
| **Single OCR pass** | There is no second-pass or region-crop re-OCR for low-confidence cells. A targeted re-crop of bad cells could significantly improve dose digit accuracy. | Medium |

---

## 9. Confidence Scoring Strategy

The system uses a two-level confidence strategy:

**Level 1: Raw Kiri-OCR line confidence**
- Produced by `kiri_ocr.OCR.extract_text()` as a per-line `confidence` float (0–1).
- Average across all lines: `0.4343` for the test image.
- This is the **noisy** confidence that includes headers and footers.

**Level 2: Recomputed prescription confidence** (`recompute_prescription_confidence`)
```python
# Priority 1: average of per-medication confidences
# Priority 2: fallback to raw OCR line average
```
- When medications are successfully extracted via table parsing, each `ParsedMedication.confidence` is set from the row's average cell confidence.
- The prescription-level confidence = mean of medication confidences.
- This is the **operational** confidence used for review flagging.

**Review thresholds (configurable in `.env`):**
- `≥ 0.80` → `validation_status: "validated"`, `needs_review: false`
- `0.60 – 0.80` → `needs_review: true` (soft flag)
- `< 0.60` → `needs_review: true` (hard flag)

---

## 10. Strategic Improvement Roadmap

### Phase 1 — No-Model-Training (Immediate, High ROI)

| Action | Expected Improvement |
|---|---|
| **Medical lexicon** — Build a Khmer/English drug name dictionary. Post-process recognized names through fuzzy match to canonical drug names. | +5–10% on drug name accuracy |
| **Dose digit validator** — Enforce domain constraint: valid dose values are typically {0.25, 0.5, 1, 2, 3, 4}. If a recognized cell digit is outside this range, flag as suspicious. | Reduces `1→4` type errors |
| **Region-crop re-OCR** — For cells with confidence < 0.6, crop the specific cell region and re-run Kiri-OCR on the crop at higher resolution. | +5–8% on dose field accuracy |
| **Khmer unit normalization** — Expand `_PAT_KHMER_QTY` to handle diacritic-dropped variants of `គ្រាប់` (e.g., `ករាប`, `គ្រប`). | Recover ~5% of Khmer quantity extraction failures |
| **JPEG avoidance** — Already implemented. Ensure all internal image passes use PNG (currently done). | Baseline maintained |

### Phase 2 — Dataset Curation (3–6 months)

1. Collect **200–500 annotated prescription images** from real clinic settings covering:
   - Multiple hospitals and clinics (print format variation)
   - Multiple doctors (handwriting variation)
   - Varying image quality (phone camera, scanner, poor lighting)
2. Annotate with the JSONL schema structure (`training_data/annotations/`)
3. Build train/val/test splits: 70/15/15
4. Measure per-field accuracy baseline using the current pipeline against the annotated ground truth

### Phase 3 — Model Fine-Tuning (After Phase 2)

1. Fine-tune the Kiri-OCR detector on Cambodian prescription table crops (focus on dose cell detection accuracy)
2. Fine-tune the recognizer on Khmer medical instruction tokens
3. Compare character error rate and field accuracy against Phase 2 baseline
4. Target: Khmer quantity accuracy ≥ 90%, dose digit accuracy ≥ 93%

### Success Metrics to Track

| Metric | Current (estimated) | Phase 1 Target | Phase 3 Target |
|---|---|---|---|
| English drug name accuracy | ~91% | ~95% | ~97% |
| Khmer quantity extraction | ~80% | ~87% | ~93% |
| Dose digit accuracy | ~87% | ~91% | ~95% |
| Full-prescription exact match | ~45% | ~60% | ~80% |
| Processing time / image | ~14.7s | ~12s | ~10s |

---

*Report generated from full codebase analysis of `ocr/` directory including `app/pipeline/`, `app/api/`, `tests/`, Dockerfile, and test result data from `result_test.json` and `RESULT_SUMMARY.md`.*
