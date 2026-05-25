# Tasks: OCR Prescription Scanning

## Phase 1 — Dependencies and assets (0.5 day)

- [ ] **1.1** Add deps: `google_mlkit_text_recognition`, `flutter_tesseract_ocr` (or `flusseract`), `camera`, `image_picker`, `image`, `cunning_document_scanner` (optional), `path_provider`.
- [ ] **1.2** Bundle Khmer + English Tesseract trained data (`tessdata_best`) under `assets/tessdata/`.
- [ ] **1.3** Curate medication dictionary `assets/medications/dictionary.json` (start with top 200 commonly prescribed drugs in Cambodia, English + Khmer names).
- [ ] **1.4** Configure iOS Podfile per `google_mlkit_text_recognition` requirements (deployment target 15.5, exclude armv7).
- [ ] **1.5** Android: ensure minSdk 21+; add proguard rules if release builds strip ML Kit.

## Phase 2 — Capture & preprocessing (1 day)

- [ ] **2.1** `CameraCapturePage` with framing overlay.
- [ ] **2.2** `CropPreviewPage` with crop + rotate + perspective controls (using `image` package).
- [ ] **2.3** Image storage: upload to Supabase Storage at `{patient_id}/{temp_uuid}/<file>.jpg`.
- [ ] **2.4** Resize to max 2000px before OCR.

## Phase 3 — On-device engines (1.5 days)

- [ ] **3.1** `MlKitEngine` per design § 4.
- [ ] **3.2** `TesseractEngine` per design § 5 (asset copy on first use, language `khm+eng`).
- [ ] **3.3** Engine result domain model.
- [ ] **3.4** Unit tests with synthetic images (well-known fixtures).

## Phase 4 — Pipeline orchestrator (1 day)

- [ ] **4.1** `OcrPipeline.recognize` per design § 6.
- [ ] **4.2** Khmer detection helper.
- [ ] **4.3** Line-aligned merge function.
- [ ] **4.4** Tests: pipeline routing decisions for 4 cases (latin only, khmer only, mixed, low-conf).

## Phase 5 — Cloud fallback Edge Function (1.5 days)

- [ ] **5.1** Add `ocr_usage` table + `increment_ocr_usage` SQL function (design § 7).
- [ ] **5.2** `supabase/functions/ocr-cloud-vision/index.ts` per design.
- [ ] **5.3** Edge secret `GCP_SERVICE_ACCOUNT_JSON` configured.
- [ ] **5.4** Service-account JWT signing helper for Vision API access token.
- [ ] **5.5** Quota enforcement: 30/24h FREEMIUM, 200/24h PREMIUM/FAMILY_PREMIUM.
- [ ] **5.6** Edge Function tests: mocked Vision response, quota path returns 429.
- [ ] **5.7** Flutter `CloudVisionClient` calling the function; map quota errors to AppFailure.

## Phase 6 — Field extractor (1.5 days)

- [ ] **6.1** `MedicationDictionary` with fuzzy matching (Levenshtein + n-gram).
- [ ] **6.2** Dosage regex with English + Khmer units.
- [ ] **6.3** Frequency keyword detection (English + Khmer + medical abbreviations).
- [ ] **6.4** Meal-relation detection.
- [ ] **6.5** Duration detection.
- [ ] **6.6** Confidence aggregation per candidate.
- [ ] **6.7** Tests with golden raw-text → expected candidates.

## Phase 7 — Review UI (1 day)

- [ ] **7.1** `OcrProgressPage` with determinate progress (capture → preprocess → recognize → extract).
- [ ] **7.2** `OcrReviewPage` with side-by-side image + editable form.
- [ ] **7.3** `MedicationCandidateCard` with editable fields and confidence chip.
- [ ] **7.4** Save flow: hand off to `03-prescription-medication`'s create use case.
- [ ] **7.5** Reject path: navigate to manual create with image attached.

## Phase 8 — Persistence and audit (0.5 day)

- [ ] **8.1** Set `ocr_metadata` JSON on the resulting prescription.
- [ ] **8.2** Audit log entry on save with action type `PRESCRIPTION_CREATE` and details.method = 'ocr'.

## Phase 9 — Privacy + offline (0.5 day)

- [ ] **9.1** Settings toggle "Allow cloud OCR fallback" (default on).
- [ ] **9.2** Offline mode: hide cloud button with tooltip; queue image upload + prescription writes via outbox.

## Phase 10 — Tests and benchmarks (1 day)

- [ ] **10.1** Unit tests for all engines, pipeline, extractor.
- [ ] **10.2** Benchmark: 5 MP image on mid-range Android (Samsung A52 or similar) — total time ≤ 3s for on-device.
- [ ] **10.3** Integration test with fixture images in 3 categories: clean Latin, clean Khmer, mixed handwriting.
- [ ] **10.4** Edge Function load test: 50 concurrent requests; quota enforcement consistent.

## Phase 11 — Sign-off

- [ ] **11.1** Demo: scan English prescription → on-device result → review → save in <5s.
- [ ] **11.2** Demo: scan Khmer prescription → Tesseract path → save.
- [ ] **11.3** Demo: scan handwritten mixed → cloud fallback succeeds; freemium quota indicator visible.
- [ ] **11.4** Demo: airplane mode → on-device works; cloud disabled with tooltip.
