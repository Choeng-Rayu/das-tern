#!/usr/bin/env python3
"""
System Verification Script
Tests all components and connections
"""
import asyncio
import httpx
import sys
from pathlib import Path


async def test_ollama_connection():
    """Test Ollama connection"""
    print("🔍 Testing Ollama connection...")
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get("http://localhost:11434/api/tags")
            if response.status_code == 200:
                models = response.json().get('models', [])
                print(f"   ✅ Ollama connected - {len(models)} models available")
                return True
            else:
                print(f"   ❌ Ollama returned status {response.status_code}")
                return False
    except Exception as e:
        print(f"   ❌ Cannot connect to Ollama: {e}")
        return False


async def test_ai_service():
    """Test AI service"""
    print("\n🔍 Testing AI service (port 8002)...")
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get("http://localhost:8002/health")
            if response.status_code == 200:
                data = response.json()
                print(f"   ✅ AI service healthy")
                print(f"      Status: {data.get('status')}")
                print(f"      Service: {data.get('service')}")
                print(f"      Ollama: {data.get('ollama_connected')}")
                return True
            else:
                print(f"   ❌ AI service returned status {response.status_code}")
                return False
    except httpx.ConnectError:
        print(f"   ❌ Cannot connect to AI service on port 8002")
        print(f"      Start it with: python -m uvicorn app.main_ollama:app --reload --port 8002")
        return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


async def test_extraction():
    """Test extraction endpoint"""
    print("\n🔍 Testing extraction endpoint...")
    try:
        test_text = """
        Hospital: Test Hospital
        Patient: John Doe
        Diagnosis: Common Cold
        
        Medications:
        1. Paracetamol 500mg - Take 1 tablet twice daily for 3 days
        2. Amoxicillin 250mg - Take 1 capsule three times daily for 5 days
        
        Doctor: Dr. Smith
        Date: 2026-02-13
        """
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "http://localhost:8002/api/v1/extract/complete",
                json={
                    "ocr_text": test_text,
                    "user_id": "test-user",
                    "language": "en"
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                medications = result.get('extracted_data', {}).get('medications', [])
                print(f"   ✅ Extraction successful")
                print(f"      Medications found: {len(medications)}")
                print(f"      Confidence: {result.get('confidence', 0):.0%}")
                return True
            else:
                print(f"   ❌ Extraction failed with status {response.status_code}")
                print(f"      Response: {response.text[:200]}")
                return False
    except Exception as e:
        print(f"   ❌ Extraction test failed: {e}")
        return False


async def test_ocr_files():
    """Test OCR file processing"""
    print("\n🔍 Testing OCR file processing...")
    data_dir = Path("data")
    if not data_dir.exists():
        print("   ❌ data/ directory not found")
        return False
    
    ocr_files = list(data_dir.glob("*.json"))
    test_files = [f for f in ocr_files if 'test' in f.name or 'ocr_result' in f.name]
    
    if not test_files:
        print("   ⚠️  No OCR test files found")
        return True
    
    print(f"   Found {len(test_files)} OCR files")
    for f in test_files[:3]:  # Test first 3
        print(f"      • {f.name}")
    
    return True


async def main():
    """Run all tests"""
    print("=" * 70)
    print("🔧 DasTern System Verification")
    print("=" * 70)
    
    results = {
        'Ollama': await test_ollama_connection(),
        'AI Service': await test_ai_service(),
        'Extraction': await test_extraction(),
        'OCR Files': await test_ocr_files()
    }
    
    print("\n" + "=" * 70)
    print("📊 SUMMARY")
    print("=" * 70)
    
    for component, status in results.items():
        icon = "✅" if status else "❌"
        print(f"   {icon} {component}")
    
    all_passed = all(results.values())
    
    if all_passed:
        print("\n🎉 All systems operational!")
        print("\n💡 You can now:")
        print("   • Process OCR files: python tools/process_ocr_file.py data/test.json")
        print("   • Use the API: curl http://localhost:8002/health")
        return 0
    else:
        print("\n⚠️  Some components need attention")
        print("\n💡 Fix the issues above and run this script again")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
