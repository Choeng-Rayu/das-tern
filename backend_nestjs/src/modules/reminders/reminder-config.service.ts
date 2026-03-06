import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { ReminderGeneratorService } from './reminder-generator.service';

@Injectable()
export class ReminderConfigService {
  constructor(
    private prisma: PrismaService,
    private reminderGenerator: ReminderGeneratorService,
  ) {}

  /**
   * Update grace period for missed dose detection.
   */
  async updateGracePeriod(patientId: string, minutes: number) {
    if (![10, 20, 30, 60].includes(minutes)) {
      throw new BadRequestException('Grace period must be 10, 20, 30, or 60 minutes');
    }

    await this.prisma.user.update({
      where: { id: patientId },
      data: { gracePeriodMinutes: minutes },
    });
  }

  /**
   * Update repeat reminder settings.
   */
  async updateRepeatFrequency(patientId: string, enabled: boolean, intervalMinutes?: number) {
    const data: any = { repeatRemindersEnabled: enabled };
    if (intervalMinutes !== undefined) {
      data.repeatIntervalMinutes = intervalMinutes;
    }

    await this.prisma.user.update({
      where: { id: patientId },
      data,
    });
  }

  /**
   * Toggle reminders on/off for a specific medication.
   */
  async toggleReminders(patientId: string, medicationId: string, enabled: boolean) {
    const medication = await this.prisma.medication.findUnique({
      where: { id: medicationId },
      include: { prescription: { select: { patientId: true } } },
    });

    if (!medication || medication.prescription.patientId !== patientId) {
      throw new NotFoundException('Medication not found');
    }

    await this.prisma.medication.update({
      where: { id: medicationId },
      data: { remindersEnabled: enabled },
    });

    if (!enabled) {
      // Cancel pending reminders
      await this.prisma.reminder.deleteMany({
        where: {
          medicationId,
          status: 'PENDING',
          scheduledTime: { gt: new Date() },
        },
      });
    } else {
      // Regenerate reminders
      await this.reminderGenerator.regenerateRemindersForMedication(medicationId);
    }

    return { medicationId, remindersEnabled: enabled };
  }

  /**
   * Update custom reminder time for a medication's specific time period.
   */
  async updateReminderTime(
    patientId: string,
    medicationId: string,
    timePeriod: string,
    newTime: string,
  ) {
    // Validate HH:mm format
    if (!/^\d{2}:\d{2}$/.test(newTime)) {
      throw new BadRequestException('Time must be in HH:mm format');
    }

    const medication = await this.prisma.medication.findUnique({
      where: { id: medicationId },
      include: { prescription: { select: { patientId: true } } },
    });

    if (!medication || medication.prescription.patientId !== patientId) {
      throw new NotFoundException('Medication not found');
    }

    const key = timePeriod === 'MORNING' ? 'morning' : timePeriod === 'DAYTIME' ? 'daytime' : 'night';
    const customTimes = (medication.customTimes as any) || {};
    customTimes[key] = newTime;

    await this.prisma.medication.update({
      where: { id: medicationId },
      data: { customTimes },
    });

    // Regenerate reminders with new time
    const result = await this.reminderGenerator.regenerateRemindersForMedication(medicationId);

    return { medication: { id: medicationId, customTimes }, regeneratedCount: result.count };
  }

  /**
   * Get all reminder settings for a patient.
   */
  async getReminderSettings(patientId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: patientId },
      select: {
        gracePeriodMinutes: true,
        repeatRemindersEnabled: true,
        repeatIntervalMinutes: true,
      },
    });

    if (!user) throw new NotFoundException('User not found');

    // Get medication-specific settings
    const medications = await this.prisma.medication.findMany({
      where: {
        prescription: { patientId, status: 'ACTIVE' },
      },
      select: {
        id: true,
        medicineName: true,
        remindersEnabled: true,
        customTimes: true,
      },
    });

    const medicationSettings: Record<string, any> = {};
    for (const med of medications) {
      medicationSettings[med.id] = {
        medicineName: med.medicineName,
        remindersEnabled: med.remindersEnabled,
        customTimes: med.customTimes,
      };
    }

    return {
      gracePeriodMinutes: user.gracePeriodMinutes,
      repeatRemindersEnabled: user.repeatRemindersEnabled,
      repeatIntervalMinutes: user.repeatIntervalMinutes,
      medicationSettings,
    };
  }
}
