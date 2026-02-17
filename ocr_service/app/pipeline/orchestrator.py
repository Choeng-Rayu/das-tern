"""Main pipeline orchestrator — coordinates preprocessing, layout, OCR, post-processing, and formatting."""
import re
import time
import logging
from typing import Dict, Any, Tuple, Optional, List
import cv2
import numpy as np
import pytesseract

from app.pipeline.preprocessor import preprocess_image
from app.pipeline.layout import analyze_layout, LayoutResult
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


class PipelineOrchestrator:
    """Orchestrates the full OCR extraction pipeline."""

    def __init__(self):
        self.ocr_engine = OCREngine()
        self.post_processor = PostProcessor()
        logger.info("Pipeline orchestrator initialized")

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
            if layout.header_region:
                header_result = self.ocr_engine.ocr_region(
                    color_img, layout.header_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                header_text = header_result.text

            # OCR patient info
            patient_text = ""
            if layout.patient_region:
                patient_result = self.ocr_engine.ocr_region(
                    color_img, layout.patient_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                patient_text = patient_result.text

            # OCR clinical info
            clinical_text = ""
            if layout.clinical_region:
                clinical_result = self.ocr_engine.ocr_region(
                    color_img, layout.clinical_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                clinical_text = clinical_result.text

            # OCR medication table using hybrid approach
            medications = []
            if layout.table:
                logger.info("  Processing medication table (hybrid approach)")
                medications = self._process_table_hybrid(color_img, gray_img, layout.table.bbox)

            # OCR footer/signature/date
            footer_text = ""
            if layout.footer_region:
                footer_result = self.ocr_engine.ocr_region(
                    color_img, layout.footer_region, content_type="mixed", lang=settings.TESSERACT_LANG
                )
                footer_text = footer_result.text

            date_text = ""
            if layout.date_region:
                date_result = self.ocr_engine.ocr_region(
                    color_img, layout.date_region, content_type="mixed", lang=settings.TESSERACT_LANG_ENG
                )
                date_text = date_result.text

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
                image_metadata=image_metadata
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
                               table_bbox: Tuple[int, int, int, int]) -> list:
        """Process medication table using hybrid approach:
        1. Upscale and OCR the text columns strip for word positions
        2. Group words into medication rows
        3. Analyze each dose column as a full strip using contour detection
        4. Map dose ink blobs to medication rows by y-proximity
        """
        tx1, ty1, tx2, ty2 = table_bbox
        tw = tx2 - tx1
        th = ty2 - ty1

        # Calculate column boundaries in image coordinates
        col_x = [tx1 + int(tw * b) for b in COL_BOUNDARIES]

        # Step A: OCR the text columns strip (item_number through instructions)
        strip_x1 = col_x[0]
        strip_x2 = col_x[4]  # Up to end of instructions
        strip_crop = color_img[ty1:ty2, strip_x1:strip_x2]

        config = '--oem 1 --psm 4'
        data = pytesseract.image_to_data(strip_crop, lang='eng', config=config,
                                          output_type=pytesseract.Output.DICT)

        # Collect detected words with positions
        words = []
        for i, text in enumerate(data['text']):
            if text.strip() and int(data['conf'][i]) > 15:
                words.append({
                    'text': text.strip(),
                    'x': data['left'][i] + strip_x1,
                    'y': data['top'][i] + ty1,
                    'w': data['width'][i],
                    'h': data['height'][i],
                    'conf': int(data['conf'][i]),
                })

        # Group words into rows by y-position
        rows = self._cluster_words_by_y(words, threshold=25)

        # Identify medication rows (rows that have text in the medication_name column)
        med_rows = []
        for row_words in rows:
            row_data = self._map_words_to_columns(row_words, col_x)
            med_name = row_data.get("medication_name", "").strip()
            if not med_name or len(med_name) < 3:
                continue
            # Compute row center y-position
            avg_y = sum(w['y'] + w['h'] // 2 for w in row_words) / len(row_words)
            med_rows.append((row_data, avg_y, row_words))

        if not med_rows:
            return []

        # Step B: Re-OCR duration column per row with Khmer+English for accuracy
        # Use row-center spacing for cell bounds instead of word positions
        dur_x1 = col_x[2]
        dur_x2 = col_x[3]
        row_centers = [avg_y for _, avg_y, _ in med_rows]
        # Estimate half-row height from row spacing
        if len(row_centers) >= 2:
            avg_spacing = (row_centers[-1] - row_centers[0]) / (len(row_centers) - 1)
            half_row = int(avg_spacing / 2)
        else:
            half_row = th // 4
        for i, (row_data, avg_y, row_words) in enumerate(med_rows):
            # Compute row boundaries from row centers
            if i == 0:
                min_y = max(ty1, int(avg_y) - half_row)
            else:
                min_y = int((row_centers[i - 1] + row_centers[i]) / 2)
            if i == len(med_rows) - 1:
                max_y = min(ty2, int(avg_y) + half_row)
            else:
                max_y = int((row_centers[i] + row_centers[i + 1]) / 2)
            dur_cell = color_img[min_y:max_y, dur_x1:dur_x2]
            if dur_cell.size > 0:
                try:
                    dur_text = pytesseract.image_to_string(
                        dur_cell, lang=settings.TESSERACT_LANG, config='--oem 1 --psm 7'
                    ).strip()
                    if dur_text:
                        row_data['duration'] = dur_text
                except Exception:
                    pass

        # Step C: Analyze each dose column using contour-based detection
        row_centers = [avg_y for _, avg_y, _ in med_rows]

        dose_results = {}
        for col_name in DOSE_COLS:
            col_idx = COL_NAMES.index(col_name)
            cell_x1 = col_x[col_idx]
            cell_x2 = col_x[col_idx + 1]
            dose_results[col_name] = self._analyze_dose_column(
                gray_img, cell_x1, cell_x2, ty1, ty2, row_centers
            )

        # Step C: Build medications list
        medications = []
        for i, (row_data, avg_y, row_words) in enumerate(med_rows):
            for col_name in DOSE_COLS:
                row_data[col_name] = dose_results[col_name].get(i, "-")

            medication = self.post_processor.process_medication_row(row_data, i + 1)
            medications.append(medication)

        return medications

    def _cluster_words_by_y(self, words: list, threshold: int = 25) -> List[list]:
        """Group words into rows based on y-position proximity."""
        if not words:
            return []

        sorted_words = sorted(words, key=lambda w: w['y'])
        groups = []
        current_group = [sorted_words[0]]

        for w in sorted_words[1:]:
            avg_y = sum(x['y'] for x in current_group) / len(current_group)
            if abs(w['y'] - avg_y) <= threshold:
                current_group.append(w)
            else:
                groups.append(current_group)
                current_group = [w]

        if current_group:
            groups.append(current_group)

        return groups

    def _map_words_to_columns(self, words: list, col_x: list) -> Dict[str, str]:
        """Map words to text columns based on x-position."""
        result = {}
        col_words = {name: [] for name in COL_NAMES[:4]}

        for w in sorted(words, key=lambda x: x['x']):
            word_center_x = w['x'] + w['w'] // 2
            for i, name in enumerate(COL_NAMES[:4]):
                if col_x[i] <= word_center_x < col_x[i + 1]:
                    col_words[name].append(w['text'])
                    break

        for name, texts in col_words.items():
            result[name] = ' '.join(texts)

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

        # Apply fixed threshold to detect dark ink marks
        _, binary = cv2.threshold(inner, 160, 255, cv2.THRESH_BINARY_INV)

        # Remove horizontal grid lines using morphological opening
        h_kernel_len = max(inner_w * 2 // 3, 5)
        kernel_h = cv2.getStructuringElement(cv2.MORPH_RECT, (h_kernel_len, 1))
        h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel_h)
        binary = cv2.subtract(binary, h_lines)

        # Find contours (remaining ink blobs = actual character marks)
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Collect significant blobs
        min_area = 12
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
                # Count rows that also have centered (non-left) blobs
                center_rows = set()
                for b in blobs:
                    if b['x'] >= left_threshold:
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
        match_threshold = 30

        for i, row_y in enumerate(row_centers):
            nearby = [b for b in blobs if abs(b['y'] - row_y) <= match_threshold]
            if nearby:
                total_area = sum(b['area'] for b in nearby)
                if total_area >= 15:
                    result[i] = "1"
                else:
                    result[i] = "-"
            else:
                result[i] = "-"

        return result
