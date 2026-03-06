import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class ReminderGeneratorService {
  private readonly logger = new Logger(ReminderGeneratorService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Generate reminders for all non-PRN medications in a prescription.
   * Creates PENDING reminders for the next 30 days (or medication duration).
   */
  async generateRemindersForPrescription(prescriptionId: string) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
      include: {
        medications: true,
        patient: {
          include: { mealTimePreference: true },
        },
      },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    const mealPrefs = prescription.patient.mealTimePreference;
    if (!mealPrefs) {
      throw new BadRequestException('Please set your meal time preferences first');
    }

    const reminders: any[] = [];
    const now = new Date();
    const startDate = prescription.startDate ? new Date(prescription.startDate) : now;

    for (const medication of prescription.medications) {
      // Skip PRN medications
      if (medication.isPRN) continue;
      // Skip medications with reminders disabled
      if (!medication.remindersEnabled) continue;

      const durationDays = medication.duration || 30;
      const endDate = prescription.endDate
        ? new Date(prescription.endDate)
        : new Date(startDate.getTime() + durationDays * 24 * 60 * 60 * 1000);

      // Cap at 30 days from now
      const maxDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
      const effectiveEnd = endDate < maxDate ? endDate : maxDate;

      const periods: { period: string; dosage: any }[] = [];
      if (medication.morningDosage) periods.push({ period: 'MORNING', dosage: medication.morningDosage });
      if (medication.daytimeDosage) periods.push({ period: 'DAYTIME', dosage: medication.daytimeDosage });
      if (medication.nightDosage) periods.push({ period: 'NIGHT', dosage: medication.nightDosage });

      for (const { period } of periods) {
        const timeStr = this.calculateReminderTime(
          period as any,
          mealPrefs,
          medication.beforeMeal,
          medication.customTimes as any,
        );

        if (!timeStr) continue;

        const [hours, minutes] = timeStr.split(':').map(Number);

        // Generate a reminder for each day
        const current = new Date(Math.max(startDate.getTime(), now.getTime()));
        current.setHours(hours, minutes, 0, 0);

        // If today's time has passed, start from tomorrow
        if (current <= now) {
          current.setDate(current.getDate() + 1);
        }

        while (current <= effectiveEnd) {
          reminders.push({
            patientId: prescription.patientId,
            medicationId: medication.id,
            prescriptionId: prescription.id,
            scheduledTime: new Date(current),
            timePeriod: period,
            status: 'PENDING',
          });
          current.setDate(current.getDate() + 1);
        }
      }
    }

    if (reminders.length === 0) {
      return { reminders: [], count: 0 };
    }

    // Batch create
    await this.prisma.reminder.createMany({ data: reminders });

    const created = await this.prisma.reminder.findMany({
      where: { prescriptionId },
      orderBy: { scheduledTime: 'asc' },
      include: {
        medication: { select: { id: true, medicineName: true, medicineNameKhmer: true, dosageAmount: true, unit: true } },
      },
    });

    this.logger.log(`Generated ${created.length} reminders for prescription ${prescriptionId}`);
    return { reminders: created, count: created.length };
  }

  /**
   * Calculate the reminder time based on meal preferences and medication timing.
   * Returns "HH:mm" string or null if cannot calculate.
   */
  calculateReminderTime(
    timePeriod: string,
    mealPrefs: { morningMeal?: string | null; afternoonMeal?: string | null; nightMeal?: string | null },
    beforeMeal: boolean,
    customTimes?: { morning?: string; daytime?: string; night?: string } | null,
  ): string | null {
    // Check for custom times first
    if (customTimes) {
      const key = timePeriod === 'MORNING' ? 'morning' : timePeriod === 'DAYTIME' ? 'daytime' : 'night';
      if (customTimes[key]) return customTimes[key];
    }

    // Use meal preference
    let mealTime: string | null | undefined;
    switch (timePeriod) {
      case 'MORNING': mealTime = mealPrefs.morningMeal; break;
      case 'DAYTIME': mealTime = mealPrefs.afternoonMeal; break;
      case 'NIGHT': mealTime = mealPrefs.nightMeal; break;
    }

    if (!mealTime) return null;

    // Parse meal time
    const [hours, minutes] = mealTime.split(':').map(Number);
    if (isNaN(hours) || isNaN(minutes)) return null;

    // Apply offset: -15 minutes if beforeMeal, +0 if afterMeal
    if (beforeMeal) {
      const totalMinutes = hours * 60 + minutes - 15;
      const h = Math.floor(totalMinutes / 60);
      const m = totalMinutes % 60;
      return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
    }

    return mealTime;
  }

  /**
   * Regenerate reminders for a specific medication.
   * Deletes existing PENDING reminders and creates new ones.
   */
  async regenerateRemindersForMedication(medicationId: string) {
    const medication = await this.prisma.medication.findUnique({
      where: { id: medicationId },
      include: { prescription: true },
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Delete existing PENDING reminders
    await this.prisma.reminder.deleteMany({
      where: {
        medicationId,
        status: 'PENDING',
        scheduledTime: { gt: new Date() },
      },
    });

    // Regenerate via prescription
    return this.generateRemindersForPrescription(medication.prescriptionId);
  }

  /**
   * Delete all PENDING reminders for a prescription.
   */
  async deleteRemindersForPrescription(prescriptionId: string) {
    const result = await this.prisma.reminder.deleteMany({
      where: {
        prescriptionId,
        status: 'PENDING',
      },
    });
    this.logger.log(`Deleted ${result.count} pending reminders for prescription ${prescriptionId}`);
  }
}
