#!/usr/bin/env python3
"""Direct OCR test script - bypasses HTTP layer."""
import json
import sys
from pathlib import Path

# Add app to path
sys.path.insert(0, str(Path(__file__).parent))

from app.pipeline.ocr_engine import KiriOCREngine
from app.pipeline.orchestrator import PipelineOrchestrator
from app.pipeline.formatter import build_dynamic_universal, build_extraction_summary
from app.config import settings

def main():
    image_path = Path("/home/rayu/das-tern/ocr/images_for_test/image2.png")
    output_path = Path("/home/rayu/das-tern/ocr/result_test.json")
    
    if not image_path.exists():
        print(f"❌ Image not found: {image_path}")
        return 1
    
    print(f"📸 Loading image: {image_path}")
    image_bytes = image_path.read_bytes()
    print(f"   Size: {len(image_bytes)} bytes")
    
    print("🔧 Initializing OCR engine...")
    engine = KiriOCREngine()
    
    print("🔄 Creating orchestrator...")
    orchestrator = PipelineOrchestrator(
        engine, 
        max_dimension=settings.PREPROCESS_MAX_DIMENSION
    )
    
    print("🚀 Running OCR extraction...")
    result = orchestrator.extract(image_bytes, filename=image_path.name)

    if not result.get("success"):
        print(f"❌ Extraction failed: {result}")
        return 1

    # Convert ParsedPrescription to JSON-serializable format
    parsed = result["parsed"]
    processing_time_ms = result["processing_time_ms"]
    pipeline_meta = result.get("pipeline_metadata", {})

    print("🔄 Converting to universal format...")
    data = build_dynamic_universal(
        parsed,
        processing_time_ms=processing_time_ms,
        image_width=image_bytes.__len__(),  # placeholder
        image_height=image_bytes.__len__(),  # placeholder
        image_format="png",
        file_size_bytes=len(image_bytes),
        preprocessing_applied=pipeline_meta.get("preprocessing_applied", []),
    )
    summary = build_extraction_summary(data, processing_time_ms)

    final_result = {
        "success": True,
        "data": data,
        "extraction_summary": summary
    }

    print("💾 Saving result to JSON...")
    output_path.write_text(json.dumps(final_result, indent=2, ensure_ascii=False))
    print(f"✅ Result saved: {output_path}")
    print(f"   Size: {output_path.stat().st_size} bytes")

    # Print summary
    meds = data["prescription"]["medications"]["items"]
    print(f"\n📋 Summary:")
    print(f"   Total medications: {len(meds)}")
    for m in meds:
        name = m["medication"]["name"]["full_text"]
        qty = m["dosing"]["total_quantity"]["value"]
        print(f"   - {name}: qty={qty}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

