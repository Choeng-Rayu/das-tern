"""
Process OCR file and extract prescription data

Usage:
    python tools/process_ocr_file.py <ocr_file_path> [user_id]

Example:
    python tools/process_ocr_file.py data/ocr_prescription_20260203.json user-123
"""
import json
import asyncio
import httpx
from pathlib import Path
import sys


async def process_ocr_file(ocr_file_path: str, user_id: str = None):
    """
    Process OCR JSON file and extract prescription data
    
    Args:
        ocr_file_path: Path to OCR JSON file
        user_id: Optional user ID to link prescription
    """
    print(f"🔍 Processing OCR file: {ocr_file_path}")
    print("=" * 70)
    
    # Load OCR file
    with open(ocr_file_path, 'r', encoding='utf-8') as f:
        ocr_data = json.load(f)
    
    # Extract full text - support multiple OCR formats
    full_text = ocr_data.get('full_text') or ocr_data.get('corrected_text') or ocr_data.get('text', '')
    
    # If full_text is empty, try to extract from blocks
    if not full_text or full_text.strip() == '':
        blocks = ocr_data.get('blocks', [])
        if blocks:
            text_parts = []
            for block in blocks:
                # Get raw_text from block if available
                raw_text = block.get('raw_text', '')
                if raw_text:
                    text_parts.append(raw_text)
                else:
                    # Otherwise, extract from lines
                    lines = block.get('lines', [])
                    for line in lines:
                        line_text = line.get('text', '')
                        if line_text:
                            text_parts.append(line_text)
            
            full_text = '\n'.join(text_parts)
            print(f"📦 Extracted text from {len(blocks)} blocks")
    
    if not full_text or full_text.strip() == '':
        print("❌ Error: No text found in OCR file")
        print("   Expected fields: 'full_text', 'corrected_text', 'text', or 'blocks'")
        print(f"   Available fields: {list(ocr_data.keys())}")
        return
    
    print(f"\n📝 OCR Text Preview:")
    print(full_text[:200] + "...")
    print(f"\n📊 OCR Confidence: {ocr_data.get('overall_confidence', 0):.2%}")
    print(f"🌐 Languages: {', '.join(ocr_data.get('languages', []))}")
    print(f"⚠️  Needs Review: {ocr_data.get('needs_review', False)}")
    
    # Call AI extraction API
    print(f"\n🤖 Calling AI extraction service...")
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            response = await client.post(
                "http://localhost:8002/api/v1/extract/complete",
                json={
                    "ocr_text": full_text,
                    "user_id": user_id,
                    "language": "mixed"
                }
            )
            
            response.raise_for_status()
            result = response.json()
            
            # Print results
            print("\n✅ Extraction successful!")
            print("=" * 70)
            
            extracted = result['extracted_data']
            
            # Print diagnosis
            print(f"\n🏥 DIAGNOSIS:")
            diagnoses = extracted.get('diagnosis', [])
            if diagnoses:
                for diag in diagnoses:
                    print(f"   • {diag}")
            else:
                print("   • No diagnosis found")
            
            # Print medications
            medications = extracted.get('medications', [])
            print(f"\n💊 MEDICATIONS ({len(medications)}):")
            if medications:
                for i, med in enumerate(medications, 1):
                    print(f"\n   {i}. {med.get('medication_name', 'Unknown')}")
                    if med.get('strength'):
                        print(f"      Strength: {med.get('strength')}")
                    if med.get('dosage'):
                        print(f"      Dosage: {med.get('dosage')}")
                    if med.get('frequency'):
                        print(f"      Frequency: {med.get('frequency')}")
                    if med.get('duration'):
                        print(f"      Duration: {med.get('duration')}")
                    if med.get('instructions_english'):
                        print(f"      Instructions: {med.get('instructions_english')}")
            else:
                print("   • No medications clearly readable")
            
            # Print prescriber info
            print(f"\n👨‍⚕️ PRESCRIBER:")
            prescriber_name = extracted.get('prescriber_name', 'N/A')
            prescriber_facility = extracted.get('prescriber_facility', 'N/A')
            print(f"   Name: {prescriber_name}")
            print(f"   Facility: {prescriber_facility}")
            
            # Print metadata
            print(f"\n📅 METADATA:")
            print(f"   Date: {extracted.get('prescription_date', 'N/A')}")
            print(f"   Language: {extracted.get('language_detected', 'N/A')}")
            print(f"   Confidence: {result.get('confidence', 0):.2%}")
            print(f"   Model: {result.get('model_used', 'N/A')}")
            
            # Save extraction result
            output_file = Path(ocr_file_path).parent / f"extracted_{Path(ocr_file_path).stem}.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            
            print(f"\n💾 Saved extraction to: {output_file}")
            
            # Show database-ready data
            print(f"\n📦 DATABASE-READY DATA:")
            print(f"   Prescription ID: (to be generated)")
            print(f"   User ID: {extracted.get('user_id', 'N/A')}")
            print(f"   Medications count: {len(medications)}")
            print(f"   Ready for insertion: {'✅' if medications else '⚠️  No medications'}")
            
            return result
            
        except httpx.ConnectError:
            print(f"\n❌ Connection Error: Cannot reach AI service")
            print("   Make sure the service is running:")
            print("   python -m uvicorn app.main_ollama:app --reload --port 8002")
            return None
        except httpx.HTTPStatusError as e:
            print(f"\n❌ HTTP Error: {e.response.status_code}")
            print(f"   Response: {e.response.text}")
            return None
        except httpx.HTTPError as e:
            print(f"\n❌ API Error: {e}")
            return None
        except Exception as e:
            print(f"\n❌ Error: {e}")
            return None


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python process_ocr_file.py <ocr_file_path> [user_id]")
        print("\nExample:")
        print("  python tools/process_ocr_file.py data/ocr_prescription_20260203.json user-123")
        print("\nOr test with existing OCR files:")
        print("  python tools/process_ocr_file.py data/ocr_result_20260128_215749.json")
        sys.exit(1)
    
    ocr_file = sys.argv[1]
    user_id = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Check if file exists
    if not Path(ocr_file).exists():
        print(f"❌ Error: File not found: {ocr_file}")
        print(f"\nAvailable OCR files in data/:")
        data_dir = Path("data")
        if data_dir.exists():
            ocr_files = list(data_dir.glob("ocr_*.json"))
            if ocr_files:
                for f in ocr_files:
                    print(f"  • {f}")
            else:
                print("  (no OCR files found)")
        sys.exit(1)
    
    # Run async processing
    asyncio.run(process_ocr_file(ocr_file, user_id))


if __name__ == "__main__":
    main()
