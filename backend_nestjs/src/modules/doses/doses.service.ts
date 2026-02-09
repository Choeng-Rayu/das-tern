import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { DoseEventStatus } from '@prisma/client';

@Injectable()
export class DosesService {
  constructor(private prisma: PrismaService) {}

  async getSchedule(patientId: string, date?: string, groupBy?: string) {
    const targetDate = date ? new Date(date) : new Date();
    targetDate.setHours(0, 0, 0, 0);
    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: targetDate, lt: nextDay },
      },
      include: {
        medication: true,
        prescription: true,
      },
      orderBy: { scheduledTime: 'asc' },
    });

    const dailyProgress = await this.calculateDailyProgress(patientId, targetDate);

    if (groupBy === 'TIME_PERIOD') {
      return {
        date: targetDate.toISOString(),
        dailyProgress,
        groups: [
          {
            period: 'DAYTIME',
            color: '#2D5BFF',
            doses: doses.filter(d => d.timePeriod === 'DAYTIME').map(this.formatDose),
          },
          {
            period: 'NIGHT',
            color: '#6B4AA3',
            doses: doses.filter(d => d.timePeriod === 'NIGHT').map(this.formatDose),
          },
        ],
      };
    }

    return { date: targetDate.toISOString(), dailyProgress, doses: doses.map(this.formatDose) };
  }

  async markTaken(id: string, patientId: string, takenAt?: string, offline = false) {
    const dose = await this.prisma.doseEvent.findUnique({ where: { id } });
    
    if (!dose) {
      throw new NotFoundException('Dose event not found');
    }

    const takenTime = takenAt ? new Date(takenAt) : new Date();
    const status = this.applyTimeWindowLogic(dose.scheduledTime, takenTime);

    await this.prisma.doseEvent.update({
      where: { id },
      data: { status, takenAt: takenTime, wasOffline: offline },
    });

    const dailyProgress = await this.calculateDailyProgress(patientId, dose.scheduledTime);

    return { dose: await this.prisma.doseEvent.findUnique({ where: { id } }), dailyProgress };
  }

  async skip(id: string, patientId: string, reason: string) {
    return this.prisma.doseEvent.update({
      where: { id },
      data: { status: 'SKIPPED', skipReason: reason },
    });
  }

  async getHistory(patientId: string, startDate?: string, endDate?: string) {
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: start, lte: end },
      },
      include: { medication: true },
      orderBy: { scheduledTime: 'desc' },
    });

    const adherencePercentage = this.calculateAdherence(doses);

    return { doses, adherencePercentage, total: doses.length };
  }

  private async calculateDailyProgress(patientId: string, date: Date): Promise<number> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: startOfDay, lt: endOfDay },
      },
    });

    if (doses.length === 0) return 0;

    const takenCount = doses.filter(d => 
      d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
    ).length;

    return Math.round((takenCount / doses.length) * 100);
  }

  private applyTimeWindowLogic(scheduledTime: Date, takenAt: Date): DoseEventStatus {
    const diffMinutes = (takenAt.getTime() - scheduledTime.getTime()) / 60000;

    if (diffMinutes >= -30 && diffMinutes <= 30) {
      return 'TAKEN_ON_TIME';
    } else if (diffMinutes > 30 && diffMinutes <= 120) {
      return 'TAKEN_LATE';
    } else {
      return 'MISSED';
    }
  }

  private calculateAdherence(doses: any[]): number {
    if (doses.length === 0) return 0;

    const takenCount = doses.filter(d => 
      d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
    ).length;

    return Math.round((takenCount / doses.length) * 100);
  }

  private formatDose(dose: any) {
    return {
      id: dose.id,
      medicationName: dose.medication.medicineName,
      medicationNameKhmer: dose.medication.medicineNameKhmer,
      dosage: this.getDosageForPeriod(dose.medication, dose.timePeriod),
      imageUrl: dose.medication.imageUrl,
      scheduledTime: dose.scheduledTime,
      status: dose.status,
      frequency: dose.medication.frequency,
      timing: dose.medication.timing,
      reminderTime: dose.reminderTime,
    };
  }

  private getDosageForPeriod(medication: any, period: string): string {
    if (period === 'DAYTIME') {
      return medication.morningDosage?.amount || medication.daytimeDosage?.amount || '';
    }
    return medication.nightDosage?.amount || '';
  }
}
