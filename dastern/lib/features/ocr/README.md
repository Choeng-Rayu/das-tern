# Feature: ocr

> Spec: [`.kiro/specs-v2-flutter-supabase/07-ocr-prescription-scanning/`](../../../../.kiro/specs-v2-flutter-supabase/07-ocr-prescription-scanning/)

Hybrid OCR pipeline: ML Kit (Latin) → Tesseract (Khmer) → Edge Function
fallback to Google Cloud Vision. Confidence routing, prescription draft
generation.
