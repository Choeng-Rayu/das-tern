"""Format parsed prescription data into the Dynamic Universal v2.0 schema."""
from datetime import datetime, timedelta, timezone
from typing import Any, Dict

from app.pipeline.text_parser import ParsedMedication, ParsedPrescription


def _timestamp() -> str:
    tz = timezone(timedelta(hours=7))
    return datetime.now(tz).isoformat()


def _build_time_slots(med: ParsedMedication) -> list[Dict[str, Any]]:
    slots = []
    for period, dose, time_range in [
        ("morning", med.morning_dose, "06:00-08:00"),
        ("midday", med.midday_dose, "11:00-12:00"),
        ("afternoon", med.afternoon_dose, "17:00-18:00"),
        ("evening", med.evening_dose, "20:00-22:00"),
    ]:
        slots.append({
            "period": period,
            "time_range": time_range,
            "dose": {
                "value": str(dose) if dose is not None else "0",
                "numeric": dose,
                "unit": med.form or "tablet",
                "bbox": None,
            },
            "enabled": dose is not None and dose > 0,
        })
    return slots


def _build_medication_item(med: ParsedMedication) -> Dict[str, Any]:
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
            "form": {"value": med.form, "khmer": None, "french": None},
            "route": {"value": med.route, "description": None},
        },
        "dosing": {
            "duration": {
                "value": med.duration_days,
                "unit": "days" if med.duration_days else None,
                "text_original": med.duration_text,
                "khmer_text": None,
                "note": None,
                "bbox": None,
            },
            "schedule": {
                "type": "prn" if med.as_needed else "fixed",
                "frequency": {
                    "times_per_day": med.times_per_day,
                    "interval_hours": round(24 / med.times_per_day, 1) if med.times_per_day else None,
                    "text_description": f"{med.times_per_day}x/day" if med.times_per_day else None,
                },
                "time_slots": _build_time_slots(med),
                "prn_instructions": {"as_needed": med.as_needed, "condition": None},
            },
            "total_quantity": {"value": med.total_quantity, "unit": med.form or "tablet"},
        },
        "instructions": {
            "timing_with_food": {
                "before_meal": med.before_meal,
                "after_meal": med.after_meal,
                "text": med.instructions_text or None,
            }
        },
        "clinical_notes": {"therapeutic_class": None},
    }


def build_dynamic_universal(
    rx: ParsedPrescription,
    processing_time_ms: float,
    image_width: int = 0,
    image_height: int = 0,
    image_format: str = "unknown",
    file_size_bytes: int = 0,
    preprocessing_applied: list | None = None,
) -> Dict[str, Any]:
    med_items = [_build_medication_item(m) for m in rx.medications]
    max_duration = max((m.duration_days for m in rx.medications if m.duration_days), default=0)
    date_part = (rx.issue_date or "").replace("-", "")
    prescription_id = f"{rx.patient_id}-{date_part}" if rx.patient_id and date_part else None

    return {
        "$schema": "cambodia-prescription-universal-v2.0",
        "prescription": {
            "metadata": {
                "extraction_info": {
                    "extracted_at": _timestamp(),
                    "ocr_engine": "kiri-ocr",
                    "confidence_score": rx.confidence,
                    "processing_time_ms": round(processing_time_ms, 1),
                    "preprocessing_applied": preprocessing_applied or [],
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
                "validation_status": "validated" if rx.medications else "needs_review",
            },
            "healthcare_facility": {
                "name": {"english": rx.facility_name, "khmer": None, "french": None, "bbox": None},
                "type": "hospital",
            },
            "patient": {
                "identification": {"patient_id": {"value": rx.patient_id}},
                "personal_info": {
                    "name": {"full_name": rx.patient_name, "khmer_name": rx.patient_name_khmer},
                    "age": {"value": rx.patient_age, "unit": rx.patient_age_unit},
                    "gender": {
                        "value": rx.patient_gender,
                        "english": {"M": "Male", "F": "Female"}.get(rx.patient_gender),
                    },
                },
            },
            "clinical_information": {
                "diagnoses": [
                    {
                        "diagnosis": {
                            "english": d if not any("\u1780" <= c <= "\u17FF" for c in d) else None,
                            "khmer": d if any("\u1780" <= c <= "\u17FF" for c in d) else None,
                        }
                    }
                    for d in rx.diagnoses
                ]
            },
            "medications": {
                "items": med_items,
                "summary": {
                    "total_medications": len(med_items),
                    "max_duration_days": max_duration or None,
                },
            },
            "prescriber": {"name": {"full_name": rx.prescriber_name}},
            "prescription_details": {
                "dates": {"issue_date": {"value": rx.issue_date}},
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


def build_extraction_summary(result: Dict[str, Any], processing_time_ms: float) -> Dict[str, Any]:
    prescription = result.get("prescription", {})
    confidence = prescription.get("metadata", {}).get("extraction_info", {}).get("confidence_score", 0.0)
    meds = prescription.get("medications", {}).get("summary", {}).get("total_medications", 0)

    fields_needing_review = []
    patient = prescription.get("patient", {}).get("personal_info", {})
    if not patient.get("name", {}).get("full_name") and not patient.get("name", {}).get("khmer_name"):
        fields_needing_review.append("patient.name")
    if meds == 0:
        fields_needing_review.append("medications.items")

    return {
        "total_medications": meds,
        "confidence_score": confidence,
        "needs_review": confidence < 0.80 or meds == 0,
        "fields_needing_review": fields_needing_review,
        "processing_time_ms": round(processing_time_ms, 1),
        "engines_used": ["kiri-ocr"],
    }