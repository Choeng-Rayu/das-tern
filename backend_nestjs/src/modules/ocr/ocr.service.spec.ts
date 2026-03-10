import { of, throwError } from 'rxjs';
import { OcrService } from './ocr.service';
import { OcrExtractionResponse } from './dto';


const OCR_RESPONSE: OcrExtractionResponse = {
  success: true,
  data: {
    $schema: 'cambodia-prescription-universal-v2.0',
    prescription: {
      metadata: { extraction_info: { confidence_score: 0.87, processing_time_ms: 123 }, prescription_type: 'outpatient', validation_status: 'validated' },
      patient: {
        identification: { patient_id: { value: 'P-1' } },
        personal_info: { name: { full_name: 'Test Patient', khmer_name: null }, age: { value: 40, unit: 'years' }, gender: { value: 'M', english: 'Male' } },
      },
      clinical_information: { diagnoses: [] },
      medications: { items: [], summary: { total_medications: 0, max_duration_days: null } },
      prescriber: { name: { full_name: 'Dr. Demo' } },
      prescription_details: { dates: { issue_date: { value: '2026-03-06' } } },
    },
  },
  extraction_summary: {
    total_medications: 0, 
    confidence_score: 0.87,
    needs_review: false,
    fields_needing_review: [],
    processing_time_ms: 123,
    engines_used: ['kiri-ocr'],
  },
};


describe('OcrService', () => {
  it('returns OCR data even when AI enhancement fails', async () => {
    const httpService = {
      post: jest
        .fn()
        .mockReturnValueOnce(of({ data: OCR_RESPONSE }))
        .mockReturnValueOnce(throwError(() => new Error('AI unavailable'))),
    };
    const configService = {
      get: jest.fn((key: string) => {
        if (key === 'OCR_SERVICE_URL') return 'http://localhost:8000';
        if (key === 'AI_SERVICE_URL') return 'http://localhost:8001';
        return undefined;
      }),
    };
    const prescriptionsService = { createPatientPrescription: jest.fn() };

    const service = new OcrService(httpService as any, configService as any, prescriptionsService as any);
    const result = await service.extractAndEnhancePrescription(Buffer.from('img'), 'test.png', 'image/png');

    expect(result.success).toBe(true);
    expect(result.data.$schema).toBe('cambodia-prescription-universal-v2.0');
    expect(result.ai_status).toBe('not_responded');
    expect(result.ai_message).toBe('AI did not respond');
    expect(result.ai_enhanced).toBeNull();
    expect(httpService.post).toHaveBeenCalledTimes(2);
  });
});