# Cambodian Prescription OCR - JSON Formats

## Overview

This directory contains the JSON schema formats and examples for extracting prescription data from Cambodian medical documents. The system supports **mixed-language prescriptions** (Khmer, English, and French) and various hospital systems across Cambodia.

---

## 📋 Files in This Directory

### Format Definitions

1. **`final.result.format.expected.json`** (Phase 2)
   - **Universal Dynamic Schema** for all Cambodian prescriptions
   - Supports multiple hospital systems, layouts, and languages
   - Comprehensive and flexible structure
   - Production-ready format

2. **`prescription.dynamic.format.json`** (Legacy)
   - Earlier version of dynamic format
   - Contains basic schema structure

3. **`result.already.defined.json`** (Legacy)
   - Simplified format for reminder conversion
   - Missing many fields from comprehensive extraction

### Extraction Examples

4. **`prescription_image_1_static_with_bbox.json`** (Phase 1)
   - **Static format with bounding boxes**
   - Direct extraction from prescription image
   - Every field includes precise `bbox: [x1, y1, x2, y2]` coordinates
   - Raw data organized by visual sections

5. **`prescription_image_1_dynamic_populated.json`** (Phase 2)
   - **Dynamic format populated with real data**
   - Same prescription using universal schema
   - Shows how static extraction maps to dynamic format
   - Includes confidence scores and metadata

---

## 🎯 Two-Phase Approach

### Phase 1: Static Format with Bounding Boxes

**Goal:** Extract **everything visible** in the prescription image with precise coordinates.

**Characteristics:**
- ✅ Every text element has a bounding box `[x1, y1, x2, y2]`
- ✅ Organized by visual layout (header, patient section, table, footer)
- ✅ Preserves original text in all languages
- ✅ Includes confidence scores for each field
- ✅ Minimal transformation - close to raw OCR output

**Use Cases:**
- Training ML models
- Debugging OCR accuracy
- Creating annotation tools
- Visual verification of extraction

**Example Structure:**
```json
{
  "header_section": {
    "hospital_name_khmer": {
      "value": "មន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត",
      "bbox": [105, 75, 230, 95],
      "confidence": 0.96
    }
  },
  "medication_table": {
    "medications": [
      {
        "medication_name": {
          "value": "Butylscopolamine 10mg",
          "bbox": [75, 438, 265, 500],
          "confidence": 0.96
        }
      }
    ]
  }
}
```

---

### Phase 2: Dynamic Format (Universal Schema)

**Goal:** Create a **standardized format** that works for **all prescription types** across Cambodia.

**Characteristics:**
- ✅ Flexible field structure (supports optional fields)
- ✅ Multi-language support (Khmer, English, French)
- ✅ Normalized medication schedules
- ✅ Rich metadata and clinical information
- ✅ Ready for reminder system integration
- ✅ Validation-friendly structure

**Use Cases:**
- Reminder system integration
- Cross-hospital data exchange
- Analytics and reporting
- Mobile app consumption
- API responses

**Key Features:**

#### 1. Multi-Language Support
```json
{
  "healthcare_facility": {
    "name": {
      "english": "Khmer-Soviet Friendship Hospital",
      "khmer": "មន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត",
      "french": null
    }
  }
}
```

#### 2. Flexible Medication Schedule
```json
{
  "schedule": {
    "type": "time_based",
    "time_slots": [
      {
        "period": "morning",
        "time_range": "06:00-08:00",
        "dose": {
          "value": "1",
          "numeric": 1.0,
          "unit": "tablet"
        },
        "enabled": true
      }
    ]
  }
}
```

#### 3. Comprehensive Metadata
```json
{
  "metadata": {
    "extraction_info": {
      "extracted_at": "2026-02-15T14:53:56+07:00",
      "confidence_score": 0.94,
      "languages_detected": {
        "primary": "khmer",
        "secondary": ["english"]
      }
    }
  }
}
```

---

## 🏥 Supported Prescription Types

The universal schema accommodates various formats:

### By Facility Type
- ✅ **Public hospitals** (H-EQIP, HIS, etc.)
- ✅ **Private clinics** (custom formats)
- ✅ **Pharmacies** (dispensing records)
- ✅ **Health centers** (simplified prescriptions)

### By Visit Type
- ✅ **Outpatient (OPD)** prescriptions
- ✅ **Inpatient (IPD)** medication orders
- ✅ **Emergency** prescriptions
- ✅ **Discharge** summaries
- ✅ **Follow-up** prescriptions

### By Layout Type
- ✅ **Table-based** schedules (like H-EQIP)
- ✅ **List-based** formats
- ✅ **Handwritten** prescriptions
- ✅ **Digital/EMR** printouts
- ✅ **Mixed** formats

---

## 🔧 Implementation Strategy

### Step 1: OCR Processing
```
Image → Tesseract/PaddleOCR → Raw Text + Bounding Boxes
```

### Step 2: Static Extraction (Phase 1)
```
Raw OCR → Section Detection → Field Extraction → Static JSON
```
- Detect visual sections (header, patient info, table, footer)
- Extract all text with coordinates
- Preserve original language and format
- Store confidence scores

### Step 3: Dynamic Transformation (Phase 2)
```
Static JSON → Field Mapping → Normalization → Dynamic JSON
```
- Map static fields to dynamic schema
- Normalize dates, times, numeric values
- Calculate derived fields (daily totals, quantities)
- Validate against schema rules

### Step 4: Reminder Conversion
```
Dynamic JSON → Medication Extraction → Reminder Schedule → Mobile App
```
- Extract medication items
- Generate time-based reminders
- Create Khmer instructions
- Package for mobile consumption

---

## 📐 Schema Design Principles

### 1. **Nullable by Default**
Almost all fields are `"value | null"` to handle missing data gracefully.

### 2. **Language Flexibility**
Fields that may appear in multiple languages have separate properties:
```json
{
  "english": "string | null",
  "khmer": "string | null",
  "french": "string | null"
}
```

### 3. **Bounding Box Support**
Important fields include optional bounding boxes for visual verification and AI training.

### 4. **Confidence Tracking**
Extraction confidence scores help identify fields needing human review.

### 5. **Type Safety**
Numeric values are stored both as strings (original) and parsed numbers:
```json
{
  "value": "10mg",
  "numeric": 10.0,
  "unit": "mg"
}
```

---

## 🎨 Example: Medication Extraction

### From Image (Static)
```json
{
  "medication_name": {
    "value": "Butylscopolamine 10mg",
    "bbox": [75, 438, 265, 500]
  },
  "morning_6_8": {
    "value": "1",
    "bbox": [443, 438, 494, 500]
  },
  "duration": {
    "value": "14 ថ្ងៃ",
    "bbox": [270, 438, 360, 500]
  }
}
```

### To Standardized Format (Dynamic)
```json
{
  "medication": {
    "name": {
      "brand_name": "Butylscopolamine",
      "generic_name": "Butylscopolamine",
      "full_text": "Butylscopolamine 10mg"
    },
    "strength": {
      "value": "10mg",
      "numeric": 10.0,
      "unit": "mg"
    }
  },
  "dosing": {
    "duration": {
      "value": 14,
      "unit": "days",
      "khmer_text": "14 ថ្ងៃ"
    },
    "schedule": {
      "time_slots": [
        {
          "period": "morning",
          "time_range": "06:00-08:00",
          "dose": {
            "numeric": 1.0,
            "unit": "tablet"
          },
          "enabled": true
        }
      ]
    }
  }
}
```

### To Reminder (App Format)
```json
{
  "medication_name": "Butylscopolamine 10mg",
  "duration_days": 14,
  "reminders": [
    {
      "time": "07:00",
      "dose": 1,
      "instruction_khmer": "ញុំថ្នាំ 1 គ្រាប់ ម៉ោង 6-8 ព្រឹក"
    }
  ]
}
```

---

## 🌍 Language Support

### Khmer (ភាសាខ្មែរ)
- Primary language in most Cambodian prescriptions
- Complex script requires specialized OCR
- Common medical terms: `រោគវិនិច្ឆ័យ` (diagnosis), `ថ្នាំ` (medicine)
- Time periods: `ព្រឹក` (morning), `ល្ងាច` (evening), `យប់` (night)

### English
- Medical terminology (drug names, diagnoses)
- Hospital systems (H-EQIP)
- International standards (ICD codes, units)

### French
- Legacy influence from colonial period
- Some older prescriptions and private clinics
- Medical terms: "comprimé" (tablet), "gouttes" (drops)

---

## ✅ Validation Rules

### Required Fields (Minimum Viable Prescription)
- ✅ At least one medication
- ✅ Medication name
- ✅ Basic dosing information (duration or schedule)
- ✅ Issue date

### Data Quality Checks
- Confidence scores above threshold (e.g., 0.7)
- Numeric fields are parseable
- Dates are valid
- Medication names match known databases
- Dosing values are reasonable

### Business Logic Validation
- Duration doesn't exceed reasonable limits
- Daily dose totals are safe
- Drug interactions are flagged
- Allergy checks are performed

---

## 🚀 Next Steps

### For OCR Service Development
1. Implement static extraction with bbox support
2. Build section detection (header, patient, table, footer)
3. Handle table structure variations
4. Support handwritten text recognition

### For Dynamic Transformation
1. Create field mapping rules
2. Implement normalization logic
3. Add validation layer
4. Build confidence scoring

### For Reminder Integration
1. Extract medication schedules
2. Generate Khmer instructions
3. Create notification payloads
4. Handle edge cases (PRN medications, complex schedules)

---

## 📊 Performance Metrics

### OCR Quality Targets
- **Printed text:** ≥95% accuracy
- **Handwritten signatures:** ≥70% confidence detection
- **Khmer script:** ≥90% accuracy
- **Mixed language:** ≥85% accuracy
- **Table detection:** ≥95% success rate

### Processing Speed
- **Static extraction:** <2 seconds per prescription
- **Dynamic transformation:** <0.5 seconds
- **End-to-end:** <3 seconds total

---

## 📝 Notes

### Design Decisions

1. **Why two formats?**
   - Static: Preserves raw OCR output for debugging and training
   - Dynamic: Standardized for business logic and app integration

2. **Why so many optional fields?**
   - Cambodian prescriptions vary widely in completeness
   - Better to have optional fields than fail validation

3. **Why include bounding boxes?**
   - Enable visual verification
   - Support AI model training
   - Help identify OCR errors

4. **Why multi-language fields?**
   - Prescriptions often mix Khmer, English, and French
   - Need to preserve all language variants for user display

### Known Challenges

- **Handwritten text** - Lower accuracy, needs review
- **Photo quality** - Affects OCR confidence
- **Table variations** - Different hospitals use different layouts
- **Numeric confusion** - Khmer numerals vs. Arabic numerals
- **Abbreviations** - Medical shorthand varies by facility

---

## 🔗 Related Documents

- `/ocr_service/prompt.ocr.md` - OCR processing guidelines
- `/docs/about_das_tern/flows/reminder_flow/` - Reminder system documentation
- API documentation (when available)

---

## 📞 Contact

For questions about these formats, refer to the project documentation or contact the development team.

**Last Updated:** 2026-02-15

**Schema Version:** 2.0 (Universal Dynamic Format)