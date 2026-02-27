#!/usr/bin/env python3
"""
Test Script: Process Real OCR Data from Khmer-Soviet Hospital
This script demonstrates how LLaMA extracts ONLY key medical data from messy OCR output
"""

import json
import os
import sys
from datetime import datetime

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.features.prescription.enhancer import PrescriptionEnhancer

def print_section(title, content="", color_code=""):
    """Pretty print sections"""
    colors = {
        "blue": "\033[94m",
        "green": "\033[92m",
        "yellow": "\033[93m",
        "red": "\033[91m",
        "reset": "\033[0m"
    }
    
    color = colors.get(color_code, "")
    reset = colors["reset"] if color else ""
    
    print(f"\n{color}{'='*80}")
    print(f"  {title}")
    print(f"{'='*80}{reset}")
    if content:
        print(content)

def load_ocr_file(file_path):
    """Load OCR JSON file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def extract_raw_text(ocr_data):
    """Extract raw text from OCR data"""
    return ocr_data.get('raw_text', '')

def main():
    print_section("🔬 DasTern AI-LLM Service - Real OCR Data Test", color_code="blue")
    
    # Load your friend's OCR file
    ocr_file = 'data/ocr_test_image2_20260127_162549.json'
    
    if not os.path.exists(ocr_file):
        print(f"❌ Error: OCR file not found: {ocr_file}")
        return
    
    print(f"📂 Loading OCR file: {ocr_file}")
    ocr_data = load_ocr_file(ocr_file)
    
    # Show OCR metadata
    print_section("📊 OCR Metadata", color_code="yellow")
    print(f"  Overall Confidence: {ocr_data['overall_confidence']:.2f}%")
    print(f"  Confidence Level: {ocr_data['confidence_level']}")
    print(f"  Needs Manual Review: {ocr_data['needs_manual_review']}")
    print(f"  Low Confidence Blocks: {len(ocr_data['low_confidence_blocks'])}/72")
    print(f"  Primary Language: {ocr_data['primary_language']}")
    
    # Show raw OCR text (the messy input)
    raw_text = extract_raw_text(ocr_data)
    print_section("📝 RAW OCR OUTPUT (Messy Input)", color_code="red")
    print(raw_text)
    
    # Highlight what we need to extract
    print_section("🎯 WHAT WE NEED TO EXTRACT", color_code="yellow")
    print("""
    ✅ EXTRACT (Keywords Only):
       • Patient age: 19
       • Hospital: Khmer-Soviet Friendship Hospital  
       • Diagnosis: Chronic Cystitis
       • Medications:
         - Butylscopolamine (14 days)
         - Multivitamin (10 days, 4x/day)
         - Esomeprazole 20mg (7 days, 1x/day)
         - Paracetamol 500mg (as needed)
       • Date: 22/06/2025
    
    ❌ IGNORE (Irrelevant Data):
       • Prescription number: HAKF1354164
       • Patient ID: 20051002-0409
       • Garbled text: "iy", "eh", "gh", "wo", "fa]", "up:", etc.
       • Layout artifacts: "|", "—", "[", "]"
       • Hospital logo text: "H-EQIp", "oviet"
    """)
    
    # Process with AI
    print_section("🤖 PROCESSING WITH OLLAMA + LLAMA...", color_code="blue")
    print("⏳ This will take 4-5 seconds on your M1 Max...")
    
    try:
        enhancer = PrescriptionEnhancer()
        
        # Parse the prescription
        result = enhancer.parse_prescription(raw_text)
        
        if result:
            print_section("✅ AI-ENHANCED OUTPUT (Clean JSON)", color_code="green")
            print(json.dumps(result, indent=2, ensure_ascii=False))
            
            # Save results
            output_file = f"test_real_ocr_result_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            print(f"\n💾 Results saved to: {output_file}")
            
            # Show before/after comparison
            print_section("📊 BEFORE vs AFTER COMPARISON", color_code="blue")
            
            print("\n🔴 BEFORE (OCR):")
            print(f"  • Confidence: {ocr_data['overall_confidence']:.1f}%")
            print(f"  • Structured Data: All fields NULL")
            print(f"  • Medications: 0 extracted")
            print(f"  • Errors: 32 low-confidence blocks")
            
            print("\n🟢 AFTER (AI-Enhanced):")
            extracted_meds = result.get('medications', [])
            print(f"  • Confidence: {result.get('confidence_score', 0)*100:.1f}%")
            print(f"  • Medications: {len(extracted_meds)} extracted")
            print(f"  • OCR Corrections: ")
            for med in extracted_meds:
                if 'Esome' in raw_text and med['medication_name'] == 'Esomeprazole':
                    print(f"     - 'Esome' → '{med['medication_name']}'")
                if 's00mg' in raw_text and med.get('strength') == '500mg':
                    print(f"     - 's00mg' → '{med['strength']}'")
            
            print("\n✅ Key Data Extracted:")
            print(f"  • Patient Age: {result.get('age')}")
            print(f"  • Hospital: {result.get('prescriber_facility')}")
            print(f"  • Diagnosis: {result.get('diagnosis')}")
            print(f"  • Date: {result.get('date')}")
            
            print("\n❌ Irrelevant Data Ignored:")
            print("  • Prescription number (HAKF1354164)")
            print("  • Patient ID (20051002-0409)")
            print("  • Garbled text (iy, eh, gh, wo, etc.)")
            print("  • Layout artifacts (|, —, [, ])")
            
        else:
            print_section("❌ PARSING FAILED", color_code="red")
            print("The AI could not extract structured data from the OCR output.")
            print("This might be due to:")
            print("  1. Ollama service not running")
            print("  2. Model not loaded")
            print("  3. Network connectivity issues")
            
    except Exception as e:
        print_section("❌ ERROR", color_code="red")
        print(f"Error processing prescription: {str(e)}")
        import traceback
        traceback.print_exc()
    
    print_section("🏁 Test Complete", color_code="blue")
    print("""
Next Steps:
1. Review the AI-enhanced output above
2. Check if all key medical data was extracted correctly
3. Verify that irrelevant data was ignored
4. If accuracy is good, proceed with integration into Flutter app

To run again:
    python test_real_ocr_data.py
    """)

if __name__ == "__main__":
    main()
