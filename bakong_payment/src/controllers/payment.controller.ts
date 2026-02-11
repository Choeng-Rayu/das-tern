import { Controller, Post, Get, Body, Param, Query, HttpException, HttpStatus } from '@nestjs/common';
import { PaymentService } from '../services/payment.service';
import { SubscriptionService } from '../services/subscription.service';
import { PaymentInitiationParams, MonitorOptions } from '../types/payment.types';
import logger from '../utils/logger';

@Controller('api/payments')
export class PaymentController {
    constructor(
        private readonly paymentService: PaymentService,
        private readonly subscriptionService: SubscriptionService,
    ) { }

    /**
     * POST /api/payments/create
     * Creates a new payment and generates QR code
     */
    @Post('create')
    async createPayment(@Body() body: PaymentInitiationParams) {
        try {
            logger.info('Payment creation request', {
                userId: body.userId,
                planType: body.planType,
                amount: body.amount,
            });

            // Validate required fields
            if (!body.userId || !body.planType || !body.amount) {
                throw new HttpException(
                    'Missing required fields: userId, planType, amount',
                    HttpStatus.BAD_REQUEST
                );
            }

            // Validate plan type
            if (!['PREMIUM', 'FAMILY_PREMIUM'].includes(body.planType)) {
                throw new HttpException(
                    'Invalid plan type. Must be PREMIUM or FAMILY_PREMIUM',
                    HttpStatus.BAD_REQUEST
                );
            }

            // Validate amount
            if (body.amount <= 0) {
                throw new HttpException(
                    'Amount must be greater than 0',
                    HttpStatus.BAD_REQUEST
                );
            }

            // Create payment
            const payment = await this.paymentService.initiatePayment(body);

            return {
                success: true,
                data: {
                    transactionId: payment.id,
                    billNumber: payment.billNumber,
                    md5Hash: payment.md5Hash,
                    qrCode: payment.qrCode,
                    qrImagePath: payment.qrImagePath,
                    deepLink: payment.deepLink,
                    amount: payment.amount,
                    currency: payment.currency,
                    status: payment.status,
                    createdAt: payment.createdAt,
                },
            };
        } catch (error) {
            logger.error('Payment creation failed', {
                error: (error as Error).message,
                userId: body.userId,
            });

            if (error instanceof HttpException) {
                throw error;
            }

            throw new HttpException(
                'Failed to create payment',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * GET /api/payments/status/:md5
     * Checks payment status by MD5 hash
     */
    @Get('status/:md5')
    async getPaymentStatus(@Param('md5') md5Hash: string) {
        try {
            logger.info('Payment status request', { md5Hash });

            if (!md5Hash || md5Hash.length !== 32) {
                throw new HttpException(
                    'Invalid MD5 hash',
                    HttpStatus.BAD_REQUEST
                );
            }

            const payment = await this.paymentService.checkPaymentStatus(md5Hash);

            return {
                success: true,
                data: {
                    transactionId: payment.id,
                    md5Hash: payment.md5Hash,
                    status: payment.status,
                    amount: payment.amount,
                    currency: payment.currency,
                    paidAt: payment.paidAt,
                    createdAt: payment.createdAt,
                    updatedAt: payment.updatedAt,
                },
            };
        } catch (error) {
            logger.error('Payment status check failed', {
                error: (error as Error).message,
                md5Hash,
            });

            if ((error as Error).message.includes('not found')) {
                throw new HttpException(
                    'Payment transaction not found',
                    HttpStatus.NOT_FOUND
                );
            }

            throw new HttpException(
                'Failed to check payment status',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * POST /api/payments/monitor
     * Starts monitoring a payment until completion or timeout
     */
    @Post('monitor')
    async monitorPayment(
        @Body() body: { transactionId: string; options?: MonitorOptions }
    ) {
        try {
            logger.info('Payment monitoring request', {
                transactionId: body.transactionId,
            });

            if (!body.transactionId) {
                throw new HttpException(
                    'Transaction ID required',
                    HttpStatus.BAD_REQUEST
                );
            }

            const payment = await this.paymentService.monitorPayment(
                body.transactionId,
                body.options
            );

            // If payment completed, create subscription
            if (payment.status === 'PAID' && !payment.isRenewal) {
                try {
                    await this.subscriptionService.createSubscription({
                        userId: payment.userId,
                        planType: payment.planType as 'PREMIUM' | 'FAMILY_PREMIUM',
                        paymentTransactionId: payment.id,
                        paidAt: payment.paidAt!,
                    });
                } catch (subError) {
                    logger.error('Subscription creation failed', {
                        error: (subError as Error).message,
                        transactionId: payment.id,
                    });
                }
            }

            return {
                success: true,
                data: {
                    transactionId: payment.id,
                    status: payment.status,
                    paidAt: payment.paidAt,
                    checkAttempts: payment.checkAttempts,
                },
            };
        } catch (error) {
            logger.error('Payment monitoring failed', {
                error: (error as Error).message,
                transactionId: body.transactionId,
            });

            throw new HttpException(
                'Failed to monitor payment',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * POST /api/payments/bulk-check
     * Bulk checks multiple payment statuses
     */
    @Post('bulk-check')
    async bulkCheckPayments(@Body() body: { md5Hashes: string[] }) {
        try {
            logger.info('Bulk payment check request', {
                count: body.md5Hashes?.length || 0,
            });

            if (!body.md5Hashes || !Array.isArray(body.md5Hashes)) {
                throw new HttpException(
                    'md5Hashes array required',
                    HttpStatus.BAD_REQUEST
                );
            }

            if (body.md5Hashes.length > 50) {
                throw new HttpException(
                    'Maximum 50 payments can be checked at once',
                    HttpStatus.BAD_REQUEST
                );
            }

            const payments = await this.paymentService.bulkCheckPayments(body.md5Hashes);

            return {
                success: true,
                data: payments.map((p) => ({
                    transactionId: p.id,
                    md5Hash: p.md5Hash,
                    status: p.status,
                    amount: p.amount,
                    currency: p.currency,
                    paidAt: p.paidAt,
                })),
            };
        } catch (error) {
            logger.error('Bulk payment check failed', {
                error: (error as Error).message,
            });

            if (error instanceof HttpException) {
                throw error;
            }

            throw new HttpException(
                'Failed to check payments',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * GET /api/payments/history
     * Gets payment history for a user
     */
    @Get('history')
    async getPaymentHistory(
        @Query('userId') userId: string,
        @Query('limit') limit?: string,
        @Query('offset') offset?: string
    ) {
        try {
            logger.info('Payment history request', { userId });

            if (!userId) {
                throw new HttpException(
                    'userId query parameter required',
                    HttpStatus.BAD_REQUEST
                );
            }

            const limitNum = limit ? parseInt(limit, 10) : 10;
            const offsetNum = offset ? parseInt(offset, 10) : 0;

            // This would need to be implemented in PaymentService
            // For now, return a placeholder response
            return {
                success: true,
                data: {
                    userId,
                    payments: [],
                    total: 0,
                    limit: limitNum,
                    offset: offsetNum,
                },
            };
        } catch (error) {
            logger.error('Payment history fetch failed', {
                error: (error as Error).message,
                userId,
            });

            if (error instanceof HttpException) {
                throw error;
            }

            throw new HttpException(
                'Failed to fetch payment history',
                HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }
}
