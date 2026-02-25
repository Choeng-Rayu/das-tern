"""Format raw OCR data into Dynamic Universal v2.0 schema."""
import time
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, List, Optional


def get_current_timestamp() -> str:
    """Get current timestamp in ISO format with Cambodia timezone."""
    tz = timezone(timedelta(hours=7))
    return datetime.now(tz).isoformat()


def build_dynamic_universal(
    facility: Dict[str, Any],
    patient: Dict[str, Any],
    clinical: Dict[str, Any],
    medications: List[Dict[str, Any]],
    footer_data: Dict[str, Any],
    quality_report: Any,
    processing_time_ms: float,
    image_metadata: Optional[Dict[str, Any]] = None,
    region_ocr_data: Optional[Dict[str, Any]] = None,
    table_words: Optional[List[Dict]] = None,
) -> Dict[str, Any]:
    """Build the Dynamic Universal v2.0 JSON response.

    This is the canonical output format for the OCR service.
    """
    # Calculate overall confidence
    all_confidences = []
    needs_review_fields = []

    # Medication summary
    total_meds = len(medications)
    max_duration = 0
    has_antibiotics = False
    has_controlled = False

    for med in medications:
        dur = med.get("dosing", {}).get("duration", {}).get("value")
        if dur and isinstance(dur, (int, float)):
            max_duration = max(max_duration, int(dur))

        tc = med.get("clinical_notes", {}).get("therapeutic_class", "") or ""
        if "antibiotic" in tc.lower():
            has_antibiotics = True

    # Preprocessing info
    preprocessing_applied = []
    if quality_report:
        preprocessing_applied = getattr(quality_report, 'preprocessing_applied', [])

    # Build image metadata
    img_meta = image_metadata or {}

    # Determine overall confidence from actual OCR results
    section_confidences = {}
    all_region_confs = []
    if region_ocr_data:
        for section_name in ["header", "patient", "clinical", "footer", "date"]:
            ocr_obj = region_ocr_data.get(section_name)
            if ocr_obj and hasattr(ocr_obj, 'confidence') and ocr_obj.confidence > 0:
                section_confidences[section_name] = round(ocr_obj.confidence, 3)
                all_region_confs.append(ocr_obj.confidence)
    overall_confidence = sum(all_region_confs) / len(all_region_confs) if all_region_confs else 0.85

    # Extract region-level bboxes for structured sections
    header_bbox = None
    patient_bbox = None
    footer_bbox = None
    date_bbox = None
    table_bbox_val = None
    if region_ocr_data:
        header_obj = region_ocr_data.get("header")
        if header_obj and hasattr(header_obj, 'bbox') and header_obj.bbox:
            header_bbox = list(header_obj.bbox)
        patient_obj = region_ocr_data.get("patient")
        if patient_obj and hasattr(patient_obj, 'bbox') and patient_obj.bbox:
            patient_bbox = list(patient_obj.bbox)
        footer_obj = region_ocr_data.get("footer")
        if footer_obj and hasattr(footer_obj, 'bbox') and footer_obj.bbox:
            footer_bbox = list(footer_obj.bbox)
        date_obj = region_ocr_data.get("date")
        if date_obj and hasattr(date_obj, 'bbox') and date_obj.bbox:
            date_bbox = list(date_obj.bbox)
        table_bbox_val = region_ocr_data.get("table_bbox")

    # Build prescriber info from footer
    prescriber = {
        "name": {
            "full_name": footer_data.get("prescriber_name"),
            "khmer_name": None,
            "title": None,
            "bbox": footer_bbox
        },
        "credentials": {
            "license_number": None,
            "specialty": {"english": None, "khmer": None, "french": None},
            "sub_specialty": None
        },
        "signature": {"present": True, "type": "handwritten", "bbox": None},
        "stamp": {"present": False, "bbox": None},
        "contact": {"phone": None, "email": None, "office_location": None}
    }

    # Build prescription details from footer dates
    prescription_details = {
        "dates": {
            "issue_date": {
                "value": footer_data.get("date"),
                "original_format": None,
                "bbox": date_bbox
            },
            "issue_datetime": {
                "value": footer_data.get("datetime"),
                "original_text": None,
                "bbox": date_bbox
            },
            "expiry_date": None,
            "valid_until": None
        },
        "prescription_number": {"value": None, "bbox": None},
        "visit_information": {
            "visit_type": "OPD",
            "department": {"name": None, "khmer": None, "bbox": None},
            "location": {
                "building": None, "floor": None, "room_number": None,
                "bed_number": None, "full_location_khmer": None, "bbox": None
            },
            "visit_date": footer_data.get("date"),
            "visit_time": None
        }
    }

    # Construct prescription ID
    patient_id = patient.get("identification", {}).get("patient_id", {}).get("value", "")
    date_part = (footer_data.get("date") or "").replace("-", "")
    prescription_id = f"{patient_id}-{date_part}" if patient_id and date_part else None

    # Full output
    result = {
        "$schema": "cambodia-prescription-universal-v2.0",
        "prescription": {
            "metadata": {
                "extraction_info": {
                    "extracted_at": get_current_timestamp(),
                    "ocr_engine": "tesseract_5.0_khmer",
                    "confidence_score": overall_confidence,
                    "preprocessing_applied": preprocessing_applied,
                    "image_metadata": {
                        "width": img_meta.get("width", 0),
                        "height": img_meta.get("height", 0),
                        "format": img_meta.get("format", "unknown"),
                        "dpi": img_meta.get("dpi", 200),
                        "file_size_bytes": img_meta.get("file_size_bytes", 0)
                    }
                },
                "prescription_id": prescription_id,
                "version": "2.0",
                "languages_detected": {
                    "primary": "khmer",
                    "secondary": ["english"],
                    "mixed_content": True
                },
                "prescription_type": "outpatient",
                "validation_status": "validated"
            },
            "healthcare_facility": facility,
            "patient": patient,
            "prescription_details": prescription_details,
            "clinical_information": clinical,
            "medications": {
                "table_structure": {
                    "detected": True,
                    "bbox": table_bbox_val,
                    "column_headers": {
                        "item_number": {"label": "ល.រ", "bbox": None},
                        "medication_name": {"label": "ឈ្មោះត្នាំ", "bbox": None},
                        "duration": {"label": "ថ្ងៃផុត", "bbox": None},
                        "instructions": {"label": "វិធីប្រើ", "bbox": None},
                        "time_slots": [
                            {"period": "morning", "label": "ព្រឹក (6-8)", "time_range": "06:00-08:00", "bbox": None},
                            {"period": "midday", "label": "ថ្ងៃត្រង់ (11-12)", "time_range": "11:00-12:00", "bbox": None},
                            {"period": "afternoon", "label": "ល្ងាច (05-06)", "time_range": "17:00-18:00", "bbox": None},
                            {"period": "evening", "label": "យប់ (08-10)", "time_range": "20:00-22:00", "bbox": None}
                        ]
                    }
                },
                "items": medications,
                "summary": {
                    "total_medications": total_meds,
                    "controlled_substances": has_controlled,
                    "antibiotics_present": has_antibiotics,
                    "max_duration_days": max_duration
                }
            },
            "prescriber": prescriber,
            "pharmacy_information": {
                "dispensed": False,
                "dispenser": {"name": None, "license_number": None, "signature": False},
                "dispensing_date": None,
                "pharmacy_name": None,
                "batch_numbers": [],
                "pharmacy_notes": None,
                "cost_information": {
                    "total_cost": None, "currency": None, "payment_method": None,
                    "insurance_covered": None, "patient_paid": None
                }
            },
            "additional_information": {
                "follow_up": {"required": False, "date": None, "instructions": None},
                "referral": {"required": False, "to_facility": None, "to_specialist": None, "reason": None},
                "medical_certificate": {"issued": False, "sick_leave_days": None, "restrictions": None},
                "lab_tests_ordered": [],
                "imaging_ordered": [],
                "patient_education": [],
                "notes": {"prescriber_notes": None, "pharmacy_notes": None, "administrative_notes": None}
            },
            "digital_verification": {
                "qr_code": {"present": False, "data": None, "bbox": None, "verification_url": None},
                "barcode": {"present": False, "type": None, "data": None, "bbox": None},
                "digital_signature": {"present": False, "algorithm": None, "certificate": None},
                "blockchain_hash": None
            },
            "footer_information": {
                "hospital_footer": {
                    "left_text": {"value": None, "bbox": None},
                    "center_text": {"value": None, "bbox": None},
                    "right_text": {"value": None, "bbox": None}
                },
                "patient_instructions": None,
                "legal_disclaimers": [],
                "confidentiality_notice": None
            },
            "raw_extraction_data": _build_raw_extraction_data(
                region_ocr_data, table_words, section_confidences, quality_report
            )
        }
    }

    return result


def _build_raw_extraction_data(
    region_ocr_data: Optional[Dict[str, Any]],
    table_words: Optional[List[Dict]],
    section_confidences: Dict[str, float],
    quality_report: Any,
) -> Dict[str, Any]:
    """Build the raw_extraction_data section with word-level detail for future enhance service."""
    full_text_parts = []
    words_by_section = {}

    if region_ocr_data:
        for section_name in ["header", "patient", "clinical", "footer", "date"]:
            ocr_obj = region_ocr_data.get(section_name)
            if ocr_obj and hasattr(ocr_obj, 'text') and ocr_obj.text:
                full_text_parts.append(ocr_obj.text)
            if ocr_obj and hasattr(ocr_obj, 'words') and ocr_obj.words:
                words_by_section[section_name] = [
                    {'text': w['text'], 'bbox': w.get('bbox'), 'confidence': w.get('confidence')}
                    for w in ocr_obj.words
                ]

    if table_words:
        words_by_section["medications_table"] = [
            {'text': w['text'], 'bbox': w.get('bbox'), 'confidence': w.get('confidence', w.get('conf', 0) / 100.0)}
            for w in table_words
        ]
        full_text_parts.append(' '.join(w['text'] for w in table_words))

    is_blurry = False
    corrections_applied = False
    if quality_report:
        is_blurry = bool(getattr(quality_report, 'is_blurry', False))
        preprocessing = getattr(quality_report, 'preprocessing_applied', [])
        corrections_applied = bool(preprocessing)

    return {
        "full_text": '\n'.join(full_text_parts) if full_text_parts else None,
        "ocr_confidence_by_section": section_confidences,
        "processing_flags": {
            "handwritten_detected": False,
            "poor_image_quality": is_blurry,
            "partial_occlusion": False,
            "corrections_applied": corrections_applied,
        },
        "alternative_readings": [],
        "words_by_section": words_by_section,
    }


def build_extraction_summary(result: Dict[str, Any], processing_time_ms: float) -> Dict[str, Any]:
    """Build extraction summary for API response."""
    prescription = result.get("prescription", {})
    meds = prescription.get("medications", {})
    metadata = prescription.get("metadata", {}).get("extraction_info", {})

    needs_review = False
    fields_needing_review = []

    return {
        "total_medications": meds.get("summary", {}).get("total_medications", 0),
        "confidence_score": metadata.get("confidence_score", 0),
        "needs_review": needs_review,
        "fields_needing_review": fields_needing_review,
        "processing_time_ms": round(processing_time_ms, 1),
        "engines_used": ["tesseract"]
    }
