import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class SnoozeHandlerService {
  constructor(private prisma: PrismaService) {}

  /**
   * Snooze a reminder for the specified duration.
   */
  async snoozeReminder(reminderId: string, patientId: string, durationMinutes: number) {
    const reminder = await this.prisma.reminder.findUnique({
      where: { id: reminderId },
    });

    if (!reminder || reminder.patientId !== patientId) {
      throw new NotFoundException('Reminder not found');
    }

    if (!['DELIVERED', 'SNOOZED'].includes(reminder.status)) {
      throw new BadRequestException('Reminder cannot be snoozed in its current state');
    }

    if (reminder.snoozeCount >= 3) {
      throw new BadRequestException('Maximum snoozes reached (3)');
    }

    if (![5, 10, 15].includes(durationMinutes)) {
      throw new BadRequestException('Snooze duration must be 5, 10, or 15 minutes');
    }

    const snoozedUntil = new Date(Date.now() + durationMinutes * 60 * 1000);

    const updated = await this.prisma.reminder.update({
      where: { id: reminderId },
      data: {
        status: 'SNOOZED',
        snoozedUntil,
        snoozeCount: { increment: 1 },
      },
      include: {
        medication: {
          select: {
            id: true,
            medicineName: true,
            medicineNameKhmer: true,
            dosageAmount: true,
            unit: true,
          },
        },
      },
    });

    return {
      reminder: updated,
      newScheduledTime: snoozedUntil,
    };
  }

  /**
   * Check if a reminder can still be snoozed.
   */
  async canSnooze(reminderId: string): Promise<boolean> {
    const reminder = await this.prisma.reminder.findUnique({
      where: { id: reminderId },
      select: { snoozeCount: true, status: true },
    });

    if (!reminder) return false;
    return reminder.snoozeCount < 3 && ['DELIVERED', 'SNOOZED'].includes(reminder.status);
  }
}
