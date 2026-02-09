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
}
