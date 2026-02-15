import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { PrescriptionsService } from '../prescriptions/prescriptions.service';
import { OcrExtractionResponse, OcrMedicationItem } from './dto';
import { MedicineType, MedicineUnit } from '@prisma/client';
import { firstValueFrom } from 'rxjs';
import FormData = require('form-data');

@Injectable()
export class OcrService {
  private readonly logger = new Logger(OcrService.name);
  readonly ocrBaseUrl: string;

  constructor(
    private httpService: HttpService,
    private configService: ConfigService,
    private prescriptionsService: PrescriptionsService,
  ) {
    this.ocrBaseUrl = this.configService.get<string>('OCR_SERVICE_URL') || 'http://localhost:8000';
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
   * Extract prescription from image and create it in the database.
   * Uses the patient-created prescription flow (CreatePatientPrescriptionDto).
   */
  async scanAndCreatePrescription(
    patientId: string,
    fileBuffer: Buffer,
    filename: string,
    mimetype: string,
  ) {
    const ocrResult = await this.extractPrescription(fileBuffer, filename, mimetype);
    const prescription = ocrResult.data.prescription;

    // Build diagnosis string from OCR
    const diagnoses = prescription.clinical_information.diagnoses
      .map(d => d.diagnosis.english || d.diagnosis.khmer)
      .filter(Boolean);
    const diagnosis = diagnoses.length > 0 ? diagnoses.join(', ') : null;

    // Map OCR medications to PatientMedicationDto format
    const medicines = prescription.medications.items.map((item, index) =>
      this.mapOcrMedicationToDto(item, index),
    );

    // Determine start date (use issue date from prescription or today)
    const issueDate = prescription.prescription_details?.dates?.issue_date?.value;
    const startDate = issueDate || new Date().toISOString().split('T')[0];

    // Calculate end date from max duration
    const maxDuration = prescription.medications.summary.max_duration_days;
    let endDate: string | undefined;
    if (maxDuration) {
      const end = new Date(startDate);
      end.setDate(end.getDate() + maxDuration);
      endDate = end.toISOString().split('T')[0];
    }

    // Build the CreatePatientPrescriptionDto
    const dto = {
      title: diagnosis || 'Scanned Prescription',
      doctorName: prescription.prescriber?.name?.full_name || undefined,
      startDate,
      endDate,
      diagnosis,
      notes: `OCR scanned (confidence: ${(ocrResult.extraction_summary.confidence_score * 100).toFixed(0)}%)`,
      medicines,
    };

    this.logger.log(`Creating prescription from scan: ${medicines.length} medications`);

    // Create via existing PrescriptionsService
    const created = await this.prescriptionsService.createPatientPrescription(patientId, dto as any);

    return {
      prescription: created,
      ocr_summary: ocrResult.extraction_summary,
      needs_review: ocrResult.extraction_summary.needs_review,
    };
  }

  /**
   * Map a single OCR medication item to the PatientMedicationDto shape.
   */
  private mapOcrMedicationToDto(item: OcrMedicationItem, index: number) {
    const med = item.medication;
    const dosing = item.dosing;
    const instructions = item.instructions;

    // Medicine name
    const medicineName = med.name.brand_name || med.name.full_text || `Medicine ${index + 1}`;
    const medicineNameKhmer = med.name.local_name || undefined;

    // Medicine type mapping: OCR route/form → Prisma MedicineType
    const medicineType = this.mapMedicineType(med.route?.value, med.form?.value);

    // Unit mapping
    const unit = this.mapMedicineUnit(med.form?.value);

    // Dosage amount and unit string
    const dosageAmount = med.strength?.numeric || 1;
    const dosageUnit = med.strength?.unit || 'tablet';

    // Form
    const form = med.form?.value || 'tablet';

    // Duration
    const durationDays = dosing.duration?.value || undefined;

    // Build frequency string from time_slots
    const timesPerDay = dosing.schedule?.frequency?.times_per_day || 1;
    const frequency = `${timesPerDay}ដង/១ថ្ងៃ`;

    // Build schedule times array for morningDosage/daytimeDosage/nightDosage mapping
    // OCR has 4 slots: morning, midday, afternoon, evening
    // Backend has 3 slots: morning, daytime, night
    // Mapping: morning→morning, midday→daytime, afternoon→afternoon, evening→evening
    // The service maps: morning/breakfast→morningDosage, afternoon/daytime/lunch→daytimeDosage, evening/night/dinner→nightDosage
    const scheduleTimes: { timePeriod: string; time: string }[] = [];

    if (dosing.schedule?.time_slots) {
      for (const slot of dosing.schedule.time_slots) {
        if (!slot.enabled) continue;

        switch (slot.period) {
          case 'morning':
            scheduleTimes.push({ timePeriod: 'morning', time: '07:00' });
            break;
          case 'midday':
            // Maps to daytimeDosage via 'daytime' period
            scheduleTimes.push({ timePeriod: 'daytime', time: '12:00' });
            break;
          case 'afternoon':
            // Also maps to daytimeDosage via 'afternoon' period
            scheduleTimes.push({ timePeriod: 'afternoon', time: '17:00' });
            break;
          case 'evening':
          case 'night':
            scheduleTimes.push({ timePeriod: 'evening', time: '20:00' });
            break;
        }
      }
    }

    // Before/after meal
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
