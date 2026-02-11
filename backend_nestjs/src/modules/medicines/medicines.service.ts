import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import { CreateMedicineDto, UpdateMedicineDto } from './dto';

@Injectable()
export class MedicinesService {
  constructor(private prisma: PrismaService) {}

  async addMedicine(prescriptionId: string, patientId: string, dto: CreateMedicineDto) {
    // Verify prescription exists and belongs to patient
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
      include: { medications: true },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    if (prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    // Only allow editing patient-created prescriptions (doctorId is null)
    if (prescription.doctorId) {
      throw new ForbiddenException('Cannot add medicines to doctor-issued prescriptions');
    }

    const rowNumber = prescription.medications.length + 1;

    // Build dosage objects from dto
    const morningDosage = dto.scheduleTimes?.some(st => st.timePeriod === 'MORNING')
      ? { amount: `${dto.dosageAmount}${dto.dosageUnit}`, beforeMeal: dto.beforeMeal || false }
      : null;
    const daytimeDosage = dto.scheduleTimes?.some(st => st.timePeriod === 'DAYTIME')
      ? { amount: `${dto.dosageAmount}${dto.dosageUnit}`, beforeMeal: dto.beforeMeal || false }
      : null;
    const nightDosage = dto.scheduleTimes?.some(st => st.timePeriod === 'NIGHT')
      ? { amount: `${dto.dosageAmount}${dto.dosageUnit}`, beforeMeal: dto.beforeMeal || false }
      : null;

    // Default: if no schedule times specified, set to morning
    const hasTimes = morningDosage || daytimeDosage || nightDosage;

    const medicine = await this.prisma.medication.create({
      data: {
        prescriptionId,
        rowNumber,
        medicineName: dto.medicineName,
        medicineNameKhmer: dto.medicineNameKhmer,
        morningDosage: hasTimes ? (morningDosage || Prisma.DbNull) : { amount: `${dto.dosageAmount}${dto.dosageUnit}`, beforeMeal: dto.beforeMeal || false },
        daytimeDosage: hasTimes ? (daytimeDosage || Prisma.DbNull) : Prisma.DbNull,
        nightDosage: hasTimes ? (nightDosage || Prisma.DbNull) : Prisma.DbNull,
        imageUrl: dto.imageUrl,
        frequency: dto.frequency || '1ដង/១ថ្ងៃ',
        timing: dto.beforeMeal ? 'មុនអាហារ' : 'បន្ទាប់ពីអាហារ',
      },
    });

    // Generate dose events for this medicine if prescription is ACTIVE
    if (prescription.status === 'ACTIVE' && !dto.isPRN) {
      await this.generateDoseEventsForMedicine(prescriptionId, medicine.id, patientId, medicine);
    }

    // Create audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Medication',
        resourceId: medicine.id,
        details: { action: 'MEDICINE_ADDED', medicineName: dto.medicineName },
      },
    });

    return medicine;
  }

  async getMedicines(prescriptionId: string, userId: string) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    // Allow access if user is the patient, the doctor, or has a connection
    if (prescription.patientId !== userId && prescription.doctorId !== userId) {
      // Check for family/doctor connection
      const connection = await this.prisma.connection.findFirst({
        where: {
          OR: [
            { initiatorId: userId, recipientId: prescription.patientId },
            { initiatorId: prescription.patientId, recipientId: userId },
          ],
          status: 'ACCEPTED',
        },
      });
      if (!connection) {
        throw new ForbiddenException('Access denied');
      }
    }

    return this.prisma.medication.findMany({
      where: { prescriptionId },
      orderBy: { rowNumber: 'asc' },
    });
  }

  async getMedicineById(id: string, userId: string) {
    const medicine = await this.prisma.medication.findUnique({
      where: { id },
      include: {
        prescription: true,
        doseEvents: {
          orderBy: { scheduledTime: 'desc' },
          take: 50,
        },
      },
    });

    if (!medicine) {
      throw new NotFoundException('Medicine not found');
    }

    // Check access
    if (medicine.prescription.patientId !== userId && medicine.prescription.doctorId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    // Compute whether medicine can be edited
    const hasTakenDoses = medicine.doseEvents.some(
      d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
    );

    return {
      ...medicine,
      canEdit: !hasTakenDoses && !medicine.prescription.doctorId,
      totalDoses: medicine.doseEvents.length,
      takenDoses: medicine.doseEvents.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length,
      missedDoses: medicine.doseEvents.filter(d => d.status === 'MISSED').length,
      skippedDoses: medicine.doseEvents.filter(d => d.status === 'SKIPPED').length,
    };
  }

  async updateMedicine(id: string, patientId: string, dto: UpdateMedicineDto) {
    const medicine = await this.prisma.medication.findUnique({
      where: { id },
      include: { prescription: true, doseEvents: true },
    });

    if (!medicine) {
      throw new NotFoundException('Medicine not found');
    }

    if (medicine.prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    if (medicine.prescription.doctorId) {
      throw new ForbiddenException('Cannot edit medicines from doctor-issued prescriptions');
    }

    // Check if any doses have been taken
    const hasTakenDoses = medicine.doseEvents.some(
      d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
    );

    if (hasTakenDoses) {
      throw new BadRequestException('Cannot edit medicine after first dose. Create a new medicine instead.');
    }

    // Build update data
    const updateData: any = {};
    if (dto.medicineName) updateData.medicineName = dto.medicineName;
    if (dto.medicineNameKhmer !== undefined) updateData.medicineNameKhmer = dto.medicineNameKhmer;
    if (dto.imageUrl !== undefined) updateData.imageUrl = dto.imageUrl;
    if (dto.beforeMeal !== undefined) {
      updateData.timing = dto.beforeMeal ? 'មុនអាហារ' : 'បន្ទាប់ពីអាហារ';
    }

    // Update dosage fields if schedule times provided
    if (dto.scheduleTimes) {
      const dosageStr = `${dto.dosageAmount || ''}${dto.dosageUnit || ''}`;
      const bm = dto.beforeMeal || false;
      updateData.morningDosage = dto.scheduleTimes.some((st: any) => st.timePeriod === 'MORNING')
        ? { amount: dosageStr, beforeMeal: bm } : Prisma.DbNull;
      updateData.daytimeDosage = dto.scheduleTimes.some((st: any) => st.timePeriod === 'DAYTIME')
        ? { amount: dosageStr, beforeMeal: bm } : Prisma.DbNull;
      updateData.nightDosage = dto.scheduleTimes.some((st: any) => st.timePeriod === 'NIGHT')
        ? { amount: dosageStr, beforeMeal: bm } : Prisma.DbNull;
    }

    if (dto.frequency) updateData.frequency = dto.frequency;

    const updated = await this.prisma.medication.update({
      where: { id },
      data: updateData,
    });

    // Regenerate dose events if prescription is active
    if (medicine.prescription.status === 'ACTIVE') {
      // Delete existing DUE dose events for this medicine
      await this.prisma.doseEvent.deleteMany({
        where: { medicationId: id, status: 'DUE' },
      });
      // Regenerate
      await this.generateDoseEventsForMedicine(
        medicine.prescriptionId,
        id,
        medicine.prescription.patientId,
        updated,
      );
    }

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Medication',
        resourceId: id,
        details: { action: 'MEDICINE_UPDATED', changes: JSON.parse(JSON.stringify(dto)) },
      },
    });

    return updated;
  }

  async deleteMedicine(id: string, patientId: string) {
    const medicine = await this.prisma.medication.findUnique({
      where: { id },
      include: { prescription: true },
    });

    if (!medicine) {
      throw new NotFoundException('Medicine not found');
    }

    if (medicine.prescription.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    if (medicine.prescription.doctorId) {
      throw new ForbiddenException('Cannot delete medicines from doctor-issued prescriptions');
    }

    // Delete cascades to dose events
    await this.prisma.medication.delete({ where: { id } });

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Medication',
        resourceId: id,
        details: { action: 'MEDICINE_DELETED', medicineName: medicine.medicineName },
      },
    });

    return { message: 'Medicine deleted successfully' };
  }

  async getArchivedMedicines(patientId: string) {
    // Get medications from inactive/completed prescriptions
    return this.prisma.medication.findMany({
      where: {
        prescription: {
          patientId,
          status: 'INACTIVE',
        },
      },
      include: {
        prescription: {
          select: { id: true, patientName: true, status: true, createdAt: true },
        },
        doseEvents: {
          select: { status: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getDosesForMedicine(medicineId: string, userId: string) {
    const medicine = await this.prisma.medication.findUnique({
      where: { id: medicineId },
      include: { prescription: true },
    });

    if (!medicine) {
      throw new NotFoundException('Medicine not found');
    }

    if (medicine.prescription.patientId !== userId && medicine.prescription.doctorId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return this.prisma.doseEvent.findMany({
      where: { medicationId: medicineId },
      orderBy: { scheduledTime: 'desc' },
    });
  }

  private async generateDoseEventsForMedicine(
    prescriptionId: string,
    medicationId: string,
    patientId: string,
    medication: any,
  ) {
    const today = new Date();
    const events: any[] = [];

    for (let day = 0; day < 30; day++) {
      const date = new Date(today);
      date.setDate(date.getDate() + day);

      if (medication.morningDosage) {
        const scheduledTime = new Date(date);
        scheduledTime.setHours(7, 0, 0, 0);
        events.push({
          prescriptionId,
          medicationId,
          patientId,
          scheduledTime,
          timePeriod: 'DAYTIME' as const,
          status: 'DUE' as const,
          reminderTime: '07:00',
        });
      }

      if (medication.daytimeDosage) {
        const scheduledTime = new Date(date);
        scheduledTime.setHours(12, 0, 0, 0);
        events.push({
          prescriptionId,
          medicationId,
          patientId,
          scheduledTime,
          timePeriod: 'DAYTIME' as const,
          status: 'DUE' as const,
          reminderTime: '12:00',
        });
      }

      if (medication.nightDosage) {
        const scheduledTime = new Date(date);
        scheduledTime.setHours(20, 0, 0, 0);
        events.push({
          prescriptionId,
          medicationId,
          patientId,
          scheduledTime,
          timePeriod: 'NIGHT' as const,
          status: 'DUE' as const,
          reminderTime: '20:00',
        });
      }
    }

    if (events.length > 0) {
      await this.prisma.doseEvent.createMany({ data: events });
    }
  }
}
