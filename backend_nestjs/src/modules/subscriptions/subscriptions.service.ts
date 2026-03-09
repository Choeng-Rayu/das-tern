import { Injectable, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { SubscriptionTier } from '@prisma/client';

@Injectable()
export class SubscriptionsService {
  constructor(private prisma: PrismaService) {}

  async findOne(userId: string) {
    const subscription = await this.prisma.subscription.findUnique({
      where: { userId },
      include: {
        familyMembers: {
          include: {
            member: {
              select: { id: true, firstName: true, lastName: true, fullName: true, phoneNumber: true },
            },
          },
        },
      },
    });

    // Check if trial has expired
    if (subscription && subscription.expiresAt) {
      const now = new Date();
      if (now > subscription.expiresAt && subscription.tier === 'PREMIUM') {
        // Trial expired, downgrade to FREEMIUM
        await this.updateTier(userId, 'FREEMIUM');
        // Re-fetch subscription with all relations
        return this.prisma.subscription.findUnique({
          where: { userId },
          include: {
            familyMembers: {
              include: {
                member: {
                  select: { id: true, firstName: true, lastName: true, fullName: true, phoneNumber: true },
                },
              },
            },
          },
        });
      }
    }

    return subscription;
  }

  async updateTier(userId: string, tier: SubscriptionTier) {
    const storageQuota = tier === 'FREEMIUM' ? BigInt(5368709120) : BigInt(21474836480);
    
    return this.prisma.subscription.update({
      where: { userId },
      data: { 
        tier, 
        storageQuota,
        expiresAt: null, // Clear expiration when manually upgrading
      },
      include: {
        familyMembers: {
          include: {
            member: {
              select: { id: true, firstName: true, lastName: true, fullName: true, phoneNumber: true },
            },
          },
        },
      },
    });
  }

  async claimFreeTrial(userId: string) {
    const subscription = await this.prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      throw new BadRequestException('No subscription found');
    }

    // Check if user has already used their trial
    if (subscription.hasUsedTrial) {
      throw new ForbiddenException('You have already claimed your free trial');
    }

    // Check if user is currently Premium (can't claim trial if already premium)
    if (subscription.tier === 'PREMIUM' || subscription.tier === 'FAMILY_PREMIUM') {
      throw new ForbiddenException('You are already on a premium plan');
    }

    // Calculate trial expiration (1 month from now)
    const trialExpiresAt = new Date();
    trialExpiresAt.setMonth(trialExpiresAt.getMonth() + 1);

    // Activate Premium trial
    return this.prisma.subscription.update({
      where: { userId },
      data: {
        tier: 'PREMIUM',
        hasUsedTrial: true,
        expiresAt: trialExpiresAt,
        storageQuota: BigInt(21474836480), // 20 GB for Premium
      },
      include: {
        familyMembers: {
          include: {
            member: {
              select: { id: true, firstName: true, lastName: true, fullName: true, phoneNumber: true },
            },
          },
        },
      },
    });
  }

  async addFamilyMember(userId: string, memberId: string) {
    const subscription = await this.findOne(userId);

    if (!subscription) {
      throw new BadRequestException('No subscription found');
    }

    if (subscription.tier === 'FREEMIUM') {
      throw new ForbiddenException('Premium plan required to add family members');
    }

    // Premium allows up to 5 family connections
    if (subscription.tier === 'PREMIUM' && subscription.familyMembers.length >= 5) {
      throw new BadRequestException('Maximum 5 family members for Premium plan');
    }

    return this.prisma.familyMember.create({
      data: { subscriptionId: subscription.id, memberId },
    });
  }

  async removeFamilyMember(userId: string, memberId: string) {
    const subscription = await this.findOne(userId);

    if (!subscription) {
      throw new BadRequestException('No subscription found');
    }

    await this.prisma.familyMember.deleteMany({
      where: { subscriptionId: subscription.id, memberId },
    });

    return { message: 'Family member removed' };
  }

  async checkStorageQuota(userId: string, additionalBytes: number): Promise<boolean> {
    const subscription = await this.findOne(userId);

    if (!subscription) return false;

    return Number(subscription.storageUsed) + additionalBytes <= Number(subscription.storageQuota);
  }

  async updateStorageUsage(userId: string, deltaBytes: number) {
    const subscription = await this.findOne(userId);

    if (!subscription) return;

    await this.prisma.subscription.update({
      where: { userId },
      data: { storageUsed: Number(subscription.storageUsed) + deltaBytes },
    });
  }

  // ============================
  // Subscription Limits
  // ============================

  async getSubscriptionLimits(userId: string) {
    const subscription = await this.findOne(userId);
    const tier = subscription?.tier || 'FREEMIUM';

    const limits = this.getTierLimits(tier);

    // Get current usage
    const prescriptionCount = await this.prisma.prescription.count({
      where: { patientId: userId, status: { in: ['ACTIVE', 'DRAFT', 'PAUSED'] } },
    });

    const medicineCount = await this.prisma.medication.count({
      where: { prescription: { patientId: userId, status: { in: ['ACTIVE', 'DRAFT', 'PAUSED'] } } },
    });

    const familyConnectionCount = await this.prisma.connection.count({
      where: {
        OR: [
          { initiatorId: userId, recipient: { role: 'FAMILY_MEMBER' } },
          { recipientId: userId, initiator: { role: 'FAMILY_MEMBER' } },
        ],
        status: { in: ['PENDING', 'ACCEPTED'] },
      },
    });

    return {
      tier,
      prescriptionLimit: limits.prescriptions,
      prescriptionCount,
      medicineLimit: limits.medicines,
      medicineCount,
      familyConnectionLimit: limits.familyConnections,
      familyConnectionCount,
      storageQuota: Number(subscription?.storageQuota || 5368709120),
      storageUsed: Number(subscription?.storageUsed || 0),
      ocrEnabled: limits.ocrEnabled,
    };
  }

  async checkOcrPermission(patientId: string): Promise<boolean> {
    const limits = await this.getSubscriptionLimits(patientId);
    return limits.ocrEnabled || false;
  }

  async checkPrescriptionLimit(patientId: string): Promise<boolean> {
    const limits = await this.getSubscriptionLimits(patientId);
    if (limits.prescriptionLimit === -1) return true; // unlimited
    return limits.prescriptionCount < limits.prescriptionLimit;
  }

  async checkMedicineLimit(patientId: string): Promise<boolean> {
    const limits = await this.getSubscriptionLimits(patientId);
    if (limits.medicineLimit === -1) return true;
    return limits.medicineCount < limits.medicineLimit;
  }

  async checkFamilyConnectionLimit(patientId: string): Promise<boolean> {
    const limits = await this.getSubscriptionLimits(patientId);
    if (limits.familyConnectionLimit === -1) return true;
    return limits.familyConnectionCount < limits.familyConnectionLimit;
  }

  private getTierLimits(tier: string) {
    switch (tier) {
      case 'FREEMIUM':
        // Manual input only, reminders, no OCR, no family plan
        return { prescriptions: -1, medicines: -1, familyConnections: 0, storageGB: 5, ocrEnabled: false };
      case 'PREMIUM':
        // Unlimited OCR, up to 5 family members
        return { prescriptions: -1, medicines: -1, familyConnections: 5, storageGB: 20, ocrEnabled: true };
      default:
        return { prescriptions: -1, medicines: -1, familyConnections: 0, storageGB: 5, ocrEnabled: false };
    }
  }

  async getFeatureComparison() {
    return {
      tiers: [
        {
          name: 'FREEMIUM',
          displayName: 'Freemium',
          price: 'Free',
          prescriptions: 'Unlimited',
          medicines: 'Unlimited',
          manualInput: true,
          ocrScanning: false,
          familyConnections: '0',
          storage: '5 GB',
          reminders: true,
          adherenceTracking: true,
          offlineMode: true,
          prioritySupport: false,
        },
        {
          name: 'PREMIUM',
          displayName: 'Premium',
          price: '$0.5/month',
          pricingOptions: [
            { period: 'month', price: 0.5, display: '$0.5/month' },
            { period: '3months', price: 1.0, display: '$1/3 months' },
          ],
          prescriptions: 'Unlimited',
          medicines: 'Unlimited',
          manualInput: true,
          ocrScanning: true,
          familyConnections: '5',
          storage: '20 GB',
          reminders: true,
          adherenceTracking: true,
          offlineMode: true,
          prioritySupport: true,
          freeTrial: '1 month free for new users',
        },
      ],
    };
  }
}
