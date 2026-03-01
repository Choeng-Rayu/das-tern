"""Main pipeline orchestrator — coordinates preprocessing, layout, OCR, post-processing, and formatting."""
import re
import time
import logging
from typing import Dict, Any, Tuple, Optional, List
import cv2
import numpy as np
import pytesseract

from app.pipeline.preprocessor import preprocess_image
from app.pipeline.layout import analyze_layout, LayoutResult, TableRowReconstructor
from app.pipeline.ocr_engine import OCREngine, OCRResult
from app.pipeline.postprocessor import PostProcessor
from app.pipeline.formatter import build_dynamic_universal, build_extraction_summary
from app.utils.image_utils import QualityReport, crop_region
from app.config import settings

logger = logging.getLogger(__name__)

# Known H-EQIP prescription column boundaries as proportions of table width
# Columns: item_number, medication_name, duration, instructions, morning, midday, afternoon, evening
COL_BOUNDARIES = [0.0, 0.043, 0.322, 0.458, 0.568, 0.648, 0.734, 0.887, 1.0]
COL_NAMES = ["item_number", "medication_name", "duration", "instructions",
             "morning", "midday", "afternoon", "evening"]
DOSE_COLS = {"morning", "midday", "afternoon", "evening"}

# Minimum area of ink blob in dose column to count as a mark
MIN_DOSE_BLOB_AREA = 8
# Minimum confidence for word detection (lower = accept more words)
MIN_WORD_CONF = 10
# Minimum characters for medication name
MIN_MED_NAME_LEN = 2

# Khmer and English keywords that indicate a table header row (not medication)
_HEADER_KEYWORDS_KM = {
    'ឈ្មោះឱសថ', 'ពេលព្រឹក', 'ក្រោយបាយ', 'ពេលថ្ងៃ', 'ពេលល្ងាច', 'ពេលយប់',
    'សម្គាល់', 'ការណែនាំ', 'ព្រឹក', 'ថ្ងៃត្រង់', 'ល្ងាច', 'ក្រោយ', 'មុន',
    'ថ្ងៃ', 'ខែ', 'ឆ្នាំ', 'រ', 'ខ', 'លេខ', 'ខ.',
    'ប្រើប្រាស់', 'ប្រើ', 'ប្រភេទ', 'ចំណាំ', 'ជំងឺ',
    'ឱសថ', 'ថ្នាំ',
    'សូមយកវេជ្ជបញ្ជាមកវិញ',  # "please return prescription"
    'វេជ្ជបញ្ជា',  # "prescription"  
    'ករណី',  # "case"
}
_HEADER_KEYWORDS_EN = frozenset([
    'medication', 'medicine', 'name', 'duration', 'morning', 'midday', 'afternoon',
    'evening', 'instructions', 'dose', 'quantity', 'item', 'unit', 'frequency',
    'total', 'days', 'remarks', 'note', 'notes', 'remark', 'drug', 'morning',
    'no.', 'number', 'prescription',
])


class PipelineOrchestrator:
    """Orchestrates the full OCR extraction pipeline."""

    def __init__(self):
        self.ocr_engine = OCREngine()
        self.post_processor = PostProcessor()
        self.row_reconstructor = TableRowReconstructor()
        logger.info("Pipeline orchestrator initialized")

    @staticmethod
    def _aggregate_bbox(words: list) -> list:
        """Compute the enclosing [x1, y1, x2, y2] bbox for a list of word dicts."""
        x1 = min(w['x'] for w in words)
        y1 = min(w['y'] for w in words)
        x2 = max(w['x'] + w['w'] for w in words)
        y2 = max(w['y'] + w['h'] for w in words)
        return [x1, y1, x2, y2]

    def extract(self, image_bytes: bytes, filename: str = "unknown") -> Dict[str, Any]:
        """Run full extraction pipeline on an image.

        Returns: {"success": True, "data": {...}, "extraction_summary": {...}}
        """
        start_time = time.time()

        try:
            # Step 1: Preprocess
            logger.info(f"Step 1: Preprocessing image ({len(image_bytes)} bytes)")
            color_img, gray_img, quality_report = preprocess_image(image_bytes)

            # Build image metadata
            h, w = color_img.shape[:2]
            fmt = "png" if filename.lower().endswith(".png") else "jpg"
            image_metadata = {
                "width": w,
                "height": h,
                "format": fmt,
                "dpi": 200,
                "file_size_bytes": len(image_bytes)
            }

            # Step 2: Layout Analysis
            logger.info("Step 2: Analyzing layout")
            layout = analyze_layout(gray_img, color_img)

            # Step 3: OCR each region
            logger.info("Step 3: Running OCR on regions")

            # OCR header
            header_text = ""
            header_result_obj = None
            if layout.header_region:
                header_result_obj = self.ocr_engine.ocr_region(
                    color_img, layout.header_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                header_text = header_result_obj.text

            # OCR patient info
            patient_text = ""
            patient_result_obj = None
            if layout.patient_region:
                patient_result_obj = self.ocr_engine.ocr_region(
                    color_img, layout.patient_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                patient_text = patient_result_obj.text

            # OCR clinical info
            clinical_text = ""
            clinical_result_obj = None
            if layout.clinical_region:
                clinical_result_obj = self.ocr_engine.ocr_region(
                    color_img, layout.clinical_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                clinical_text = clinical_result_obj.text

            # OCR medication table using hybrid approach
            medications = []
            table_words = []
            if layout.table:
                logger.info("  Processing medication table (hybrid approach)")
                medications, table_words = self._process_table_hybrid(color_img, gray_img, layout.table.bbox)

            # Full-image fallback: if no medications found via table, scan the entire upper
            # portion of the image (covers prescriptions with non-standard layouts or wrong
            # table detection)
            if not medications:
                logger.info("  No medications from table — trying full-image fallback")
                h_img, w_img = color_img.shape[:2]
                full_bbox = (0, 0, w_img, int(h_img * 0.85))
                medications, table_words = self._extract_text_fallback(color_img, gray_img, full_bbox)
                logger.info(f"  Full-image fallback → {len(medications)} medications")

            # OCR footer/signature/date
            footer_text = ""
            footer_result_obj = None
            if layout.footer_region:
                footer_result_obj = self.ocr_engine.ocr_region(
                    color_img, layout.footer_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                footer_text = footer_result_obj.text

            date_text = ""
            date_result_obj = None
            if layout.date_region:
                date_result_obj = self.ocr_engine.ocr_region(
                    color_img, layout.date_region, content_type="mixed", lang=settings.TESSERACT_LANG_ENG
                )
                date_text = date_result_obj.text

            # Build region OCR data for raw extraction output
            region_ocr_data = {
                "header": header_result_obj,
                "patient": patient_result_obj,
                "clinical": clinical_result_obj,
                "footer": footer_result_obj,
                "date": date_result_obj,
                "table_bbox": list(layout.table.bbox) if layout.table else None,
            }

            # Step 4: Post-process
            logger.info("Step 4: Post-processing OCR results")
            facility = self.post_processor.process_header(header_text, w)
            patient = self.post_processor.process_patient_info(patient_text)
            clinical = self.post_processor.process_clinical_info(clinical_text)
            footer_data = self.post_processor.process_footer(footer_text + "\n" + date_text)

            # Step 5: Format output
            logger.info("Step 5: Formatting output")
            processing_time_ms = (time.time() - start_time) * 1000

            result = build_dynamic_universal(
                facility=facility,
                patient=patient,
                clinical=clinical,
                medications=medications,
                footer_data=footer_data,
                quality_report=quality_report,
                processing_time_ms=processing_time_ms,
                image_metadata=image_metadata,
                region_ocr_data=region_ocr_data,
                table_words=table_words,
            )

            summary = build_extraction_summary(result, processing_time_ms)

            logger.info(f"Pipeline complete in {processing_time_ms:.0f}ms — {summary['total_medications']} medications found")

            return {
                "success": True,
                "data": result,
                "extraction_summary": summary
            }

        except Exception as e:
            processing_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Pipeline failed after {processing_time_ms:.0f}ms: {e}", exc_info=True)
            return {
                "success": False,
                "error": "extraction_failed",
                "message": str(e),
                "extraction_summary": {
                    "total_medications": 0,
                    "confidence_score": 0.0,
                    "needs_review": True,
                    "fields_needing_review": ["all"],
                    "processing_time_ms": round(processing_time_ms, 1),
                    "engines_used": ["tesseract"]
                }
            }

    def _process_table_hybrid(self, color_img: np.ndarray, gray_img: np.ndarray,
                               table_bbox: Tuple[int, int, int, int]) -> Tuple[list, list]:
        """Process medication table using a multi-strategy hybrid approach.
        Returns (medications, table_words).

        Strategy 1: Dynamic column detection from actual vertical grid lines
        Strategy 2: Hardcoded H-EQIP column proportions (original approach)
        Strategy 3: Full-text OCR fallback — parse medication names from raw text lines
        """
        tx1, ty1, tx2, ty2 = table_bbox
        tw = tx2 - tx1
        th = ty2 - ty1

        # --- Strategy 1: Try dynamic vertical-line-based column detection ---
        logger.info("  Trying dynamic column detection from vertical lines")
        dynamic_col_x = self._detect_dynamic_columns(gray_img, table_bbox)
        if dynamic_col_x and len(dynamic_col_x) >= 5:
            logger.info(f"  Dynamic columns found: {len(dynamic_col_x)} boundaries")
            medications, table_words = self._extract_structured(color_img, gray_img, table_bbox, dynamic_col_x)
            if medications:
                logger.info(f"  Strategy 1 (dynamic columns) → {len(medications)} medications")
                return medications, table_words
            logger.info("  Strategy 1 yielded 0 medications, trying Strategy 2")

        # --- Strategy 2: Hardcoded H-EQIP column proportions ---
        logger.info("  Using hardcoded H-EQIP column boundaries")
        heqip_col_x = [tx1 + int(tw * b) for b in COL_BOUNDARIES]
        medications, table_words = self._extract_structured(color_img, gray_img, table_bbox, heqip_col_x)
        if medications:
            logger.info(f"  Strategy 2 (H-EQIP columns) → {len(medications)} medications")
            return medications, table_words
        logger.info("  Strategy 2 yielded 0 medications, trying Strategy 3 (text fallback)")

        # --- Strategy 3: General text OCR fallback ---
        medications, table_words = self._extract_text_fallback(color_img, gray_img, table_bbox)
        logger.info(f"  Strategy 3 (text fallback) → {len(medications)} medications")
        return medications, table_words

    def _detect_dynamic_columns(self, gray_img: np.ndarray,
                                 table_bbox: Tuple[int, int, int, int]) -> Optional[List[int]]:
        """Detect actual column x-boundaries by finding vertical grid lines within the table."""
        tx1, ty1, tx2, ty2 = table_bbox
        tw = tx2 - tx1
        th = ty2 - ty1

        if tw < 50 or th < 30:
            return None

        table_crop = gray_img[ty1:ty2, tx1:tx2].copy()

        # Binarize with Otsu
        _, binary = cv2.threshold(table_crop, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

        # Detect vertical lines that span at least 35% of the table height
        v_len = max(int(th * 0.35), 15)
        v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, v_len))
        v_lines_img = cv2.morphologyEx(binary, cv2.MORPH_OPEN, v_kernel, iterations=2)

        # Project onto x-axis — find columns with high vertical density
        col_sums = np.sum(v_lines_img, axis=0).astype(np.float32)
        max_val = float(np.max(col_sums))
        if max_val == 0:
            return None

        threshold = max_val * 0.25
        above = col_sums > threshold

        # Collect centers of contiguous high-density regions
        boundaries = [0]
        in_region = False
        start_x = 0
        for x in range(tw):
            if above[x] and not in_region:
                in_region = True
                start_x = x
            elif not above[x] and in_region:
                in_region = False
                center = (start_x + x) // 2
                # Ignore boundaries too close to existing ones (merge noise)
                if not boundaries or center - boundaries[-1] > tw * 0.02:
                    boundaries.append(center)
        if in_region:
            boundaries.append(start_x)
        boundaries.append(tw)
        boundaries = sorted(set(boundaries))

        # Need at least 4 internal separators to form meaningful columns
        if len(boundaries) < 5:
            return None

        # Convert to image coordinates
        return [tx1 + x for x in boundaries]

    def _extract_structured(self, color_img: np.ndarray, gray_img: np.ndarray,
                             table_bbox: Tuple[int, int, int, int],
                             col_x: List[int]) -> Tuple[list, list]:
        """Extract medications using explicit column x-boundaries.
        Returns (medications, all_words).

        col_x must have at least 5 entries ([item_num, ..., med_name_end, ..., dose_cols, end]).
        When the prescription has a different column count than H-EQIP, we auto-assign
        col roles: leftmost narrow = item#, wide middle = medication_name, far-right = doses.
        """
        tx1, ty1, tx2, ty2 = table_bbox
        tw = tx2 - tx1
        th = ty2 - ty1

        n_cols = len(col_x) - 1

        # Determine which col_x segment contains the medication names.
        # Heuristic: the widest column in the left 60% of the table is the name column.
        name_col_idx = 1  # default: second column
        best_width = 0
        for i in range(n_cols):
            col_center = (col_x[i] + col_x[i + 1]) / 2
            col_width = col_x[i + 1] - col_x[i]
            rel_center = (col_center - tx1) / max(tw, 1)
            if rel_center < 0.65 and col_width > best_width:
                best_width = col_width
                name_col_idx = i

        # Ensure strip_x covers from col 0 through the name column + 2 more (instructions)
        strip_end_idx = min(name_col_idx + 3, n_cols)
        strip_x1 = tx1
        strip_x2 = col_x[strip_end_idx]
        if strip_x2 <= strip_x1:
            strip_x2 = min(tx1 + int(tw * 0.65), col_x[-1])

        strip_crop = color_img[ty1:ty2, strip_x1:strip_x2]
        if strip_crop.size == 0:
            return [], []

        # OCR the text strip
        config = '--oem 1 --psm 4'
        try:
            data = pytesseract.image_to_data(
                strip_crop, lang=settings.TESSERACT_LANG, config=config,
                output_type=pytesseract.Output.DICT
            )
        except Exception as e:
            logger.warning(f"OCR failed on strip: {e}")
            return [], []

        # Collect words with sufficient confidence
        words = []
        for i, text in enumerate(data['text']):
            if text.strip() and int(data['conf'][i]) > MIN_WORD_CONF:
                wx = data['left'][i] + strip_x1
                wy = data['top'][i] + ty1
                ww = data['width'][i]
                wh = data['height'][i]
                words.append({
                    'text': text.strip(),
                    'x': wx,
                    'y': wy,
                    'w': ww,
                    'h': wh,
                    'conf': int(data['conf'][i]),
                    'bbox': [wx, wy, wx + ww, wy + wh],
                    'confidence': int(data['conf'][i]) / 100.0,
                })

        if not words:
            return [], []

        # Group words into rows by Y-center alignment (uses configurable tolerance)
        rows = self.row_reconstructor.cluster_word_dicts(words)

        # Supplement: if a significant portion of the table bottom has no detected
        # words (PSM 4 sometimes misses the last row in tall strips), re-OCR that
        # bottom region with PSM 11 (sparse text) to catch any missed rows.
        if words:
            last_word_bottom = max(w['y'] + w['h'] for w in words)
            remaining_h = ty2 - last_word_bottom
            est_row_h = (ty2 - ty1) / max(len(rows) + 1, 4)
            if remaining_h > est_row_h * 0.6:
                bottom_y_start = max(ty1, last_word_bottom - 20)
                bottom_crop = color_img[bottom_y_start:ty2, strip_x1:strip_x2]
                if bottom_crop.size > 0:
                    try:
                        data_b = pytesseract.image_to_data(
                            bottom_crop, lang=settings.TESSERACT_LANG,
                            config='--oem 1 --psm 11',
                            output_type=pytesseract.Output.DICT,
                        )
                        for bi, btext in enumerate(data_b['text']):
                            if btext.strip() and int(data_b['conf'][bi]) > MIN_WORD_CONF:
                                bwx = data_b['left'][bi] + strip_x1
                                bwy = data_b['top'][bi] + bottom_y_start
                                bww = data_b['width'][bi]
                                bwh = data_b['height'][bi]
                                # Only add words that are below the already-detected region
                                if bwy > last_word_bottom - 10:
                                    words.append({
                                        'text': btext.strip(),
                                        'x': bwx, 'y': bwy, 'w': bww, 'h': bwh,
                                        'conf': int(data_b['conf'][bi]),
                                        'bbox': [bwx, bwy, bwx + bww, bwy + bwh],
                                        'confidence': int(data_b['conf'][bi]) / 100.0,
                                        'from_supplement': True,
                                    })
                        rows = self.row_reconstructor.cluster_word_dicts(words)
                    except Exception as e:
                        logger.warning(f"Bottom-strip supplement OCR failed: {e}")

        # Map each row's words to columns, then identify medication rows
        med_rows = []
        for row_words in rows:
            row_data = self._map_words_to_columns_flexible(row_words, col_x, name_col_idx, n_cols)
            med_name = row_data.get("medication_name", "").strip()

            # If structured mapping didn't find a name, fall back: take all alphanumeric
            # words from the row that aren't purely numeric as the medication name.
            if len(med_name) < MIN_MED_NAME_LEN:
                candidate_word_objs = [
                    w for w in sorted(row_words, key=lambda x: x['x'])
                    if re.search(r'[A-Za-z\u1780-\u17FF]', w['text'])
                ]
                med_name = ' '.join(w['text'] for w in candidate_word_objs).strip()
                if len(med_name) >= MIN_MED_NAME_LEN:
                    row_data['medication_name'] = med_name
                    if candidate_word_objs:
                        row_data['medication_name_bbox'] = self._aggregate_bbox(candidate_word_objs)
                        row_data['medication_name_words'] = [
                            {'text': w['text'], 'bbox': w.get('bbox'), 'confidence': w.get('confidence', w['conf'] / 100.0)}
                            for w in candidate_word_objs
                        ]

            # Skip rows that are clearly header/label rows, not medication rows
            if len(med_name) < MIN_MED_NAME_LEN or self._is_header_or_label_text(med_name):
                continue

            avg_y = sum(w['y'] + w['h'] // 2 for w in row_words) / len(row_words)
            if any(w.get('from_supplement', False) for w in row_words):
                row_data['from_supplement'] = True
            med_rows.append((row_data, avg_y, row_words))

        if not med_rows:
            return [], words

        # Re-OCR duration column per row with Khmer+English
        dur_x1 = col_x[min(name_col_idx + 1, len(col_x) - 2)]
        dur_x2 = col_x[min(name_col_idx + 2, len(col_x) - 1)]
        row_centers = [avg_y for _, avg_y, _ in med_rows]

        if len(row_centers) >= 2:
            avg_spacing = (row_centers[-1] - row_centers[0]) / (len(row_centers) - 1)
            half_row = int(avg_spacing / 2)
        else:
            half_row = th // 4

        for i, (row_data, avg_y, row_words) in enumerate(med_rows):
            min_y = max(ty1, int(avg_y) - half_row) if i == 0 else int((row_centers[i - 1] + row_centers[i]) / 2)
            max_y = min(ty2, int(avg_y) + half_row) if i == len(med_rows) - 1 else int((row_centers[i] + row_centers[i + 1]) / 2)
            dur_cell = color_img[min_y:max_y, dur_x1:dur_x2]
            if dur_cell.size > 0:
                try:
                    dur_text = pytesseract.image_to_string(
                        dur_cell, lang=settings.TESSERACT_LANG, config='--oem 1 --psm 7'
                    ).strip()
                    if not dur_text:
                        # PSM 7 (single-line) can fail on taller crops; try PSM 6 as fallback
                        dur_text = pytesseract.image_to_string(
                            dur_cell, lang=settings.TESSERACT_LANG, config='--oem 1 --psm 6'
                        ).strip()
                    if dur_text:
                        row_data['duration'] = dur_text
                        row_data['duration_bbox'] = [dur_x1, min_y, dur_x2, max_y]
                except Exception:
                    pass

        # Analyze dose columns — try to use the rightmost columns as dose columns
        dose_col_start = max(n_cols - 4, name_col_idx + 2)
        actual_dose_cols = COL_NAMES[4:]  # morning, midday, afternoon, evening

        dose_results = {}
        for j, col_name in enumerate(actual_dose_cols):
            col_idx = dose_col_start + j
            if col_idx >= n_cols:
                dose_results[col_name] = {k: "-" for k in range(len(med_rows))}
                continue
            cell_x1 = col_x[col_idx]
            cell_x2 = col_x[col_idx + 1]
            dose_results[col_name] = self._analyze_dose_column(
                gray_img, cell_x1, cell_x2, ty1, ty2, row_centers
            )

        # For rows detected via the bottom-strip supplement, blob analysis may
        # miss dose marks near column boundaries due to trimming or fold artifacts.
        # Use row-level OCR to fill in any '-' values that should be '1'.
        for i, (row_data, avg_y, row_words) in enumerate(med_rows):
            if not row_data.get('from_supplement', False):
                continue
            row_y1 = int((row_centers[i - 1] + row_centers[i]) / 2) if i > 0 else max(ty1, int(avg_y) - half_row)
            # Extend 50 px below for OCR context (helps Tesseract recognise marks near table edge)
            row_y2 = min(color_img.shape[0], int(avg_y) + half_row + 50)
            ocr_doses = self._detect_doses_from_row_ocr(
                color_img, row_y1, row_y2, col_x, dose_col_start, n_cols, actual_dose_cols
            )
            for col_name, ocr_val in ocr_doses.items():
                if dose_results[col_name].get(i, '-') == '-' and ocr_val == '1':
                    dose_results[col_name][i] = '1'

        medications = []
        for i, (row_data, avg_y, row_words) in enumerate(med_rows):
            min_y_row = max(ty1, int(avg_y) - half_row) if i == 0 else int((row_centers[i - 1] + row_centers[i]) / 2)
            max_y_row = min(ty2, int(avg_y) + half_row) if i == len(med_rows) - 1 else int((row_centers[i] + row_centers[i + 1]) / 2)
            for j, col_name in enumerate(actual_dose_cols):
                row_data[col_name] = dose_results[col_name].get(i, "-")
                # Add dose cell bbox from column boundaries
                col_idx = dose_col_start + j
                if col_idx < n_cols:
                    row_data[f"{col_name}_bbox"] = [col_x[col_idx], min_y_row,
                                                     col_x[col_idx + 1], max_y_row]
            medication = self.post_processor.process_medication_row(row_data, i + 1)
            medications.append(medication)

        return medications, words

    def _extract_text_fallback(self, color_img: np.ndarray, gray_img: np.ndarray,
                                table_bbox: Tuple[int, int, int, int]) -> Tuple[list, list]:
        """Fallback: OCR the entire table area as a text block and parse medication names
        from each line heuristically. Returns (medications, all_words).
        This handles prescriptions with non-standard layouts."""
        tx1, ty1, tx2, ty2 = table_bbox

        # Expand the crop slightly to avoid missing text at edges
        h_img, w_img = color_img.shape[:2]
        expand = 10
        cx1 = max(0, tx1 - expand)
        cy1 = max(0, ty1 - expand)
        cx2 = min(w_img, tx2 + expand)
        cy2 = min(h_img, ty2 + expand)

        table_crop = color_img[cy1:cy2, cx1:cx2]
        if table_crop.size == 0:
            return [], []

        # Try with combined Khmer+English language first, then English-only
        medications = []
        all_words = []
        for lang in [settings.TESSERACT_LANG, settings.TESSERACT_LANG_ENG]:
            try:
                data = pytesseract.image_to_data(
                    table_crop, lang=lang,
                    config='--oem 1 --psm 4',
                    output_type=pytesseract.Output.DICT
                )
            except Exception as e:
                logger.warning(f"Fallback OCR failed with lang={lang}: {e}")
                continue

            words = []
            for i, text in enumerate(data['text']):
                if text.strip() and int(data['conf'][i]) > MIN_WORD_CONF:
                    wx = data['left'][i] + cx1
                    wy = data['top'][i] + cy1
                    ww = data['width'][i]
                    wh = data['height'][i]
                    words.append({
                        'text': text.strip(),
                        'x': wx,
                        'y': wy,
                        'w': ww,
                        'h': wh,
                        'conf': int(data['conf'][i]),
                        'bbox': [wx, wy, wx + ww, wy + wh],
                        'confidence': int(data['conf'][i]) / 100.0,
                    })

            if not words:
                continue

            all_words = words
            rows = self.row_reconstructor.cluster_word_dicts(words)

            item_num = 0
            for row_words in rows:
                sorted_words = sorted(row_words, key=lambda w: w['x'])
                row_text = ' '.join(w['text'] for w in sorted_words).strip()

                if len(row_text) < MIN_MED_NAME_LEN:
                    continue

                # Skip header/label rows
                if self._is_header_or_label_text(row_text):
                    continue

                # Extract alphabetic words (likely medication name) — keep full word objects
                alpha_word_objs = [
                    w for w in sorted_words
                    if re.search(r'[A-Za-z\u1780-\u17FF]', w['text']) and len(w['text']) >= 2
                ]
                if not alpha_word_objs:
                    continue

                med_name_candidate = ' '.join(w['text'] for w in alpha_word_objs)

                # Check against lexicon or pattern heuristics
                # If lexicon is unavailable, rely entirely on text pattern heuristics
                has_lexicon = len(self.post_processor.lexicon.medications_en) > 0
                if has_lexicon:
                    _, _, _, match_conf = self.post_processor.lexicon.match_medication(med_name_candidate)
                    is_known_med = match_conf >= 0.85
                else:
                    is_known_med = False

                if not is_known_med and not self._looks_like_medication_text(row_text):
                    continue

                item_num += 1
                row_data = {
                    'medication_name': med_name_candidate,
                    'medication_name_bbox': self._aggregate_bbox(alpha_word_objs),
                    'medication_name_words': [
                        {'text': w['text'], 'bbox': w.get('bbox'), 'confidence': w.get('confidence', w['conf'] / 100.0)}
                        for w in alpha_word_objs
                    ],
                    'duration': '',
                    'instructions': '',
                    'morning': '-',
                    'midday': '-',
                    'afternoon': '-',
                    'evening': '-',
                    'item_number': str(item_num),
                }
                medication = self.post_processor.process_medication_row(row_data, item_num)
                medications.append(medication)

            if medications:
                break  # Success with this language

        return medications, all_words

    def _looks_like_medication_text(self, text: str) -> bool:
        """Heuristic: does this line of text look like it contains a medication entry?"""
        # Must NOT be a known header label
        if self._is_header_or_label_text(text):
            return False
        # Dose/strength pattern (500mg, 10mg, 250ml, 5mcg, etc.)
        if re.search(r'\b\d+\s*(?:mg|ml|mcg|g|iu|unit|tab|cap)\b', text, re.IGNORECASE):
            return True
        # Capitalized English word of 4+ chars — typical branded drug name
        if re.search(r'\b[A-Z][a-z]{3,}', text):
            return True
        # Khmer text of 3+ chars that is NOT a known header word
        if re.search(r'[\u1780-\u17FF]{3,}', text):
            return True
        # Numbered list entry (e.g., "1. Amoxicillin" or "1 Paracetamol")
        if re.match(r'^\d+[\.\s]\s*[A-Za-z\u1780-\u17FF]', text):
            return True
        # Common medication suffixes
        if re.search(r'\b\w+(?:cillin|mycin|zole|pril|sartan|statin|lone|olol|pam|xam)\b', text, re.IGNORECASE):
            return True
        return False

    def _is_header_or_label_text(self, text: str) -> bool:
        """Return True if text looks like a table column header or label, not a medication."""
        if not text:
            return True
        stripped = text.strip()
        if not stripped:
            return True

        # Exact or substring match against Khmer blacklist
        for kw in _HEADER_KEYWORDS_KM:
            if kw in stripped:
                return True

        # Check if ALL English words in text are header keywords (e.g. pure "morning afternoon")
        lower = stripped.lower()
        english_words = set(re.findall(r'[a-z]{3,}', lower))
        if english_words and english_words.issubset(_HEADER_KEYWORDS_EN):
            return True

        # Reject text that is clearly garbage from OCR (mostly symbols/noise, no alphanumeric)
        alphanumeric = re.findall(r'[A-Za-z\u1780-\u17FF0-9]', stripped)
        if len(alphanumeric) < 2:
            return True

        return False

    def _map_words_to_columns_flexible(self, words: list, col_x: List[int],
                                        name_col_idx: int, n_cols: int) -> Dict[str, Any]:
        """Map words to columns using actual detected column boundaries.

        Uses the detected name_col_idx for medication_name, and flexibly assigns
        item_number, duration, instructions columns relative to name column.
        Outputs *_bbox and *_words keys for each column.
        """
        result = {}
        col_words: Dict[str, list] = {name: [] for name in COL_NAMES[:4]}

        for w in sorted(words, key=lambda x: x['x']):
            word_center_x = w['x'] + w['w'] // 2

            # Find which column segment this word falls in
            for i in range(n_cols):
                if col_x[i] <= word_center_x < col_x[i + 1]:
                    # Map segment index to semantic column name
                    if i == 0:
                        col_words['item_number'].append(w)
                    elif i == name_col_idx:
                        col_words['medication_name'].append(w)
                    elif i == name_col_idx - 1 and i > 0:
                        col_words['item_number'].append(w)
                    elif i == name_col_idx + 1 and n_cols - i > 4:
                        col_words['duration'].append(w)
                    elif i == name_col_idx + 2 and n_cols - i > 3:
                        col_words['instructions'].append(w)
                    break

        for name, word_list in col_words.items():
            result[name] = ' '.join(w['text'] for w in word_list)
            if word_list:
                result[f"{name}_bbox"] = self._aggregate_bbox(word_list)
                result[f"{name}_words"] = [
                    {'text': w['text'], 'bbox': w.get('bbox'), 'confidence': w.get('confidence', w['conf'] / 100.0)}
                    for w in word_list
                ]

        return result



    def _cluster_words_by_y(self, words: list, threshold: int = 30) -> List[list]:
        """Group words into rows based on y-position proximity.

        .. deprecated:: Use ``self.row_reconstructor.cluster_word_dicts`` directly.
        Kept for backward compatibility.
        """
        if not words:
            return []
        reconstructor = TableRowReconstructor(tolerance=threshold, adaptive=False)
        return reconstructor.cluster_word_dicts(words)

    def _map_words_to_columns(self, words: list, col_x: list) -> Dict[str, Any]:
        """Map words to text columns based on x-position (H-EQIP fixed boundaries).
        Outputs *_bbox and *_words keys for each column."""
        result = {}
        col_words = {name: [] for name in COL_NAMES[:4]}

        for w in sorted(words, key=lambda x: x['x']):
            word_center_x = w['x'] + w['w'] // 2
            for i, name in enumerate(COL_NAMES[:4]):
                if col_x[i] <= word_center_x < col_x[i + 1]:
                    col_words[name].append(w)
                    break

        for name, word_list in col_words.items():
            result[name] = ' '.join(w['text'] for w in word_list)
            if word_list:
                result[f"{name}_bbox"] = self._aggregate_bbox(word_list)
                result[f"{name}_words"] = [
                    {'text': w['text'], 'bbox': w.get('bbox'), 'confidence': w.get('confidence', w['conf'] / 100.0)}
                    for w in word_list
                ]

        return result

    def _analyze_dose_column(self, gray_img: np.ndarray, col_x1: int, col_x2: int,
                              ty1: int, ty2: int, row_centers: List[float]) -> Dict[int, str]:
        """Analyze a full dose column strip using contour detection.

        Steps:
        1. Extract column strip with border trimming
        2. Threshold to binary
        3. Remove horizontal grid lines
        4. Find ink blobs using contour detection
        5. Detect and filter fold/crease artifacts by position analysis
        6. Map blobs to medication rows by y-proximity

        Returns mapping of row_index -> dose_value ("1" or "-")
        """
        img_h, img_w = gray_img.shape
        x1 = max(0, col_x1)
        x2 = min(img_w, col_x2)
        y1 = max(0, ty1)
        y2 = min(img_h, ty2)

        cw = x2 - x1
        if cw < 10:
            return {i: "-" for i in range(len(row_centers))}

        # Extract the full column strip
        strip = gray_img[y1:y2, x1:x2].copy()
        if strip.size == 0:
            return {i: "-" for i in range(len(row_centers))}

        sh, sw = strip.shape

        # Trim vertical borders (30% each side) to remove grid lines at column edges
        trim_x = max(int(sw * 0.30), 5)
        inner = strip[:, trim_x:sw - trim_x]
        if inner.size == 0 or inner.shape[1] < 3:
            return {i: "-" for i in range(len(row_centers))}

        inner_w = inner.shape[1]

        # Apply adaptive threshold to detect dark ink marks (more robust than fixed 160)
        # First try Otsu, then use a fixed fallback if the strip is mostly white or uniform
        otsu_val, binary_otsu = cv2.threshold(inner, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        fixed_val, binary_fixed = cv2.threshold(inner, 160, 255, cv2.THRESH_BINARY_INV)
        # Pick whichever threshold captures more ink (higher non-zero pixel count)
        binary = binary_otsu if cv2.countNonZero(binary_otsu) >= cv2.countNonZero(binary_fixed) else binary_fixed

        # Remove horizontal grid lines using morphological opening
        h_kernel_len = max(inner_w * 2 // 3, 5)
        kernel_h = cv2.getStructuringElement(cv2.MORPH_RECT, (h_kernel_len, 1))
        h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel_h)
        binary = cv2.subtract(binary, h_lines)

        # Find contours (remaining ink blobs = actual character marks)
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Collect significant blobs
        min_area = MIN_DOSE_BLOB_AREA
        blobs = []
        for c in contours:
            area = cv2.contourArea(c)
            if area >= min_area:
                bx, by, bw, bh = cv2.boundingRect(c)
                if bh >= 3:
                    blob_center_y = y1 + by + bh // 2
                    blobs.append({'y': blob_center_y, 'area': area, 'h': bh, 'w': bw, 'x': bx})

        # Fold artifact detection: a paper fold/crease creates blobs at
        # x-positions near the left edge of the trimmed area across multiple rows.
        # Real centered characters appear further right in the column.
        if blobs and len(row_centers) >= 3:
            left_threshold = inner_w * 0.30
            # Find left-edge blobs and which rows they match
            left_blob_rows = set()
            left_blob_indices = set()
            for idx, b in enumerate(blobs):
                if b['x'] < left_threshold:
                    left_blob_indices.add(idx)
                    for i, row_y in enumerate(row_centers):
                        if abs(b['y'] - row_y) <= 30:
                            left_blob_rows.add(i)

            # Only apply fold filter if left blobs match most rows
            min_fold_rows = len(row_centers) - 1
            if len(left_blob_rows) >= min_fold_rows:
                # Count rows that also have centered (non-left) blobs.
                # Only count center blobs with sufficient area as valid alternatives
                # (tiny blobs < 20 are noise/grid artefacts, not real marks).
                MIN_CENTER_BLOB_AREA = 20
                center_rows = set()
                for b in blobs:
                    if b['x'] >= left_threshold and b['area'] >= MIN_CENTER_BLOB_AREA:
                        for i, row_y in enumerate(row_centers):
                            if abs(b['y'] - row_y) <= 30:
                                center_rows.add(i)

                if len(center_rows) >= len(row_centers) // 2:
                    # Most rows have centered alternatives — selectively remove
                    # left blobs only for rows that have a centered backup
                    remove_indices = set()
                    for idx in left_blob_indices:
                        b = blobs[idx]
                        for i, row_y in enumerate(row_centers):
                            if abs(b['y'] - row_y) <= 30 and i in center_rows:
                                remove_indices.add(idx)
                                break
                    blobs = [b for i, b in enumerate(blobs) if i not in remove_indices]
                else:
                    # Most rows lack centered blobs — left blobs are pure fold
                    blobs = [b for i, b in enumerate(blobs) if i not in left_blob_indices]

        # Map blobs to medication rows by y-proximity
        result = {}
        match_threshold = 30  # tighter window prevents adjacent-row blob overlap

        for i, row_y in enumerate(row_centers):
            nearby = [b for b in blobs if abs(b['y'] - row_y) <= match_threshold]
            if nearby:
                total_area = sum(b['area'] for b in nearby)
                if total_area >= 25:
                    result[i] = "1"
                else:
                    result[i] = "-"
            else:
                result[i] = "-"

        return result

    def _detect_doses_from_row_ocr(
        self,
        color_img: np.ndarray,
        row_y1: int,
        row_y2: int,
        col_x: list,
        dose_col_start: int,
        n_cols: int,
        actual_dose_cols: list,
    ) -> Dict[str, str]:
        """OCR-based dose detection for a single supplement row.

        Blob analysis can miss marks that fall near column separator lines or are
        hidden by the 30 % border trim.  This method crops the FULL TABLE WIDTH of
        the row (Tesseract needs the surrounding text context for PSM-4 layout
        analysis) and runs OCR, then assigns detected marks to dose columns using
        midpoint-based boundaries so that marks near column separators are still
        assigned to the correct column.

        Returns a dict of {col_name: "1"} for any '1' marks that are found.
        Only '1' values are returned; callers use this to fill gaps left by blob
        detection.
        """
        n_dose_cols = min(len(actual_dose_cols), n_cols - dose_col_start)
        if n_dose_cols <= 0:
            return {}

        # Use the full table width: col_x[0] (table left) to col_x[-1] (table right).
        # PSM-4 needs full-row context to correctly segment short dose marks.
        table_x1 = col_x[0]
        table_x2 = col_x[-1]
        dose_x1 = col_x[dose_col_start]
        dose_x2 = col_x[min(dose_col_start + n_dose_cols, len(col_x) - 1)]

        img_h, img_w = color_img.shape[:2]
        crop_y1 = max(0, row_y1)
        crop_y2 = min(img_h, row_y2)

        if crop_y2 - crop_y1 < 5:
            return {}

        crop = color_img[crop_y1:crop_y2, max(0, table_x1):min(img_w, table_x2)]
        if crop.size == 0:
            return {}

        try:
            data = pytesseract.image_to_data(
                crop,
                lang=settings.TESSERACT_LANG,
                config='--oem 1 --psm 4',
                output_type=pytesseract.Output.DICT,
            )
        except Exception:
            return {}

        # Compute midpoint-based column boundaries so that marks written near the
        # right edge of a cell (close to the next separator) are still assigned to
        # the correct column.
        col_centers = [
            (col_x[dose_col_start + j] + col_x[dose_col_start + j + 1]) / 2
            for j in range(n_dose_cols)
        ]
        boundaries = [col_x[dose_col_start]]
        for j in range(1, n_dose_cols):
            boundaries.append((col_centers[j - 1] + col_centers[j]) / 2)
        boundaries.append(col_x[min(dose_col_start + n_dose_cols, len(col_x) - 1)])

        result: Dict[str, str] = {}
        for idx in range(len(data['text'])):
            t = data['text'][idx].strip()
            if not t or int(data['conf'][idx]) < 30:
                continue
            x_abs = data['left'][idx] + table_x1
            y_abs = data['top'][idx] + crop_y1
            # Only process words within the row's y-range and dose x-range
            if not (row_y1 - 20 <= y_abs <= row_y2 + 20):
                continue
            if not (dose_x1 - 10 <= x_abs < dose_x2 + 10):
                continue
            for j in range(n_dose_cols):
                if boundaries[j] <= x_abs < boundaries[j + 1]:
                    col_name = actual_dose_cols[j]
                    if re.search(r'^[1lI]$', t):
                        result[col_name] = '1'
                    break

        return result
