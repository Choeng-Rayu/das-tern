import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateBatchDto, BatchMedicationItemDto } from './dto';
import { UpdateBatchDto } from './dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class BatchMedicationService {
  constructor(private readonly prisma: PrismaService) {}

  async createBatch(patientId: string, dto: CreateBatchDto) {
    if (!dto.medicines || dto.medicines.length === 0) {
      throw new BadRequestException('A batch must contain at least one medicine');
    }

    // Fetch patient info for prescription creation
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

    const patientName = patient.fullName ||
      `${patient.firstName || ''} ${patient.lastName || ''}`.trim() ||
      'Patient';
    const patientAge = patient.dateOfBirth
      ? this.calculateAge(patient.dateOfBirth)
      : 0;

    // Parse scheduled time
    const [hours, minutes] = dto.scheduledTime.split(':').map(Number);

    return this.prisma.$transaction(async (tx) => {
      // 1. Create the MedicationBatch
      const batch = await tx.medicationBatch.create({
        data: {
          patientId,
          name: dto.name,
          scheduledTime: dto.scheduledTime,
        },
      });

      // 2. Create a prescription to hold the medications
      const prescription = await tx.prescription.create({
        data: {
          patientId,
          patientName,
          patientGender: patient.gender || 'OTHER',
          patientAge,
          symptoms: `Batch: ${dto.name}`,
          status: 'ACTIVE',
          startDate: new Date(),
        },
      });

      // 3. Create medications linked to both prescription and batch
      const medications = [];
      for (let i = 0; i < dto.medicines.length; i++) {
        const med = dto.medicines[i];
        const dosage = {
          amount: `${med.dosageAmount || 1}`,
          beforeMeal: med.beforeMeal || false,
        };

        const medication = await tx.medication.create({
          data: {
            prescriptionId: prescription.id,
            batchId: batch.id,
            rowNumber: i + 1,
            medicineName: med.medicineName,
            medicineNameKhmer: med.medicineNameKhmer || null,
            medicineType: med.medicineType || 'ORAL',
            unit: med.unit || 'TABLET',
            dosageAmount: med.dosageAmount || 1,
            frequency: med.frequency || '1 time/day',
            duration: med.durationDays || 30,
            description: med.description || null,
            additionalNote: med.additionalNote || null,
            beforeMeal: med.beforeMeal || false,
            isPRN: med.isPRN || false,
            createdBy: patientId,
            // All medicines in this batch share the same scheduled time
            morningDosage: hours < 12 ? dosage : Prisma.DbNull,
            daytimeDosage: hours >= 12 && hours < 18 ? dosage : Prisma.DbNull,
            nightDosage: hours >= 18 ? dosage : Prisma.DbNull,
            timing: dto.scheduledTime,
          },
        });

        medications.push(medication);
      }

      // 4. Generate dose events for all medications at the batch time
      await this.generateBatchDoseEvents(
        tx,
        prescription.id,
        patientId,
        medications,
        dto.scheduledTime,
      );

      // 5. Create audit log
      await tx.auditLog.create({
        data: {
          actorId: patientId,
          actorRole: 'PATIENT',
          actionType: 'PRESCRIPTION_CREATE',
          resourceType: 'MedicationBatch',
          resourceId: batch.id,
          details: {
            action: 'BATCH_CREATED',
            batchName: dto.name,
            scheduledTime: dto.scheduledTime,
            medicineCount: dto.medicines.length,
          },
        },
      });

      return {
        ...batch,
        prescription,
        medications,
      };
    });
  }

  async findAllBatches(patientId: string) {
    return this.prisma.medicationBatch.findMany({
      where: { patientId },
      include: {
        medications: {
          include: {
            doseEvents: {
              where: { status: { in: ['TAKEN_ON_TIME', 'TAKEN_LATE'] } },
              select: { id: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOneBatch(id: string, patientId: string) {
    const batch = await this.prisma.medicationBatch.findUnique({
      where: { id },
      include: {
        medications: {
          include: {
            doseEvents: true,
          },
        },
      },
    });

    if (!batch) {
      throw new NotFoundException('Batch not found');
    }

    if (batch.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    return batch;
  }

  async updateBatch(id: string, patientId: string, dto: UpdateBatchDto) {
    const batch = await this.prisma.medicationBatch.findUnique({
      where: { id },
      include: { medications: true },
    });

    if (!batch) {
      throw new NotFoundException('Batch not found');
    }

    if (batch.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    const updated = await this.prisma.medicationBatch.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.scheduledTime !== undefined && { scheduledTime: dto.scheduledTime }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
      include: { medications: true },
    });

    // If scheduled time changed, regenerate dose events
    if (dto.scheduledTime && dto.scheduledTime !== batch.scheduledTime) {
      // Find the prescription associated with this batch
      if (batch.medications.length > 0) {
        const prescriptionId = batch.medications[0].prescriptionId;

        // Delete future DUE dose events
        await this.prisma.doseEvent.deleteMany({
          where: {
            prescriptionId,
            status: 'DUE',
            scheduledTime: { gte: new Date() },
          },
        });

        // Regenerate with new time
        await this.generateBatchDoseEvents(
          this.prisma,
          prescriptionId,
          patientId,
          batch.medications,
          dto.scheduledTime,
        );
      }
    }

    return updated;
  }

  async deleteBatch(id: string, patientId: string) {
    const batch = await this.prisma.medicationBatch.findUnique({
      where: { id },
      include: { medications: true },
    });

    if (!batch) {
      throw new NotFoundException('Batch not found');
    }

    if (batch.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    // Delete the batch (medications stay via onDelete: SetNull, batchId becomes null)
    // Also delete the associated prescription and its dose events
    if (batch.medications.length > 0) {
      const prescriptionId = batch.medications[0].prescriptionId;
      await this.prisma.prescription.delete({
        where: { id: prescriptionId },
      });
    }

    await this.prisma.medicationBatch.delete({ where: { id } });

    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'MedicationBatch',
        resourceId: id,
        details: { action: 'BATCH_DELETED', batchName: batch.name },
      },
    });

    return { message: 'Batch deleted successfully' };
  }

  async addMedicineToBatch(
    batchId: string,
    patientId: string,
    dto: BatchMedicationItemDto,
  ) {
    const batch = await this.prisma.medicationBatch.findUnique({
      where: { id: batchId },
      include: { medications: true },
    });

    if (!batch) {
      throw new NotFoundException('Batch not found');
    }

    if (batch.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    // Get prescription ID from existing medications
    if (batch.medications.length === 0) {
      throw new BadRequestException('Batch has no associated prescription');
    }

    const prescriptionId = batch.medications[0].prescriptionId;
    const nextRowNumber = Math.max(...batch.medications.map(m => m.rowNumber), 0) + 1;

    const [hours] = batch.scheduledTime.split(':').map(Number);
    const dosage = {
      amount: `${dto.dosageAmount || 1}`,
      beforeMeal: dto.beforeMeal || false,
    };

    const medication = await this.prisma.medication.create({
      data: {
        prescriptionId,
        batchId,
        rowNumber: nextRowNumber,
        medicineName: dto.medicineName,
        medicineNameKhmer: dto.medicineNameKhmer || null,
        medicineType: dto.medicineType || 'ORAL',
        unit: dto.unit || 'TABLET',
        dosageAmount: dto.dosageAmount || 1,
        frequency: dto.frequency || '1 time/day',
        duration: dto.durationDays || 30,
        description: dto.description || null,
        additionalNote: dto.additionalNote || null,
        beforeMeal: dto.beforeMeal || false,
        isPRN: dto.isPRN || false,
        createdBy: patientId,
        morningDosage: hours < 12 ? dosage : Prisma.DbNull,
        daytimeDosage: hours >= 12 && hours < 18 ? dosage : Prisma.DbNull,
        nightDosage: hours >= 18 ? dosage : Prisma.DbNull,
        timing: batch.scheduledTime,
      },
    });

    // Generate dose events for this new medication
    if (!dto.isPRN) {
      await this.generateBatchDoseEvents(
        this.prisma,
        prescriptionId,
        patientId,
        [medication],
        batch.scheduledTime,
      );
    }

    return medication;
  }

  async removeMedicineFromBatch(
    batchId: string,
    medicineId: string,
    patientId: string,
  ) {
    const batch = await this.prisma.medicationBatch.findUnique({
      where: { id: batchId },
    });

    if (!batch) {
      throw new NotFoundException('Batch not found');
    }

    if (batch.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    const medication = await this.prisma.medication.findUnique({
      where: { id: medicineId },
    });

    if (!medication || medication.batchId !== batchId) {
      throw new NotFoundException('Medicine not found in this batch');
    }

    // Delete the medication (cascades to dose events)
    await this.prisma.medication.delete({ where: { id: medicineId } });

    return { message: 'Medicine removed from batch' };
  }

  private async generateBatchDoseEvents(
    tx: any,
    prescriptionId: string,
    patientId: string,
    medications: any[],
    scheduledTime: string,
  ) {
    const [hours, minutes] = scheduledTime.split(':').map(Number);
    const timePeriod = hours < 18 ? 'DAYTIME' : 'NIGHT';
    const reminderTime = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;

    const events: any[] = [];
    const now = new Date();

    for (const med of medications) {
      if (med.isPRN) continue;

      const duration = med.duration || 30;

      for (let day = 0; day < duration; day++) {
        const scheduledDate = new Date(now);
        scheduledDate.setDate(scheduledDate.getDate() + day);
        scheduledDate.setHours(hours, minutes, 0, 0);

        // Skip if in the past
        if (scheduledDate <= now) continue;

        events.push({
          prescriptionId,
          medicationId: med.id,
          patientId,
          scheduledTime: scheduledDate,
          timePeriod,
          reminderTime,
          status: 'DUE',
        });
      }
    }

    if (events.length > 0) {
      await tx.doseEvent.createMany({ data: events });
    }
  }

  private calculateAge(dateOfBirth: Date): number {
    const now = new Date();
    let age = now.getFullYear() - dateOfBirth.getFullYear();
    const monthDiff = now.getMonth() - dateOfBirth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dateOfBirth.getDate())) {
      age--;
    }
    return age;
  }
}
