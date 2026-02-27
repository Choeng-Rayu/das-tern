#!/usr/bin/env python3
"""
Simple Training Tool - Works directly with your OCR JSON format

Usage:
  python3 add_training_simple.py <ocr_file.json>

This tool:
1. Loads your OCR JSON file (with "corrected_text" field)
2. You provide the CORRECT extracted data
3. Saves as training example for AI to learn
"""

import json
import os
import sys

TRAINING_FILE = "data/training/sample_prescriptions.jsonl"

def print_header(text):
    print(f"\n{'='*70}")
    print(f"  {text}")
    print(f"{'='*70}\n")

def extract_text_from_ocr(ocr_data):
    """Extract text from your OCR format"""
    # Method 1: Use corrected_text if available
    if 'corrected_text' in ocr_data:
        return ocr_data['corrected_text']
    
    # Method 2: Concatenate from raw array
    if 'raw' in ocr_data:
        words = [item['text'] for item in ocr_data['raw']]
        return ' '.join(words)
    
    # Method 3: Use reminder_text
    if 'reminder_text' in ocr_data:
        return ocr_data['reminder_text']
    
    return None

def main():
    print_header("🎓 Simple Training Example Creator")
    
    if len(sys.argv) < 2:
        print("Usage: python3 add_training_simple.py <ocr_file.json>")
        print("\nExample:")
        print("  python3 add_training_simple.py data/my_prescription.json")
        print("\nYour OCR JSON should have 'corrected_text' or 'raw' field")
        return
    
    ocr_file = sys.argv[1]
    
    if not os.path.exists(ocr_file):
        print(f"❌ File not found: {ocr_file}")
        return
    
    # Load OCR file
    print(f"📂 Loading: {ocr_file}")
    with open(ocr_file, 'r', encoding='utf-8') as f:
        ocr_data = json.load(f)
    
    # Extract text
    raw_text = extract_text_from_ocr(ocr_data)
    
    if not raw_text:
        print("❌ Could not extract text from OCR file")
        print("   Expected 'corrected_text', 'raw', or 'reminder_text' field")
        return
    
    print("✅ OCR text extracted")
    print("\n" + "-"*70)
    print("RAW OCR TEXT (what AI receives):")
    print("-"*70)
    print(raw_text[:500] + "..." if len(raw_text) > 500 else raw_text)
    print("-"*70)
    
    # Show OCR stats if available
    if 'stats' in ocr_data:
        stats = ocr_data['stats']
        print(f"\n📊 OCR Quality: {stats.get('avg_confidence', 0):.1f}% average confidence")
    
    # Now get correct data from user
    print_header("📝 Enter the CORRECT Extracted Data")
    print("This is what the AI should learn to extract:\n")
    
    # Patient info
    print("👤 PATIENT INFORMATION:")
    patient_name = input("  Patient name (Khmer or English): ").strip() or None
    
    age_input = input("  Age (number only): ").strip()
    age = int(age_input) if age_input.isdigit() else None
    
    gender_input = input("  Gender (M/F or leave blank): ").strip().upper()
    gender = "Male" if gender_input == "M" else "Female" if gender_input == "F" else None
    
    print("\n🏥 HOSPITAL/DOCTOR:")
    doctor = input("  Doctor name: ").strip() or None
    hospital = input("  Hospital/Clinic: ").strip() or None
    
    print("\n📅 OTHER INFO:")
    date = input("  Date (DD/MM/YYYY or leave blank): ").strip() or None
    diagnosis = input("  Diagnosis: ").strip() or None
    
    # Medications
    print("\n💊 MEDICATIONS:")
    print("Enter each medication. Type 'done' when finished.\n")
    
    medications = []
    med_num = 1
    
    while True:
        print(f"--- Medication #{med_num} ---")
        med_name = input("  Name (CORRECT spelling, or 'done'): ").strip()
        
        if med_name.lower() == 'done':
            break
        
        med_strength = input("  Strength (e.g., 500mg): ").strip() or None
        
        # Schedule
        print("  Schedule (enter doses for each time, or 0):")
        morning = input("    Morning: ").strip()
        morning = int(morning) if morning.isdigit() else 0
        
        noon = input("    Noon: ").strip()
        noon = int(noon) if noon.isdigit() else 0
        
        evening = input("    Evening: ").strip()
        evening = int(evening) if evening.isdigit() else 0
        
        night = input("    Night: ").strip()
        night = int(night) if night.isdigit() else 0
        
        duration_input = input("  Duration (days): ").strip()
        duration_days = int(duration_input) if duration_input.isdigit() else None
        
        medication = {
            "medication_name": med_name,
            "strength": med_strength,
            "schedule": {
                "morning": morning,
                "noon": noon,
                "evening": evening,
                "night": night
            },
            "duration_days": duration_days
        }
        
        # Remove None values
        medication = {k: v for k, v in medication.items() if v is not None}
        medications.append(medication)
        med_num += 1
        print()
    
    # Build output JSON
    output_data = {}
    
    if patient_name:
        output_data["patient_name"] = patient_name
    if age:
        output_data["age"] = age
    if gender:
        output_data["gender"] = gender
    if doctor:
        output_data["prescriber_name"] = doctor
    if hospital:
        output_data["prescriber_facility"] = hospital
    if date:
        output_data["prescription_date"] = date
    if diagnosis:
        output_data["diagnosis"] = diagnosis
    
    output_data["medications"] = medications
    output_data["language_detected"] = "mixed_khmer_english"
    output_data["confidence_score"] = 0.90
    
    # Show preview
    print_header("📋 Preview Training Example")
    
    print("INPUT (messy OCR):")
    print("-"*70)
    preview_input = raw_text[:200] + "..." if len(raw_text) > 200 else raw_text
    print(preview_input)
    print("-"*70)
    
    print("\nOUTPUT (clean data AI should extract):")
    print("-"*70)
    output_json = json.dumps(output_data, indent=2, ensure_ascii=False)
    print(output_json)
    print("-"*70)
    
    # Confirm save
    confirm = input("\n💾 Save this training example? (yes/no): ").strip().lower()
    
    if confirm in ['yes', 'y']:
        # Create training example
        example = {
            "user": raw_text,
            "assistant": output_json
        }
        
        # Save to file
        os.makedirs(os.path.dirname(TRAINING_FILE), exist_ok=True)
        
        with open(TRAINING_FILE, 'a', encoding='utf-8') as f:
            f.write(json.dumps(example, ensure_ascii=False) + '\n')
        
        # Count examples
        with open(TRAINING_FILE, 'r', encoding='utf-8') as f:
            total = sum(1 for line in f if line.strip())
        
        print(f"\n✅ Training example saved!")
        print(f"📊 Total examples: {total}")
        print(f"📁 File: {TRAINING_FILE}")
        
        print("\n🎓 What this teaches the AI:")
        print(f"   • Extract {len(medications)} medications from messy OCR")
        print("   • Correct spelling errors automatically")
        print("   • Ignore irrelevant data (codes, IDs, noise)")
        print("   • Structure data for prescription reminders")
        
    else:
        print("\n❌ Not saved.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Cancelled")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
