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

# Semantic column role names (dynamic — actual count may differ per prescription)
DEFAULT_COL_NAMES = ["item_number", "medication_name", "duration", "instructions",
                     "morning", "midday", "afternoon", "evening"]
DOSE_PERIOD_NAMES = ["morning", "midday", "afternoon", "evening"]
DOSE_COLS = set(DOSE_PERIOD_NAMES)

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

            # Keep raw decoded image for OCR fallback (some cells OCR better un-preprocessed)
            raw_img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)

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
                medications, table_words = self._process_table_hybrid(color_img, gray_img, layout.table.bbox, raw_img=raw_img)

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
                               table_bbox: Tuple[int, int, int, int],
                               raw_img: Optional[np.ndarray] = None) -> Tuple[list, list]:
        """Process medication table using a multi-strategy hybrid approach.
        Returns (medications, table_words).

        Strategy 1: Dynamic column detection from actual vertical grid lines
        Strategy 2: Text-gap column detection from OCR word x-positions
        Strategy 3: Full-text OCR fallback — parse medication names from raw text lines

        raw_img: optional un-preprocessed image for OCR fallback on cells where
                 preprocessing degrades text quality.
        """
        tx1, ty1, tx2, ty2 = table_bbox
        tw = tx2 - tx1
        th = ty2 - ty1

        # --- Strategy 1: Try dynamic vertical-line-based column detection ---
        logger.info("  Trying dynamic column detection from vertical lines")
        dynamic_col_x = self._detect_dynamic_columns(gray_img, table_bbox)
        if dynamic_col_x and len(dynamic_col_x) >= 5:
            logger.info(f"  Dynamic columns found: {len(dynamic_col_x)} boundaries")
            medications, table_words = self._extract_structured(color_img, gray_img, table_bbox, dynamic_col_x, raw_img=raw_img)
            if medications:
                logger.info(f"  Strategy 1 (dynamic columns) → {len(medications)} medications")
                return medications, table_words
            logger.info("  Strategy 1 yielded 0 medications, trying Strategy 2")

        # --- Strategy 2: Text-gap column detection from OCR word positions ---
        logger.info("  Trying text-gap column detection from OCR word positions")
        gap_col_x = self._detect_columns_from_text_gaps(color_img, table_bbox)
        if gap_col_x and len(gap_col_x) >= 5:
            logger.info(f"  Text-gap columns found: {len(gap_col_x)} boundaries")
            medications, table_words = self._extract_structured(color_img, gray_img, table_bbox, gap_col_x, raw_img=raw_img)
            if medications:
                logger.info(f"  Strategy 2 (text-gap columns) → {len(medications)} medications")
                return medications, table_words
            logger.info("  Strategy 2 yielded 0 medications, trying Strategy 3")
        else:
            logger.info(f"  Text-gap detection found {len(gap_col_x) if gap_col_x else 0} boundaries, trying Strategy 3")

        # --- Strategy 3: General text OCR fallback ---
        medications, table_words = self._extract_text_fallback(color_img, gray_img, table_bbox)
        logger.info(f"  Strategy 3 (text fallback) → {len(medications)} medications")
        return medications, table_words

    def _detect_dynamic_columns(self, gray_img: np.ndarray,
                                 table_bbox: Tuple[int, int, int, int]) -> Optional[List[int]]:
        """Detect actual column x-boundaries by finding vertical grid lines within the table.

        Uses the layout module's detect_lines() for consistent line detection,
        then converts to absolute image coordinates.
        """
        from app.pipeline.layout import detect_lines as layout_detect_lines

        tx1, ty1, tx2, ty2 = table_bbox
        tw = tx2 - tx1
        th = ty2 - ty1

        if tw < 50 or th < 30:
            return None

        table_crop = gray_img[ty1:ty2, tx1:tx2].copy()

        # Use the proven detect_lines function
        v_lines = layout_detect_lines(table_crop, "vertical")
        if len(v_lines) < 2:
            return None

        # Extract x-center of each vertical line
        x_centers = []
        for x1, y1, x2, y2 in v_lines:
            cx = (x1 + x2) // 2
            x_centers.append(cx)

        x_centers = sorted(set(x_centers))

        # Merge close x-values
        min_gap = max(int(tw * 0.02), 3)
        merged = [x_centers[0]]
        for cx in x_centers[1:]:
            if cx - merged[-1] > min_gap:
                merged.append(cx)

        # Build boundary list with endpoints
        boundaries = [0]
        for cx in merged:
            if cx > min_gap and cx < tw - min_gap:
                boundaries.append(cx)
        boundaries.append(tw)
        boundaries = sorted(set(boundaries))

        # Need at least 5 boundaries (4 columns) for structured extraction
        if len(boundaries) < 5:
            return None

        # Convert to image coordinates
        return [tx1 + x for x in boundaries]

    def _detect_columns_from_text_gaps(self, color_img: np.ndarray,
                                        table_bbox: Tuple[int, int, int, int]) -> Optional[List[int]]:
        """Detect column boundaries by finding x-gaps between OCR words.

        This is a format-agnostic method: it runs OCR on the table region, collects
        all word bounding boxes, and identifies vertical gaps where no text appears.
        Those gaps correspond to column separators.
        """
        tx1, ty1, tx2, ty2 = table_bbox
        tw = tx2 - tx1
        th = ty2 - ty1

        if tw < 50 or th < 30:
            return None

        table_crop = color_img[ty1:ty2, tx1:tx2]
        if table_crop.size == 0:
            return None

        # Run OCR to get word positions
        try:
            data = pytesseract.image_to_data(
                table_crop, lang=settings.TESSERACT_LANG,
                config='--oem 1 --psm 4',
                output_type=pytesseract.Output.DICT
            )
        except Exception as e:
            logger.warning(f"Text-gap column detection OCR failed: {e}")
            return None

        # Collect word x-ranges with sufficient confidence
        word_ranges = []  # list of (x_start, x_end)
        for i, text in enumerate(data['text']):
            word = text.strip()
            conf = int(data['conf'][i])
            if not word or conf <= MIN_WORD_CONF:
                continue
            if not re.search(r'[A-Za-z0-9\u1780-\u17FF]', word):
                continue
            wx = data['left'][i]
            ww = data['width'][i]
            if ww > 0:
                word_ranges.append((wx, wx + ww))

        if len(word_ranges) < 3:
            return None

        # Build x-occupancy histogram (which x-positions have text)
        occupancy = np.zeros(tw, dtype=np.int32)
        for x_start, x_end in word_ranges:
            x_s = max(0, x_start)
            x_e = min(tw, x_end)
            occupancy[x_s:x_e] += 1

        # Find gaps (runs of zero occupancy wider than 1% of table width)
        min_gap_width = max(int(tw * 0.01), 3)
        gaps = []  # list of (gap_center, gap_width)
        in_gap = False
        gap_start = 0
        for x in range(tw):
            if occupancy[x] == 0 and not in_gap:
                in_gap = True
                gap_start = x
            elif occupancy[x] > 0 and in_gap:
                in_gap = False
                gap_width = x - gap_start
                if gap_width >= min_gap_width:
                    gaps.append(((gap_start + x) // 2, gap_width))
        if in_gap:
            gap_width = tw - gap_start
            if gap_width >= min_gap_width:
                gaps.append(((gap_start + tw) // 2, gap_width))

        if len(gaps) < 2:
            return None

        # Sort gaps by width (wider gaps are more likely column separators)
        # Keep the most prominent gaps
        gaps.sort(key=lambda g: g[1], reverse=True)

        # Take top gaps — up to 10 separators for complex tables
        max_separators = min(len(gaps), 10)
        selected_gaps = sorted([g[0] for g in gaps[:max_separators]])

        # Build boundary list
        boundaries = [0] + selected_gaps + [tw]
        boundaries = sorted(set(boundaries))

        # Merge close boundaries
        merged = [boundaries[0]]
        for b in boundaries[1:]:
            if b - merged[-1] > tw * 0.02:
                merged.append(b)
        merged[-1] = tw

        if len(merged) < 3:
            return None

        # Convert to image coordinates
        return [tx1 + x for x in merged]

    def _extract_structured(self, color_img: np.ndarray, gray_img: np.ndarray,
                             table_bbox: Tuple[int, int, int, int],
                             col_x: List[int],
                             raw_img: Optional[np.ndarray] = None) -> Tuple[list, list]:
        """Extract medications using explicit column x-boundaries.
        Returns (medications, all_words).

        col_x must have at least 5 entries ([item_num, ..., med_name_end, ..., dose_cols, end]).
        When the prescription has a different column count than H-EQIP, we auto-assign
        col roles: leftmost narrow = item#, wide middle = medication_name, far-right = doses.

        raw_img: optional un-preprocessed image for OCR fallback on duration cells.
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

        # Collect words with sufficient confidence, filtering OCR grid-line noise
        words = []
        for i, text in enumerate(data['text']):
            word = text.strip()
            conf = int(data['conf'][i])
            if not word or conf <= MIN_WORD_CONF:
                continue
            # Skip pure punctuation / symbols leaked from table grid lines
            if not re.search(r'[A-Za-z0-9\u1780-\u17FF]', word):
                continue
            # Strip leading/trailing pipe, bracket, equals characters
            word = re.sub(r'^[\|\[\]=]+|[\|\[\]=]+$', '', word).strip()
            if not word:
                continue
            wx = data['left'][i] + strip_x1
            wy = data['top'][i] + ty1
            ww = data['width'][i]
            wh = data['height'][i]
            words.append({
                'text': word,
                'x': wx,
                'y': wy,
                'w': ww,
                'h': wh,
                'conf': conf,
                'bbox': [wx, wy, wx + ww, wy + wh],
                'confidence': conf / 100.0,
            })

        if not words:
            return [], []

        # Filter out OCR noise: pure punctuation/symbols leaked from grid lines
        words = [w for w in words if re.search(r'[A-Za-z0-9\u1780-\u17FF]', w['text'])]
        if not words:
            return [], []

        # Group words into rows by Y-center alignment (configurable tolerance)
        rows = self.row_reconstructor.cluster_word_dicts(words)

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
            med_rows.append((row_data, avg_y, row_words))

        if not med_rows:
            return [], words

        # --- Residual row recovery ---
        # When PSM 4 on the full text strip misses medication rows (especially
        # near the bottom of the table), re-scan the uncovered tail region with
        # a tighter crop so Tesseract can resolve the text.
        last_med_bottom = max(avg_y for _, avg_y, _ in med_rows) + 20
        residual_height = ty2 - last_med_bottom
        if residual_height > th * 0.10:  # >10% of table height remains
            logger.info(f"  Residual scan: {residual_height}px below last med (table h={th})")
            residual_crop = color_img[int(last_med_bottom):ty2, strip_x1:strip_x2]
            if residual_crop.size > 0:
                try:
                    rdata = pytesseract.image_to_data(
                        residual_crop, lang=settings.TESSERACT_LANG,
                        config='--oem 1 --psm 6',  # PSM 6 = uniform block, better for small regions
                        output_type=pytesseract.Output.DICT
                    )
                    rwords = []
                    for ri, rtext in enumerate(rdata['text']):
                        rw = rtext.strip()
                        rconf = int(rdata['conf'][ri])
                        if not rw or rconf <= MIN_WORD_CONF:
                            continue
                        if not re.search(r'[A-Za-z0-9\u1780-\u17FF]', rw):
                            continue
                        rw = re.sub(r'^[\|\[\]=]+|[\|\[\]=]+$', '', rw).strip()
                        if not rw:
                            continue
                        rwx = rdata['left'][ri] + strip_x1
                        rwy = rdata['top'][ri] + int(last_med_bottom)
                        rww = rdata['width'][ri]
                        rwh = rdata['height'][ri]
                        rwords.append({
                            'text': rw, 'x': rwx, 'y': rwy, 'w': rww, 'h': rwh,
                            'conf': rconf, 'bbox': [rwx, rwy, rwx + rww, rwy + rwh],
                            'confidence': rconf / 100.0,
                        })
                    if rwords:
                        rrows = self.row_reconstructor.cluster_word_dicts(rwords)
                        for rrow_words in rrows:
                            rrow_data = self._map_words_to_columns_flexible(rrow_words, col_x, name_col_idx, n_cols)
                            rmed = rrow_data.get("medication_name", "").strip()
                            if len(rmed) < MIN_MED_NAME_LEN:
                                candidate = [w for w in sorted(rrow_words, key=lambda x: x['x'])
                                             if re.search(r'[A-Za-z\u1780-\u17FF]', w['text'])]
                                rmed = ' '.join(w['text'] for w in candidate).strip()
                                if len(rmed) >= MIN_MED_NAME_LEN:
                                    rrow_data['medication_name'] = rmed
                                    if candidate:
                                        rrow_data['medication_name_bbox'] = self._aggregate_bbox(candidate)
                                        rrow_data['medication_name_words'] = [
                                            {'text': w['text'], 'bbox': w.get('bbox'), 'confidence': w.get('confidence', w['conf'] / 100.0)}
                                            for w in candidate
                                        ]
                            if len(rmed) < MIN_MED_NAME_LEN or self._is_header_or_label_text(rmed):
                                continue
                            ravg_y = sum(w['y'] + w['h'] // 2 for w in rrow_words) / len(rrow_words)
                            med_rows.append((rrow_data, ravg_y, rrow_words))
                            words.extend(rwords)
                            logger.info(f"  Residual recovery: found '{rmed}' at y={ravg_y:.0f}")
                except Exception as e:
                    logger.warning(f"Residual OCR scan failed: {e}")

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

            # Try duration OCR on preprocessed image first, fallback to raw image
            dur_text = ""
            for img_source in [color_img, raw_img]:
                if img_source is None:
                    continue
                dur_cell = img_source[min_y:max_y, dur_x1:dur_x2]
                if dur_cell.size == 0:
                    continue
                for psm in ['--oem 1 --psm 7', '--oem 1 --psm 6']:
                    try:
                        dur_text = pytesseract.image_to_string(
                            dur_cell, lang=settings.TESSERACT_LANG, config=psm
                        ).strip()
                        if dur_text and re.search(r'\d', dur_text):
                            break
                    except Exception:
                        continue
                if dur_text and re.search(r'\d', dur_text):
                    break
            if dur_text:
                row_data['duration'] = dur_text
                row_data['duration_bbox'] = [dur_x1, min_y, dur_x2, max_y]

        # Analyze dose columns — dynamically determine how many dose columns exist
        # Heuristic: rightmost narrow columns after name+duration+instructions are dose cols
        # The number of dose columns depends on the actual table structure
        dose_col_start = max(n_cols - 4, name_col_idx + 2)
        available_dose_cols = n_cols - dose_col_start
        n_dose_cols = min(available_dose_cols, len(DOSE_PERIOD_NAMES))

        # Map detected dose columns to period names
        actual_dose_cols = DOSE_PERIOD_NAMES[:n_dose_cols]
        logger.info(f"  Detected {n_dose_cols} dose columns (start={dose_col_start}, total={n_cols})")

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

        # Fill any missing periods with defaults
        for period in DOSE_PERIOD_NAMES:
            if period not in dose_results:
                dose_results[period] = {k: "-" for k in range(len(med_rows))}

        medications = []
        for i, (row_data, avg_y, row_words) in enumerate(med_rows):
            min_y_row = max(ty1, int(avg_y) - half_row) if i == 0 else int((row_centers[i - 1] + row_centers[i]) / 2)
            max_y_row = min(ty2, int(avg_y) + half_row) if i == len(med_rows) - 1 else int((row_centers[i] + row_centers[i + 1]) / 2)
            for j, col_name in enumerate(DOSE_PERIOD_NAMES):
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
                word = text.strip()
                conf = int(data['conf'][i])
                if not word or conf <= MIN_WORD_CONF:
                    continue
                # Skip pure punctuation / symbols leaked from table grid lines
                if not re.search(r'[A-Za-z0-9\u1780-\u17FF]', word):
                    continue
                # Strip leading/trailing pipe, bracket, equals characters
                word = re.sub(r'^[\|\[\]=]+|[\|\[\]=]+$', '', word).strip()
                if not word:
                    continue
                wx = data['left'][i] + cx1
                wy = data['top'][i] + cy1
                ww = data['width'][i]
                wh = data['height'][i]
                words.append({
                    'text': word,
                    'x': wx,
                    'y': wy,
                    'w': ww,
                    'h': wh,
                    'conf': conf,
                    'bbox': [wx, wy, wx + ww, wy + wh],
                    'confidence': conf / 100.0,
                })

            if not words:
                continue

            all_words = words

            # Filter out OCR noise: pure punctuation/symbols from grid lines
            words = [w for w in words if re.search(r'[A-Za-z0-9\u1780-\u17FF]', w['text'])]
            if not words:
                continue

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

        # Reject purely numeric text (e.g. "1030", "28") — not a medication name
        if re.match(r'^[\d\s\.\,\-\+]+$', stripped):
            return True

        # Reject standalone strength values (e.g. "500mg", "10mg", "100 mg")
        if re.match(r'^\d+\s*(mg|mcg|ml|g|iu|µg|tab|cap)\s*$', stripped, re.IGNORECASE):
            return True

        # Reject very short text with mostly digits (e.g. "5x", "3/")
        letters = re.findall(r'[A-Za-z\u1780-\u17FF]', stripped)
        if len(letters) < 2 and len(stripped) <= 5:
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
        col_words: Dict[str, list] = {name: [] for name in DEFAULT_COL_NAMES[:4]}

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

    def _analyze_dose_column(self, gray_img: np.ndarray, col_x1: int, col_x2: int,
                              ty1: int, ty2: int, row_centers: List[float]) -> Dict[int, str]:
        """Analyze a full dose column strip using hybrid OCR + contour detection.

        For each medication row, crops the individual dose cell and tries:
        1. OCR the cell — if readable digit/fraction, use it
        2. Fall back to blob detection with strict filtering

        Returns mapping of row_index -> dose_value ("1", "½", "-", etc.)
        """
        img_h, img_w = gray_img.shape
        x1 = max(0, col_x1)
        x2 = min(img_w, col_x2)

        cw = x2 - x1
        if cw < 8:
            return {i: "-" for i in range(len(row_centers))}

        # Calculate row intervals for per-row cell cropping
        if len(row_centers) >= 2:
            avg_spacing = (row_centers[-1] - row_centers[0]) / (len(row_centers) - 1)
            half_row = int(avg_spacing / 2)
        else:
            half_row = (ty2 - ty1) // 4

        result = {}

        for i, row_y in enumerate(row_centers):
            # Compute per-row y-bounds
            if i == 0:
                cell_y1 = max(ty1, int(row_y) - half_row)
            else:
                cell_y1 = int((row_centers[i - 1] + row_centers[i]) / 2)

            if i == len(row_centers) - 1:
                cell_y2 = min(ty2, int(row_y) + half_row)
            else:
                cell_y2 = int((row_centers[i] + row_centers[i + 1]) / 2)

            cell_y1 = max(0, cell_y1)
            cell_y2 = min(img_h, cell_y2)
            if cell_y2 <= cell_y1:
                result[i] = "-"
                continue

            cell = gray_img[cell_y1:cell_y2, x1:x2]
            if cell.size == 0:
                result[i] = "-"
                continue

            ch, cw_actual = cell.shape

            # Trim column edges (15% each side) to avoid grid lines while keeping content
            trim = max(int(cw_actual * 0.15), 2)
            inner = cell[:, trim:cw_actual - trim]
            if inner.size == 0 or inner.shape[1] < 3:
                result[i] = "-"
                continue

            # Approach 1: Try OCR — only trust it for special values (fractions, multi-digit)
            dose_val = self._ocr_dose_cell(inner)

            # Approach 2: Blob detection — always run as the primary for simple dose marks
            blob_val = self._blob_detect_dose_cell(inner)

            # Decision logic:
            # - If OCR found a fraction/special value (e.g. "1/2", "½"), prefer OCR
            # - Otherwise, blob detection is primary — if it detects a mark, return "1"
            # - Blob detection is more reliable than OCR for mark-based dose cells
            if dose_val is not None and dose_val != "-" and ('/' in dose_val or '½' in dose_val or '¼' in dose_val or '¾' in dose_val):
                final_val = dose_val
            elif blob_val != "-":
                final_val = "1"
            else:
                final_val = "-"
            result[i] = final_val

        return result

    def _ocr_dose_cell(self, cell_img: np.ndarray) -> Optional[str]:
        """Try to OCR a single dose cell. Returns dose value or None if unreadable."""
        try:
            text = pytesseract.image_to_string(
                cell_img, lang='eng',
                config='--oem 1 --psm 10 -c tessedit_char_whitelist=0123456789/-½¼¾.'
            ).strip()
        except Exception:
            return None

        if not text:
            return None

        # Clean up OCR result
        text = re.sub(r'[^0-9/½¼¾.\-]', '', text)
        if not text:
            return None

        # Check if it looks like a dose value
        if text in ('-', '0', '.'):
            return "-"
        if re.match(r'^[\d½¼¾]+(/[\d]+)?$', text):
            # Validate: per-period dose values are typically 0-3 (e.g. 1, 1/2, 2, 3).
            # Anything >=4 is almost certainly a misread (item number, quantity, etc.)
            try:
                numeric = float(text.split('/')[0]) if '/' in text else float(text)
                if numeric >= 4:
                    return None  # reject; fall back to blob detection
            except ValueError:
                pass
            return text

        return None

    def _blob_detect_dose_cell(self, cell_img: np.ndarray) -> str:
        """Detect dose mark in a single cell using blob/contour analysis.
        Uses Otsu binarization first, then adaptive thresholding as fallback."""
        ch, cw = cell_img.shape

        # Filter: must have reasonable size relative to cell
        min_area = max(MIN_DOSE_BLOB_AREA, ch * cw * 0.004)  # at least 0.4% of cell area
        min_h = max(4, ch // 10)

        for method in ('otsu', 'adaptive'):
            if method == 'otsu':
                _, binary = cv2.threshold(cell_img, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
            else:
                block_size = max(15, (min(ch, cw) // 4) | 1)  # must be odd
                binary = cv2.adaptiveThreshold(
                    cell_img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                    cv2.THRESH_BINARY_INV, block_size, 5
                )

            # Remove horizontal grid lines
            if cw >= 5:
                h_kernel_len = max(cw * 2 // 3, 5)
                kernel_h = cv2.getStructuringElement(cv2.MORPH_RECT, (h_kernel_len, 1))
                h_lines_mask = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel_h)
                binary = cv2.subtract(binary, h_lines_mask)

            # Remove vertical line artifacts
            if ch >= 10:
                v_kernel_len = max(ch // 3, 5)
                kernel_v = cv2.getStructuringElement(cv2.MORPH_RECT, (1, v_kernel_len))
                v_lines_mask = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel_v)
                binary = cv2.subtract(binary, v_lines_mask)

            # Find contours
            contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            significant_blobs = []
            for c in contours:
                area = cv2.contourArea(c)
                if area < min_area:
                    continue
                _, _, bw, bh = cv2.boundingRect(c)
                if bh < min_h:
                    continue
                # Reject blobs that span nearly the full cell width (likely grid line remnant)
                if bw > cw * 0.8:
                    continue
                # Reject blobs that span nearly the full cell height (likely vertical artifact)
                if bh > ch * 0.8:
                    continue
                significant_blobs.append({'area': area, 'w': bw, 'h': bh})

            if significant_blobs:
                total_area = sum(b['area'] for b in significant_blobs)
                if total_area >= min_area:
                    return "1"

        return "-"
