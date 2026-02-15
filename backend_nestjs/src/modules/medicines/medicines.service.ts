import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { Prisma, MedicineUnit } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import { CreateMedicineDto, UpdateMedicineDto } from './dto';

@Injectable()
export class MedicinesService {
  constructor(private prisma: PrismaService) {}

  async addMedicine(prescriptionId: string, userId: string, dto: CreateMedicineDto, userRole: string) {
    // Verify prescription exists
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
      include: { medications: true },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    // Permission logic:
    // - Patient can add to their own patient-created prescriptions (doctorId is null)
    // - Doctor can add to their own doctor-created prescriptions
    if (prescription.doctorId) {
      if (prescription.doctorId !== userId) {
        throw new ForbiddenException('Cannot modify another doctor\'s prescription');
      }
    } else {
      if (prescription.patientId !== userId) {
        throw new ForbiddenException('Access denied');
      }
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
        medicineType: dto.medicineType || 'ORAL',
        unit: dto.unit || this.mapDosageUnit(dto.dosageUnit),
        dosageAmount: dto.dosageAmount,
        description: dto.description,
        additionalNote: dto.additionalNote,
        createdBy: userId,
        morningDosage: hasTimes ? (morningDosage || Prisma.DbNull) : { amount: `${dto.dosageAmount}${dto.dosageUnit}`, beforeMeal: dto.beforeMeal || false },
        daytimeDosage: hasTimes ? (daytimeDosage || Prisma.DbNull) : Prisma.DbNull,
        nightDosage: hasTimes ? (nightDosage || Prisma.DbNull) : Prisma.DbNull,
        imageUrl: dto.imageUrl,
        frequency: dto.frequency || '1ដង/១ថ្ងៃ',
        duration: dto.durationDays || null,
        timing: dto.beforeMeal ? 'មុនអាហារ' : 'បន្ទាប់ពីអាហារ',
        isPRN: dto.isPRN || false,
        beforeMeal: dto.beforeMeal || false,
      },
    });

    // Generate dose events for this medicine if prescription is ACTIVE
    if (prescription.status === 'ACTIVE' && !dto.isPRN) {
      await this.generateDoseEventsForMedicine(prescriptionId, medicine.id, prescription.patientId, medicine);
    }

    // Create audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: userId,
        actorRole: userRole as any,
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

    const hasTakenDoses = medicine.doseEvents.some(
      d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
    );

    return {
      ...medicine,
      canEdit: !hasTakenDoses && (
        (!medicine.prescription.doctorId && medicine.prescription.patientId === userId) ||
        (medicine.prescription.doctorId === userId)
      ),
      totalDoses: medicine.doseEvents.length,
      takenDoses: medicine.doseEvents.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length,
      missedDoses: medicine.doseEvents.filter(d => d.status === 'MISSED').length,
      skippedDoses: medicine.doseEvents.filter(d => d.status === 'SKIPPED').length,
    };
  }

  async updateMedicine(id: string, userId: string, dto: UpdateMedicineDto, userRole: string) {
    const medicine = await this.prisma.medication.findUnique({
      where: { id },
      include: { prescription: true, doseEvents: true },
    });

    if (!medicine) {
      throw new NotFoundException('Medicine not found');
    }

    // Permission logic: doctor can edit own prescription, patient can edit patient-created
    if (medicine.prescription.doctorId) {
      if (medicine.prescription.doctorId !== userId) {
        throw new ForbiddenException('Cannot edit medicines from another doctor\'s prescription');
      }
    } else {
      if (medicine.prescription.patientId !== userId) {
        throw new ForbiddenException('Access denied');
      }
    }

    // Check if any doses have been taken (only restrict for non-doctor edits)
    if (!medicine.prescription.doctorId) {
      const hasTakenDoses = medicine.doseEvents.some(
        d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
      );
      if (hasTakenDoses) {
        throw new BadRequestException('Cannot edit medicine after first dose. Create a new medicine instead.');
      }
    }

    // Build update data
    const updateData: any = {};
    if (dto.medicineName) updateData.medicineName = dto.medicineName;
    if (dto.medicineNameKhmer !== undefined) updateData.medicineNameKhmer = dto.medicineNameKhmer;
    if (dto.medicineType !== undefined) updateData.medicineType = dto.medicineType;
    if (dto.unit !== undefined) updateData.unit = dto.unit;
    if (dto.dosageAmount !== undefined) updateData.dosageAmount = dto.dosageAmount;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.additionalNote !== undefined) updateData.additionalNote = dto.additionalNote;
    if (dto.durationDays !== undefined) updateData.duration = dto.durationDays;
    if (dto.isPRN !== undefined) updateData.isPRN = dto.isPRN;
    if (dto.imageUrl !== undefined) updateData.imageUrl = dto.imageUrl;
    if (dto.beforeMeal !== undefined) {
      updateData.beforeMeal = dto.beforeMeal;
      updateData.timing = dto.beforeMeal ? 'មុនអាហារ' : 'បន្ទាប់ពីអាហារ';
    }

    // Update dosage fields if schedule times provided
    if (dto.scheduleTimes) {
      const dosageStr = `${dto.dosageAmount || medicine.dosageAmount}${dto.dosageUnit || ''}`;
      const bm = dto.beforeMeal ?? medicine.beforeMeal;
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
      await this.prisma.doseEvent.deleteMany({
        where: { medicationId: id, status: 'DUE' },
      });
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
        actorId: userId,
        actorRole: userRole as any,
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Medication',
        resourceId: id,
        details: { action: 'MEDICINE_UPDATED', changes: JSON.parse(JSON.stringify(dto)) },
      },
    });

    return updated;
  }

  async deleteMedicine(id: string, userId: string, userRole: string) {
    const medicine = await this.prisma.medication.findUnique({
      where: { id },
      include: { prescription: true },
    });

    if (!medicine) {
      throw new NotFoundException('Medicine not found');
    }

    // Permission logic
    if (medicine.prescription.doctorId) {
      if (medicine.prescription.doctorId !== userId) {
        throw new ForbiddenException('Cannot delete medicines from another doctor\'s prescription');
      }
    } else {
      if (medicine.prescription.patientId !== userId) {
        throw new ForbiddenException('Access denied');
      }
    }

    // Delete cascades to dose events
    await this.prisma.medication.delete({ where: { id } });

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: userId,
        actorRole: userRole as any,
        actionType: 'PRESCRIPTION_UPDATE',
        resourceType: 'Medication',
        resourceId: id,
        details: { action: 'MEDICINE_DELETED', medicineName: medicine.medicineName },
      },
    });

    return { message: 'Medicine deleted successfully' };
  }

  async getArchivedMedicines(patientId: string) {
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

  private mapDosageUnit(unitStr: string): MedicineUnit {
    const mapping: Record<string, MedicineUnit> = {
      tablet: 'TABLET',
      tablets: 'TABLET',
      capsule: 'CAPSULE',
      capsules: 'CAPSULE',
      ml: 'ML',
      mg: 'MG',
      drop: 'DROP',
      drops: 'DROP',
    };
    return mapping[unitStr.toLowerCase()] || 'OTHER';
  }

  private async generateDoseEventsForMedicine(
    prescriptionId: string,
    medicationId: string,
    patientId: string,
    medication: any,
  ) {
    const today = new Date();
    const events: any[] = [];
    const days = medication.duration || 30;

    // Try to get patient's meal time preferences for personalized dose times
    const mealPref = await this.prisma.mealTimePreference.findUnique({
      where: { userId: patientId },
    });

    const morningHour = mealPref?.morningMeal ? parseInt(mealPref.morningMeal.split(':')[0]) : 7;
    const morningMin = mealPref?.morningMeal ? parseInt(mealPref.morningMeal.split(':')[1]) : 0;
    const afternoonHour = mealPref?.afternoonMeal ? parseInt(mealPref.afternoonMeal.split(':')[0]) : 12;
    const afternoonMin = mealPref?.afternoonMeal ? parseInt(mealPref.afternoonMeal.split(':')[1]) : 0;
    const nightHour = mealPref?.nightMeal ? parseInt(mealPref.nightMeal.split(':')[0]) : 20;
    const nightMin = mealPref?.nightMeal ? parseInt(mealPref.nightMeal.split(':')[1]) : 0;

    for (let day = 0; day < days; day++) {
      const date = new Date(today);
      date.setDate(date.getDate() + day);

      if (medication.morningDosage) {
        const scheduledTime = new Date(date);
        scheduledTime.setHours(morningHour, morningMin, 0, 0);
        events.push({
          prescriptionId,
          medicationId,
          patientId,
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
          prescriptionId,
          medicationId,
          patientId,
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
          prescriptionId,
          medicationId,
          patientId,
          scheduledTime,
          timePeriod: 'NIGHT' as const,
          status: 'DUE' as const,
          reminderTime: `${String(nightHour).padStart(2, '0')}:${String(nightMin).padStart(2, '0')}`,
        });
      }
    }

    if (events.length > 0) {
      await this.prisma.doseEvent.createMany({ data: events });
    }
  }
}
