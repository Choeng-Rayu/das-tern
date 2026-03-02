#!/usr/bin/env python3
"""
Process OCR Data and Generate Detailed Correction Report

This script:
1. Takes raw OCR data (like your friend's file)
2. Processes it with AI
3. Generates a detailed JSON report showing all corrections made
4. Saves before/after comparison
"""

import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Any

# Add parent directory to path so we can import from app/
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.features.prescription.enhancer import PrescriptionEnhancer

def detect_corrections(raw_text: str, enhanced_data: Dict) -> List[Dict]:
    """
    Detect what corrections were made by comparing raw OCR to enhanced output
    """
    corrections = []
    
    # Check medication name corrections
    for med in enhanced_data.get('medications', []):
        med_name = med.get('medication_name', '')
        
        # Common OCR errors to check
        possible_errors = [
            med_name.replace('l', '1'),  # paracetamol -> paracetamo1
            med_name.replace('o', '0'),  # 
            med_name[:4],  # Truncated (Esome -> Esomeprazole)
            med_name.lower(),
        ]
        
        for error_variant in possible_errors:
            if error_variant in raw_text and error_variant != med_name.lower():
                corrections.append({
                    "type": "medication_name",
                    "field": "medication_name",
                    "original": error_variant,
                    "corrected": med_name,
                    "confidence": "high",
                    "reason": "OCR spelling error correction"
                })
                break
        
        # Check strength corrections (s00mg -> 500mg)
        strength = med.get('strength', '')
        if strength and 'mg' in strength:
            # Check for number-letter confusion
            strength_variants = [
                strength.replace('0', 'o'),  # 500 -> s00 (OCR mistake)
                strength.replace('5', 's'),
                strength.replace('1', 'l'),
            ]
            
            for variant in strength_variants:
                if variant in raw_text and variant != strength:
                    corrections.append({
                        "type": "dosage_strength",
                        "field": "strength",
                        "original": variant,
                        "corrected": strength,
                        "confidence": "high",
                        "reason": "OCR number/letter confusion"
                    })
                    break
    
    # Check for ignored irrelevant data
    ignored_patterns = [
        ("prescription_number", r"[A-Z]{3,}\d{6,}", "Prescription ID numbers"),
        ("patient_id", r"\d{8,}-\d{4,}", "Patient ID numbers"),
        ("phone_number", r"\d{3}-\d{3}-\d{3,}", "Phone numbers"),
    ]
    
    import re
    for field, pattern, description in ignored_patterns:
        matches = re.findall(pattern, raw_text)
        for match in matches:
            corrections.append({
                "type": "ignored_data",
                "field": field,
                "original": match,
                "corrected": None,
                "confidence": "high",
                "reason": f"{description} (intentionally ignored)"
            })
    
    return corrections

def generate_correction_report(ocr_file: str, output_file: str = None):
    """
    Generate detailed correction report from OCR file
    """
    print("="*80)
    print("  📊 OCR CORRECTION REPORT GENERATOR")
    print("="*80)
    
    # Load OCR file
    print(f"\n📂 Loading: {ocr_file}")
    with open(ocr_file, 'r', encoding='utf-8') as f:
        ocr_data = json.load(f)
    
    raw_text = ocr_data.get('raw_text', '')
    
    print(f"✅ Loaded {len(raw_text)} characters of OCR text")
    print(f"   Confidence: {ocr_data.get('overall_confidence', 0):.1f}%")
    print(f"   Low confidence blocks: {len(ocr_data.get('low_confidence_blocks', []))}")
    
    # Process with AI
    print("\n🤖 Processing with AI (this takes 4-5 seconds)...")
    
    try:
        enhancer = PrescriptionEnhancer()
        enhanced_data = enhancer.parse_prescription(raw_text)
        
        if not enhanced_data:
            print("❌ AI processing failed")
            return None
        
        print("✅ AI processing complete")
        
    except Exception as e:
        print(f"❌ Error during AI processing: {e}")
        import traceback
        traceback.print_exc()
        return None
    
    # Detect corrections
    print("\n🔍 Analyzing corrections...")
    corrections = detect_corrections(raw_text, enhanced_data)
    print(f"✅ Detected {len(corrections)} corrections")
    
    # Build comprehensive report
    report = {
        "report_metadata": {
            "generated_at": datetime.now().isoformat(),
            "ocr_source_file": ocr_file,
            "processor": "DasTern AI-LLM Service",
            "model": "LLaMA 3.1 8B via Ollama"
        },
        
        "ocr_input": {
            "raw_text": raw_text,
            "overall_confidence": ocr_data.get('overall_confidence'),
            "confidence_level": ocr_data.get('confidence_level'),
            "total_blocks": ocr_data.get('block_count'),
            "low_confidence_blocks": len(ocr_data.get('low_confidence_blocks', [])),
            "needs_manual_review": ocr_data.get('needs_manual_review'),
            "primary_language": ocr_data.get('primary_language')
        },
        
        "ai_enhanced_output": enhanced_data,
        
        "corrections_made": {
            "total_corrections": len(corrections),
            "by_type": {},
            "details": corrections
        },
        
        "extraction_summary": {
            "extracted_fields": list(enhanced_data.keys()),
            "medications_found": len(enhanced_data.get('medications', [])),
            "patient_info_complete": all([
                enhanced_data.get('patient_name') is not None or enhanced_data.get('age') is not None,
            ]),
            "prescription_usable": len(enhanced_data.get('medications', [])) > 0
        },
        
        "quality_metrics": {
            "input_confidence": ocr_data.get('overall_confidence', 0),
            "output_confidence": enhanced_data.get('confidence_score', 0) * 100 if enhanced_data.get('confidence_score') else None,
            "improvement": None,
            "corrections_made": len(corrections),
            "data_completeness": calculate_completeness(enhanced_data)
        }
    }
    
    # Calculate correction types
    for correction in corrections:
        corr_type = correction['type']
        report['corrections_made']['by_type'][corr_type] = \
            report['corrections_made']['by_type'].get(corr_type, 0) + 1
    
    # Calculate improvement
    if report['quality_metrics']['input_confidence'] and report['quality_metrics']['output_confidence']:
        report['quality_metrics']['improvement'] = \
            report['quality_metrics']['output_confidence'] - report['quality_metrics']['input_confidence']
    
    # Determine output filename
    if not output_file:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_file = f"correction_report_{timestamp}.json"
    
    # Save report
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Report saved: {output_file}")
    
    # Print summary
    print("\n" + "="*80)
    print("  📈 CORRECTION SUMMARY")
    print("="*80)
    
    print(f"\n🔴 INPUT (Raw OCR):")
    print(f"   • Confidence: {report['ocr_input']['overall_confidence']:.1f}%")
    print(f"   • Low quality blocks: {report['ocr_input']['low_confidence_blocks']}")
    print(f"   • Needs review: {report['ocr_input']['needs_manual_review']}")
    
    print(f"\n🟢 OUTPUT (AI Enhanced):")
    print(f"   • Confidence: {report['quality_metrics']['output_confidence']:.1f}%")
    print(f"   • Medications extracted: {report['extraction_summary']['medications_found']}")
    print(f"   • Data completeness: {report['quality_metrics']['data_completeness']:.1f}%")
    
    print(f"\n🔧 CORRECTIONS MADE: {report['corrections_made']['total_corrections']}")
    for corr_type, count in report['corrections_made']['by_type'].items():
        print(f"   • {corr_type.replace('_', ' ').title()}: {count}")
    
    if corrections:
        print("\n📝 CORRECTION DETAILS:")
        for i, corr in enumerate(corrections[:5], 1):  # Show first 5
            print(f"   {i}. {corr['original']} → {corr['corrected'] or '[IGNORED]'}")
            print(f"      Reason: {corr['reason']}")
        
        if len(corrections) > 5:
            print(f"   ... and {len(corrections) - 5} more corrections")
    
    print(f"\n✅ Full report saved to: {output_file}")
    print("\n" + "="*80)
    
    return report

def calculate_completeness(data: Dict) -> float:
    """Calculate how complete the extracted data is"""
    required_fields = [
        'age', 'gender', 'date', 'prescriber_name', 
        'prescriber_facility', 'medications'
    ]
    
    present = sum(1 for field in required_fields if data.get(field))
    return (present / len(required_fields)) * 100

def main():
    if len(sys.argv) < 2:
        print("Usage: python process_with_corrections.py <ocr_file.json> [output_file.json]")
        print("\nExample:")
        print("  python process_with_corrections.py data/ocr_test_image2_20260127_162549.json")
        print("\nThis will generate a detailed correction report showing:")
        print("  • What was corrected (spelling, dosages, etc.)")
        print("  • What was ignored (IDs, phone numbers, etc.)")
        print("  • Before/after comparison")
        print("  • Quality metrics")
        return
    
    ocr_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(ocr_file):
        print(f"❌ Error: File not found: {ocr_file}")
        return
    
    generate_correction_report(ocr_file, output_file)

if __name__ == "__main__":
    main()
