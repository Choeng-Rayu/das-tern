import { Injectable, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { SubscriptionTier } from '@prisma/client';

@Injectable()
export class SubscriptionsService {
  constructor(private prisma: PrismaService) {}

  async findOne(userId: string) {
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

  async updateTier(userId: string, tier: SubscriptionTier) {
    const storageQuota = tier === 'FREEMIUM' ? BigInt(5368709120) : BigInt(21474836480);
    
    return this.prisma.subscription.update({
      where: { userId },
      data: { tier, storageQuota },
    });
  }

  async addFamilyMember(userId: string, memberId: string) {
    const subscription = await this.findOne(userId);

    if (!subscription) {
      throw new BadRequestException('No subscription found');
    }

    if (subscription.tier !== 'FAMILY_PREMIUM') {
      throw new ForbiddenException('Family plan required');
    }

    if (subscription.familyMembers.length >= 2) {
      throw new BadRequestException('Maximum 3 members (including owner)');
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
    };
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
        return { prescriptions: 1, medicines: 3, familyConnections: 1, storageGB: 5 };
      case 'PREMIUM':
        return { prescriptions: -1, medicines: -1, familyConnections: 5, storageGB: 20 };
      case 'FAMILY_PREMIUM':
        return { prescriptions: -1, medicines: -1, familyConnections: 10, storageGB: 20 };
      default:
        return { prescriptions: 1, medicines: 3, familyConnections: 1, storageGB: 5 };
    }
  }

  async getFeatureComparison() {
    return {
      tiers: [
        {
          name: 'FREEMIUM',
          prescriptions: '1',
          medicines: '3',
          familyConnections: '1',
          storage: '5 GB',
          reminders: true,
          adherenceTracking: true,
          offlineMode: true,
          doctorConnection: true,
          prioritySupport: false,
        },
        {
          name: 'PREMIUM',
          prescriptions: 'Unlimited',
          medicines: 'Unlimited',
          familyConnections: '5',
          storage: '20 GB',
          reminders: true,
          adherenceTracking: true,
          offlineMode: true,
          doctorConnection: true,
          prioritySupport: true,
        },
        {
          name: 'FAMILY_PREMIUM',
          prescriptions: 'Unlimited',
          medicines: 'Unlimited',
          familyConnections: '10',
          storage: '20 GB',
          reminders: true,
          adherenceTracking: true,
          offlineMode: true,
          doctorConnection: true,
          prioritySupport: true,
        },
      ],
    };
  }
}
