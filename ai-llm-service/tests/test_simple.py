"""
Simple test of prescription extraction
"""

import os
import sys
sys.path.append('/Users/macbook/CADT/DasTern/ai-llm-service')

from app.core.generation import generate

def test_simple_extraction():
    """Test simple extraction with clear instructions"""
    
    # Set environment
    os.environ['OLLAMA_HOST'] = 'http://localhost:11434'
    
    print("🧪 Testing Simple Prescription Extraction")
    print("=" * 60)
    
    prompt = """Extract the patient name and medication from this prescription and return as JSON:

Dr. Smith
Patient: John Doe
Age: 30

Rx:
Paracetamol 500mg
Take 1 tablet twice daily

Return JSON format:
{"patient_name": "extracted name", "medication_name": "extracted medicine"}"""
    
    result = generate(prompt, temperature=0.1)
    
    print("Raw LLaMA Response:")
    print("-" * 40)
    print(result)
    print("-" * 40)
    
    # Try to extract JSON
    if result and '{' in result:
        start = result.find('{')
        end = result.rfind('}') + 1
        if start >= 0 and end > start:
            json_part = result[start:end]
            print("\\nExtracted JSON:")
            print(json_part)
            
            try:
                import json
                parsed = json.loads(json_part)
                print("\\n✅ JSON Parsing Success!")
                print(f"Patient: {parsed.get('patient_name')}")
                print(f"Medication: {parsed.get('medication_name')}")
                return True
            except Exception as e:
                print(f"\\n❌ JSON Parsing Failed: {e}")
                return False
        else:
            print("\\n❌ No JSON found in response")
            return False
    else:
        print("\\n❌ No response or no JSON structure")
        return False

if __name__ == "__main__":
    success = test_simple_extraction()
    print(f"\\n🎯 Result: {'SUCCESS' if success else 'FAILED'}")