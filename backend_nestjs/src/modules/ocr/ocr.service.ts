import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { PrescriptionsService } from '../prescriptions/prescriptions.service';
import { OcrExtractionResponse, OcrMedicationItem } from './dto';
import { MedicineType, MedicineUnit } from '@prisma/client';
import { firstValueFrom } from 'rxjs';
import FormData = require('form-data');

/** Result wrapper from the AI service call — always present, status signals availability. */
interface AiCallResult {
  enhanced: AiEnhancement | null;
  status: 'ok' | 'not_responded';
  message: string;
}

/** Shape of the enhanced object returned by the AI service. */
interface AiEnhancement {
  medications?: Array<{
    item_number: number;
    corrected_brand_name?: string | null;
    corrected_generic_name?: string | null;
    strength?: string | null;
    was_corrected?: boolean;
  }>;
  patient?: {
    name?: string | null;
    age?: number | null;
    gender?: string | null;
    patient_id?: string | null;
  } | null;
  prescriber_name?: string | null;
  diagnoses?: string[];
  prescription_date?: string | null;
}

@Injectable()
export class OcrService {
  private readonly logger = new Logger(OcrService.name);
  readonly ocrBaseUrl: string;
  private readonly aiBaseUrl: string;

  constructor(
    private httpService: HttpService,
    private configService: ConfigService,
    private prescriptionsService: PrescriptionsService,
  ) {
    this.ocrBaseUrl = this.configService.get<string>('OCR_SERVICE_URL') || 'http://localhost:8000';
    this.aiBaseUrl = this.configService.get<string>('AI_SERVICE_URL') || 'http://localhost:8001';
  }

  /**
   * Send image to OCR service and return raw extraction result.
   */
  async extractPrescription(
    fileBuffer: Buffer,
    filename: string,
    mimetype: string,
  ): Promise<OcrExtractionResponse> {
    const url = `${this.ocrBaseUrl}/api/v1/extract`;
    this.logger.log(`Sending image to OCR service: ${url} (${filename}, ${fileBuffer.length} bytes)`);

    const form = new FormData();
    form.append('file', fileBuffer, { filename, contentType: mimetype });

    try {
      const { data: result } = await firstValueFrom(
        this.httpService.post<OcrExtractionResponse>(url, form, {
          headers: form.getHeaders(),
          timeout: 30000,
          maxBodyLength: 10 * 1024 * 1024,
        }),
      );

      if (!result.success) {
        throw new HttpException(
          'OCR extraction failed',
          HttpStatus.UNPROCESSABLE_ENTITY,
        );
      }

      this.logger.log(
        `OCR extraction complete: ${result.extraction_summary.total_medications} medications, ` +
        `confidence: ${(result.extraction_summary.confidence_score * 100).toFixed(0)}%`,
      );

      return result;
    } catch (error) {
      if (error instanceof HttpException) throw error;
      if (error.response) {
        this.logger.error(`OCR service error [${error.response.status}]: ${JSON.stringify(error.response.data)}`);
        throw new HttpException(
          `OCR service returned ${error.response.status}`,
          HttpStatus.BAD_GATEWAY,
        );
      }
      this.logger.error(`OCR service connection failed: ${error.message}`);
      throw new HttpException(
        'Cannot connect to OCR service. Ensure it is running.',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
  }

  /**
   * Call the AI enhancement service with the raw OCR result.
   * Always returns an AiCallResult — never throws, never blocks the OCR flow.
   */
  private async callAiEnhance(ocrResult: OcrExtractionResponse): Promise<AiCallResult> {
    const url = `${this.aiBaseUrl}/api/v1/enhance`;
    this.logger.log(`Sending OCR result to AI service: ${url}`);

    try {
      const { data } = await firstValueFrom(
        this.httpService.post<{ success: boolean; enhanced: AiEnhancement; error?: string }>(
          url,
          { ocr_result: ocrResult },
          { timeout: 90000 },
        ),
      );

      if (data.success && data.enhanced) {
        this.logger.log(
          `AI enhancement complete: ${data.enhanced.medications?.length ?? 0} medications processed`,
        );
        return { enhanced: data.enhanced, status: 'ok', message: 'AI enhancement applied' };
      }

      const reason = data.error || 'AI service returned no data';
      this.logger.warn(`AI service did not respond usefully: ${reason}`);
      return { enhanced: null, status: 'not_responded', message: 'AI did not respond' };
    } catch (error) {
      this.logger.warn(`AI enhancement failed (non-blocking): ${error.message}`);
      return { enhanced: null, status: 'not_responded', message: 'AI did not respond' };
    }
  }

  /**
   * Extract prescription data with optional AI enhancement.
   * Returns OCR result merged with AI corrections plus an ai_status field
   * so the client always knows whether AI ran successfully.
   * Used by the /extract (preview) endpoint.
   */
  async extractAndEnhancePrescription(
    fileBuffer: Buffer,
    filename: string,
    mimetype: string,
  ) {
    const ocrResult = await this.extractPrescription(fileBuffer, filename, mimetype);
    const aiResult = await this.callAiEnhance(ocrResult);
    return {
      ...ocrResult,
      ai_status: aiResult.status,
      ai_message: aiResult.message,
      ai_enhanced: aiResult.enhanced,
    };
  }

  /**
   * Extract prescription from image and create it in the database.
   * Uses the patient-created prescription flow (CreatePatientPrescriptionDto).
   * AI enhancement is applied to correct medication names, patient info, etc.
   */
  async scanAndCreatePrescription(
    patientId: string,
    fileBuffer: Buffer,
    filename: string,
    mimetype: string,
  ) {
    const ocrResult = await this.extractPrescription(fileBuffer, filename, mimetype);
    const aiResult = await this.callAiEnhance(ocrResult);
    const aiEnhancement = aiResult.enhanced;

    const prescription = ocrResult.data.prescription;

    // Build AI medication corrections lookup by item_number
    const aiMedMap = new Map<number, NonNullable<AiEnhancement['medications']>[number]>();
    if (aiEnhancement?.medications) {
      for (const m of aiEnhancement.medications) {
        aiMedMap.set(m.item_number, m);
      }
    }

    // Build diagnosis string — prefer AI corrections over OCR if meaningful
    const ocrDiagnoses = prescription.clinical_information.diagnoses
      .map(d => d.diagnosis.english || d.diagnosis.khmer)
      .filter(Boolean);
    const aiDiagnoses = aiEnhancement?.diagnoses?.filter(Boolean) ?? [];
    const diagnosisSource = aiDiagnoses.length > 0 ? aiDiagnoses : ocrDiagnoses;
    const diagnosis = diagnosisSource.length > 0 ? diagnosisSource.join(', ') : null;

    // Map OCR medications to PatientMedicationDto format, applying AI corrections
    const medicines = prescription.medications.items.map((item, index) =>
      this.mapOcrMedicationToDto(item, index, aiMedMap.get(item.item_number?.value ?? index + 1)),
    );

    // Date — prefer AI-detected date
    const issueDate =
      aiEnhancement?.prescription_date ||
      prescription.prescription_details?.dates?.issue_date?.value;
    const startDate = issueDate || new Date().toISOString().split('T')[0];

    // Calculate end date from max duration
    const maxDuration = prescription.medications.summary.max_duration_days;
    let endDate: string | undefined;
    if (maxDuration) {
      const end = new Date(startDate);
      end.setDate(end.getDate() + maxDuration);
      endDate = end.toISOString().split('T')[0];
    }

    // Prescriber name — prefer AI
    const doctorName =
      aiEnhancement?.prescriber_name ||
      prescription.prescriber?.name?.full_name ||
      undefined;

    // Build the CreatePatientPrescriptionDto
    const dto = {
      title: diagnosis || 'Scanned Prescription',
      doctorName,
      startDate,
      endDate,
      diagnosis,
      notes:
        `OCR scanned (confidence: ${(ocrResult.extraction_summary.confidence_score * 100).toFixed(0)}%)` +
        (aiEnhancement ? ' | AI enhanced' : ''),
      medicines,
    };

    this.logger.log(
      `Creating prescription from scan: ${medicines.length} medications` +
      (aiEnhancement ? ' (AI-enhanced)' : ' (OCR-only)'),
    );

    const created = await this.prescriptionsService.createPatientPrescription(patientId, dto as any);

    return {
      prescription: created,
      ocr_summary: ocrResult.extraction_summary,
      needs_review: ocrResult.extraction_summary.needs_review,
      ai_status: aiResult.status,
      ai_message: aiResult.message,
    };
  }

  /**
   * Map a single OCR medication item to the PatientMedicationDto shape.
   * Applies AI corrections when available.
   */
  private mapOcrMedicationToDto(
    item: OcrMedicationItem,
    index: number,
    aiMed?: NonNullable<AiEnhancement['medications']>[number],
  ) {
    const med = item.medication;
    const dosing = item.dosing;
    const instructions = item.instructions;

    // Medicine name — prefer AI-corrected name when it was actually corrected
    const ocrName = med.name.brand_name || med.name.full_text || `Medicine ${index + 1}`;
    const medicineName =
      (aiMed?.was_corrected && aiMed.corrected_brand_name) ? aiMed.corrected_brand_name : ocrName;
    const medicineNameKhmer = med.name.local_name || undefined;

    // Medicine type mapping: OCR route/form → Prisma MedicineType
    const medicineType = this.mapMedicineType(med.route?.value, med.form?.value);

    // Unit mapping
    const unit = this.mapMedicineUnit(med.form?.value);

    // Dosage amount and unit string — use AI-corrected strength if available
    const aiStrength = aiMed?.strength;
    const strengthMatch = aiStrength?.match(/^(\d+(?:\.\d+)?)\s*(\w+)$/);
    const dosageAmount = strengthMatch ? parseFloat(strengthMatch[1]) : (med.strength?.numeric || 1);
    const dosageUnit = strengthMatch ? strengthMatch[2] : (med.strength?.unit || 'tablet');

    // Form
    const form = med.form?.value || 'tablet';

    // Duration
    const durationDays = dosing.duration?.value || undefined;

    // Build frequency string from time_slots
    const timesPerDay = dosing.schedule?.frequency?.times_per_day || 1;
    const frequency = `${timesPerDay}ដង/១ថ្ងៃ`;

    const scheduleTimes: { timePeriod: string; time: string }[] = [];

    if (dosing.schedule?.time_slots) {
      for (const slot of dosing.schedule.time_slots) {
        if (!slot.enabled) continue;

        switch (slot.period) {
          case 'morning':
            scheduleTimes.push({ timePeriod: 'morning', time: '07:00' });
            break;
          case 'midday':
            scheduleTimes.push({ timePeriod: 'daytime', time: '12:00' });
            break;
          case 'afternoon':
            scheduleTimes.push({ timePeriod: 'afternoon', time: '17:00' });
            break;
          case 'evening':
          case 'night':
            scheduleTimes.push({ timePeriod: 'evening', time: '20:00' });
            break;
        }
      }
    }

    const beforeMeal = instructions?.timing_with_food?.before_meal === true;

    return {
      medicineName,
      medicineNameKhmer,
      medicineType,
      unit,
      dosageAmount,
      dosageUnit,
      form,
      frequency,
      scheduleTimes: scheduleTimes.length > 0 ? scheduleTimes : undefined,
      durationDays,
      description: item.clinical_notes?.therapeutic_class || undefined,
      beforeMeal,
      isPRN: dosing.schedule?.prn_instructions?.as_needed || false,
    };
  }

  /**
   * Map OCR route/form to Prisma MedicineType enum.
   */
  private mapMedicineType(route?: string | null, form?: string | null): MedicineType {
    if (route) {
      const r = route.toUpperCase();
      if (r === 'PO' || r === 'ORAL') return MedicineType.ORAL;
      if (r === 'IV' || r === 'IM' || r === 'SC') return MedicineType.INJECTION;
      if (r === 'TOPICAL') return MedicineType.TOPICAL;
    }
    if (form) {
      const f = form.toLowerCase();
      if (['tablet', 'capsule', 'syrup', 'suspension'].includes(f)) return MedicineType.ORAL;
      if (['injection'].includes(f)) return MedicineType.INJECTION;
      if (['cream', 'ointment', 'patch'].includes(f)) return MedicineType.TOPICAL;
    }
    return MedicineType.ORAL;
  }

  /**
   * Map OCR form to Prisma MedicineUnit enum.
   */
  private mapMedicineUnit(form?: string | null): MedicineUnit {
    if (!form) return MedicineUnit.TABLET;
    const f = form.toLowerCase();
    if (f === 'tablet') return MedicineUnit.TABLET;
    if (f === 'capsule') return MedicineUnit.CAPSULE;
    if (['syrup', 'suspension', 'drops'].includes(f)) return MedicineUnit.ML;
    return MedicineUnit.TABLET;
  }
}
