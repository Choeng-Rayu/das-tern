import { Injectable, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class AdherenceService {
  constructor(
    private prisma: PrismaService,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
  ) {}

  private async cacheGet(key: string): Promise<any> {
    try {
      return await this.cacheManager.get(key);
    } catch {
      return null;
    }
  }

  private async cacheSet(key: string, value: any, ttl: number): Promise<void> {
    try {
      await this.cacheManager.set(key, value, ttl);
    } catch {
      // Cache write failure is non-critical
    }
  }

  async getTodayAdherence(patientId: string) {
    const cacheKey = `adherence:${patientId}:daily:${new Date().toISOString().split('T')[0]}`;
    const cached = await this.cacheGet(cacheKey);
    if (cached) return cached;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: today, lt: tomorrow },
      },
    });

    const total = doses.length;
    const taken = doses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length;
    const missed = doses.filter(d => d.status === 'MISSED').length;
    const skipped = doses.filter(d => d.status === 'SKIPPED').length;
    const due = doses.filter(d => d.status === 'DUE').length;
    const percentage = total > 0 ? Math.round((taken / total) * 100) : 0;

    const result = { percentage, taken, missed, skipped, due, total, date: today.toISOString() };
    await this.cacheSet(cacheKey, result, 300000);
    return result;
  }

  async getWeeklyAdherence(patientId: string) {
    const cacheKey = `adherence:${patientId}:weekly:${new Date().toISOString().split('T')[0]}`;
    const cached = await this.cacheGet(cacheKey);
    if (cached) return cached;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: weekAgo, lt: new Date() },
      },
    });

    const total = doses.length;
    const taken = doses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length;
    const percentage = total > 0 ? Math.round((taken / total) * 100) : 0;

    // Daily breakdown
    const dailyData: any[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const dayDoses = doses.filter(d => {
        const st = new Date(d.scheduledTime);
        return st >= date && st < nextDate;
      });

      const dayTotal = dayDoses.length;
      const dayTaken = dayDoses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length;

      dailyData.push({
        date: date.toISOString().split('T')[0],
        percentage: dayTotal > 0 ? Math.round((dayTaken / dayTotal) * 100) : 0,
        taken: dayTaken,
        total: dayTotal,
      });
    }

    const result = { percentage, taken, total, period: '7days', dailyData };
    await this.cacheSet(cacheKey, result, 300000);
    return result;
  }

  async getMonthlyAdherence(patientId: string) {
    const cacheKey = `adherence:${patientId}:monthly:${new Date().toISOString().split('T')[0]}`;
    const cached = await this.cacheGet(cacheKey);
    if (cached) return cached;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const monthAgo = new Date(today);
    monthAgo.setDate(monthAgo.getDate() - 30);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: monthAgo, lt: new Date() },
      },
    });

    const total = doses.length;
    const taken = doses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length;
    const percentage = total > 0 ? Math.round((taken / total) * 100) : 0;

    // Weekly breakdown
    const weeklyData: any[] = [];
    for (let w = 3; w >= 0; w--) {
      const weekStart = new Date(today);
      weekStart.setDate(weekStart.getDate() - (w + 1) * 7);
      const weekEnd = new Date(today);
      weekEnd.setDate(weekEnd.getDate() - w * 7);

      const weekDoses = doses.filter(d => {
        const st = new Date(d.scheduledTime);
        return st >= weekStart && st < weekEnd;
      });

      const weekTotal = weekDoses.length;
      const weekTaken = weekDoses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length;

      weeklyData.push({
        weekStart: weekStart.toISOString().split('T')[0],
        weekEnd: weekEnd.toISOString().split('T')[0],
        percentage: weekTotal > 0 ? Math.round((weekTaken / weekTotal) * 100) : 0,
        taken: weekTaken,
        total: weekTotal,
      });
    }

    const result = { percentage, taken, total, period: '30days', weeklyData };
    await this.cacheSet(cacheKey, result, 300000);
    return result;
  }

  async getAdherenceTrends(patientId: string, days = 7) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const startDate = new Date(today);
    startDate.setDate(startDate.getDate() - days);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId,
        scheduledTime: { gte: startDate, lt: new Date() },
      },
      orderBy: { scheduledTime: 'asc' },
    });

    const trendData: any[] = [];
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const dayDoses = doses.filter(d => {
        const st = new Date(d.scheduledTime);
        return st >= date && st < nextDate;
      });

      const dayTotal = dayDoses.length;
      const dayTaken = dayDoses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length;

      trendData.push({
        date: date.toISOString().split('T')[0],
        percentage: dayTotal > 0 ? Math.round((dayTaken / dayTotal) * 100) : 0,
        taken: dayTaken,
        missed: dayDoses.filter(d => d.status === 'MISSED').length,
        skipped: dayDoses.filter(d => d.status === 'SKIPPED').length,
        total: dayTotal,
      });
    }

    return { patientId, days, trendData };
  }

  async getPrescriptionAdherence(prescriptionId: string, patientId: string) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
    });

    if (!prescription || prescription.patientId !== patientId) {
      return null;
    }

    const doses = await this.prisma.doseEvent.findMany({
      where: { prescriptionId },
    });

    const total = doses.length;
    const taken = doses.filter(d => d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE').length;
    const percentage = total > 0 ? Math.round((taken / total) * 100) : 0;

    return { prescriptionId, percentage, taken, total };
  }

  async invalidateCache(patientId: string) {
    const today = new Date().toISOString().split('T')[0];
    try {
      await this.cacheManager.del(`adherence:${patientId}:daily:${today}`);
      await this.cacheManager.del(`adherence:${patientId}:weekly:${today}`);
      await this.cacheManager.del(`adherence:${patientId}:monthly:${today}`);
    } catch (e) {
      // Cache deletion failure is non-critical
    }
  }
}
