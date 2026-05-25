# Requirements: OCR Prescription Scanning (Hybrid On-Device + Cloud Fallback)

## Introduction

This spec defines how Das Tern v2 captures a prescription image, extracts text, and turns it into a draft prescription form. The v1 Python `kiri_ocr` microservice is removed. v2 uses a **hybrid OCR pipeline**:

1. **On-device Latin** via Google ML Kit Text Recognition — fastest, free, no network.
2. **On-device Khmer** via Tesseract (`flutter_tesseract_ocr`) with `khm.traineddata` from `tessdata_best`.
3. **Cloud fallback** via Supabase Edge Function `ocr-cloud-vision` proxying Google Cloud Vision API for low-confidence cases or mixed handwritten text.

The output is a structured set of medication candidates that the user reviews and confirms before saving.

## Glossary

- **OCR_Pipeline** — The orchestrator that chooses the engine(s) and merges results.
- **Confidence** — Average per-word confidence score returned by the engine.
- **Field_Extractor** — A pure-Dart function that turns raw OCR text into candidate medication fields (name, dosage, frequency, etc.).
- **Review_Screen** — The UI where the user confirms or edits extracted fields before saving.
- **Bilingual_Detection** — Heuristic detection of Khmer characters to route an image to the correct on-device engine.

## Requirements

### Requirement 1: Image capture and import

**User Story:** As a patient, I want to take or pick a prescription photo, so that the app can read it.

#### Acceptance Criteria

1. THE Flutter_App SHALL provide a "Scan prescription" entry point on the home screen and on the create-prescription flow.
2. THE Flutter_App SHALL allow capture via camera (using `camera` plugin) and selection from gallery (using `image_picker`).
3. THE Flutter_App SHALL guide the user with a framing overlay during camera capture (rectangular guides, focus on document edges).
4. THE Flutter_App SHALL support preprocessing: rotate, crop, contrast adjust, perspective correction (using `image` package or `cunning_document_scanner`).
5. THE Flutter_App SHALL upload the (cropped, preprocessed) image to `prescription-images` Storage at `{patient_id}/<temp_uuid>/<file>.jpg` and persist the path on the resulting prescription.

### Requirement 2: Bilingual detection

**User Story:** As the OCR pipeline, I want to detect the language script(s) in the image, so that I route to the right engine.

#### Acceptance Criteria

1. THE OCR_Pipeline SHALL run an initial pass with Google ML Kit (Latin script).
2. WHEN the result contains characters outside U+0000-U+007F AND the average confidence is below 0.6, THE OCR_Pipeline SHALL also run Tesseract with `khm+eng` data files.
3. WHEN both engines have run, THE OCR_Pipeline SHALL merge results: take ML Kit blocks for Latin lines, Tesseract blocks for lines containing Khmer Unicode block (U+1780–U+17FF).
4. THE OCR_Pipeline SHALL compute a final confidence as the weighted average of merged blocks.
5. THE OCR_Pipeline SHALL operate fully on-device without network for steps 1-3.

### Requirement 3: Cloud fallback (Edge Function)

**User Story:** As a patient with handwritten or low-quality prescription, I want a high-quality fallback OCR, so that I don't have to type everything manually.

#### Acceptance Criteria

1. WHEN the merged on-device confidence is below 0.5 OR the user explicitly taps "Try better OCR", THE Flutter_App SHALL call the `ocr-cloud-vision` Edge Function with the image (or its Storage path) and language hint `km, en`.
2. THE `ocr-cloud-vision` Edge Function SHALL invoke Google Cloud Vision `images:annotate` with `DOCUMENT_TEXT_DETECTION` feature.
3. THE Edge Function SHALL store the GCP service-account credentials as a Supabase secret (`GCP_VISION_API_KEY` or service account JSON).
4. THE Edge Function SHALL apply per-user rate limiting (max 30 cloud OCR calls per 24 hours per FREEMIUM, 200 per PREMIUM/FAMILY_PREMIUM).
5. THE Edge Function SHALL return text + bounding boxes + average confidence.
6. THE Edge Function SHALL log every call (status + latency + truncated text length) for analytics; never log full raw text.

### Requirement 4: Field extraction

**User Story:** As a patient, I want the extracted text turned into structured fields, so that I don't fill out the whole form by hand.

#### Acceptance Criteria

1. THE Field_Extractor SHALL produce candidates for: medication name (English + Khmer), dosage amount + unit, frequency string, before/after meal flag, duration days.
2. THE Field_Extractor SHALL use heuristics: regex for dosage patterns (`\d+\s*(mg|ml|mcg|tab|cap|drop)`), keyword matching for frequency in Khmer + English ("twice daily", "BID", "ពីរដងក្នុងមួយថ្ងៃ"), and keyword matching for meal timing.
3. THE Field_Extractor SHALL use a curated medication-name dictionary (committed in app assets) to suggest the best match for partial OCR text.
4. THE Field_Extractor SHALL produce 0..N medication candidates per image.
5. THE Field_Extractor SHALL assign a confidence per candidate; candidates below 0.4 are marked "Needs review".

### Requirement 5: Review and confirm screen

**User Story:** As a patient, I want to review and edit extracted fields before saving, so that I catch OCR mistakes.

#### Acceptance Criteria

1. THE Flutter_App SHALL show the original image alongside an editable form pre-filled with extracted candidates.
2. THE Flutter_App SHALL allow the user to add, remove, or edit each medication candidate.
3. THE Flutter_App SHALL highlight low-confidence fields with a yellow border.
4. THE Flutter_App SHALL provide a "Reject all and enter manually" escape hatch.
5. THE Flutter_App SHALL save on confirmation by creating prescription + medications + dose events as in `03-prescription-medication`.

### Requirement 6: OCR metadata persistence

**User Story:** As a developer, I want OCR provenance stored on the prescription, so that we can debug accuracy and improve over time.

#### Acceptance Criteria

1. THE Flutter_App SHALL set `prescriptions.ocr_metadata` to a JSON object with: `engines_used` (array), `total_confidence`, `image_path`, `raw_text` (trimmed to 5000 chars), `field_candidates` (array of field-level results with confidence), `created_at`.
2. THE Flutter_App SHALL NEVER store the raw image in the database; only the Storage path.
3. THE Flutter_App SHALL allow user opt-out of "improve OCR by sharing" — when opted out, `ocr_metadata.shareable = false` so analytics jobs skip the row.

### Requirement 7: Quota and tier enforcement

**User Story:** As a freemium user, I want to know my OCR cloud-fallback quota, so that I can plan upgrades.

#### Acceptance Criteria

1. THE Edge Function SHALL count cloud OCR calls per user per rolling 24h via a `ocr_usage` table updated on each call.
2. WHEN quota is exceeded, THE Edge Function SHALL return HTTP 429 with body `{"error":"quota_exceeded","resets_at":...}`.
3. THE Flutter_App SHALL display a clear message and option to upgrade.
4. THE Flutter_App SHALL show remaining quota in settings.

### Requirement 8: Privacy and data handling

**User Story:** As a privacy-conscious user, I want my prescription images handled securely, so that they're not exposed.

#### Acceptance Criteria

1. THE Flutter_App SHALL upload images to a private Supabase Storage bucket with RLS path scoping.
2. THE `ocr-cloud-vision` Edge Function SHALL request a signed URL for the image, send it to Google Cloud Vision, and not retain the image bytes locally.
3. THE Edge Function SHALL configure GCP Vision to NOT store data for content improvement (the API supports `imageContext.features` opt-out where available).
4. THE Flutter_App SHALL allow the user to delete an OCR'd image and its derived data; deletion cascades through Storage and any cached `ocr_metadata`.

### Requirement 9: Performance

**User Story:** As a user, I want OCR to feel fast, so that scanning a prescription is convenient.

#### Acceptance Criteria

1. THE Flutter_App SHALL complete on-device OCR (ML Kit + optional Tesseract) within 3 seconds on a mid-range Android device for a 5 MP image.
2. THE Flutter_App SHALL show progress (capture → preprocessing → recognizing → extracting → ready) with a determinate progress bar.
3. THE Edge Function SHALL respond within 3 seconds for cloud OCR on a 1 MB image.
4. THE Flutter_App SHALL display partial results (e.g., "Found 2 medications, looking for more...") if extraction takes >1.5s.

### Requirement 10: Offline behavior

**User Story:** As a user without network, I want to scan and extract text offline, so that I can finalize the prescription later.

#### Acceptance Criteria

1. THE Flutter_App SHALL allow capture, on-device OCR, field extraction, and reviewing fully offline.
2. WHEN offline, THE Flutter_App SHALL disable the "Try better OCR" cloud fallback button with a tooltip "Online required".
3. WHEN the user saves an offline-extracted prescription, THE Flutter_App SHALL queue the image upload and prescription writes via the outbox.
4. WHEN connectivity returns, THE Flutter_App SHALL auto-resume.

### Requirement 11: Tesseract assets

**User Story:** As an Android user, I want the app to come with Khmer language data, so that on-device Khmer OCR works without downloads.

#### Acceptance Criteria

1. THE Flutter_App SHALL bundle `khm.traineddata` (≈10 MB) and `eng.traineddata` (≈4 MB) from the `tessdata_best` repository in `assets/tessdata/`.
2. THE Flutter_App SHALL initialize Tesseract on first OCR use and cache the engine instance.
3. THE Flutter_App SHALL allow updating language data via app updates only (not run-time downloads, to keep the boundary clear).

### Requirement 12: Error handling

**User Story:** As a user when OCR fails, I want a clear path forward, so that I can still create the prescription.

#### Acceptance Criteria

1. WHEN OCR returns no candidates, THE Flutter_App SHALL show "No medications detected. Want to enter manually?" and pre-create an empty prescription form.
2. WHEN cloud OCR fails (network or quota), THE Flutter_App SHALL fall back to on-device results.
3. WHEN ALL OCR paths fail, THE Flutter_App SHALL provide manual entry without losing the captured image.
