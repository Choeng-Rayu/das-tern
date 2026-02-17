import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { UpdateProfileDto } from './dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { subscription: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const { passwordHash, ...userData } = user;

    // Add computed fields
    const profile: any = {
      ...userData,
      storageUsed: user.subscription?.storageUsed || 0,
      storageQuota: user.subscription?.storageQuota || 5368709120,
      storagePercentage: this.calculateStoragePercentage(
        user.subscription?.storageUsed || BigInt(0),
        user.subscription?.storageQuota || BigInt(5368709120),
      ),
      subscriptionTier: user.subscription?.tier || 'FREEMIUM',
    };

    // Add daily progress for patients
    if (user.role === 'PATIENT') {
      profile.dailyProgress = await this.calculateDailyProgress(id);
      profile.greeting = this.generateGreeting(user.firstName || user.fullName, profile.dailyProgress);
    }

    return profile;
  }

  async update(id: string, data: UpdateProfileDto) {
    const user = await this.prisma.user.update({
      where: { id },
      data,
    });

    const { passwordHash, ...result } = user;
    return result;
  }

  async updateGracePeriod(id: string, minutes: number) {
    const validOptions = [10, 20, 30, 60];
    if (!validOptions.includes(minutes)) {
      throw new NotFoundException('Grace period must be 10, 20, 30, or 60 minutes');
    }

    const user = await this.prisma.user.update({
      where: { id },
      data: { gracePeriodMinutes: minutes },
    });

    const { passwordHash, ...result } = user;
    return result;
  }

  async getStorageInfo(userId: string) {
    const subscription = await this.prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      return {
        used: 0,
        quota: 5368709120,
        percentage: 0,
        breakdown: { prescriptions: 0, doseEvents: 0, auditLogs: 0, files: 0 },
      };
    }

    const breakdown = await this.calculateStorageBreakdown(userId);

    return {
      used: subscription.storageUsed,
      quota: subscription.storageQuota,
      percentage: this.calculateStoragePercentage(subscription.storageUsed, subscription.storageQuota),
      breakdown,
    };
  }

  private calculateStoragePercentage(used: bigint, quota: bigint): number {
    if (quota === BigInt(0)) return 0;
    return Math.round((Number(used) / Number(quota)) * 100);
  }

  private async calculateDailyProgress(userId: string): Promise<number> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const doses = await this.prisma.doseEvent.findMany({
      where: {
        patientId: userId,
        scheduledTime: {
          gte: today,
          lt: tomorrow,
        },
      },
    });

    if (doses.length === 0) return 0;

    const takenCount = doses.filter(d => 
      d.status === 'TAKEN_ON_TIME' || d.status === 'TAKEN_LATE'
    ).length;

    return Math.round((takenCount / doses.length) * 100);
  }

  private generateGreeting(name: string | null, progress: number): string {
    const displayName = name || 'there';
    if (progress >= 80) {
      return `Great job, ${displayName}! You're doing excellent with ${progress}% completion today.`;
    } else if (progress >= 50) {
      return `Keep it up, ${displayName}! You're at ${progress}% completion today.`;
    } else if (progress > 0) {
      return `Hello, ${displayName}. You're at ${progress}% completion. Let's stay on track!`;
    } else {
      return `Hello, ${displayName}. Ready to start your medication schedule today?`;
    }
  }

  private async calculateStorageBreakdown(userId: string) {
    // Estimate storage usage (simplified)
    const prescriptionCount = await this.prisma.prescription.count({
      where: { patientId: userId },
    });

    const doseEventCount = await this.prisma.doseEvent.count({
      where: { patientId: userId },
    });

    const auditLogCount = await this.prisma.auditLog.count({
      where: { actorId: userId },
    });

    // Rough estimates: prescription ~5KB, dose ~2KB, audit ~1KB
    return {
      prescriptions: prescriptionCount * 5120,
      doseEvents: doseEventCount * 2048,
      auditLogs: auditLogCount * 1024,
      files: 0, // TODO: Calculate from S3
    };
  }

  // ============================
  // Meal Time Preferences
  // ============================

  async getMealTimePreferences(userId: string) {
    const prefs = await this.prisma.mealTimePreference.findUnique({
      where: { userId },
    });

    if (!prefs) {
      // Return defaults for Cambodia timezone
      return {
        userId,
        morningMeal: '07:00',
        afternoonMeal: '12:00',
        nightMeal: '18:00',
        isDefault: true,
      };
    }

    return { ...prefs, isDefault: false };
  }

  async updateMealTimePreferences(userId: string, data: { morningMeal?: string; afternoonMeal?: string; nightMeal?: string }) {
    return this.prisma.mealTimePreference.upsert({
      where: { userId },
      create: {
        userId,
        morningMeal: data.morningMeal || '07:00',
        afternoonMeal: data.afternoonMeal || '12:00',
        nightMeal: data.nightMeal || '18:00',
      },
      update: {
        ...(data.morningMeal && { morningMeal: data.morningMeal }),
        ...(data.afternoonMeal && { afternoonMeal: data.afternoonMeal }),
        ...(data.nightMeal && { nightMeal: data.nightMeal }),
      },
    });
  }
}
