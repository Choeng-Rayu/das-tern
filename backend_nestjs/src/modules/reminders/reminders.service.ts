import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class RemindersService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get upcoming reminders for a patient.
   */
  async getUpcomingReminders(patientId: string, days: number = 7, limit: number = 50) {
    const now = new Date();
    const endDate = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    const reminders = await this.prisma.reminder.findMany({
      where: {
        patientId,
        status: { in: ['PENDING', 'DELIVERED', 'SNOOZED'] },
        scheduledTime: { gte: now, lte: endDate },
      },
      include: {
        medication: {
          select: {
            id: true,
            medicineName: true,
            medicineNameKhmer: true,
            dosageAmount: true,
            unit: true,
            imageUrl: true,
            beforeMeal: true,
          },
        },
      },
      orderBy: { scheduledTime: 'asc' },
      take: limit,
    });

    return reminders;
  }

  /**
   * Get reminder history with pagination and filters.
   */
  async getReminderHistory(
    patientId: string,
    filters: {
      startDate?: string;
      endDate?: string;
      status?: string;
      medicationId?: string;
      page?: number;
    },
  ) {
    const page = filters.page || 1;
    const pageSize = 50;
    const skip = (page - 1) * pageSize;

    // Max 90 days in the past
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const where: any = {
      patientId,
      scheduledTime: { gte: ninetyDaysAgo },
    };

    if (filters.startDate) {
      where.scheduledTime = { ...where.scheduledTime, gte: new Date(filters.startDate) };
    }
    if (filters.endDate) {
      where.scheduledTime = { ...where.scheduledTime, lte: new Date(filters.endDate) };
    }
    if (filters.status) {
      where.status = filters.status;
    }
    if (filters.medicationId) {
      where.medicationId = filters.medicationId;
    }

    const [reminders, total] = await Promise.all([
      this.prisma.reminder.findMany({
        where,
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
          doseEvent: {
            select: {
              id: true,
              status: true,
              takenAt: true,
              skipReason: true,
            },
          },
        },
        orderBy: { scheduledTime: 'desc' },
        skip,
        take: pageSize,
      }),
      this.prisma.reminder.count({ where }),
    ]);

    return {
      reminders,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  /**
   * Find a reminder by ID and verify ownership.
   */
  async findById(id: string, patientId: string) {
    const reminder = await this.prisma.reminder.findUnique({
      where: { id },
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

    if (!reminder) {
      throw new NotFoundException('Reminder not found');
    }

    if (reminder.patientId !== patientId) {
      throw new NotFoundException('Reminder not found');
    }

    return reminder;
  }
}
