import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreatePrescriptionDto, UpdatePrescriptionDto } from './dto';

@Injectable()
export class PrescriptionsService {
  constructor(private prisma: PrismaService) {}

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

    // Create prescription with medications
    const prescription = await this.prisma.prescription.create({
      data: {
        patientId: dto.patientId,
        doctorId,
        patientName: dto.patientName,
        patientGender: dto.patientGender,
        patientAge: dto.patientAge,
        symptoms: dto.symptoms,
        status: 'DRAFT',
        currentVersion: 1,
        isUrgent: dto.isUrgent || false,
        urgentReason: dto.urgentReason,
        medications: {
          create: dto.medications.map(med => ({
            rowNumber: med.rowNumber,
            medicineName: med.medicineName,
            medicineNameKhmer: med.medicineNameKhmer,
            morningDosage: med.morningDosage as any,
            daytimeDosage: med.daytimeDosage as any,
            nightDosage: med.nightDosage as any,
            imageUrl: med.imageUrl,
            frequency: this.calculateFrequency(med),
            timing: this.determineTiming(med),
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
        doctor: { select: { id: true, fullName: true, specialty: true } },
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
          morningDosage: med.morningDosage as any,
          daytimeDosage: med.daytimeDosage as any,
          nightDosage: med.nightDosage as any,
          imageUrl: med.imageUrl,
          frequency: this.calculateFrequency(med),
          timing: this.determineTiming(med),
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

    // TODO: Send notification to patient

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

    // TODO: Notify doctor about retake request

    return { message: 'Retake request sent to doctor', reason };
  }

  private async generateDoseEvents(prescription: any) {
    const today = new Date();
    const events: any[] = [];

    for (const medication of prescription.medications) {
      // Generate for next 30 days
      for (let day = 0; day < 30; day++) {
        const date = new Date(today);
        date.setDate(date.getDate() + day);

        if (medication.morningDosage) {
          events.push({
            prescriptionId: prescription.id,
            medicationId: medication.id,
            patientId: prescription.patientId,
            scheduledTime: new Date(date.setHours(7, 0, 0, 0)),
            timePeriod: 'DAYTIME' as const,
            status: 'DUE' as const,
            reminderTime: '07:00',
          });
        }

        if (medication.daytimeDosage) {
          events.push({
            prescriptionId: prescription.id,
            medicationId: medication.id,
            patientId: prescription.patientId,
            scheduledTime: new Date(date.setHours(12, 0, 0, 0)),
            timePeriod: 'DAYTIME' as const,
            status: 'DUE' as const,
            reminderTime: '12:00',
          });
        }

        if (medication.nightDosage) {
          events.push({
            prescriptionId: prescription.id,
            medicationId: medication.id,
            patientId: prescription.patientId,
            scheduledTime: new Date(date.setHours(20, 0, 0, 0)),
            timePeriod: 'NIGHT' as const,
            status: 'DUE' as const,
            reminderTime: '20:00',
          });
        }
      }
    }

    await this.prisma.doseEvent.createMany({ data: events });
  }

  private calculateFrequency(med: any): string {
    const count = [med.morningDosage, med.daytimeDosage, med.nightDosage].filter(Boolean).length;
    return `${count}ដង/១ថ្ងៃ`;
  }

  private determineTiming(med: any): string {
    const hasBeforeMeal = [med.morningDosage, med.daytimeDosage, med.nightDosage]
      .some(d => d?.beforeMeal);
    return hasBeforeMeal ? 'មុនអាហារ' : 'បន្ទាប់ពីអាហារ';
  }
}
