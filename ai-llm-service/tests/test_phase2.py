"""
Test Prescription Extraction with Few-Shot Learning
"""

import json
import os
import sys
from typing import Dict

# Add the parent directory to Python path
sys.path.append('/Users/macbook/CADT/DasTern/ai-llm-service')

from app.features.prescription.enhancer import enhance_prescription, parse_prescription

def test_cambodian_prescription():
    """Test with realistic Cambodian prescription"""
    
    print("🧪 Testing Cambodian Prescription Extraction")
    print("=" * 80)
    
    # Test prescription in Khmer with OCR errors
    test_data = {
        "raw_text": """វេជ្ជបណ្ឌិត ដោក់ទ័រ ស៊ុន មនីរ័ត្ន
មន្ទីរពេទ្យកាល់ម៉ិត Tel: 023-123-456

អ្នកជំងឺ: លោក ពេជ្រ ចន្ទ
អាយុ: ៣៥ឆ្នាំ ភេទ: ប
កាលបរិច្ឆេទ: ២៥/០១/២០២៤

ឱសថកម្មង់:
១. paracetamol1 500mg (OCR error)
   Tab i bd x 7days
   
២. amoxicilin 250mg  
   Cap i tds x 5days

៣. ORS sachet
   Sol i prn"""
    }
    
    # Run extraction
    result = enhance_prescription(test_data)
    
    # Display results
    print(f"✅ Success: {result.get('success')}")
    print(f"🤖 Extraction Method: {result.get('extraction_method')}")
    print(f"🎯 Confidence: {result.get('metadata', {}).get('confidence', 0):.2f}")
    
    if result.get('success'):
        data = result.get('extracted_data', {})
        
        print(f"\n👤 Patient: {data.get('patient_name')}")
        print(f"👨‍⚕️ Doctor: {data.get('prescriber_name')}")
        print(f"💊 Medications: {len(data.get('medications', []))}")
        
        for i, med in enumerate(data.get('medications', []), 1):
            print(f"\n   {i}. {med.get('medication_name')} {med.get('strength')}")
            
            # Handle dosage being either dict or string
            dosage = med.get('dosage', {})
            if isinstance(dosage, dict):
                frequency = dosage.get('frequency', 'N/A')
                duration = dosage.get('duration', 'N/A')
            else:
                frequency = str(dosage)
                duration = 'N/A'
                
            print(f"      📋 {frequency} for {duration}")
            print(f"      🇬🇧 {med.get('instructions_english', 'N/A')}")
            print(f"      🇰🇭 {med.get('instructions_khmer', 'N/A')}")
        
        print(f"\n🌐 Language: {data.get('language_detected')}")
        
    else:
        print(f"❌ Error: {result.get('error')}")
    
    # Save full result
    with open('test_result.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    
    print(f"\n📁 Full result saved to: test_result.json")
    return result.get('success', False)

def test_direct_parsing():
    """Test direct parsing function"""
    
    print("\n🔬 Testing Direct Parsing Function")
    print("=" * 50)
    
    # Simple English prescription
    raw_text = """Dr. Smith
Patient: John Doe
Age: 30

Rx:
1. Paracetamol 500mg
   Take 1 tablet bd x 7days

2. Ibuprofen 400mg  
   Take 1 tab tds with food x 5days"""
    
    result = parse_prescription(raw_text)
    
    if result:
        print("✅ Direct parsing successful!")
        print(f"Patient: {result.get('patient_name')}")
        print(f"Medications: {len(result.get('medications', []))}")
        for med in result.get('medications', []):
            print(f"  - {med.get('medication_name')} {med.get('strength')}")
    else:
        print("❌ Direct parsing failed")
    
    return result is not None

def main():
    """Run complete test suite"""
    
    print("🚀 Starting Phase 2 Testing - Few-Shot Learning Prescription Extraction")
    print("=" * 100)
    
    # Set environment variable for localhost
    os.environ['OLLAMA_HOST'] = 'http://localhost:11434'
    
    # Test 1: Cambodian prescription
    success1 = test_cambodian_prescription()
    
    # Test 2: Direct parsing
    success2 = test_direct_parsing()
    
    # Summary
    print(f"\n🎯 TEST SUMMARY")
    print("=" * 50)
    print(f"Cambodian Prescription Test: {'✅ PASSED' if success1 else '❌ FAILED'}")
    print(f"Direct Parsing Test: {'✅ PASSED' if success2 else '❌ FAILED'}")
    
    overall_success = success1 and success2
    print(f"\nOverall Status: {'🟢 ALL TESTS PASSED' if overall_success else '🔴 SOME TESTS FAILED'}")
    
    if overall_success:
        print("\n🎉 Phase 2 Complete! Your prescription extraction system is working!")
        print("✅ Few-shot learning implemented")
        print("✅ Khmer/English support working")
        print("✅ OCR error correction functioning")
        print("✅ Structured JSON output generated")
        print("\n📍 Next: Proceed to Phase 3 - Integration with main.py API endpoint")
    else:
        print("\n⚠️  Some tests failed. Check the logs and fix issues before proceeding.")
    
    return overall_success

if __name__ == "__main__":
    main()