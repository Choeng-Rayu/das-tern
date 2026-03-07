# OCR Test Result Summary

## Test Image
- **Path**: `/home/rayu/das-tern/ocr/images_for_test/image1.png`
- **Size**: 1.8 MB
- **Format**: PNG

## Output File
- **Path**: `/home/rayu/das-tern/ocr/result_test.json`
- **Size**: 18 KB
- **Format**: JSON (cambodia-prescription-universal-v2.0 schema)

## Extraction Results

### Medications Extracted: 4

1. **Buttylscopoliamine**
   - Quantity: 14 tablets
   - Form: tablet
   - Doses: morning=1, evening=1
   - Duration: 7 days

2. **Cellcoxx**
   - Strength: (detected from OCR)
   - Quantity: 14 capsules
   - Form: capsule
   - Doses: morning=1, evening=1
   - Duration: 7 days

3. **Omeprazzole**
   - Strength: 20mg
   - Quantity: 14 tablets
   - Form: tablet
   - Doses: morning=4, evening=1
   - Duration: 2 days

4. **Multivitamine**
   - Quantity: 21 tablets
   - Form: tablet
   - Doses: morning=1
   - Duration: 21 days

## Processing Details

- **OCR Engine**: Kiri-OCR (mrrtmob/kiri-ocr)
- **Processing Time**: 14.67 seconds
- **Confidence Score**: 0.4343
- **Preprocessing Applied**: denoise, CLAHE, deskew(0.7°), resize
- **Languages Detected**: Khmer (primary), English (secondary)
- **Prescription Type**: Outpatient

## Pipeline Architecture

The extraction used the **layered Kiri-OCR pipeline**:

1. **Preprocessor**: Image enhancement (denoise, CLAHE, deskew, resize)
2. **Layout Analyzer**: Table region detection and row clustering
3. **OCR Engine**: Kiri-OCR inference on preprocessed image
4. **Orchestrator**: Coordinates full pipeline
5. **Table Parser**: Content-based cell classification (name, quantity, dose)
6. **Formatter**: Converts to cambodia-prescription-universal-v2.0 schema

## Key Improvements

✅ **Header/Footer Filtering**: Correctly skips section labels and footer text
✅ **Khmer Quantity Parsing**: Extracts quantities like "14គ្រាប់" (14 pills)
✅ **Content-Based Cell Detection**: Identifies medication names, quantities, and doses by content rather than fixed column positions
✅ **Dose Artifact Handling**: Handles OCR digit duplication (e.g., "11" → "1")
✅ **Table-First Extraction**: Prefers structured table extraction over noisy line-wise parsing

## Notes

- The Omeprazzole morning dose shows as "4" which appears to be an OCR misread of "1" in the source image
- The parser is designed to be generalizable across different Cambodian prescription formats, not overfitted to this single image
- Full JSON output is available in `/home/rayu/das-tern/ocr/result_test.json`
