import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ReminderSchedulerJob {
  private readonly logger = new Logger(ReminderSchedulerJob.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Runs every minute to deliver due reminders and re-deliver snoozed ones.
   */
  @Cron('* * * * *')
  async deliverReminders() {
    try {
      await this.deliverPendingReminders();
      await this.redeliverSnoozedReminders();
    } catch (error) {
      this.logger.error('Error in reminder delivery job', error);
    }
  }

  /**
   * Runs every 10 minutes to send repeat reminders.
   */
  @Cron('*/10 * * * *')
  async processRepeatReminders() {
    try {
      const now = new Date();

      // Find DELIVERED reminders with no dose event where repeat is needed
      const reminders = await this.prisma.reminder.findMany({
        where: {
          status: 'DELIVERED',
          doseEvent: null,
          repeatCount: { lt: 3 },
        },
        include: {
          patient: {
            select: {
              id: true,
              fullName: true,
              firstName: true,
              repeatRemindersEnabled: true,
              repeatIntervalMinutes: true,
              language: true,
            },
          },
          medication: {
            select: { id: true, medicineName: true, medicineNameKhmer: true, dosageAmount: true, unit: true },
          },
        },
      });

      for (const reminder of reminders) {
        // Skip if repeat reminders disabled for this patient
        if (!reminder.patient.repeatRemindersEnabled) continue;

        // Check if enough time has passed since delivery
        if (!reminder.deliveredAt) continue;
        const intervalMs = (reminder.patient.repeatIntervalMinutes || 10) * 60 * 1000;
        const nextRepeatTime = new Date(reminder.deliveredAt.getTime() + intervalMs * (reminder.repeatCount + 1));

        if (now < nextRepeatTime) continue;

        // Send repeat notification
        const patientName = reminder.patient.fullName || reminder.patient.firstName || 'Patient';
        const medName = reminder.medication.medicineName;
        const time = reminder.scheduledTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

        await this.notificationsService.send(
          reminder.patientId,
          'REMINDER_DELIVERED',
          `[Repeat] Dose Reminder`,
          `Reminder: Time to take ${medName} (scheduled at ${time})`,
          {
            reminderId: reminder.id,
            medicationId: reminder.medicationId,
            scheduledTime: reminder.scheduledTime.toISOString(),
            isRepeat: true,
            repeatCount: reminder.repeatCount + 1,
          },
        );

        // Increment repeat count
        await this.prisma.reminder.update({
          where: { id: reminder.id },
          data: { repeatCount: { increment: 1 } },
        });

        this.logger.debug(`Sent repeat reminder #${reminder.repeatCount + 1} for reminder ${reminder.id}`);
      }
    } catch (error) {
      this.logger.error('Error in repeat reminder job', error);
    }
  }

  /**
   * Find and deliver PENDING reminders that are due.
   */
  private async deliverPendingReminders() {
    const now = new Date();

    const dueReminders = await this.prisma.reminder.findMany({
      where: {
        status: 'PENDING',
        scheduledTime: { lte: now },
      },
      include: {
        patient: {
          select: { id: true, fullName: true, firstName: true, language: true },
        },
        medication: {
          select: { id: true, medicineName: true, medicineNameKhmer: true, dosageAmount: true, unit: true },
        },
      },
    });

    if (dueReminders.length === 0) return;

    this.logger.log(`Delivering ${dueReminders.length} due reminders`);

    for (const reminder of dueReminders) {
      try {
        // Update status to DELIVERED
        await this.prisma.reminder.update({
          where: { id: reminder.id },
          data: {
            status: 'DELIVERED',
            deliveredAt: now,
          },
        });

        // Create notification record for in-app display
        const medName = reminder.medication.medicineName;
        const time = reminder.scheduledTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

        await this.notificationsService.send(
          reminder.patientId,
          'REMINDER_DELIVERED',
          'Dose Reminder',
          `Time to take ${medName} (${time})`,
          {
            reminderId: reminder.id,
            medicationId: reminder.medicationId,
            scheduledTime: reminder.scheduledTime.toISOString(),
            isRepeat: false,
          },
        );
      } catch (error) {
        this.logger.error(`Failed to deliver reminder ${reminder.id}`, error);
        // Mark as FAILED after logging
        await this.prisma.reminder.update({
          where: { id: reminder.id },
          data: { status: 'FAILED' },
        });
      }
    }
  }

  /**
   * Re-deliver snoozed reminders past their snoozedUntil time.
   */
  private async redeliverSnoozedReminders() {
    const now = new Date();

    const snoozedReminders = await this.prisma.reminder.findMany({
      where: {
        status: 'SNOOZED',
        snoozedUntil: { lte: now },
      },
      include: {
        patient: {
          select: { id: true, fullName: true, firstName: true, language: true },
        },
        medication: {
          select: { id: true, medicineName: true, medicineNameKhmer: true, dosageAmount: true, unit: true },
        },
      },
    });

    for (const reminder of snoozedReminders) {
      try {
        await this.prisma.reminder.update({
          where: { id: reminder.id },
          data: {
            status: 'DELIVERED',
            deliveredAt: now,
            snoozedUntil: null,
          },
        });

        const medName = reminder.medication.medicineName;
        const time = reminder.scheduledTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

        await this.notificationsService.send(
          reminder.patientId,
          'REMINDER_DELIVERED',
          'Dose Reminder (Snoozed)',
          `Reminder: Time to take ${medName} (originally scheduled at ${time})`,
          {
            reminderId: reminder.id,
            medicationId: reminder.medicationId,
            scheduledTime: reminder.scheduledTime.toISOString(),
            isSnoozedRedelivery: true,
          },
        );

        this.logger.debug(`Re-delivered snoozed reminder ${reminder.id}`);
      } catch (error) {
        this.logger.error(`Failed to re-deliver snoozed reminder ${reminder.id}`, error);
      }
    }
  }
}
