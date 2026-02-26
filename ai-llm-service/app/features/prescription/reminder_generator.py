"""
Reminder Generator Module
Generates structured medication reminders from prescription data
"""

import json
import logging
from datetime import datetime, timedelta, date
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)

# Khmer time slot mapping to 24-hour format
KHMER_TIME_SLOTS = {
    "ព្រឹក": {"slot": "morning", "time": "08:00", "range": "06:00-08:00"},
    "matin": {"slot": "morning", "time": "08:00", "range": "06:00-08:00"},
    "morning": {"slot": "morning", "time": "08:00", "range": "06:00-08:00"},
    
    "ថ្ងៃត្រង់": {"slot": "noon", "time": "12:00", "range": "11:00-12:00"},
    "midi": {"slot": "noon", "time": "12:00", "range": "11:00-12:00"},
    "noon": {"slot": "noon", "time": "12:00", "range": "11:00-12:00"},
    
    "ល្ងាច": {"slot": "afternoon", "time": "18:00", "range": "17:00-18:00"},
    "soir": {"slot": "afternoon", "time": "18:00", "range": "17:00-18:00"},
    "evening": {"slot": "afternoon", "time": "18:00", "range": "17:00-18:00"},
    
    "យប់": {"slot": "night", "time": "21:00", "range": "20:00-22:00"},
    "nuit": {"slot": "night", "time": "21:00", "range": "20:00-22:00"},
    "night": {"slot": "night", "time": "21:00", "range": "20:00-22:00"},
}

# Default time slots if not specified
DEFAULT_TIME_SLOTS = {
    "morning": "08:00",
    "noon": "12:00",
    "afternoon": "18:00",
    "evening": "20:00",
    "night": "21:00"
}


class ReminderGenerator:
    """Generate medication reminders from prescription data"""
    
    def __init__(self):
        self.time_slot_map = KHMER_TIME_SLOTS
        
    def generate_reminders(
        self, 
        prescription_data: Dict[str, Any],
        base_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate complete reminder structure from prescription data
        
        Args:
            prescription_data: Structured prescription data from AI processing
            base_date: Starting date for reminders (default: today)
            
        Returns:
            Dictionary with prescription, reminders, and metadata
        """
        try:
            # Use provided date or default to today
            from datetime import date as date_cls
            start_date = datetime.strptime(base_date, "%Y-%m-%d").date() if base_date else date_cls.today()
            
            # Extract medications
            medications = prescription_data.get("medications", [])
            patient_info = prescription_data.get("patient_info", {})
            medical_info = prescription_data.get("medical_info", {})
            
            reminders = []
            
            for med in medications:
                med_reminders = self._generate_medication_reminders(
                    med, start_date, patient_info, medical_info
                )
                reminders.extend(med_reminders)
            
            # Build complete response
            result = {
                "prescription": {
                    "patient_info": patient_info,
                    "medical_info": medical_info,
                    "medications": medications
                },
                "reminders": reminders,
                "metadata": {
                    "total_medications": len(medications),
                    "total_reminders": len(reminders),
                    "start_date": start_date.isoformat(),
                    "generated_at": datetime.now().isoformat()
                }
            }
            
            logger.info(f"Generated {len(reminders)} reminders for {len(medications)} medications")
            return result
            
        except Exception as e:
            logger.error(f"Reminder generation failed: {e}")
            return {
                "prescription": prescription_data,
                "reminders": [],
                "metadata": {
                    "error": str(e),
                    "generated_at": datetime.now().isoformat()
                }
            }
    
    def _generate_medication_reminders(
        self,
        medication: Dict[str, Any],
        start_date: date,
        patient_info: Dict[str, Any],
        medical_info: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate reminders for a single medication"""
        reminders = []
        
        # Extract medication details
        name = medication.get("name", "Unknown Medication")
        dosage = medication.get("dosage", "")
        quantity = medication.get("quantity", 0)
        duration_days = medication.get("duration_days")
        instructions = medication.get("instructions", "")
        
        # Get schedule information
        schedule = medication.get("schedule", {})
        times = schedule.get("times", [])
        times_24h = schedule.get("times_24h", [])
        
        # If no specific times, use default mapping
        if not times_24h and times:
            times_24h = self._convert_times_to_24h(times)
        
        # Calculate end date
        if duration_days:
            end_date = start_date + timedelta(days=duration_days)
        else:
            # Estimate from quantity if available
            daily_doses = len(times_24h) if times_24h else 1
            if quantity and daily_doses > 0:
                estimated_days = quantity // daily_doses
                end_date = start_date + timedelta(days=estimated_days)
            else:
                end_date = start_date + timedelta(days=7)  # Default 7 days
        
        # Generate reminder for each time slot
        for i, time_slot in enumerate(times):
            time_24h = times_24h[i] if i < len(times_24h) else DEFAULT_TIME_SLOTS.get(time_slot, "08:00")
            
            # Determine dose amount (default to 1)
            dose_amount = 1
            if "dose" in medication:
                dose_amount = medication.get("dose", 1)
            
            # Build notification messages
            notification_title = f"Time to take {name}"
            notification_body = self._build_notification_body(name, dosage, dose_amount, instructions)
            
            reminder = {
                "medication_name": name,
                "medication_dosage": dosage,
                "time_slot": time_slot,
                "scheduled_time": time_24h,
                "dose_amount": dose_amount,
                "dose_unit": medication.get("unit", "tablet"),
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "instructions": instructions,
                "notification_title": notification_title,
                "notification_body": notification_body,
                "days_of_week": [1, 2, 3, 4, 5, 6, 7],  # All days by default
                "advance_notification_minutes": 15,
                "snooze_duration_minutes": 10
            }
            
            reminders.append(reminder)
        
        return reminders
    
    def _convert_times_to_24h(self, times: List[str]) -> List[str]:
        """Convert time slot names to 24-hour format"""
        result = []
        for time in times:
            time_lower = time.lower()
            if time_lower in self.time_slot_map:
                result.append(self.time_slot_map[time_lower]["time"])
            elif time_lower in DEFAULT_TIME_SLOTS:
                result.append(DEFAULT_TIME_SLOTS[time_lower])
            else:
                # Try to parse as time string
                result.append(time)
        return result
    
    def _build_notification_body(
        self, 
        name: str, 
        dosage: str, 
        dose_amount: int,
        instructions: str
    ) -> str:
        """Build user-friendly notification body"""
        parts = [f"Take {dose_amount} {name}"]
        
        if dosage:
            parts.append(f"({dosage})")
        
        if instructions:
            parts.append(f"- {instructions}")
        
        return " ".join(parts)
    
    def validate_reminders(self, reminders: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Validate generated reminders for completeness and accuracy"""
        errors = []
        warnings = []
        
        for i, reminder in enumerate(reminders):
            # Check required fields
            if not reminder.get("medication_name"):
                errors.append(f"Reminder {i}: Missing medication name")
            
            if not reminder.get("scheduled_time"):
                errors.append(f"Reminder {i}: Missing scheduled time")
            
            if not reminder.get("start_date"):
                errors.append(f"Reminder {i}: Missing start date")
            
            # Validate time format
            time = reminder.get("scheduled_time", "")
            if time and not self._is_valid_time_format(time):
                warnings.append(f"Reminder {i}: Invalid time format '{time}'")
            
            # Check dose amount
            dose = reminder.get("dose_amount", 0)
            if dose <= 0:
                warnings.append(f"Reminder {i}: Invalid dose amount {dose}")
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "total_reminders": len(reminders)
        }
    
    def _is_valid_time_format(self, time_str: str) -> bool:
        """Check if time string is in valid HH:MM format"""
        try:
            datetime.strptime(time_str, "%H:%M")
            return True
        except ValueError:
            return False


# Global instance
reminder_generator = ReminderGenerator()


def generate_reminders_from_prescription(
    prescription_data: Dict[str, Any],
    base_date: Optional[str] = None
) -> Dict[str, Any]:
    """
    Main function to generate reminders from prescription data
    
    Args:
        prescription_data: Structured prescription data
        base_date: Optional start date (YYYY-MM-DD)
        
    Returns:
        Complete reminder structure with validation
    """
    result = reminder_generator.generate_reminders(prescription_data, base_date)
    
    # Validate the generated reminders
    validation = reminder_generator.validate_reminders(result.get("reminders", []))
    result["validation"] = validation
    
    return result


# ============================================================
# Unified Reminder Generation with Khmer Instructions
# ============================================================

# Import Khmer instructions module
try:
    from .khmer_instructions import (
        generate_khmer_instruction,
        KHMER_TIME_CONTEXT
    )
    KHMER_INSTRUCTIONS_AVAILABLE = True
except ImportError:
    KHMER_INSTRUCTIONS_AVAILABLE = False
    logger.warning("Khmer instructions module not available")


# Standard time slot mapping
STANDARD_TIME_SLOTS = {
    "morning": {"time_24h": "08:00", "display": "Morning"},
    "noon": {"time_24h": "12:00", "display": "Noon"},
    "afternoon": {"time_24h": "18:00", "display": "Evening"},
    "evening": {"time_24h": "18:00", "display": "Evening"},
    "night": {"time_24h": "21:00", "display": "Night"},
    # Khmer time slots
    "ព្រឹក": {"time_24h": "08:00", "display": "Morning"},
    "ថ្ងៃត្រង់": {"time_24h": "12:00", "display": "Noon"},
    "រសៀល": {"time_24h": "18:00", "display": "Evening"},
    "ល្ងាច": {"time_24h": "18:00", "display": "Evening"},
    "យប់": {"time_24h": "21:00", "display": "Night"},
}


def generate_unified_reminders(
    prescription_data: Dict[str, Any],
    patient_name: str = "",
    source: str = "",
    visit_date: str = ""
) -> Dict[str, Any]:
    """
    Generate unified prescription JSON with Khmer instructions.
    
    This produces the target format:
    {
      "prescription_data": {
        "patients": [{
          "name": "patient name",
          "source": "hospital name",
          "visit_date": "DD/MM/YYYY",
          "medicines": [{
            "name": "Medication 20mg",
            "total_quantity": 14,
            "unit": "Tablet",
            "reminders": [{
              "time": "Morning",
              "dosage_quantity": 1,
              "dosage_unit": "Tablet",
              "instruction_kh": "លេប ១ គ្រាប់"
            }]
          }]
        }]
      }
    }
    
    Args:
        prescription_data: Structured prescription data from AI processing
        patient_name: Patient name (optional, extracted from data if missing)
        source: Hospital/clinic name (optional)
        visit_date: Visit date in DD/MM/YYYY format (optional)
        
    Returns:
        Unified prescription JSON with Khmer instructions
    """
    try:
        # Extract patient info
        patient_info = prescription_data.get("patient_info", {})
        medical_info = prescription_data.get("medical_info", {})
        medications = prescription_data.get("medications", [])
        
        # Use provided values or extract from data
        final_patient_name = patient_name or patient_info.get("name", "Unknown")
        final_source = source or patient_info.get("hospital_code", "") or medical_info.get("department", "Unknown")
        final_visit_date = visit_date or medical_info.get("date", datetime.now().strftime("%d/%m/%Y"))
        
        # Process each medication
        medicines_with_reminders = []
        
        for med in medications:
            medicine = _process_medication_for_unified(med)
            if medicine:
                medicines_with_reminders.append(medicine)
        
        # Build patient prescription
        patient_prescription = {
            "name": final_patient_name,
            "source": final_source,
            "visit_date": final_visit_date,
            "medicines": medicines_with_reminders
        }
        
        # Add optional diagnosis and doctor
        if medical_info.get("diagnosis"):
            patient_prescription["diagnosis"] = medical_info["diagnosis"]
        if medical_info.get("doctor"):
            patient_prescription["doctor"] = medical_info["doctor"]
        
        return {
            "success": True,
            "prescription_data": {
                "patients": [patient_prescription]
            },
            "metadata": {
                "total_medicines": len(medicines_with_reminders),
                "total_reminders": sum(len(m.get("reminders", [])) for m in medicines_with_reminders),
                "khmer_instructions_enabled": KHMER_INSTRUCTIONS_AVAILABLE,
                "generated_at": datetime.now().isoformat()
            }
        }
        
    except Exception as e:
        logger.error(f"Unified reminder generation failed: {e}")
        return {
            "success": False,
            "prescription_data": {"patients": []},
            "error": str(e),
            "metadata": {"generated_at": datetime.now().isoformat()}
        }


def _process_medication_for_unified(medication: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Process a single medication into the unified format with Khmer instructions.
    
    Args:
        medication: Medication data from prescription
        
    Returns:
        Medicine with reminders in unified format
    """
    try:
        # Extract medication details
        name = medication.get("name", "")
        dosage = medication.get("dosage", "")
        
        # Combine name and dosage if separate
        if dosage and dosage not in name:
            full_name = f"{name} {dosage}".strip()
        else:
            full_name = name
        
        # Get quantity and unit
        total_quantity = medication.get("quantity", 0) or medication.get("total_quantity", 0)
        unit = medication.get("unit", "Tablet")
        
        # Capitalize unit for display
        unit = unit.capitalize() if unit else "Tablet"
        
        # Get schedule
        schedule = medication.get("schedule", {})
        times = schedule.get("times", []) or medication.get("times", [])
        
        # If no times specified, check for individual time flags
        if not times:
            times = []
            if medication.get("morning") or schedule.get("morning"):
                times.append("morning")
            if medication.get("noon") or schedule.get("noon"):
                times.append("noon")
            if medication.get("evening") or medication.get("afternoon") or schedule.get("evening"):
                times.append("evening")
            if medication.get("night") or schedule.get("night"):
                times.append("night")
        
        # Skip if no times
        if not times:
            logger.warning(f"No schedule times for medication: {name}")
            return None
        
        # Get meal context if available
        notes = medication.get("notes", "") or medication.get("instructions", "")
        meal_context = None
        if "ក្រោយបាយ" in notes or "after meal" in notes.lower():
            meal_context = "after_meal"
        elif "មុនបាយ" in notes or "before meal" in notes.lower():
            meal_context = "before_meal"
        
        # Determine dose amount per time
        dose_amount = medication.get("dose", 1) or schedule.get("dose_per_time", 1)
        
        # Build reminders for each time slot
        reminders = []
        for time_slot in times:
            time_lower = time_slot.lower() if isinstance(time_slot, str) else str(time_slot)
            slot_info = STANDARD_TIME_SLOTS.get(time_lower, {"time_24h": "08:00", "display": "Morning"})
            
            # Generate Khmer instruction (includes meal context directly)
            instruction_kh = ""
            if KHMER_INSTRUCTIONS_AVAILABLE:
                instruction_kh = generate_khmer_instruction(
                    quantity=dose_amount,
                    unit=unit,
                    context=meal_context  # Context is included in instruction_kh
                )
            else:
                instruction_kh = f"Take {dose_amount} {unit}"
                if meal_context == "after_meal":
                    instruction_kh += " after meal"
                elif meal_context == "before_meal":
                    instruction_kh += " before meal"
            
            reminder = {
                "time": slot_info["display"],
                "time_24h": slot_info["time_24h"],
                "dosage_quantity": dose_amount,
                "dosage_unit": unit,
                "instruction_kh": instruction_kh
            }
            
            reminders.append(reminder)
        
        # Build medicine entry
        medicine = {
            "name": full_name,
            "total_quantity": total_quantity,
            "unit": unit,
            "reminders": reminders
        }
        
        # Add optional fields
        duration = medication.get("duration_days")
        if duration:
            medicine["duration_days"] = duration
        
        if notes and not meal_context:
            medicine["notes"] = notes
        
        return medicine
        
    except Exception as e:
        logger.error(f"Error processing medication: {e}")
        return None


def combine_prescriptions(
    prescriptions: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """
    Combine multiple prescription results into a single unified response.
    
    Args:
        prescriptions: List of individual prescription processing results
        
    Returns:
        Combined prescription_data with all patients
    """
    all_patients = []
    total_medicines = 0
    total_reminders = 0
    
    for rx in prescriptions:
        if rx.get("success"):
            patients = rx.get("prescription_data", {}).get("patients", [])
            all_patients.extend(patients)
            metadata = rx.get("metadata", {})
            total_medicines += metadata.get("total_medicines", 0)
            total_reminders += metadata.get("total_reminders", 0)
    
    return {
        "success": True,
        "prescription_data": {
            "patients": all_patients
        },
        "metadata": {
            "total_prescriptions": len(prescriptions),
            "total_patients": len(all_patients),
            "total_medicines": total_medicines,
            "total_reminders": total_reminders,
            "generated_at": datetime.now().isoformat()
        }
    }

