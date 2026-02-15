import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreatePrescriptionDto, UpdatePrescriptionDto, CreatePatientPrescriptionDto } from './dto';

@Injectable()
export class PrescriptionsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  async create(doctorId: string, dto: CreatePrescriptionDto) {
    // Verify doctor-patient connection
    const connection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: doctorId, recipientId: dto.patientId },
          { initiatorId: dto.patientId, recipientId: doctorId },
        ],
        status: 'ACCEPTED',
      },
    });

    if (!connection) {
      throw new ForbiddenException('No active connection with patient');
    }

    // Validation: at least 1 medication required
    if (!dto.medications || dto.medications.length === 0) {
      throw new BadRequestException('Prescription must have at least 1 medication');
    }

    // Validation: diagnosis or symptoms required
    if (!dto.symptoms && !dto.diagnosis) {
      throw new BadRequestException('Diagnosis or symptoms is required');
    }

    // Get doctor's license number from profile
    const doctor = await this.prisma.user.findUnique({
      where: { id: doctorId },
      select: { licenseNumber: true },
    });

    // Create prescription with medications
    const prescription = await this.prisma.prescription.create({
      data: {
        patientId: dto.patientId,
        doctorId,
        patientName: dto.patientName,
        patientGender: dto.patientGender,
        patientAge: dto.patientAge,
        symptoms: dto.symptoms,
        diagnosis: dto.diagnosis,
        clinicalNote: dto.clinicalNote,
        doctorLicenseNumber: doctor?.licenseNumber || null,
        followUpDate: dto.followUpDate ? new Date(dto.followUpDate) : null,
        startDate: new Date(),
        status: 'DRAFT',
        currentVersion: 1,
        isUrgent: dto.isUrgent || false,
        urgentReason: dto.urgentReason,
        medications: {
          create: dto.medications.map(med => ({
            rowNumber: med.rowNumber,
            medicineName: med.medicineName,
            medicineNameKhmer: med.medicineNameKhmer,
            medicineType: med.medicineType || 'ORAL',
            unit: med.unit || 'TABLET',
            dosageAmount: med.dosageAmount || 1,
            description: med.description,
            additionalNote: med.additionalNote,
            createdBy: doctorId,
            morningDosage: med.morningDosage as any,
            daytimeDosage: med.daytimeDosage as any,
            nightDosage: med.nightDosage as any,
            imageUrl: med.imageUrl,
            frequency: med.frequency || this.calculateFrequency(med),
            duration: med.durationDays || null,
            timing: this.determineTiming(med),
            isPRN: med.isPRN || false,
            beforeMeal: med.beforeMeal || false,
          })),
        },
      },
      include: { medications: true },
    });

    // Create initial version
    await this.prisma.prescriptionVersion.create({
      data: {
        prescriptionId: prescription.id,
        versionNumber: 1,
        authorId: doctorId,
        changeReason: 'Initial prescription',
        medicationsSnapshot: (prescription as any).medications,
      },
    });

    return prescription;
  }

  async findAll(userId: string, role: string, filters?: { status?: string; patientId?: string }) {
    const where: any = role === 'PATIENT'
      ? { patientId: userId, ...(filters?.status && { status: filters.status }) }
      : { doctorId: userId, ...(filters?.patientId && { patientId: filters.patientId }) };

    return this.prisma.prescription.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        medications: true,
        patient: { select: { id: true, firstName: true, lastName: true, phoneNumber: true } },
        doctor: { select: { id: true, fullName: true, specialty: true } },
      },
    });
  }

  async findOne(id: string) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id },
      include: {
        medications: true,
        versions: { orderBy: { versionNumber: 'desc' } },
        patient: { select: { id: true, firstName: true, lastName: true } },
        doctor: { select: { id: true, fullName: true, specialty: true, licenseNumber: true } },
      },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    return prescription;
  }

  async update(id: string, doctorId: string, dto: UpdatePrescriptionDto) {
    const prescription = await this.findOne(id);

    if (prescription.doctorId !== doctorId) {
      throw new ForbiddenException('Access denied');
    }

    // Create version snapshot
    await this.prisma.prescriptionVersion.create({
      data: {
        prescriptionId: id,
        versionNumber: prescription.currentVersion,
        authorId: doctorId,
        changeReason: dto.changeReason || 'Updated prescription',
        medicationsSnapshot: prescription.medications,
      },
    });

    // Update prescription
    const updated = await this.prisma.prescription.update({
      where: { id },
      data: {
        symptoms: dto.symptoms,
        diagnosis: dto.diagnosis,
        clinicalNote: dto.clinicalNote,
        followUpDate: dto.followUpDate ? new Date(dto.followUpDate) : undefined,
        currentVersion: prescription.currentVersion + 1,
        isUrgent: dto.isUrgent,
        urgentReason: dto.urgentReason,
      },
      include: { medications: true },
    });

    // Update medications if provided
    if (dto.medications) {
      await this.prisma.medication.deleteMany({ where: { prescriptionId: id } });
      await this.prisma.medication.createMany({
        data: dto.medications.map(med => ({
          prescriptionId: id,
          rowNumber: med.rowNumber,
          medicineName: med.medicineName,
          medicineNameKhmer: med.medicineNameKhmer,
          medicineType: med.medicineType || 'ORAL',
          unit: med.unit || 'TABLET',
          dosageAmount: med.dosageAmount || 1,
          description: med.description,
          additionalNote: med.additionalNote,
          createdBy: doctorId,
          morningDosage: med.morningDosage as any,
          daytimeDosage: med.daytimeDosage as any,
          nightDosage: med.nightDosage as any,
          imageUrl: med.imageUrl,
          frequency: med.frequency || this.calculateFrequency(med),
          duration: med.durationDays || null,
          timing: this.determineTiming(med),
          isPRN: med.isPRN || false,
          beforeMeal: med.beforeMeal || false,
        })),
      });
    }

    return this.findOne(id);
  }

  async urgentUpdate(id: string, doctorId: string, dto: UpdatePrescriptionDto) {
    if (!dto.urgentReason) {
      throw new BadRequestException('Urgent reason is required for urgent updates');
    }

    const updated = await this.update(id, doctorId, { ...dto, isUrgent: true });

    // Auto-activate for urgent updates
    await this.prisma.prescription.update({
      where: { id },
      data: { status: 'ACTIVE' },
    });

    // Notify patient about urgent prescription change
    const prescription = await this.findOne(id);
    await this.notifications.send(
      prescription.patientId,
      'URGENT_PRESCRIPTION_CHANGE',
      'Urgent Prescription Update',
      `Your prescription has been urgently updated by Dr. ${prescription.doctor?.fullName || 'your doctor'}. Reason: ${dto.urgentReason}`,
      { prescriptionId: id, urgentReason: dto.urgentReason },
    );

    return updated;
  }

  async confirm(id: string, patientId: string) {
    const prescription = await this.findOne(id);

    if (prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    const activated = await this.prisma.prescription.update({
      where: { id },
      data: { status: 'ACTIVE' },
      include: { medications: true },
    });

    // Generate dose events
    await this.generateDoseEvents(activated);

    // Create audit log entry
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_CONFIRM',
        resourceType: 'Prescription',
        resourceId: id,
        details: {
          prescriptionId: id,
          status: 'ACTIVE',
          confirmedAt: new Date().toISOString(),
        },
      },
    });

    return activated;
  }

  async retake(id: string, patientId: string, reason: string) {
    const prescription = await this.findOne(id);

    if (prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    await this.prisma.prescription.update({
      where: { id },
      data: { status: 'DRAFT' },
    });

    // Notify doctor about retake request
    if (prescription.doctorId) {
      await this.notifications.send(
        prescription.doctorId,
        'PRESCRIPTION_UPDATE',
        'Prescription Retake Request',
        `Patient ${prescription.patient?.firstName || prescription.patientName} has requested a retake for their prescription. Reason: ${reason}`,
        { prescriptionId: id, retakeReason: reason },
      );
    }

    return { message: 'Retake request sent to doctor', reason };
  }

  async createPatientPrescription(patientId: string, dto: CreatePatientPrescriptionDto) {
    // Fetch patient info from User table
    const patient = await this.prisma.user.findUnique({
      where: { id: patientId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        fullName: true,
        gender: true,
        dateOfBirth: true,
      },
    });

    if (!patient) {
      throw new NotFoundException('Patient not found');
    }

    // Validation: each medicine needs name + frequency
    for (const med of dto.medicines) {
      if (!med.medicineName) {
        throw new BadRequestException('Each medicine must have a name');
      }
      if (!med.frequency) {
        throw new BadRequestException('Each medicine must have a frequency');
      }
    }

    // Build patient name
    const patientName = patient.fullName
      || [patient.firstName, patient.lastName].filter(Boolean).join(' ')
      || 'Unknown';

    // Calculate patient age from dateOfBirth
    let patientAge = 0;
    if (patient.dateOfBirth) {
      const today = new Date();
      const birth = new Date(patient.dateOfBirth);
      patientAge = today.getFullYear() - birth.getFullYear();
      const monthDiff = today.getMonth() - birth.getMonth();
      if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
        patientAge--;
      }
    }

    // Create prescription with ACTIVE status (patient-created)
    const prescription = await this.prisma.prescription.create({
      data: {
        patientId,
        doctorId: null,
        patientName,
        patientGender: patient.gender || 'OTHER',
        patientAge,
        symptoms: dto.diagnosis || dto.title,
        diagnosis: dto.diagnosis,
        startDate: new Date(dto.startDate),
        endDate: dto.endDate ? new Date(dto.endDate) : null,
        status: 'ACTIVE',
        currentVersion: 1,
        isUrgent: false,
        medications: {
          create: dto.medicines.map((med, index) => {
            const dosageInfo = {
              amount: `${med.dosageAmount}${med.dosageUnit}`,
              beforeMeal: med.beforeMeal || false,
            };

            // Map scheduleTimes to morning/daytime/night dosages
            let morningDosage: any = null;
            let daytimeDosage: any = null;
            let nightDosage: any = null;

            if (med.scheduleTimes && med.scheduleTimes.length > 0) {
              for (const schedule of med.scheduleTimes) {
                const period = schedule.timePeriod.toLowerCase();
                if (period === 'morning' || period === 'breakfast') {
                  morningDosage = { ...dosageInfo, time: schedule.time };
                } else if (period === 'afternoon' || period === 'daytime' || period === 'lunch') {
                  daytimeDosage = { ...dosageInfo, time: schedule.time };
                } else if (period === 'evening' || period === 'night' || period === 'dinner') {
                  nightDosage = { ...dosageInfo, time: schedule.time };
                }
              }
            } else {
              // Default: set morning dosage if no schedule times provided
              morningDosage = dosageInfo;
            }

            return {
              rowNumber: index + 1,
              medicineName: med.medicineName,
              medicineNameKhmer: med.medicineNameKhmer,
              medicineType: med.medicineType || 'ORAL',
              unit: med.unit || 'TABLET',
              dosageAmount: med.dosageAmount,
              description: med.description,
              additionalNote: med.additionalNote,
              createdBy: patientId,
              morningDosage,
              daytimeDosage,
              nightDosage,
              imageUrl: med.imageUrl,
              frequency: med.frequency,
              duration: med.durationDays || null,
              timing: med.beforeMeal ? 'មុនអាហារ' : 'បន្ទាប់ពីអាហារ',
              isPRN: med.isPRN || false,
              beforeMeal: med.beforeMeal || false,
            };
          }),
        },
      },
      include: { medications: true },
    });

    // Generate dose events
    await this.generateDoseEvents(prescription);

    // Create audit log entry
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_CREATE',
        resourceType: 'Prescription',
        resourceId: prescription.id,
        details: {
          title: dto.title,
          doctorName: dto.doctorName,
          medicationCount: dto.medicines.length,
          createdByPatient: true,
          startDate: dto.startDate,
          endDate: dto.endDate,
        },
      },
    });

    return prescription;
  }

  async deletePrescription(id: string, patientId: string) {
    const prescription = await this.findOne(id);

    if (prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied: you can only delete your own prescriptions');
    }

    // Delete associated dose events first
    await this.prisma.doseEvent.deleteMany({
      where: { prescriptionId: id },
    });

    // Delete associated medications
    await this.prisma.medication.deleteMany({
      where: { prescriptionId: id },
    });

    // Delete associated versions
    await this.prisma.prescriptionVersion.deleteMany({
      where: { prescriptionId: id },
    });

    // Delete the prescription
    await this.prisma.prescription.delete({
      where: { id },
    });

    return { message: 'Prescription deleted successfully' };
  }

  async pausePrescription(id: string, patientId: string) {
    const prescription = await this.findOne(id);

    if (prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    if (prescription.status !== 'ACTIVE') {
      throw new BadRequestException('Only ACTIVE prescriptions can be paused');
    }

    const paused = await this.prisma.prescription.update({
      where: { id },
      data: { status: 'PAUSED' },
      include: { medications: true },
    });

    // Create audit log entry
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Prescription',
        resourceId: id,
        details: {
          action: 'pause',
          previousStatus: 'ACTIVE',
          newStatus: 'PAUSED',
        },
      },
    });

    return paused;
  }

  async resumePrescription(id: string, patientId: string) {
    const prescription = await this.findOne(id);

    if (prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    if (prescription.status !== 'PAUSED') {
      throw new BadRequestException('Only PAUSED prescriptions can be resumed');
    }

    const resumed = await this.prisma.prescription.update({
      where: { id },
      data: { status: 'ACTIVE' },
      include: { medications: true },
    });

    // Delete future DUE dose events, then regenerate
    await this.prisma.doseEvent.deleteMany({
      where: {
        prescriptionId: id,
        status: 'DUE',
        scheduledTime: { gte: new Date() },
      },
    });

    await this.generateDoseEvents(resumed);

    // Create audit log entry
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Prescription',
        resourceId: id,
        details: {
          action: 'resume',
          previousStatus: 'PAUSED',
          newStatus: 'ACTIVE',
        },
      },
    });

    return resumed;
  }

  async rejectPrescription(id: string, patientId: string, reason?: string) {
    const prescription = await this.findOne(id);

    if (prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    if (prescription.status !== 'DRAFT') {
      throw new BadRequestException('Only DRAFT prescriptions can be rejected');
    }

    const rejected = await this.prisma.prescription.update({
      where: { id },
      data: { status: 'INACTIVE' },
      include: { medications: true },
    });

    // Create audit log entry
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Prescription',
        resourceId: id,
        details: {
          action: 'reject',
          previousStatus: prescription.status,
          newStatus: 'INACTIVE',
          reason: reason || null,
        },
      },
    });

    return rejected;
  }

  private async generateDoseEvents(prescription: any) {
    const today = new Date();
    const events: any[] = [];

    // Get patient's meal time preferences
    const mealPref = await this.prisma.mealTimePreference.findUnique({
      where: { userId: prescription.patientId },
    });

    const morningHour = mealPref?.morningMeal ? parseInt(mealPref.morningMeal.split(':')[0]) : 7;
    const morningMin = mealPref?.morningMeal ? parseInt(mealPref.morningMeal.split(':')[1]) : 0;
    const afternoonHour = mealPref?.afternoonMeal ? parseInt(mealPref.afternoonMeal.split(':')[0]) : 12;
    const afternoonMin = mealPref?.afternoonMeal ? parseInt(mealPref.afternoonMeal.split(':')[1]) : 0;
    const nightHour = mealPref?.nightMeal ? parseInt(mealPref.nightMeal.split(':')[0]) : 20;
    const nightMin = mealPref?.nightMeal ? parseInt(mealPref.nightMeal.split(':')[1]) : 0;

    for (const medication of prescription.medications) {
      if (medication.isPRN) continue;

      const days = medication.duration || 30;

      for (let day = 0; day < days; day++) {
        const date = new Date(today);
        date.setDate(date.getDate() + day);

        if (medication.morningDosage) {
          const scheduledTime = new Date(date);
          scheduledTime.setHours(morningHour, morningMin, 0, 0);
          events.push({
            prescriptionId: prescription.id,
            medicationId: medication.id,
            patientId: prescription.patientId,
            scheduledTime,
            timePeriod: 'DAYTIME' as const,
            status: 'DUE' as const,
            reminderTime: `${String(morningHour).padStart(2, '0')}:${String(morningMin).padStart(2, '0')}`,
          });
        }

        if (medication.daytimeDosage) {
          const scheduledTime = new Date(date);
          scheduledTime.setHours(afternoonHour, afternoonMin, 0, 0);
          events.push({
            prescriptionId: prescription.id,
            medicationId: medication.id,
            patientId: prescription.patientId,
            scheduledTime,
            timePeriod: 'DAYTIME' as const,
            status: 'DUE' as const,
            reminderTime: `${String(afternoonHour).padStart(2, '0')}:${String(afternoonMin).padStart(2, '0')}`,
          });
        }

        if (medication.nightDosage) {
          const scheduledTime = new Date(date);
          scheduledTime.setHours(nightHour, nightMin, 0, 0);
          events.push({
            prescriptionId: prescription.id,
            medicationId: medication.id,
            patientId: prescription.patientId,
            scheduledTime,
            timePeriod: 'NIGHT' as const,
            status: 'DUE' as const,
            reminderTime: `${String(nightHour).padStart(2, '0')}:${String(nightMin).padStart(2, '0')}`,
          });
        }
      }
    }

    if (events.length > 0) {
      await this.prisma.doseEvent.createMany({ data: events });
    }
  }

  private calculateFrequency(med: any): string {
    const count = [med.morningDosage, med.daytimeDosage, med.nightDosage].filter(Boolean).length;
    return `${count}ដង/១ថ្ងៃ`;
  }

  private determineTiming(med: any): string {
    const hasBeforeMeal = med.beforeMeal || [med.morningDosage, med.daytimeDosage, med.nightDosage]
      .some(d => d?.beforeMeal);
    return hasBeforeMeal ? 'មុនអាហារ' : 'បន្ទាប់ពីអាហារ';
  }
}
