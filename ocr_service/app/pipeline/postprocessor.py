"""Post-processing: text normalization, medication parsing, schedule construction."""
import re
from typing import List, Dict, Optional, Any
from app.utils.text_utils import (
    parse_medication_name, parse_duration, parse_dose_value,
    parse_date, parse_datetime, normalize_text, convert_khmer_numerals
)
from app.utils.med_lexicon import MedLexicon
from app.config import settings

TIME_SLOTS = [
    {"period": "morning", "time_range": "06:00-08:00"},
    {"period": "midday", "time_range": "11:00-12:00"},
    {"period": "afternoon", "time_range": "17:00-18:00"},
    {"period": "evening", "time_range": "20:00-22:00"},
]

DOSE_COLUMNS = ["morning", "midday", "afternoon", "evening"]

ROUTE_PATTERNS = {
    "PO": r'\b(PO|oral|per\s*os)\b',
    "IV": r'\b(IV|intravenous)\b',
    "IM": r'\b(IM|intramuscular)\b',
    "SC": r'\b(SC|subcutaneous)\b',
    "topical": r'\b(topical|external)\b',
    "inhaled": r'\b(inhaled|inhalation)\b',
}


class PostProcessor:
    """Post-process raw OCR results into structured prescription data."""

    def __init__(self, lexicon: Optional[MedLexicon] = None):
        if lexicon is None:
            self.lexicon = MedLexicon(settings.lexicon_dir, settings.MED_NAME_MATCH_THRESHOLD)
        else:
            self.lexicon = lexicon

    def process_medication_row(self, row_data: Dict[str, str], item_number: int) -> Dict[str, Any]:
        """Process a single medication row from OCR results."""
        # Parse medication name and strength
        med_text = row_data.get("medication_name", "")
        name, strength_val, strength_unit = parse_medication_name(med_text)

        # Fuzzy match against lexicon
        matched_name, generic_name, therapeutic_class, match_confidence = self.lexicon.match_medication(name)
        brand_name = matched_name or name
        if not generic_name:
            generic_name = brand_name

        # Parse duration
        duration_text = row_data.get("duration", "")
        duration_days, duration_unit, duration_note = parse_duration(duration_text)

        # Parse dose values for each time slot
        time_slots = []
        enabled_count = 0
        total_daily_dose = 0.0

        for i, slot_name in enumerate(DOSE_COLUMNS):
            dose_text = row_data.get(slot_name, "-")
            dose_val, is_enabled = parse_dose_value(dose_text)

            slot_info = TIME_SLOTS[i]
            time_slot = {
                "period": slot_info["period"],
                "time_range": slot_info["time_range"],
                "dose": {
                    "value": dose_text.strip() if dose_text.strip() else "-",
                    "numeric": dose_val,
                    "unit": "tablet",
                    "bbox": row_data.get(f"{slot_name}_bbox")
                },
                "enabled": is_enabled
            }
            time_slots.append(time_slot)
            if is_enabled:
                enabled_count += 1
                total_daily_dose += dose_val

        # Calculate frequency
        if enabled_count >= 2:
            interval = 24 // enabled_count
        else:
            interval = 24

        # Calculate total quantity
        total_quantity = None
        if duration_days and total_daily_dose > 0:
            total_quantity = int(total_daily_dose * duration_days)

        # Detect route
        route = self._detect_route(row_data.get("instructions", ""))

        # Build medication item
        medication_item = {
            "item_number": {
                "value": item_number,
                "bbox": row_data.get("item_number_bbox")
            },
            "medication": {
                "name": {
                    "brand_name": brand_name,
                    "generic_name": generic_name,
                    "local_name": None,
                    "full_text": med_text,
                    "bbox": row_data.get("medication_name_bbox"),
                    "words": row_data.get("medication_name_words"),
                },
                "strength": {
                    "value": f"{strength_val}{strength_unit}" if strength_val and strength_unit else None,
                    "numeric": float(strength_val) if strength_val else None,
                    "unit": strength_unit
                },
                "form": {"value": "tablet", "khmer": None, "french": None},
                "route": {"value": route, "description": self._route_description(route)},
                "packaging": {"quantity_per_unit": None, "unit_type": None}
            },
            "dosing": {
                "duration": {
                    "value": duration_days,
                    "unit": "days",
                    "text_original": duration_text,
                    "khmer_text": duration_text if any(ord(c) > 0x1780 for c in duration_text) else None,
                    "note": duration_note,
                    "bbox": row_data.get("duration_bbox")
                },
                "schedule": {
                    "type": "time_based",
                    "frequency": {
                        "times_per_day": enabled_count,
                        "interval_hours": interval,
                        "text_description": self._frequency_text(enabled_count, duration_note)
                    },
                    "time_slots": time_slots,
                    "prn_instructions": {
                        "as_needed": False, "condition": None,
                        "max_dose_per_day": None, "min_interval_hours": None
                    }
                },
                "total_quantity": {
                    "value": total_quantity,
                    "unit": "tablets",
                    "calculated_from_duration": True
                } if total_quantity else {"value": None, "unit": "tablets", "calculated_from_duration": False},
                "daily_totals": {
                    "total_daily_dose": total_daily_dose,
                    "unit": "tablets"
                }
            },
            "instructions": {
                "timing_with_food": self._guess_food_timing(brand_name, therapeutic_class),
                "special_instructions": {
                    "english": "Take until finished" if duration_note and "until finished" in duration_note else None,
                    "khmer": "\u179a\u17bd\u179f\u17b6\u1794\u17cb" if duration_note and "until finished" in duration_note else None,
                    "french": None
                },
                "administration_technique": None,
                "storage_requirements": None,
                "warnings": [],
                "patient_counseling": []
            },
            "dispensing": {
                "substitution_allowed": None,
                "refills": {"allowed": False, "number": None, "valid_until": None},
                "priority": "routine"
            },
            "clinical_notes": {
                "indication": None,
                "therapeutic_class": therapeutic_class,
                "interactions_check": None,
                "pregnancy_category": None
            }
        }

        return medication_item

    def _detect_route(self, instructions_text: str) -> str:
        """Detect medication route from instructions."""
        text = normalize_text(instructions_text).lower()
        for route, pattern in ROUTE_PATTERNS.items():
            if re.search(pattern, text, re.IGNORECASE):
                return route
        return "PO"  # Default to oral

    def _route_description(self, route: str) -> str:
        """Get human-readable route description."""
        descriptions = {
            "PO": "Oral", "IV": "Intravenous", "IM": "Intramuscular",
            "SC": "Subcutaneous", "topical": "Topical", "inhaled": "Inhaled"
        }
        return descriptions.get(route, "Oral")

    def _frequency_text(self, times_per_day: int, note: Optional[str] = None) -> str:
        """Generate frequency text."""
        base = f"{times_per_day} time{'s' if times_per_day != 1 else ''} daily"
        if note and "until finished" in note:
            base += " until finished"
        return base

    def _guess_food_timing(self, med_name: str, therapeutic_class: Optional[str]) -> Dict[str, Any]:
        """Guess food timing based on medication class."""
        timing = {
            "before_meal": None, "after_meal": None,
            "with_meal": None, "empty_stomach": None, "text": None
        }
        if therapeutic_class:
            tc_lower = therapeutic_class.lower()
            if "proton pump" in tc_lower:
                timing["before_meal"] = True
                timing["text"] = "Take before meals"
            elif "vitamin" in tc_lower or "supplement" in tc_lower:
                timing["after_meal"] = True
                timing["text"] = "Take after meals"
            elif "nsaid" in tc_lower:
                timing["after_meal"] = True
                timing["text"] = "Take after meals"
        return timing

    def process_header(self, ocr_text: str, image_width: int) -> Dict[str, Any]:
        """Process header region OCR text."""
        lines = [l.strip() for l in ocr_text.split('\n') if l.strip()]

        facility = {
            "name": {"english": None, "khmer": None, "french": None, "bbox": None},
            "facility_code": None,
            "facility_type": "public_hospital",
            "logo": {"detected": False, "bbox": None, "logo_text": None},
            "system_name": {"value": None, "bbox": None},
            "contact": {
                "address": {"english": None, "khmer": None, "bbox": None},
                "phone": None, "email": None, "website": None
            },
            "accreditation": {"ministry_registration": None, "license_number": None}
        }

        for line in lines:
            line_lower = line.lower()
            if 'h-eqip' in line_lower or 'heqip' in line_lower:
                facility["system_name"]["value"] = "H-EQIP"
            elif 'hospital' in line_lower or 'clinic' in line_lower:
                facility["name"]["english"] = line

            from app.utils.text_utils import is_khmer_text
            if is_khmer_text(line) and not facility["name"]["khmer"]:
                if len(line) > 5:
                    facility["name"]["khmer"] = line

        return facility

    def process_patient_info(self, ocr_text: str) -> Dict[str, Any]:
        """Process patient information region."""
        text = normalize_text(convert_khmer_numerals(ocr_text))

        patient = {
            "identification": {
                "patient_id": {"value": None, "id_type": "hospital_id", "bbox": None},
                "reference_number": {"value": None, "description": None, "bbox": None},
                "medical_record_number": None
            },
            "personal_info": {
                "name": {"full_name": None, "khmer_name": None, "first_name": None, "last_name": None, "bbox": None},
                "date_of_birth": {"value": None, "format_detected": None, "bbox": None},
                "age": {"value": None, "unit": "years", "khmer_text": None, "bbox": None},
                "gender": {"value": None, "khmer": None, "english": None, "french": None, "bbox": None}
            },
            "contact": {
                "phone": None,
                "address": {"full_address": None, "province": None, "district": None, "commune": None},
                "emergency_contact": {"name": None, "phone": None, "relationship": None}
            },
            "insurance": {"provider": None, "number": None, "coverage_type": None, "expiry_date": None},
            "classification": {"value": None, "bbox": None}
        }

        # Extract patient ID (common patterns: HAKF followed by digits)
        id_match = re.search(r'([A-Z]{2,5}\d{5,})', text)
        if id_match:
            patient["identification"]["patient_id"]["value"] = id_match.group(1)

        # Extract age
        age_match = re.search(r'(\d{1,3})\s*(?:years?|ans?|\u1786\u17d2\u1793\u17b6\u17c6)', text, re.IGNORECASE)
        if age_match:
            patient["personal_info"]["age"]["value"] = int(age_match.group(1))

        # Extract gender
        text_lower = text.lower()
        if any(g in text_lower for g in ['female', 'femme', '\u179f\u17d2\u179a\u17b8']):
            patient["personal_info"]["gender"].update({"value": "F", "english": "Female", "khmer": "\u179f\u17d2\u179a\u17b8", "french": "Femme"})
        elif any(g in text_lower for g in ['male', 'homme', '\u1794\u17d2\u179a\u17bb\u179f']):
            patient["personal_info"]["gender"].update({"value": "M", "english": "Male", "khmer": "\u1794\u17d2\u179a\u17bb\u179f", "french": "Homme"})

        return patient

    def process_clinical_info(self, ocr_text: str) -> Dict[str, Any]:
        """Process clinical information / diagnosis section."""
        text = normalize_text(ocr_text)

        clinical = {
            "diagnoses": [],
            "symptoms": [],
            "allergies": {"has_allergies": False, "items": []},
            "vital_signs": {
                "blood_pressure": {"systolic": None, "diastolic": None, "text": None},
                "heart_rate": None,
                "temperature": {"value": None, "unit": None},
                "weight": {"value": None, "unit": None},
                "height": {"value": None, "unit": None},
                "bmi": None
            },
            "past_medical_history": [],
            "current_medications": []
        }

        # Extract diagnosis - look for known patterns
        if text:
            clinical["diagnoses"].append({
                "sequence": 1,
                "diagnosis": {"english": text, "khmer": None, "french": None, "bbox": None},
                "code": {"icd10": None, "icd11": None, "local_code": None},
                "type": "primary",
                "status": "confirmed",
                "onset_date": None
            })

        return clinical

    def process_footer(self, ocr_text: str) -> Dict[str, Any]:
        """Process footer region."""
        text = normalize_text(ocr_text)
        lines = [l.strip() for l in text.split('\n') if l.strip()]

        # Extract date/time
        date_str = None
        datetime_str = None
        for line in lines:
            dt = parse_datetime(line)
            if dt:
                datetime_str = dt
                date_str = parse_date(line)
                break
            d = parse_date(line)
            if d:
                date_str = d

        # Extract prescriber name (look for known patterns)
        prescriber_name = None
        for line in lines:
            if re.search(r'[A-Z][a-z]+\s+[A-Z][a-z]+', line):
                prescriber_name = line.strip()
                break

        return {
            "date": date_str,
            "datetime": datetime_str,
            "prescriber_name": prescriber_name,
            "footer_text": lines
        }
