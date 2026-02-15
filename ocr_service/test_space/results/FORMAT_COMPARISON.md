# Format Comparison Summary

## Quick Reference Guide

This document provides a side-by-side comparison of the different JSON formats for prescription data extraction.

---

## Format Types

| Format | File | Phase | Purpose |
|--------|------|-------|---------|
| **Static with BBox** | `prescription_image_1_static_with_bbox.json` | Phase 1 | Raw OCR extraction with coordinates |
| **Dynamic Universal** | `final.result.format.expected.json` | Phase 2 | Schema definition for all prescriptions |
| **Dynamic Populated** | `prescription_image_1_dynamic_populated.json` | Phase 2 | Example using universal schema |
| **Reminder Format** | `result.already.defined.json` | Legacy | Simplified for app integration |

---

## When to Use Each Format

### Static Format with BBox (Phase 1)
**Use when:**
- Building or training OCR models
- Debugging extraction accuracy
- Creating annotation tools
- Need precise location data
- Quality assurance and verification

**Don't use when:**
- Building application features
- Need standardized data structure
- Working with multiple prescription types

### Dynamic Universal Format (Phase 2)
**Use when:**
- Integrating with reminder system
- Building APIs
- Storing in database
- Need flexibility for different hospitals
- Processing varied prescription layouts
- Analytics and reporting

**Don't use when:**
- Need raw OCR output
- Building OCR training datasets
- Debugging text extraction issues

### Reminder Format (Legacy)
**Use when:**
- Quick prototyping
- Simple reminder-only applications

**Don't use for:**
- New development (use Dynamic Universal instead)
- Complex prescription data
- Multi-hospital support

---

## Field Coverage Comparison

| Category | Static BBox | Dynamic Universal | Reminder (Legacy) |
|----------|-------------|-------------------|-------------------|
| Hospital Info | ✅ Basic | ✅ Comprehensive | ⚠️ Limited |
| Patient Info | ✅ All visible | ✅ Structured | ⚠️ Basic |
| Diagnosis | ✅ Raw text | ✅ Multi-language | ❌ None |
| Medications | ✅ Table structure | ✅ Normalized | ✅ Basic |
| Dosing Schedule | ✅ Raw values | ✅ Standardized | ✅ Simplified |
| Prescriber | ✅ With signature bbox | ✅ Credentials | ✅ Name only |
| Bounding Boxes | ✅ All fields | ⚠️ Optional | ❌ None |
| Confidence Scores | ✅ Per field | ⚠️ By section | ❌ None |
| Multi-language | ✅ As-is | ✅ Separated | ❌ Mixed |
| Metadata | ⚠️ Basic | ✅ Rich | ❌ None |

---

## Data Structure Examples

### Patient Information

#### Static Format
```json
{
  "patient_section": {
    "patient_id": {
      "label": "លេខកូដ",
      "value": "HAKF1354164",
      "bbox": [35, 145, 200, 165],
      "confidence": 0.98
    },
    "age": {
      "label": "អាយុ",
      "value": "19",
      "unit": "ឆ្នាំ",
      "bbox": [520, 145, 610, 165],
      "confidence": 0.99
    }
  }
}
```

#### Dynamic Universal
```json
{
  "patient": {
    "identification": {
      "patient_id": {
        "value": "HAKF1354164",
        "id_type": "hospital_id",
        "bbox": [35, 145, 200, 165]
      }
    },
    "personal_info": {
      "age": {
        "value": 19,
        "unit": "years",
        "khmer_text": "19 ឆ្នាំ",
        "bbox": [520, 145, 610, 165]
      }
    }
  }
}
```

#### Reminder Format (Legacy)
```json
{
  "patient": {
    "id": "HAKF1354164",
    "age": 19,
    "age_unit": "years"
  }
}
```

---

### Medication Dosing

#### Static Format
```json
{
  "medication_name": {
    "value": "Butylscopolamine 10mg",
    "name": "Butylscopolamine",
    "strength": "10mg",
    "bbox": [75, 438, 265, 500],
    "confidence": 0.96
  },
  "duration": {
    "value": "14 ថ្ងៃ",
    "value_numeric": 14,
    "unit": "days",
    "bbox": [270, 438, 360, 500],
    "confidence": 0.98
  },
  "morning_6_8": {
    "value": "1",
    "value_numeric": 1,
    "bbox": [443, 438, 494, 500],
    "confidence": 0.99
  }
}
```

#### Dynamic Universal
```json
{
  "medication": {
    "name": {
      "brand_name": "Butylscopolamine",
      "generic_name": "Butylscopolamine",
      "full_text": "Butylscopolamine 10mg",
      "bbox": [75, 438, 265, 500]
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
      "text_original": "14 ថ្ងៃ",
      "khmer_text": "14 ថ្ងៃ"
    },
    "schedule": {
      "type": "time_based",
      "frequency": {
        "times_per_day": 2,
        "interval_hours": 12
      },
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
}
```

#### Reminder Format (Legacy)
```json
{
  "medication": {
    "name": "Butylscopolamine",
    "strength": "10mg",
    "form": "tablet"
  },
  "duration": {
    "value": 14,
    "unit": "days",
    "khmer": "14 ថ្ងៃ"
  },
  "schedule": {
    "morning": {
      "time_range": "06:00-08:00",
      "dose": 1,
      "enabled": true
    }
  }
}
```

---

## Migration Path

### From Static → Dynamic

**Automatic Mapping:**
- Extract text values from bbox annotations
- Parse numeric values from strings
- Map table columns to time_slots
- Normalize language-specific fields

**Manual Review Needed:**
- Clinical interpretation (diagnosis codes)
- Drug name standardization
- Dosing instruction translation
- Confidence threshold decisions

**Example Transformation:**
```python
def static_to_dynamic(static_data):
    return {
        "medication": {
            "name": {
                "brand_name": static_data["medication_name"]["name"],
                "full_text": static_data["medication_name"]["value"]
            },
            "strength": {
                "value": static_data["medication_name"]["strength"],
                "numeric": parse_strength(static_data["medication_name"]["strength"])
            }
        },
        "dosing": {
            "duration": {
                "value": static_data["duration"]["value_numeric"],
                "unit": static_data["duration"]["unit"],
                "khmer_text": static_data["duration"]["value"]
            }
        }
    }
```

### From Legacy Reminder → Dynamic

**Data Enrichment Needed:**
- Add missing metadata fields
- Expand language support
- Include confidence scores
- Add clinical information
- Support optional fields

---

## Key Differences

### 1. **Bounding Boxes**
- **Static:** Every field has bbox
- **Dynamic:** Optional bbox for important fields
- **Legacy:** No bbox support

### 2. **Language Handling**
- **Static:** Original text as-is
- **Dynamic:** Separate fields per language
- **Legacy:** Mixed or primary language only

### 3. **Medication Schedule**
- **Static:** Direct table column mapping
- **Dynamic:** Normalized time_slots array
- **Legacy:** Fixed time period objects

### 4. **Validation**
- **Static:** Minimal (presence check)
- **Dynamic:** Schema validation + business rules
- **Legacy:** Basic field validation

### 5. **Extensibility**
- **Static:** Layout-dependent
- **Dynamic:** Highly extensible
- **Legacy:** Limited structure

---

## Recommended Workflow

### For OCR Development
```
Image → OCR Engine → Static Format (with bbox)
                 ↓
            Visual Verification
                 ↓
           Model Training Data
```

### For Application Integration
```
Image → OCR Engine → Static Format → Transformation → Dynamic Universal Format
                                                    ↓
                                            Database Storage
                                                    ↓
                                            API Responses
                                                    ↓
                                            Mobile App / Web UI
```

### For Reminder System
```
Dynamic Universal Format → Medication Extractor → Reminder Generator
                                                ↓
                                        Khmer Instructions
                                                ↓
                                        Push Notifications
```

---

## Performance Considerations

| Aspect | Static BBox | Dynamic Universal | Reminder Legacy |
|--------|-------------|-------------------|-----------------|
| File Size | Large (bbox data) | Medium | Small |
| Parse Speed | Fast | Medium | Fast |
| Validation Time | Minimal | Moderate | Fast |
| Storage Cost | High | Medium | Low |
| Query Performance | Slow (flat structure) | Fast (indexed fields) | Fast |

---

## Best Practices

### ✅ Do:
- Use Static format during OCR development and debugging
- Use Dynamic Universal for all production features
- Keep both formats during transition period
- Validate data at format boundaries
- Document any custom field additions

### ❌ Don't:
- Mix format types in the same database
- Skip validation between format conversions
- Store bbox data in production database (unless needed)
- Hardcode field mappings (use configuration)
- Ignore confidence scores in Dynamic format

---

## Schema Evolution

### Version History

**v1.0** - Reminder Legacy Format
- Basic medication and schedule support
- Single prescription structure
- Limited metadata

**v2.0** - Dynamic Universal Format (Current)
- Multi-language support
- Flexible medication schedules
- Rich metadata and clinical information
- Bounding box support (optional)
- Validation-ready structure

**Future (v3.0)?**
- FHIR standard alignment
- International drug code integration
- AI-generated dosing recommendations
- Blockchain verification

---

## FAQ

**Q: Why keep the Static format if Dynamic is better?**
A: Static format is crucial for OCR debugging, training, and quality assurance. It preserves the raw extraction data.

**Q: Can I use only the Dynamic format?**
A: Yes, for application integration. But you'll lose OCR debugging capabilities.

**Q: How do I handle prescriptions that don't fit the schema?**
A: The Dynamic Universal schema is designed to be flexible. Most fields are optional. For truly unique cases, use the `additional_information.notes` field.

**Q: What about handwritten prescriptions?**
A: Both formats support handwritten content. The Static format will have lower confidence scores, and the Dynamic format includes processing flags to indicate handwritten detection.

**Q: How do I validate the extracted data?**
A: Use JSON schema validation for structure, then apply business rules (dose ranges, drug interactions, etc.) on the Dynamic format.

---

**Last Updated:** 2026-02-15
