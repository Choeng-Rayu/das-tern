"""OCR pipeline test script.

Processes all test images from test_space/images_for_test/ and stores
extraction results in test_space/results/ as result_ocr_{n}.json.
"""
import sys
import os
import json
import time

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, project_root)

from app.pipeline.orchestrator import PipelineOrchestrator


def run_tests():
    """Run OCR extraction on all test images and store results."""
    images_dir = os.path.join(project_root, "test_space", "images_for_test")
    results_dir = os.path.join(project_root, "test_space", "results")
    os.makedirs(results_dir, exist_ok=True)

    # Test images mapped to their result number
    test_images = [
        ("image.png", 1),
        ("image1.png", 2),
        ("image2.png", 3),
    ]

    orch = PipelineOrchestrator()
    all_results = []

    for filename, test_num in test_images:
        image_path = os.path.join(images_dir, filename)
        if not os.path.exists(image_path):
            print(f"[SKIP] {filename} not found")
            continue

        print(f"\n{'='*60}")
        print(f"Test {test_num}: {filename}")
        print(f"{'='*60}")

        with open(image_path, "rb") as f:
            image_bytes = f.read()

        start_time = time.time()
        result = orch.extract(image_bytes, filename)
        elapsed = time.time() - start_time

        # Add test metadata
        result["test_metadata"] = {
            "test_number": test_num,
            "source_image": filename,
            "image_size_bytes": len(image_bytes),
            "processing_time_seconds": round(elapsed, 2),
        }

        # Save result
        result_path = os.path.join(results_dir, f"result_ocr_{test_num}.json")
        with open(result_path, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)

        # Print summary
        if result["success"]:
            summary = result.get("extraction_summary", {})
            med_count = summary.get("total_medications", 0)
            confidence = summary.get("confidence_score", 0)
            print(f"  Status:      SUCCESS")
            print(f"  Medications: {med_count}")
            print(f"  Confidence:  {confidence:.1%}")
            print(f"  Time:        {elapsed:.2f}s")

            # Show medication details
            med_section = result["data"].get("prescription", {}).get("medications", {})
            meds = med_section.get("items", []) if isinstance(med_section, dict) else []
            for med in meds:
                if isinstance(med, str):
                    continue
                name = med["medication"]["name"]["brand_name"]
                dur = med["dosing"]["duration"]
                doses = []
                for slot in med["dosing"]["schedule"]["time_slots"]:
                    p = slot["period"][:3]
                    v = slot["dose"]["value"]
                    doses.append(f"{p}={v}")
                print(f"    {name}: dur={dur['value']} {dur['unit']}  [{' '.join(doses)}]")
        else:
            print(f"  Status: FAILED - {result.get('message', 'unknown error')}")
            print(f"  Time:   {elapsed:.2f}s")

        print(f"  Saved:  {result_path}")
        all_results.append((test_num, filename, result["success"], elapsed))

    # Summary table
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    for test_num, filename, success, elapsed in all_results:
        status = "PASS" if success else "FAIL"
        print(f"  Test {test_num}: {filename:15s} {status}  ({elapsed:.2f}s)")

    passed = sum(1 for _, _, s, _ in all_results if s)
    total = len(all_results)
    print(f"\n  Result: {passed}/{total} tests passed")


if __name__ == "__main__":
    run_tests()
