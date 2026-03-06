"""Format parsed prescription data into Dynamic Universal v2.0 schema.

This produces the exact same JSON structure as the existing ocr_service
so the NestJS backend and AI service work without modification.
"""
import time
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, List, Optional

from app.pipeline.text_parser import ParsedPrescription, ParsedMedication


def _timestamp() -> str:
    """Current ISO timestamp in Cambodia timezone (UTC+7)."""
    tz = timezone(timedelta(hours=7))
    return datetime.now(tz).isoformat()


def _build_medication_item(med: ParsedMedication) -> Dict[str, Any]:
    """Build a single medication item in the Dynamic Universal v2.0 format."""

    # Time slots
    time_slots = []
    for period, dose, time_range in [
        ("morning", med.morning_dose, "06:00-08:00"),
        ("midday", med.midday_dose, "11:00-12:00"),
        ("afternoon", med.afternoon_dose, "17:00-18:00"),
        ("evening", med.evening_dose, "20:00-22:00"),
    ]:
        time_slots.append({
            "period": period,
            "time_range": time_range,
            "dose": {
                "value": str(dose) if dose else "0",
                "numeric": dose,
                "unit": med.form or "tablet",
                "bbox": None,
            },
            "enabled": bool(dose and dose > 0),
        })

    return {
        "item_number": {"value": med.item_number, "bbox": med.bbox or None},
        "medication": {
            "name": {
                "brand_name": med.brand_name,
                "generic_name": med.generic_name,
                "local_name": med.local_name,
                "full_text": med.name_full,
                "bbox": None,
            },
            "strength": {
                "value": med.strength_value,
                "numeric": med.strength_numeric,
                "unit": med.strength_unit,
            },
            "form": {
                "value": med.form or "tablet",
                "khmer": None,
                "french": None,
            },
            "route": {
                "value": med.route or "PO",
                "description": None,
            },
        },
        "dosing": {
            "duration": {
                "value": med.duration_days,
                "unit": "days" if med.duration_days else None,
                "text_original": med.duration_text or "",
                "khmer_text": None,
                "note": None,
                "bbox": None,
            },
            "schedule": {
                "type": "fixed" if not med.as_needed else "prn",
                "frequency": {
                    "times_per_day": med.times_per_day,
                    "interval_hours": round(24 / med.times_per_day, 1) if med.times_per_day > 0 else None,
                    "text_description": f"{med.times_per_day}x/day",
                },
                "time_slots": time_slots,
                "prn_instructions": {
                    "as_needed": med.as_needed,
                    "condition": None,
                },
            },
            "total_quantity": {
                "value": med.total_quantity,
                "unit": med.form or "tablet",
            },
        },
        "instructions": {
            "timing_with_food": {
                "before_meal": med.before_meal,
                "after_meal": med.after_meal,
                "text": med.instructions_text or None,
            },
        },
        "clinical_notes": {
            "therapeutic_class": None,
        },
    }


def build_dynamic_universal(
    rx: ParsedPrescription,
    processing_time_ms: float,
    image_width: int = 0,
    image_height: int = 0,
    image_format: str = "unknown",
    file_size_bytes: int = 0,
) -> Dict[str, Any]:
    """Build the full Dynamic Universal v2.0 JSON response.

    This matches the schema defined in:
    backend_nestjs/src/modules/ocr/dto/ocr-response.interface.ts
    """

    # Build medication items
    med_items = [_build_medication_item(m) for m in rx.medications]
    total_meds = len(med_items)
    max_duration = max(
        (m.duration_days for m in rx.medications if m.duration_days),
        default=0,
    )

    # Prescription ID construction
    date_part = (rx.issue_date or "").replace("-", "")
    prescription_id = f"{rx.patient_id}-{date_part}" if rx.patient_id and date_part else None

    result = {
        "$schema": "cambodia-prescription-universal-v2.0",
        "prescription": {
            "metadata": {
                "extraction_info": {
                    "extracted_at": _timestamp(),
                    "ocr_engine": "kiri-ocr",
                    "confidence_score": rx.confidence,
                    "preprocessing_applied": [],
                    "image_metadata": {
                        "width": image_width,
                        "height": image_height,
                        "format": image_format,
                        "dpi": 200,
                        "file_size_bytes": file_size_bytes,
                    },
                },
                "prescription_id": prescription_id,
                "version": "2.0",
                "languages_detected": {
                    "primary": "khmer",
                    "secondary": ["english"],
                    "mixed_content": True,
                },
                "prescription_type": "outpatient",
                "validation_status": "validated",
            },
            "healthcare_facility": {
                "name": {"english": rx.facility_name, "khmer": None, "french": None, "bbox": None},
                "type": "hospital",
                "accreditation": {"status": None, "body": None, "level": None},
                "identification": {"code": None, "license_number": None},
                "contact": {"phone": None, "email": None, "website": None, "fax": None},
                "address": {"full_address": None, "province": None, "district": None, "commune": None},
                "department": {"name": None, "khmer": None, "code": None, "bbox": None},
            },
            "patient": {
                "identification": {
                    "patient_id": {"value": rx.patient_id, "bbox": None},
                    "national_id": None,
                    "passport_number": None,
                },
                "personal_info": {
                    "name": {
                        "full_name": rx.patient_name,
                        "khmer_name": rx.patient_name_khmer,
                        "first_name": None,
                        "last_name": None,
                        "bbox": None,
                    },
                    "age": {
                        "value": rx.patient_age,
                        "unit": rx.patient_age_unit,
                        "date_of_birth": None,
                        "bbox": None,
                    },
                    "gender": {
                        "value": rx.patient_gender,
                        "english": {"M": "Male", "F": "Female"}.get(rx.patient_gender or "", None),
                        "khmer": {"M": "ប្រុស", "F": "ស្រី"}.get(rx.patient_gender or "", None),
                        "bbox": None,
                    },
                    "contact": {"phone": None, "email": None, "address": None},
                    "insurance": {"provider": None, "policy_number": None, "coverage_type": None},
                },
            },
            "prescription_details": {
                "dates": {
                    "issue_date": {"value": rx.issue_date, "original_format": None, "bbox": None},
                    "issue_datetime": {"value": None, "original_text": None, "bbox": None},
                    "expiry_date": None,
                    "valid_until": None,
                },
                "prescription_number": {"value": None, "bbox": None},
                "visit_information": {
                    "visit_type": "OPD",
                    "department": {"name": None, "khmer": None, "bbox": None},
                    "location": {
                        "building": None, "floor": None, "room_number": None,
                        "bed_number": None, "full_location_khmer": None, "bbox": None,
                    },
                    "visit_date": rx.issue_date,
                    "visit_time": None,
                },
            },
            "clinical_information": {
                "diagnoses": [
                    {
                        "diagnosis": {
                            "english": d if not any('\u1780' <= c <= '\u17FF' for c in d) else None,
                            "khmer": d if any('\u1780' <= c <= '\u17FF' for c in d) else None,
                            "icd_code": None,
                        },
                        "type": "primary",
                        "confidence": rx.confidence,
                    }
                    for d in rx.diagnoses
                ],
                "symptoms": [],
                "allergies": [],
                "vital_signs": {},
            },
            "medications": {
                "table_structure": {
                    "detected": True,
                    "bbox": None,
                    "column_headers": {
                        "item_number": {"label": "ល.រ", "bbox": None},
                        "medication_name": {"label": "ឈ្មោះថ្នាំ", "bbox": None},
                        "duration": {"label": "ថ្ងៃផុត", "bbox": None},
                        "instructions": {"label": "វិធីប្រើ", "bbox": None},
                        "time_slots": [
                            {"period": "morning", "label": "ព្រឹក (6-8)", "time_range": "06:00-08:00", "bbox": None},
                            {"period": "midday", "label": "ថ្ងៃត្រង់ (11-12)", "time_range": "11:00-12:00", "bbox": None},
                            {"period": "afternoon", "label": "ល្ងាច (05-06)", "time_range": "17:00-18:00", "bbox": None},
                            {"period": "evening", "label": "យប់ (08-10)", "time_range": "20:00-22:00", "bbox": None},
                        ],
                    },
                },
                "items": med_items,
                "summary": {
                    "total_medications": total_meds,
                    "controlled_substances": False,
                    "antibiotics_present": False,
                    "max_duration_days": max_duration if max_duration > 0 else None,
                },
            },
            "prescriber": {
                "name": {
                    "full_name": rx.prescriber_name,
                    "khmer_name": None,
                    "title": None,
                    "bbox": None,
                },
                "credentials": {
                    "license_number": None,
                    "specialty": {"english": None, "khmer": None, "french": None},
                    "sub_specialty": None,
                },
                "signature": {"present": True, "type": "handwritten", "bbox": None},
                "stamp": {"present": False, "bbox": None},
                "contact": {"phone": None, "email": None, "office_location": None},
            },
            "pharmacy_information": {
                "dispensed": False,
                "dispenser": {"name": None, "license_number": None, "signature": False},
                "dispensing_date": None,
                "pharmacy_name": None,
                "batch_numbers": [],
                "pharmacy_notes": None,
                "cost_information": {
                    "total_cost": None, "currency": None, "payment_method": None,
                    "insurance_covered": None, "patient_paid": None,
                },
            },
            "additional_information": {
                "follow_up": {"required": False, "date": None, "instructions": None},
                "referral": {"required": False, "to_facility": None, "to_specialist": None, "reason": None},
                "medical_certificate": {"issued": False, "sick_leave_days": None, "restrictions": None},
                "lab_tests_ordered": [],
                "imaging_ordered": [],
                "patient_education": [],
                "notes": {"prescriber_notes": None, "pharmacy_notes": None, "administrative_notes": None},
            },
            "digital_verification": {
                "qr_code": {"present": False, "data": None, "bbox": None, "verification_url": None},
                "barcode": {"present": False, "type": None, "data": None, "bbox": None},
                "digital_signature": {"present": False, "algorithm": None, "certificate": None},
                "blockchain_hash": None,
            },
            "footer_information": {
                "hospital_footer": {
                    "left_text": {"value": None, "bbox": None},
                    "center_text": {"value": None, "bbox": None},
                    "right_text": {"value": None, "bbox": None},
                },
                "patient_instructions": None,
                "legal_disclaimers": [],
                "confidentiality_notice": None,
            },
            "raw_extraction_data": {
                "full_text": rx.full_text,
                "ocr_confidence_by_section": {},
                "processing_flags": {
                    "handwritten_detected": False,
                    "poor_image_quality": False,
                    "partial_occlusion": False,
                    "corrections_applied": False,
                },
                "alternative_readings": [],
                "words_by_section": {},
            },
        },
    }

    return result


def build_extraction_summary(
    result: Dict[str, Any],
    processing_time_ms: float,
) -> Dict[str, Any]:
    """Build extraction summary for the API response."""
    prescription = result.get("prescription", {})
    meds = prescription.get("medications", {})
    metadata = prescription.get("metadata", {}).get("extraction_info", {})

    return {
        "total_medications": meds.get("summary", {}).get("total_medications", 0),
        "confidence_score": metadata.get("confidence_score", 0),
        "needs_review": metadata.get("confidence_score", 0) < 0.80,
        "fields_needing_review": [],
        "processing_time_ms": round(processing_time_ms, 1),
        "engines_used": ["kiri-ocr"],
    }
