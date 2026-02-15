import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSubscriptionParams, UpgradeParams, DowngradeParams } from '../types/payment.types';
import { SubscriptionStatus, PlanType } from '@prisma/client';
import logger from '../utils/logger';

@Injectable()
export class SubscriptionService {
    constructor(private readonly prisma: PrismaService) { }

    /**
     * Creates a new subscription after successful payment
     */
    async createSubscription(params: CreateSubscriptionParams) {
        const { userId, planType, paymentTransactionId, paidAt } = params;

        logger.info('Creating subscription', {
            userId,
            planType,
            paymentTransactionId,
        });

        // Check if user already has an active subscription
        const existing = await this.prisma.subscription.findUnique({
            where: { userId },
        });

        if (existing && existing.status === SubscriptionStatus.ACTIVE) {
            throw new Error('User already has an active subscription');
        }

        // Calculate billing dates
        const startDate = paidAt;
        const nextBillingDate = this.addDays(startDate, 30);

        // Create subscription
        const subscription = await this.prisma.subscription.create({
            data: {
                userId,
                planType: planType as PlanType,
                status: SubscriptionStatus.ACTIVE,
                startDate,
                nextBillingDate,
                lastBillingDate: startDate,
            },
        });

        // Link payment transaction to subscription
        await this.prisma.paymentTransaction.update({
            where: { id: paymentTransactionId },
            data: { subscriptionId: subscription.id },
        });

        // Create status history
        await this.prisma.subscriptionStatusHistory.create({
            data: {
                subscriptionId: subscription.id,
                oldStatus: null,
                newStatus: SubscriptionStatus.ACTIVE,
                reason: 'Subscription created after successful payment',
            },
        });

        // Create audit log
        await this.prisma.auditLog.create({
            data: {
                userId,
                action: 'SUBSCRIPTION_CREATED',
                resourceType: 'subscription',
                resourceId: subscription.id,
                details: {
                    planType,
                    startDate,
                    nextBillingDate,
                },
            },
        });

        logger.info('Subscription created successfully', {
            subscriptionId: subscription.id,
            userId,
            planType,
        });

        return subscription;
    }

    /**
     * Renews an existing subscription
     */
    async renewSubscription(userId: string) {
        logger.info('Renewing subscription', { userId });

        const subscription = await this.prisma.subscription.findUnique({
            where: { userId },
        });

        if (!subscription) {
            throw new Error('Subscription not found');
        }

        // Extend next billing date by 30 days
        const newNextBillingDate = this.addDays(subscription.nextBillingDate, 30);

        // Update subscription
        const updated = await this.prisma.subscription.update({
            where: { id: subscription.id },
            data: {
                nextBillingDate: newNextBillingDate,
                lastBillingDate: new Date(),
                status: SubscriptionStatus.ACTIVE,
            },
        });

        // Create status history
        await this.prisma.subscriptionStatusHistory.create({
            data: {
                subscriptionId: subscription.id,
                oldStatus: subscription.status,
                newStatus: SubscriptionStatus.ACTIVE,
                reason: 'Subscription renewed',
                metadata: {
                    previousNextBillingDate: subscription.nextBillingDate,
                    newNextBillingDate,
                },
            },
        });

        // Create audit log
        await this.prisma.auditLog.create({
            data: {
                userId,
                action: 'SUBSCRIPTION_RENEWED',
                resourceType: 'subscription',
                resourceId: subscription.id,
                details: {
                    newNextBillingDate,
                },
            },
        });

        logger.info('Subscription renewed successfully', {
            subscriptionId: subscription.id,
            newNextBillingDate,
        });

        return updated;
    }

    /**
     * Upgrades a subscription from PREMIUM to FAMILY_PREMIUM
     * Returns the prorated amount to be charged
     */
    async upgradeSubscription(params: UpgradeParams) {
        const { userId, newPlanType, currentPlanType } = params;

        logger.info('Upgrading subscription', {
            userId,
            currentPlanType,
            newPlanType,
        });

        const subscription = await this.prisma.subscription.findUnique({
            where: { userId },
        });

        if (!subscription) {
            throw new Error('Subscription not found');
        }

        if (subscription.planType !== currentPlanType) {
            throw new Error('Current plan type mismatch');
        }

        if (subscription.status !== SubscriptionStatus.ACTIVE) {
            throw new Error('Subscription is not active');
        }

        // Calculate prorated amount
        const proratedAmount = this.calculateProratedAmount(
            currentPlanType,
            newPlanType,
            subscription.nextBillingDate
        );

        logger.info('Prorated amount calculated', {
            proratedAmount,
            currentPlanType,
            newPlanType,
        });

        return {
            subscription,
            proratedAmount,
            requiresPayment: proratedAmount > 0,
        };
    }

    /**
     * Applies the upgrade after payment is confirmed
     */
    async applyUpgrade(userId: string, newPlanType: 'FAMILY_PREMIUM') {
        logger.info('Applying subscription upgrade', { userId, newPlanType });

        const subscription = await this.prisma.subscription.findUnique({
            where: { userId },
        });

        if (!subscription) {
            throw new Error('Subscription not found');
        }

        const oldPlanType = subscription.planType;

        // Update subscription plan type immediately
        const updated = await this.prisma.subscription.update({
            where: { id: subscription.id },
            data: {
                planType: newPlanType as PlanType,
            },
        });

        // Create status history
        await this.prisma.subscriptionStatusHistory.create({
            data: {
                subscriptionId: subscription.id,
                oldStatus: subscription.status,
                newStatus: subscription.status,
                reason: `Plan upgraded from ${oldPlanType} to ${newPlanType}`,
                metadata: {
                    oldPlanType,
                    newPlanType,
                },
            },
        });

        // Create audit log
        await this.prisma.auditLog.create({
            data: {
                userId,
                action: 'SUBSCRIPTION_UPGRADED',
                resourceType: 'subscription',
                resourceId: subscription.id,
                details: {
                    oldPlanType,
                    newPlanType,
                },
            },
        });

        logger.info('Subscription upgraded successfully', {
            subscriptionId: subscription.id,
            newPlanType,
        });

        return updated;
    }

    /**
     * Downgrades a subscription from FAMILY_PREMIUM to PREMIUM
     * Downgrade takes effect at the next billing cycle
     */
    async downgradeSubscription(params: DowngradeParams) {
        const { userId, newPlanType, currentPlanType } = params;

        logger.info('Scheduling subscription downgrade', {
            userId,
            currentPlanType,
            newPlanType,
        });

        const subscription = await this.prisma.subscription.findUnique({
            where: { userId },
        });

        if (!subscription) {
            throw new Error('Subscription not found');
        }

        if (subscription.planType !== currentPlanType) {
            throw new Error('Current plan type mismatch');
        }

        if (subscription.status !== SubscriptionStatus.ACTIVE) {
            throw new Error('Subscription is not active');
        }

        // Create status history noting the scheduled downgrade
        await this.prisma.subscriptionStatusHistory.create({
            data: {
                subscriptionId: subscription.id,
                oldStatus: subscription.status,
                newStatus: subscription.status,
                reason: `Downgrade scheduled from ${currentPlanType} to ${newPlanType} at next billing cycle`,
                metadata: {
                    scheduledPlanType: newPlanType,
                    effectiveDate: subscription.nextBillingDate,
                },
            },
        });

        // Create audit log
        await this.prisma.auditLog.create({
            data: {
                userId,
                action: 'SUBSCRIPTION_DOWNGRADE_SCHEDULED',
                resourceType: 'subscription',
                resourceId: subscription.id,
                details: {
                    currentPlanType,
                    scheduledPlanType: newPlanType,
                    effectiveDate: subscription.nextBillingDate,
                },
            },
        });

        logger.info('Subscription downgrade scheduled', {
            subscriptionId: subscription.id,
            effectiveDate: subscription.nextBillingDate,
        });

        return {
            subscription,
            scheduledPlanType: newPlanType,
            effectiveDate: subscription.nextBillingDate,
        };
    }

    /**
     * Cancels a subscription
     */
    async cancelSubscription(userId: string, reason?: string) {
        logger.info('Cancelling subscription', { userId, reason });

        const subscription = await this.prisma.subscription.findUnique({
            where: { userId },
        });

        if (!subscription) {
            throw new Error('Subscription not found');
        }

        const oldStatus = subscription.status;

        // Update subscription to cancelled
        const updated = await this.prisma.subscription.update({
            where: { id: subscription.id },
            data: {
                status: SubscriptionStatus.CANCELLED,
                cancelledAt: new Date(),
                cancellationReason: reason || 'User requested cancellation',
            },
        });

        // Create status history
        await this.prisma.subscriptionStatusHistory.create({
            data: {
                subscriptionId: subscription.id,
                oldStatus,
                newStatus: SubscriptionStatus.CANCELLED,
                reason: reason || 'User requested cancellation',
            },
        });

        // Create audit log
        await this.prisma.auditLog.create({
            data: {
                userId,
                action: 'SUBSCRIPTION_CANCELLED',
                resourceType: 'subscription',
                resourceId: subscription.id,
                details: {
                    reason: reason || 'User requested cancellation',
                    cancelledAt: updated.cancelledAt,
                },
            },
        });

        logger.info('Subscription cancelled successfully', {
            subscriptionId: subscription.id,
        });

        return updated;
    }

    /**
     * Gets subscription status for a user
     */
    async getSubscriptionStatus(userId: string) {
        const subscription = await this.prisma.subscription.findUnique({
            where: { userId },
            include: {
                payments: {
                    orderBy: { createdAt: 'desc' },
                    take: 5,
                },
                statusHistory: {
                    orderBy: { createdAt: 'desc' },
                    take: 10,
                },
            },
        });

        if (!subscription) {
            return null;
        }

        // Check if subscription has expired
        if (
            subscription.status === SubscriptionStatus.ACTIVE &&
            subscription.nextBillingDate < new Date()
        ) {
            // Mark as expired
            await this.expireSubscription(subscription.id);
            subscription.status = SubscriptionStatus.EXPIRED;
        }

        return subscription;
    }

    /**
     * Expires a subscription
     */
    async expireSubscription(subscriptionId: string) {
        logger.info('Expiring subscription', { subscriptionId });

        const subscription = await this.prisma.subscription.findUnique({
            where: { id: subscriptionId },
        });

        if (!subscription) {
            return;
        }

        const oldStatus = subscription.status;

        await this.prisma.subscription.update({
            where: { id: subscriptionId },
            data: {
                status: SubscriptionStatus.EXPIRED,
            },
        });

        // Create status history
        await this.prisma.subscriptionStatusHistory.create({
            data: {
                subscriptionId,
                oldStatus,
                newStatus: SubscriptionStatus.EXPIRED,
                reason: 'Subscription expired - payment not received',
            },
        });

        // Create audit log
        await this.prisma.auditLog.create({
            data: {
                userId: subscription.userId,
                action: 'SUBSCRIPTION_EXPIRED',
                resourceType: 'subscription',
                resourceId: subscriptionId,
                details: {
                    reason: 'Payment not received',
                },
            },
        });

        logger.warn('Subscription expired', {
            subscriptionId,
            userId: subscription.userId,
        });
    }

    /**
     * Calculates prorated amount for plan change
     * Formula: (newPrice - oldPrice) * (remainingDays / 30)
     */
    private calculateProratedAmount(
        currentPlan: string,
        newPlan: string,
        nextBillingDate: Date
    ): number {
        const currentPrice = this.getPlanPrice(currentPlan);
        const newPrice = this.getPlanPrice(newPlan);

        const now = new Date();
        const remainingMs = nextBillingDate.getTime() - now.getTime();
        const remainingDays = Math.max(0, remainingMs / (1000 * 60 * 60 * 24));

        const proratedAmount = (newPrice - currentPrice) * (remainingDays / 30);

        return Math.max(0, Math.round(proratedAmount * 100) / 100); // Round to 2 decimals
    }

    /**
     * Gets plan price from environment variables
     */
    private getPlanPrice(planType: string): number {
        switch (planType) {
            case 'PREMIUM':
                return parseFloat(process.env.PREMIUM_PRICE || '0.50');
            case 'FAMILY_PREMIUM':
                return parseFloat(process.env.FAMILY_PREMIUM_PRICE || '1.00');
            default:
                return 0;
        }
    }

    /**
     * Adds days to a date
     */
    private addDays(date: Date, days: number): Date {
        const result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
    }
}
