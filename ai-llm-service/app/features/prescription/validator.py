"""
Prescription Validator
Validates enhanced prescription data for safety
"""

import logging
import re
from typing import Dict, Any, List, Tuple

logger = logging.getLogger(__name__)

# Known dangerous combinations (simplified - would be more extensive in production)
DANGEROUS_COMBINATIONS = [
    (["warfarin"], ["aspirin", "ibuprofen", "naproxen"]),
    (["metformin"], ["alcohol"]),
    (["ssri", "sertraline", "fluoxetine"], ["maoi", "tramadol"]),
]

# Maximum reasonable dosages (simplified)
MAX_DOSAGES = {
    "paracetamol": {"daily_mg": 4000, "single_mg": 1000},
    "ibuprofen": {"daily_mg": 2400, "single_mg": 800},
    "amoxicillin": {"daily_mg": 3000, "single_mg": 1000},
}


def validate_prescription(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validate prescription data for safety issues.
    
    Args:
        data: Enhanced prescription data
        
    Returns:
        Validation result with warnings/errors
    """
    result = {
        "is_valid": True,
        "warnings": [],
        "errors": [],
        "medication_validations": []
    }
    
    medications = data.get("structured_data", {}).get("medications", [])
    
    if not medications:
        result["warnings"].append("No medications found in prescription")
        return result
    
    # Validate each medication
    for med in medications:
        med_validation = validate_medication(med)
        result["medication_validations"].append(med_validation)
        
        if med_validation.get("errors"):
            result["errors"].extend(med_validation["errors"])
            result["is_valid"] = False
        
        if med_validation.get("warnings"):
            result["warnings"].extend(med_validation["warnings"])
    
    # Check for drug interactions
    interaction_warnings = check_interactions(medications)
    result["warnings"].extend(interaction_warnings)
    
    return result


def validate_medication(med: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validate a single medication.
    
    Args:
        med: Medication dict
        
    Returns:
        Validation result for this medication
    """
    result = {
        "medication": med.get("name", "Unknown"),
        "warnings": [],
        "errors": []
    }
    
    name = med.get("name", "").lower()
    strength = med.get("strength", "")
    schedule = med.get("dosage_schedule", {})
    
    # Check for missing critical info
    if not name or name == "unknown":
        result["errors"].append("Medication name is missing or unreadable")
    
    if not strength:
        result["warnings"].append(f"{name}: Strength not specified")
    
    if not schedule:
        result["warnings"].append(f"{name}: Dosage schedule not specified")
    
    # Check dosage limits
    dosage_check = check_dosage_limits(name, strength, schedule)
    if dosage_check:
        result["warnings"].extend(dosage_check)
    
    # Check confidence
    confidence = med.get("confidence", 1.0)
    if confidence < 0.7:
        result["warnings"].append(f"{name}: Low OCR confidence ({confidence:.0%}) - verify manually")
    
    return result


def check_dosage_limits(
    name: str, 
    strength: str, 
    schedule: Dict[str, float]
) -> List[str]:
    """Check if dosage is within safe limits."""
    warnings = []
    
    # Extract mg from strength
    mg_match = re.search(r"(\d+(?:\.\d+)?)\s*mg", strength.lower())
    if not mg_match:
        return warnings
    
    single_dose_mg = float(mg_match.group(1))
    
    # Calculate daily dose
    doses_per_day = sum(1 for v in schedule.values() if v and v > 0)
    daily_mg = single_dose_mg * doses_per_day
    
    # Check against known limits
    for drug, limits in MAX_DOSAGES.items():
        if drug in name:
            if single_dose_mg > limits.get("single_mg", float("inf")):
                warnings.append(f"{name}: Single dose ({single_dose_mg}mg) exceeds recommended maximum ({limits['single_mg']}mg)")
            
            if daily_mg > limits.get("daily_mg", float("inf")):
                warnings.append(f"{name}: Daily dose ({daily_mg}mg) may exceed recommended maximum ({limits['daily_mg']}mg)")
    
    return warnings


def check_interactions(medications: List[Dict[str, Any]]) -> List[str]:
    """Check for known drug interactions."""
    warnings = []
    
    med_names = [m.get("name", "").lower() for m in medications]
    
    for group1, group2 in DANGEROUS_COMBINATIONS:
        found1 = [n for n in med_names if any(g in n for g in group1)]
        found2 = [n for n in med_names if any(g in n for g in group2)]
        
        if found1 and found2:
            warnings.append(
                f"Potential interaction: {', '.join(found1)} with {', '.join(found2)} - "
                "consult pharmacist"
            )
    
    return warnings


def is_safe_for_patient(
    medications: List[Dict[str, Any]],
    patient_conditions: List[str] = None
) -> Tuple[bool, List[str]]:
    """
    Check if medications are safe for patient with known conditions.
    
    Args:
        medications: List of medications
        patient_conditions: Known patient conditions
        
    Returns:
        Tuple of (is_safe, warnings)
    """
    warnings = []
    
    if not patient_conditions:
        return True, warnings
    
    # Simplified condition-drug contraindications
    contraindications = {
        "kidney disease": ["ibuprofen", "naproxen", "nsaid"],
        "liver disease": ["paracetamol", "acetaminophen"],
        "asthma": ["aspirin", "ibuprofen", "beta-blocker"],
        "pregnancy": ["warfarin", "ibuprofen", "methotrexate"],
    }
    
    conditions_lower = [c.lower() for c in patient_conditions]
    
    for condition, drugs in contraindications.items():
        if condition in conditions_lower:
            for med in medications:
                med_name = med.get("name", "").lower()
                if any(drug in med_name for drug in drugs):
                    warnings.append(
                        f"Caution: {med.get('name')} may be contraindicated with {condition}"
                    )
    
    return len(warnings) == 0, warnings

