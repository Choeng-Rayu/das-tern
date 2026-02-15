/**
 * TypeScript interfaces for OCR Dynamic Universal v2.0 response.
 * Only the fields needed for backend mapping are defined here.
 */

export interface OcrTimeSlot {
  period: 'morning' | 'midday' | 'afternoon' | 'evening' | 'night' | 'custom';
  time_range: string | null;
  dose: {
    value: string;
    numeric: number | null;
    unit: string | null;
    bbox: number[] | null;
  };
  enabled: boolean;
}

export interface OcrMedicationItem {
  item_number: { value: number; bbox: number[] | null };
  medication: {
    name: {
      brand_name: string | null;
      generic_name: string | null;
      local_name: string | null;
      full_text: string;
      bbox: number[] | null;
    };
    strength: {
      value: string | null;
      numeric: number | null;
      unit: string | null;
    };
    form: {
      value: string | null;
      khmer: string | null;
      french: string | null;
    };
    route: {
      value: string | null;
      description: string | null;
    };
  };
  dosing: {
    duration: {
      value: number | null;
      unit: string | null;
      text_original: string;
      khmer_text: string | null;
      note: string | null;
      bbox: number[] | null;
    };
    schedule: {
      type: string | null;
      frequency: {
        times_per_day: number | null;
        interval_hours: number | null;
        text_description: string | null;
      };
      time_slots: OcrTimeSlot[];
      prn_instructions: {
        as_needed: boolean;
        condition: string | null;
      };
    };
    total_quantity: {
      value: number | null;
      unit: string | null;
    };
  };
  instructions: {
    timing_with_food: {
      before_meal: boolean | null;
      after_meal: boolean | null;
      text: string | null;
    };
  };
  clinical_notes: {
    therapeutic_class: string | null;
  };
}

export interface OcrExtractionResponse {
  success: boolean;
  data: {
    $schema: string;
    prescription: {
      metadata: {
        extraction_info: {
          confidence_score: number;
          processing_time_ms?: number;
        };
        prescription_type: string | null;
        validation_status: string | null;
      };
      patient: {
        identification: {
          patient_id: { value: string | null };
        };
        personal_info: {
          name: { full_name: string | null; khmer_name: string | null };
          age: { value: number | null; unit: string | null };
          gender: { value: string | null; english: string | null };
        };
      };
      clinical_information: {
        diagnoses: Array<{
          diagnosis: { english: string | null; khmer: string | null };
        }>;
      };
      medications: {
        items: OcrMedicationItem[];
        summary: {
          total_medications: number;
          max_duration_days: number | null;
        };
      };
      prescriber: {
        name: { full_name: string | null };
      };
      prescription_details: {
        dates: {
          issue_date: { value: string | null };
        };
      };
    };
  };
  extraction_summary: {
    total_medications: number;
    confidence_score: number;
    needs_review: boolean;
    fields_needing_review: string[];
    processing_time_ms: number;
    engines_used: string[];
  };
}
