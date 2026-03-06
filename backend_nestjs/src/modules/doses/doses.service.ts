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

    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'DOSE_TAKEN',
        resourceType: 'DoseEvent',
        resourceId: id,
        details: { takenAt: takenTime.toISOString() },
      },
    });

    const dailyProgress = await this.calculateDailyProgress(patientId, dose.scheduledTime);

    return { dose: await this.prisma.doseEvent.findUnique({ where: { id } }), dailyProgress };
  }

  async skip(id: string, patientId: string, reason?: string) {
    const dose = await this.prisma.doseEvent.update({
      where: { id },
      data: { status: 'SKIPPED', skipReason: reason },
    });

    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'DOSE_SKIPPED',
        resourceType: 'DoseEvent',
        resourceId: id,
        details: { reason },
      },
    });

    return dose;
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

  async getUpcomingDose(patientId: string) {
    const now = new Date();
    const dose = await this.prisma.doseEvent.findFirst({
      where: {
        patientId,
        scheduledTime: { gte: now },
        status: 'DUE',
      },
      include: {
        medication: true,
        prescription: true,
      },
      orderBy: { scheduledTime: 'asc' },
    });

    if (!dose) return null;

    return {
      id: dose.id,
      medicationName: dose.medication.medicineName,
      medicationNameKhmer: dose.medication.medicineNameKhmer,
      dosage: dose.medication.morningDosage || dose.medication.daytimeDosage || dose.medication.nightDosage,
      scheduledTime: dose.scheduledTime,
      timePeriod: dose.timePeriod,
      prescriptionId: dose.prescriptionId,
    };
  }

  async getTodaysDoses(patientId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: today, lt: tomorrow },
      },
      include: {
        medication: true,
        prescription: true,
      },
      orderBy: { scheduledTime: 'asc' },
    });

    const dailyProgress = await this.calculateDailyProgress(patientId, today);

    return {
      date: today.toISOString(),
      dailyProgress,
      total: doses.length,
      taken: doses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length,
      missed: doses.filter(d => d.status === 'MISSED').length,
      skipped: doses.filter(d => d.status === 'SKIPPED').length,
      due: doses.filter(d => d.status === 'DUE').length,
      doses: doses.map(d => ({
        id: d.id,
        medicationName: d.medication.medicineName,
        medicationNameKhmer: d.medication.medicineNameKhmer,
        dosage: this.getDosageForTimePeriod(d.medication, d.timePeriod),
        imageUrl: d.medication.imageUrl,
        scheduledTime: d.scheduledTime,
        timePeriod: d.timePeriod,
        status: d.status,
        takenAt: d.takenAt,
        skipReason: d.skipReason,
        frequency: d.medication.frequency,
        timing: d.medication.timing,
        reminderTime: d.reminderTime,
        prescriptionId: d.prescriptionId,
      })),
    };
  }

  async syncOfflineDoses(patientId: string, events: any[]) {
    const results = { synced: 0, failed: 0, conflicts: [] as any[] };

    for (const event of events) {
      try {
        const dose = await this.prisma.doseEvent.findUnique({
          where: { id: event.doseId },
        });

        if (!dose) {
          results.failed++;
          results.conflicts.push({ localId: event.localId, doseId: event.doseId, reason: 'Dose not found', resolution: 'SKIPPED' });
          continue;
        }

        if (dose.patientId !== patientId) {
          results.failed++;
          continue;
        }

        // Check if already recorded (conflict)
        if (dose.status !== 'DUE') {
          // Resolve conflict - earliest timestamp wins
          if (event.status === 'TAKEN' && dose.takenAt) {
            const newTime = new Date(event.takenAt);
            if (newTime < dose.takenAt) {
              await this.prisma.doseEvent.update({
                where: { id: event.doseId },
                data: { takenAt: newTime, wasOffline: true },
              });
              results.synced++;
              results.conflicts.push({ localId: event.localId, doseId: event.doseId, reason: 'Earlier timestamp', resolution: 'CLIENT_WINS' });
            } else {
              results.conflicts.push({ localId: event.localId, doseId: event.doseId, reason: 'Server has earlier timestamp', resolution: 'SERVER_WINS' });
              results.synced++;
            }
          } else {
            results.conflicts.push({ localId: event.localId, doseId: event.doseId, reason: 'Already recorded', resolution: 'SERVER_WINS' });
            results.synced++;
          }
          continue;
        }

        // Check 24-hour window
        const scheduledTime = new Date(dose.scheduledTime);
        const takenTime = new Date(event.takenAt);
        const diffHours = (takenTime.getTime() - scheduledTime.getTime()) / (1000 * 60 * 60);

        if (diffHours > 24) {
          results.failed++;
          results.conflicts.push({ localId: event.localId, doseId: event.doseId, reason: 'Beyond 24-hour window', resolution: 'SKIPPED' });
          continue;
        }

        if (event.status === 'TAKEN') {
          const status = this.applyTimeWindowLogic(scheduledTime, takenTime);
          await this.prisma.doseEvent.update({
            where: { id: event.doseId },
            data: { status, takenAt: takenTime, wasOffline: true },
          });
        } else if (event.status === 'SKIPPED') {
          await this.prisma.doseEvent.update({
            where: { id: event.doseId },
            data: { status: 'SKIPPED', skipReason: event.skipReason || null, wasOffline: true },
          });
        }

        // Create audit log
        await this.prisma.auditLog.create({
          data: {
            actorId: patientId,
            actorRole: 'PATIENT',
            actionType: event.status === 'TAKEN' ? 'DOSE_TAKEN' : 'DOSE_SKIPPED',
            resourceType: 'DoseEvent',
            resourceId: event.doseId,
            details: { offline: true, deviceTimestamp: event.deviceTimestamp },
          },
        });

        results.synced++;
      } catch (error) {
        results.failed++;
      }
    }

    return results;
  }

  private getDosageForTimePeriod(medication: any, period: string): any {
    if (period === 'NIGHT') {
      return medication.nightDosage;
    }
    return medication.morningDosage || medication.daytimeDosage;
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
