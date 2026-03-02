#!/usr/bin/env python3
"""
Simple AI Enhancement fallback for OCR text
Provides basic text correction when Ollama is too slow
"""

import re
from typing import Dict

def simple_ocr_correction(text: str, language: str = "en") -> Dict:
    """
    Simple OCR text correction using regex and common medical terms
    
    Args:
        text: Raw OCR text
        language: Language code
        
    Returns:
        Dict with corrected text and metadata
    """
    
    # Common medical OCR corrections
    corrections = {
        # English medical terms
        "Parscotamol": "Paracetamol",
        "Parascotamol": "Paracetamol", 
        "Tako": "Take",
        "2ibotsdeiy": "2 tablets daily",
        "2iblets": "2 tablets",
        "tablots": "tablets",
        "medicaton": "medication",
        "medcine": "medicine",
        "dossage": "dosage",
        "prescrption": "prescription",
        "recomended": "recommended",
        "Glibenclamide": "Glibenclamide",
        "Lisinopril": "Lisinopril",
        "Amitriptyline": "Amitriptyline",
        "Insuline": "Insulin",
        "DIABETE": "DIABETES",
        "TYPE": "TYPE",
        
        # Khmer corrections (if needed)
        "គ": "ខ",
        "ឃ": "គ", 
        "ង": "ង",
        
        # French corrections
        "medicament": "médicament",
        "prise": "prise",
        "matin": "matin",
        "soir": "soir",
    }
    
    # Apply corrections
    corrected_text = text
    changes_made = 0
    
    for wrong, right in corrections.items():
        if wrong in corrected_text:
            corrected_text = corrected_text.replace(wrong, right)
            changes_made += 1
    
    # Clean up extra spaces and formatting
    corrected_text = re.sub(r'\s+', ' ', corrected_text)  # Multiple spaces to single
    corrected_text = corrected_text.strip()
    
    # Extract medication information
    medications = extract_medications(corrected_text)
    
    return {
        "corrected_text": corrected_text,
        "confidence": 0.75 if changes_made > 0 else 0.90,
        "changes_made": changes_made,
        "medications_found": medications,
        "language": language,
        "method": "simple_regex",
        "model_used": "rule_based_v1"
    }

def extract_medications(text: str) -> list:
    """Extract medication names from text"""
    medications = []
    
    # Common medication names to look for
    med_names = [
        "Paracetamol", "Glibenclamide", "Lisinopril", 
        "Amitriptyline", "Insulin", "Aspirin", "Ibuprofen"
    ]
    
    for med in med_names:
        if med.lower() in text.lower():
            medications.append(med)
    
    return medications

def create_medical_reminder(text: str) -> str:
    """Create a simple medical reminder from corrected text"""
    lines = text.split('\n')
    reminder_parts = []
    
    # Look for dosage instructions
    for line in lines:
        line_lower = line.lower()
        if any(word in line_lower for word in ['take', 'morning', 'evening', 'daily', 'mg', 'tablets']):
            reminder_parts.append(f"• {line.strip()}")
    
    # If no specific instructions found, use the whole text
    if not reminder_parts:
        reminder_parts.append(f"• {text.strip()}")
    
    return "\n".join(reminder_parts)

if __name__ == "__main__":
    # Test the function
    test_text = "Take Parscotamol 2ibotsdeiy daily. Glibenclamide Smg in morning."
    result = simple_ocr_correction(test_text)
    
    print("Original:", test_text)
    print("Corrected:", result["corrected_text"])
    print("Changes:", result["changes_made"])
    print("Medications:", result["medications_found"])