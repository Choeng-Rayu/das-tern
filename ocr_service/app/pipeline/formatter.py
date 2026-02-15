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

    # Determine overall confidence
    overall_confidence = 0.85  # Default

    # Build prescriber info from footer
    prescriber = {
        "name": {
            "full_name": footer_data.get("prescriber_name"),
            "khmer_name": None,
            "title": None,
            "bbox": None
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
                "bbox": None
            },
            "issue_datetime": {
                "value": footer_data.get("datetime"),
                "original_text": None,
                "bbox": None
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
                    "bbox": None,
                    "column_headers": {
                        "item_number": {"label": "\u179b.\u179a", "bbox": None},
                        "medication_name": {"label": "\u1788\u17d2\u1798\u17c4\u17c7\u178f\u17d2\u1793\u17b6\u17c6", "bbox": None},
                        "duration": {"label": "\u1790\u17d2\u1784\u17c3\u1795\u17bb\u178f", "bbox": None},
                        "instructions": {"label": "\u179c\u17b7\u1792\u17b8\u1794\u17d2\u179a\u17be", "bbox": None},
                        "time_slots": [
                            {"period": "morning", "label": "\u1796\u17d2\u179a\u17b9\u1780 (6-8)", "time_range": "06:00-08:00", "bbox": None},
                            {"period": "midday", "label": "\u1790\u17d2\u1784\u17c3\u178f\u17d2\u179a\u1784\u17cb (11-12)", "time_range": "11:00-12:00", "bbox": None},
                            {"period": "afternoon", "label": "\u179b\u17d2\u1784\u17b6\u1785 (05-06)", "time_range": "17:00-18:00", "bbox": None},
                            {"period": "evening", "label": "\u1799\u1794\u17cb (08-10)", "time_range": "20:00-22:00", "bbox": None}
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
            "raw_extraction_data": {
                "full_text": None,
                "ocr_confidence_by_section": {},
                "processing_flags": {
                    "handwritten_detected": False,
                    "poor_image_quality": False,
                    "partial_occlusion": False,
                    "corrections_applied": False
                },
                "alternative_readings": []
            }
        }
    }

    return result


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
