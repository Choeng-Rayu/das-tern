"""
Medical Safety Constraints
Ensures AI does not provide medical advice or diagnose conditions
"""

import logging
import re
from typing import Tuple, List

logger = logging.getLogger(__name__)

# Forbidden patterns - AI must not generate these
FORBIDDEN_PATTERNS = [
    r"you (should|must|need to) (take|use|try)",
    r"i (recommend|suggest|advise)",
    r"you (have|might have|probably have) (a |an )?[a-z]+ (disease|condition|disorder|syndrome)",
    r"diagnosis[:\s]",
    r"(stop|discontinue) (taking|using)",
    r"(increase|decrease) (your |the )?dos(e|age)",
    r"alternative[s]? (to|for|include)",
    r"you (don't |do not )?need (to see |a )?doctor",
]

# Allowed patterns - descriptions only
ALLOWED_PATTERNS = [
    r"this medication is (commonly )?used (for|to)",
    r"(paracetamol|ibuprofen|amoxicillin|etc\.?) is a[n]?",
    r"take as (directed|prescribed)",
    r"follow (your )?doctor'?s instructions",
    r"consult (your )?(doctor|pharmacist|healthcare provider)",
]


def check_response_safety(text: str) -> Tuple[bool, List[str]]:
    """
    Check if LLM response is safe (no medical advice).
    
    Args:
        text: LLM generated text
        
    Returns:
        Tuple of (is_safe, violations)
    """
    if not text:
        return True, []
    
    violations = []
    text_lower = text.lower()
    
    for pattern in FORBIDDEN_PATTERNS:
        if re.search(pattern, text_lower):
            violations.append(f"Contains forbidden pattern: {pattern}")
    
    return len(violations) == 0, violations


def sanitize_response(text: str) -> str:
    """
    Remove or replace unsafe content from LLM response.
    
    Args:
        text: Raw LLM response
        
    Returns:
        Sanitized response
    """
    if not text:
        return text
    
    sanitized = text
    
    # Add disclaimer if needed
    is_safe, violations = check_response_safety(text)
    
    if not is_safe:
        logger.warning(f"Sanitizing unsafe response: {violations}")
        
        # Replace unsafe patterns with safe alternatives
        replacements = [
            (r"you should take", "the prescription indicates to take"),
            (r"i recommend", "the prescription indicates"),
            (r"i suggest", "please follow the prescription"),
            (r"stop taking", "consult your doctor about"),
            (r"increase the dose", "consult your doctor about dosage"),
        ]
        
        for pattern, replacement in replacements:
            sanitized = re.sub(pattern, replacement, sanitized, flags=re.IGNORECASE)
    
    return sanitized


def add_medical_disclaimer(text: str) -> str:
    """Add standard medical disclaimer to response."""
    disclaimer = (
        "\n\n⚠️ This information is for reference only. "
        "Always follow your doctor's instructions and consult a healthcare "
        "professional for medical advice."
    )
    
    return text + disclaimer


def validate_medication_description(description: str) -> Tuple[bool, str]:
    """
    Validate that medication description is informational only.
    
    Args:
        description: AI-generated medication description
        
    Returns:
        Tuple of (is_valid, cleaned_description)
    """
    is_safe, violations = check_response_safety(description)
    
    if is_safe:
        return True, description
    
    # Clean and return
    cleaned = sanitize_response(description)
    
    # If still not safe after cleaning, return generic description
    is_safe_now, _ = check_response_safety(cleaned)
    if not is_safe_now:
        return False, "A medication prescribed by your doctor. Follow the prescribed dosage."
    
    return True, cleaned


def is_diagnosis_request(text: str) -> bool:
    """Check if user is asking for diagnosis."""
    diagnosis_patterns = [
        r"what (do i|could i|might i) have",
        r"what'?s wrong with me",
        r"diagnose",
        r"what (disease|condition|illness)",
        r"why (am i|do i) (feel|have|experience)",
        r"is (this|it) (cancer|serious|dangerous)",
    ]
    
    text_lower = text.lower()
    return any(re.search(p, text_lower) for p in diagnosis_patterns)


def is_drug_advice_request(text: str) -> bool:
    """Check if user is asking for drug recommendations."""
    advice_patterns = [
        r"what (should|can) i take",
        r"recommend (a |any )?(medicine|drug|medication)",
        r"what'?s (good|best) for",
        r"should i (take|try|use)",
        r"can i (take|use) .+ instead",
    ]
    
    text_lower = text.lower()
    return any(re.search(p, text_lower) for p in advice_patterns)


def get_safe_refusal(request_type: str) -> str:
    """Get appropriate refusal message for unsafe requests."""
    refusals = {
        "diagnosis": (
            "I'm sorry, but I cannot diagnose medical conditions. "
            "Please consult a healthcare professional for proper diagnosis."
        ),
        "drug_advice": (
            "I cannot recommend medications. Please consult your doctor or "
            "pharmacist for medication advice."
        ),
        "default": (
            "I can only help you understand your existing prescription. "
            "For medical advice, please consult a healthcare professional."
        )
    }
    
    return refusals.get(request_type, refusals["default"])

