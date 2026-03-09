"""Pipeline orchestrator — ties preprocessing, layout, OCR, and parsing together.

Flow:
    1. Preprocess image (denoise, CLAHE, sharpen, deskew, resize)
    2. Analyze layout (detect regions, table lines)
    3. Run full-image Kiri-OCR
    4. Assign OCR lines to layout regions by bbox overlap
    5. Cluster table-region lines into rows
    6. Attempt structured table medication parsing
    7. Fall back to line-wise heuristic parsing if table extraction fails
    8. Parse header/footer metadata from region-assigned lines
    9. Format output
"""
import logging
import time
from typing import Any, Dict, List, Optional, Tuple

from app.pipeline.layout import BBox, LayoutResult, TableRowReconstructor, analyze_layout
from app.pipeline.ocr_engine import KiriOCREngine, LineResult
from app.pipeline.preprocessor import PreprocessResult, preprocess
from app.pipeline.text_parser import (
    ParsedPrescription,
    parse_prescription,
    parse_table_medications,
    _fill_default_time_slots,
)

logger = logging.getLogger(__name__)


class PipelineOrchestrator:
    """Full OCR extraction pipeline using Kiri-OCR."""

    def __init__(self, engine: KiriOCREngine, max_dimension: int = 3000):
        self.engine = engine
        self.max_dimension = max_dimension

    def extract(self, image_bytes: bytes, filename: str = "") -> Dict[str, Any]:
        """Run the full extraction pipeline.

        Returns a dict with: success, data (parsed prescription + metadata),
        processing_time_ms, and pipeline_metadata.
        """
        start = time.time()

        try:
            # Layer 1: Preprocess
            prep = preprocess(image_bytes, max_dimension=self.max_dimension)
            logger.info("Preprocessing complete: %s", prep.quality.preprocessing_applied)

            # Layer 2: Layout analysis
            layout = analyze_layout(prep.gray)

            # Layer 3: OCR on preprocessed image
            full_text, line_results = self.engine.extract_from_numpy(prep.color)
            logger.info("OCR complete: %d lines extracted", len(line_results))

            # Layer 4: Region assignment + table extraction
            section_lines = self._assign_to_regions(line_results, layout)
            table_lines = section_lines.get("table", [])

            # Layer 5: Table-aware medication parsing
            table_meds = self._extract_table_medications(table_lines, layout)

            # Layer 6: Full prescription parsing (metadata + medications)
            parsed = parse_prescription(full_text, line_results)

            # Prefer table-extracted medications when a table region was detected
            # Table extraction is more reliable since it uses structural layout
            # (row clustering + content-based cell classification)
            if table_meds:
                parsed.medications = table_meds
                logger.info("Using table-extracted medications: %d items", len(table_meds))

            processing_time_ms = (time.time() - start) * 1000

            return {
                "success": True,
                "parsed": parsed,
                "full_text": full_text,
                "line_results": line_results,
                "processing_time_ms": processing_time_ms,
                "pipeline_metadata": {
                    "preprocessing_applied": prep.quality.preprocessing_applied,
                    "quality_report": {
                        "is_blurry": prep.quality.is_blurry,
                        "blur_score": prep.quality.blur_score,
                        "is_dark": prep.quality.is_dark,
                        "is_bright": prep.quality.is_bright,
                        "mean_brightness": prep.quality.mean_brightness,
                        "skew_angle": prep.quality.skew_angle,
                    },
                    "layout": {
                        "has_table_lines": layout.has_table_lines,
                        "image_size": layout.image_size,
                    },
                    "section_line_counts": {k: len(v) for k, v in section_lines.items()},
                    "table_meds_used": table_meds is not None and len(table_meds) > 0,
                },
            }
        except Exception as exc:
            processing_time_ms = (time.time() - start) * 1000
            logger.exception("Pipeline extraction failed")
            return {
                "success": False,
                "message": str(exc),
                "processing_time_ms": processing_time_ms,
            }

    def _assign_to_regions(
        self, lines: List[LineResult], layout: LayoutResult
    ) -> Dict[str, List[LineResult]]:
        """Assign OCR lines to layout regions based on bbox vertical overlap."""
        sections: Dict[str, List[LineResult]] = {
            "header": [], "patient": [], "clinical": [],
            "table": [], "footer": [], "unassigned": [],
        }

        region_map = [
            ("header", layout.header_region),
            ("patient", layout.patient_region),
            ("clinical", layout.clinical_region),
            ("table", layout.table_region),
            ("footer", layout.footer_region),
        ]

        for line in lines:
            if not line.bbox or len(line.bbox) < 4:
                sections["unassigned"].append(line)
                continue

            line_cy = line.bbox[1] + line.bbox[3] / 2.0
            assigned = False
            for region_name, region_bbox in region_map:
                if region_bbox is None:
                    continue
                _, ry1, _, ry2 = region_bbox
                if ry1 <= line_cy <= ry2:
                    sections[region_name].append(line)
                    assigned = True
                    break
            if not assigned:
                sections["unassigned"].append(line)

        return sections

    # Footer patterns — lines that are NOT medication data
    _FOOTER_PATS = [
        r'រាជធានី',         # "Phnom Penh" (city name in dates)
        r'គ្រពេទ្យព្យាបាល',  # "treating doctor"
        r'វេជ្ជបណ្ឌិត',      # "doctor"
        r'សូមយក',           # "please bring"
        r'ថ្ងៃទី.*\d{4}',    # date pattern
        r'\d{1,2}:\d{2}',   # time pattern (14:20)
    ]

    def _is_footer_row(self, row_texts: List[str]) -> bool:
        """Check if a row is footer content (dates, doctor name, etc.)."""
        import re
        joined = " ".join(row_texts)
        return any(re.search(pat, joined) for pat in self._FOOTER_PATS)

    def _extract_table_medications(
        self, table_lines: List[LineResult], layout: LayoutResult
    ) -> Optional[list]:
        """Try to extract medications by clustering table lines into rows.

        Returns a list of ParsedMedication or None if table extraction fails.
        """
        if not table_lines or len(table_lines) < 2:
            return None

        # Convert LineResults to BBox for row clustering
        boxes = []
        for lr in table_lines:
            if not lr.bbox or len(lr.bbox) < 4:
                continue
            boxes.append(BBox(
                x=lr.bbox[0], y=lr.bbox[1], w=lr.bbox[2], h=lr.bbox[3],
                text=lr.text, confidence=lr.confidence,
            ))

        if len(boxes) < 2:
            return None

        reconstructor = TableRowReconstructor()
        rows = reconstructor.cluster_into_rows(boxes)

        if len(rows) < 2:
            return None

        # --- Classify rows: header, data, footer ---
        header_keywords = (
            "ឈ្មោះ", "ព្រឹក", "ថ្ងៃ", "ល.រ", "ល្ងាច", "យប់",
            "name", "morning", "qty", "duration", "ចំនួន",
            "វិធីប្រើ", "ឱសថ",
        )

        header_labels: List[str] = []
        data_start_idx = 0

        # Scan rows top-to-bottom to find header rows and data start
        for ri, row in enumerate(rows):
            texts = [b.text for b in row]
            joined = " ".join(texts).lower()

            # Single-cell rows at the top are section labels, skip them
            if len(row) <= 1:
                data_start_idx = ri + 1
                continue

            # Check if this row is a header (contains known column labels)
            if any(kw in joined for kw in header_keywords):
                # Merge header labels across multi-row headers
                header_labels.extend(texts)
                data_start_idx = ri + 1
                continue

            # Once we hit a row that's not header/label, stop scanning
            break

        # Extract data rows, filtering out footer rows
        data_rows = []
        for row in rows[data_start_idx:]:
            texts = [b.text for b in row]
            # Skip single-cell rows (likely misaligned fragments)
            if len(texts) < 2:
                continue
            # Skip footer rows
            if self._is_footer_row(texts):
                continue
            data_rows.append(texts)

        if not data_rows:
            return None

        meds = parse_table_medications(
            data_rows,
            header_labels=header_labels if header_labels else None,
        )

        if meds:
            logger.info(
                "Table extraction: %d data rows → %d medications (headers=%d labels)",
                len(data_rows), len(meds), len(header_labels),
            )
        return meds if meds else None

