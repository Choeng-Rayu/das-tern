import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

export type AdherenceLevel = 'GREEN' | 'YELLOW' | 'RED';

export interface AdherenceResult {
  overallPercentage: number;
  level: AdherenceLevel;
  totalDoses: number;
  takenDoses: number;
  missedDoses: number;
  lateDoses: number;
}

export interface AdherenceTimelinePoint {
  date: string;
  percentage: number;
  takenDoses: number;
  totalDoses: number;
}

export interface MissedDoseAlert {
  type: 'WARNING' | 'CRITICAL';
  patientId: string;
  patientName: string;
  consecutiveMissed: number;
  lastMissedAt: Date;
}

@Injectable()
export class AdherenceService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get adherence level from percentage.
   * GREEN: >= 90%, YELLOW: 70-89%, RED: < 70%
   */
  getAdherenceLevel(percentage: number): AdherenceLevel {
    if (percentage >= 90) return 'GREEN';
    if (percentage >= 70) return 'YELLOW';
    return 'RED';
  }

  /**
   * Calculate adherence for a patient within a date range.
   */
  async calculateAdherence(
    patientId: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<AdherenceResult> {
    const now = new Date();
    const start = startDate || new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate || now;

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: start, lte: end },
        status: { not: 'DUE' },
      },
    });

    const totalDoses = doses.length;
    if (totalDoses === 0) {
      return {
        overallPercentage: 100,
        level: 'GREEN',
        totalDoses: 0,
        takenDoses: 0,
        missedDoses: 0,
        lateDoses: 0,
      };
    }

    const takenDoses = doses.filter(
      (d) => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE',
    ).length;
    const missedDoses = doses.filter((d) => d.status === 'MISSED').length;
    const lateDoses = doses.filter((d) => d.status === 'TAKEN_LATE').length;
    const percentage = Math.round((takenDoses / totalDoses) * 100);

    return {
      overallPercentage: percentage,
      level: this.getAdherenceLevel(percentage),
      totalDoses,
      takenDoses,
      missedDoses,
      lateDoses,
    };
  }

  /**
   * Calculate adherence for multiple patients in parallel.
   */
  async getBatchAdherence(
    patientIds: string[],
  ): Promise<Map<string, AdherenceResult>> {
    const results = new Map<string, AdherenceResult>();
    const promises = patientIds.map(async (id) => {
      const result = await this.calculateAdherence(id);
      results.set(id, result);
    });
    await Promise.all(promises);
    return results;
  }

  /**
   * Get adherence timeline (daily data points) for a patient.
   */
  async getAdherenceTimeline(
    patientId: string,
    days = 30,
  ): Promise<AdherenceTimelinePoint[]> {
    const now = new Date();
    const timeline: AdherenceTimelinePoint[] = [];

    for (let i = days - 1; i >= 0; i--) {
      const dayStart = new Date(now);
      dayStart.setDate(dayStart.getDate() - i);
      dayStart.setHours(0, 0, 0, 0);

      const dayEnd = new Date(dayStart);
      dayEnd.setHours(23, 59, 59, 999);

      const doses = await this.prisma.doseEvent.findMany({
        where: {
          patientId,
          scheduledTime: { gte: dayStart, lte: dayEnd },
          status: { not: 'DUE' },
        },
      });

      const totalDoses = doses.length;
      const takenDoses = doses.filter(
        (d) => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE',
      ).length;

      timeline.push({
        date: dayStart.toISOString().split('T')[0],
        percentage: totalDoses > 0 ? Math.round((takenDoses / totalDoses) * 100) : 100,
        takenDoses,
        totalDoses,
      });
    }

    return timeline;
  }

  /**
   * Detect missed doses and generate alerts for a doctor's patients.
   */
  async detectMissedDoseAlerts(patientIds: string[]): Promise<MissedDoseAlert[]> {
    const alerts: MissedDoseAlert[] = [];
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    for (const patientId of patientIds) {
      const missedDoses = await this.prisma.doseEvent.findMany({
        where: {
          patientId,
          status: 'MISSED',
          scheduledTime: { gte: threeDaysAgo },
        },
        orderBy: { scheduledTime: 'desc' },
        include: {
          patient: { select: { firstName: true, lastName: true, fullName: true } },
        },
      });

      if (missedDoses.length === 0) continue;

      // Check consecutive missed doses
      const consecutiveMissed = missedDoses.length;
      const patient = missedDoses[0].patient;
      const patientName =
        patient.fullName || `${patient.firstName || ''} ${patient.lastName || ''}`.trim();

      if (consecutiveMissed >= 3) {
        // 3+ days continuous missed = CRITICAL
        alerts.push({
          type: 'CRITICAL',
          patientId,
          patientName,
          consecutiveMissed,
          lastMissedAt: missedDoses[0].scheduledTime,
        });
      } else if (consecutiveMissed >= 2) {
        // 2+ consecutive missed = WARNING
        alerts.push({
          type: 'WARNING',
          patientId,
          patientName,
          consecutiveMissed,
          lastMissedAt: missedDoses[0].scheduledTime,
        });
      }
    }

    return alerts;
  }
}
