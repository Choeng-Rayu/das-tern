import { Controller, Post, Get, Body, Param, HttpException, HttpStatus } from '@nestjs/common';
import { SubscriptionService } from '../services/subscription.service';
import { PaymentService } from '../services/payment.service';
import logger from '../utils/logger';

@Controller('api/subscriptions')
export class SubscriptionController {
    constructor(
        private readonly subscriptionService: SubscriptionService,
        private readonly paymentService: PaymentService,
    ) { }

    /**
     * GET /api/subscriptions/status/:userId
     * Gets subscription status for a user
     */
    @Get('status/:userId')
    async getSubscriptionStatus(@Param('userId') userId: string) {
        try {
            logger.info('Subscription status request', { userId });

            if (!userId) {
                throw new HttpException(
                    'User ID required',
                    HttpStatus.BAD_REQUEST
                );
            }

            const subscription = await this.subscriptionService.getSubscriptionStatus(userId);

            if (!subscription) {
                return {
                    success: true,
                    data: {
                        hasSubscription: false,
                        userId,
                    },
                };
            }

            return {
                success: true,
                data: {
                    hasSubscription: true,
                    subscription: {
                        id: subscription.id,
                        userId: subscription.userId,
                        planType: subscription.planType,
                        status: subscription.status,
                        startDate: subscription.startDate,
                        nextBillingDate: subscription.nextBillingDate,
                        lastBillingDate: subscription.lastBillingDate,
                        cancelledAt: subscription.cancelledAt,
                        cancellationReason: subscription.cancellationReason,
                        createdAt: subscription.createdAt,
                        updatedAt: subscription.updatedAt,
                    },
                    recentPayments: subscription.payments?.map((p) => ({
                        id: p.id,
                        amount: parseFloat(p.amount.toString()),
                        currency: p.currency,
                        status: p.status,
                        createdAt: p.createdAt,
                        paidAt: p.paidAt,
                    })),
                },
            };
        } catch (error) {
            logger.error('Subscription status fetch failed', {
                error: (error as Error).message,
                userId,
            });

            throw new HttpException(
                'Failed to fetch subscription status',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * POST /api/subscriptions/upgrade
     * Upgrades subscription from PREMIUM to FAMILY_PREMIUM
     */
    @Post('upgrade')
    async upgradeSubscription(
        @Body() body: { userId: string; callback?: string; appName?: string }
    ) {
        try {
            logger.info('Subscription upgrade request', {
                userId: body.userId,
            });

            if (!body.userId) {
                throw new HttpException(
                    'User ID required',
                    HttpStatus.BAD_REQUEST
                );
            }

            // Get current subscription
            const currentSubscription = await this.subscriptionService.getSubscriptionStatus(body.userId);

            if (!currentSubscription) {
                throw new HttpException(
                    'No active subscription found',
                    HttpStatus.NOT_FOUND
                );
            }

            if (currentSubscription.planType === 'FAMILY_PREMIUM') {
                throw new HttpException(
                    'Already on FAMILY_PREMIUM plan',
                    HttpStatus.BAD_REQUEST
                );
            }

            // Calculate prorated amount
            const upgradeResult = await this.subscriptionService.upgradeSubscription({
                userId: body.userId,
                newPlanType: 'FAMILY_PREMIUM',
                currentPlanType: 'PREMIUM',
            });

            // Create payment for prorated amount
            const payment = await this.paymentService.initiatePayment({
                userId: body.userId,
                planType: 'FAMILY_PREMIUM',
                amount: upgradeResult.proratedAmount,
                currency: 'USD',
                isUpgrade: true,
                isRenewal: false,
                callback: body.callback,
                appName: body.appName,
            });

            return {
                success: true,
                data: {
                    requiresPayment: upgradeResult.requiresPayment,
                    proratedAmount: upgradeResult.proratedAmount,
                    payment: {
                        transactionId: payment.id,
                        billNumber: payment.billNumber,
                        md5Hash: payment.md5Hash,
                        qrCode: payment.qrCode,
                        qrImagePath: payment.qrImagePath,
                        deepLink: payment.deepLink,
                        amount: payment.amount,
                        currency: payment.currency,
                    },
                    message: 'Complete payment to upgrade to FAMILY_PREMIUM',
                },
            };
        } catch (error) {
            logger.error('Subscription upgrade failed', {
                error: (error as Error).message,
                userId: body.userId,
            });

            if (error instanceof HttpException) {
                throw error;
            }

            throw new HttpException(
                'Failed to upgrade subscription',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * POST /api/subscriptions/downgrade
     * Downgrades subscription from FAMILY_PREMIUM to PREMIUM
     * Downgrade takes effect at next billing cycle
     */
    @Post('downgrade')
    async downgradeSubscription(@Body() body: { userId: string }) {
        try {
            logger.info('Subscription downgrade request', {
                userId: body.userId,
            });

            if (!body.userId) {
                throw new HttpException(
                    'User ID required',
                    HttpStatus.BAD_REQUEST
                );
            }

            // Get current subscription
            const currentSubscription = await this.subscriptionService.getSubscriptionStatus(body.userId);

            if (!currentSubscription) {
                throw new HttpException(
                    'No active subscription found',
                    HttpStatus.NOT_FOUND
                );
            }

            if (currentSubscription.planType === 'PREMIUM') {
                throw new HttpException(
                    'Already on PREMIUM plan',
                    HttpStatus.BAD_REQUEST
                );
            }

            // Schedule downgrade
            const result = await this.subscriptionService.downgradeSubscription({
                userId: body.userId,
                newPlanType: 'PREMIUM',
                currentPlanType: 'FAMILY_PREMIUM',
            });

            return {
                success: true,
                data: {
                    currentPlanType: 'FAMILY_PREMIUM',
                    scheduledPlanType: result.scheduledPlanType,
                    effectiveDate: result.effectiveDate,
                    message: `Downgrade to PREMIUM scheduled for ${result.effectiveDate.toISOString()}`,
                },
            };
        } catch (error) {
            logger.error('Subscription downgrade failed', {
                error: (error as Error).message,
                userId: body.userId,
            });

            if (error instanceof HttpException) {
                throw error;
            }

            throw new HttpException(
                'Failed to downgrade subscription',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * POST /api/subscriptions/cancel
     * Cancels a subscription
     */
    @Post('cancel')
    async cancelSubscription(
        @Body() body: { userId: string; reason?: string }
    ) {
        try {
            logger.info('Subscription cancellation request', {
                userId: body.userId,
            });

            if (!body.userId) {
                throw new HttpException(
                    'User ID required',
                    HttpStatus.BAD_REQUEST
                );
            }

            const subscription = await this.subscriptionService.cancelSubscription(
                body.userId,
                body.reason
            );

            return {
                success: true,
                data: {
                    subscriptionId: subscription.id,
                    status: subscription.status,
                    cancelledAt: subscription.cancelledAt,
                    cancellationReason: subscription.cancellationReason,
                    message: 'Subscription cancelled successfully',
                },
            };
        } catch (error) {
            logger.error('Subscription cancellation failed', {
                error: (error as Error).message,
                userId: body.userId,
            });

            if ((error as Error).message.includes('not found')) {
                throw new HttpException(
                    'Subscription not found',
                    HttpStatus.NOT_FOUND
                );
            }

            throw new HttpException(
                'Failed to cancel subscription',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * POST /api/subscriptions/renew
     * Manually triggers subscription renewal (usually called after payment)
     */
    @Post('renew')
    async renewSubscription(@Body() body: { userId: string }) {
        try {
            logger.info('Subscription renewal request', {
                userId: body.userId,
            });

            if (!body.userId) {
                throw new HttpException(
                    'User ID required',
                    HttpStatus.BAD_REQUEST
                );
            }

            const subscription = await this.subscriptionService.renewSubscription(body.userId);

            return {
                success: true,
                data: {
                    subscriptionId: subscription.id,
                    planType: subscription.planType,
                    status: subscription.status,
                    nextBillingDate: subscription.nextBillingDate,
                    message: 'Subscription renewed successfully',
                },
            };
        } catch (error) {
            logger.error('Subscription renewal failed', {
                error: (error as Error).message,
                userId: body.userId,
            });

            if ((error as Error).message.includes('not found')) {
                throw new HttpException(
                    'Subscription not found',
                    HttpStatus.NOT_FOUND
                );
            }

            throw new HttpException(
                'Failed to renew subscription',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }
}
