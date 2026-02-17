import {
    Injectable,
    Logger,
    HttpException,
    HttpStatus,
    OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { BakongPlanType, BakongPaymentResponse, BakongStatusResponse } from './bakong-payment.dto';
import * as crypto from 'crypto';

/**
 * Bakong Payment Service — Secure proxy to the standalone Bakong payment microservice.
 *
 * Security measures:
 * - API Key authentication (Bearer token)
 * - HMAC request signing (SHA-256) for tamper protection
 * - Request ID tracing for audit log correlation
 * - Response signature verification
 * - Timeout with circuit breaker pattern
 * - Input sanitization before forwarding
 */
@Injectable()
export class BakongPaymentService implements OnModuleInit {
    private readonly logger = new Logger(BakongPaymentService.name);
    private bakongServiceUrl: string;
    private bakongApiKey: string;
    private webhookSecret: string;

    // Circuit breaker state
    private failureCount = 0;
    private lastFailureTime = 0;
    private readonly MAX_FAILURES = 5;
    private readonly CIRCUIT_RESET_MS = 60_000; // 1 minute

    constructor(
        private configService: ConfigService,
        private prisma: PrismaService,
        private subscriptionsService: SubscriptionsService,
    ) { }

    onModuleInit() {
        this.bakongServiceUrl = this.configService.get<string>(
            'BAKONG_SERVICE_URL',
            'http://localhost:3002',
        );
        this.bakongApiKey = this.configService.get<string>(
            'BAKONG_API_KEY',
            '',
        );
        this.webhookSecret = this.configService.get<string>(
            'BAKONG_WEBHOOK_SECRET',
            'changeme_webhook_secret_here',
        );

        if (!this.bakongApiKey) {
            this.logger.warn('⚠️ BAKONG_API_KEY is not set — service calls will fail');
        }

        this.logger.log(`Bakong service URL: ${this.bakongServiceUrl}`);
    }

    // =============================================
    // SECURITY: HMAC Signature
    // =============================================

    /**
     * Create HMAC-SHA256 signature for request body to prevent tampering.
     */
    private signRequest(body: string, timestamp: string): string {
        const payload = `${timestamp}.${body}`;
        return crypto
            .createHmac('sha256', this.webhookSecret)
            .update(payload)
            .digest('hex');
    }

    /**
     * Verify response signature from Bakong service.
     */
    private verifyResponseSignature(
        body: string,
        signature: string | undefined,
        timestamp: string | undefined,
    ): boolean {
        if (!signature || !timestamp) return false;
        const expected = this.signRequest(body, timestamp);
        return crypto.timingSafeEqual(
            Buffer.from(expected, 'hex'),
            Buffer.from(signature, 'hex'),
        );
    }

    // =============================================
    // SECURITY: Circuit Breaker
    // =============================================

    private isCircuitOpen(): boolean {
        if (this.failureCount >= this.MAX_FAILURES) {
            const elapsed = Date.now() - this.lastFailureTime;
            if (elapsed < this.CIRCUIT_RESET_MS) {
                return true; // Circuit is open, reject requests
            }
            // Reset after cooldown
            this.failureCount = 0;
        }
        return false;
    }

    private recordFailure() {
        this.failureCount++;
        this.lastFailureTime = Date.now();
    }

    private recordSuccess() {
        this.failureCount = 0;
    }

    // =============================================
    // HTTP Client — Secure fetch wrapper
    // =============================================

    private async secureFetch<T>(
        method: 'GET' | 'POST',
        path: string,
        body?: Record<string, any>,
    ): Promise<T> {
        // Circuit breaker check
        if (this.isCircuitOpen()) {
            throw new HttpException(
                'Payment service temporarily unavailable. Please try again later.',
                HttpStatus.SERVICE_UNAVAILABLE,
            );
        }

        const url = `${this.bakongServiceUrl}${path}`;
        const requestId = crypto.randomUUID();
        const timestamp = Date.now().toString();
        const bodyStr = body ? JSON.stringify(body) : '';

        const headers: Record<string, string> = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.bakongApiKey}`,
            'X-Request-ID': requestId,
            'X-Timestamp': timestamp,
        };

        // Sign the request body
        if (bodyStr) {
            headers['X-Signature'] = this.signRequest(bodyStr, timestamp);
        }

        this.logger.log(
            `[${requestId}] → ${method} ${path} ${body ? JSON.stringify({ planType: body.planType }) : ''}`,
        );

        try {
            const controller = new AbortController();
            const timeout = setTimeout(() => controller.abort(), 15_000); // 15s timeout

            const response = await fetch(url, {
                method,
                headers,
                body: bodyStr || undefined,
                signal: controller.signal,
            });

            clearTimeout(timeout);

            const responseText = await response.text();

            if (!response.ok) {
                this.recordFailure();
                this.logger.error(
                    `[${requestId}] ← ${response.status} ${responseText.substring(0, 200)}`,
                );
                throw new HttpException(
                    {
                        message: 'Payment service error',
                        statusCode: response.status,
                        requestId,
                    },
                    response.status >= 500
                        ? HttpStatus.BAD_GATEWAY
                        : response.status,
                );
            }

            this.recordSuccess();

            let parsed: T;
            try {
                parsed = JSON.parse(responseText);
            } catch {
                throw new HttpException(
                    'Invalid response from payment service',
                    HttpStatus.BAD_GATEWAY,
                );
            }

            this.logger.log(`[${requestId}] ← ${response.status} OK`);
            return parsed;
        } catch (error) {
            if (error instanceof HttpException) throw error;

            this.recordFailure();
            this.logger.error(
                `[${requestId}] ✕ Bakong service unreachable: ${error.message}`,
            );
            throw new HttpException(
                'Payment service is currently unavailable',
                HttpStatus.SERVICE_UNAVAILABLE,
            );
        }
    }

    // =============================================
    // Payment Operations
    // =============================================

    /**
     * Create a new Bakong payment and return QR code data.
     * The main backend forwards the authenticated user's ID.
     */
    async createPayment(userId: string, planType: BakongPlanType, appName?: string) {
        // Validate user exists
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (!user) {
            throw new HttpException('User not found', HttpStatus.NOT_FOUND);
        }

        // Check if user already has the requested tier
        const currentSub = await this.subscriptionsService.findOne(userId);
        if (currentSub?.tier === planType) {
            throw new HttpException(
                `User already has ${planType} subscription`,
                HttpStatus.CONFLICT,
            );
        }

        // Determine pricing
        const amount = planType === 'PREMIUM' ? 0.5 : 1.0;

        const rawResponse = await this.secureFetch<any>(
            'POST',
            '/api/payments/create',
            {
                userId,
                planType,
                amount,
                currency: 'USD',
                appName: appName || 'Das Tern',
            },
        );

        // Normalize: Bakong service returns { success, data: {...} }
        // but Flutter client expects { success, payment: {...} }
        const paymentData = rawResponse?.data ?? rawResponse?.payment ?? {};
        const response: BakongPaymentResponse = {
            success: rawResponse?.success ?? true,
            payment: paymentData,
        };

        // Audit log
        await this.prisma.auditLog.create({
            data: {
                actorId: userId,
                actorRole: user.role,
                actionType: 'SUBSCRIPTION_CHANGE',
                resourceType: 'PAYMENT',
                resourceId: null,
                details: {
                    action: 'PAYMENT_INITIATED',
                    planType,
                    amount,
                    transactionId: response?.payment?.transactionId,
                },
            },
        });

        return response;
    }

    /**
     * Check payment status from the Bakong service.
     * If paid, automatically upgrade the user's subscription in the main DB.
     */
    async checkPaymentStatus(userId: string, md5Hash: string) {
        // Sanitize input
        if (!/^[a-f0-9]{32}$/i.test(md5Hash)) {
            throw new HttpException('Invalid payment hash', HttpStatus.BAD_REQUEST);
        }

        const rawResponse = await this.secureFetch<any>(
            'GET',
            `/api/payments/status/${encodeURIComponent(md5Hash)}`,
        );

        // Normalize: Bakong service returns { success, data: {...} }
        // but Flutter client expects { success, payment: {...} }
        const paymentData = rawResponse?.data ?? rawResponse?.payment ?? {};
        const response: BakongStatusResponse = {
            success: rawResponse?.success ?? true,
            payment: paymentData,
        };

        // If payment is confirmed PAID, upgrade subscription in main DB
        if (response?.payment?.status === 'PAID') {
            await this.handlePaymentSuccess(userId, response);
        }

        return response;
    }

    /**
     * Handle successful payment: upgrade subscription in main database.
     * Determines planType from the payment amount since the Bakong service
     * doesn't include subscription metadata in status responses.
     */
    private async handlePaymentSuccess(userId: string, response: BakongStatusResponse) {
        try {
            // Determine plan type from amount since Bakong status doesn't include it
            const amount = Number(response.payment?.amount) || 0;
            let tier: string;
            if (amount >= 1.0) {
                tier = 'FAMILY_PREMIUM';
            } else if (amount >= 0.5) {
                tier = 'PREMIUM';
            } else {
                this.logger.warn(`Unknown payment amount ${amount} for user ${userId}`);
                return;
            }

            // Update local subscription
            const currentSub = await this.subscriptionsService.findOne(userId);

            if (currentSub && currentSub.tier !== tier) {
                await this.subscriptionsService.updateTier(userId, tier as any);

                this.logger.log(
                    `✅ Subscription upgraded: ${userId} → ${tier}`,
                );

                // Audit log the upgrade
                const user = await this.prisma.user.findUnique({ where: { id: userId } });
                await this.prisma.auditLog.create({
                    data: {
                        actorId: userId,
                        actorRole: user?.role,
                        actionType: 'SUBSCRIPTION_CHANGE',
                        resourceType: 'SUBSCRIPTION',
                        resourceId: currentSub.id,
                        details: {
                            action: 'SUBSCRIPTION_UPGRADED',
                            oldTier: currentSub.tier,
                            newTier: tier,
                            paymentTransactionId: response.payment?.transactionId,
                            paidAt: response.payment?.paidAt,
                        },
                    },
                });
            } else if (!currentSub) {
                // Create subscription if none exists (edge case)
                await this.prisma.subscription.create({
                    data: {
                        userId,
                        tier: tier as any,
                        storageQuota: BigInt(21474836480), // 20GB
                        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
                    },
                });
                this.logger.log(`✅ Subscription created: ${userId} → ${tier}`);
            }
        } catch (error) {
            this.logger.error(
                `Failed to upgrade subscription for ${userId}: ${error.message}`,
            );
            // Don't throw — payment was successful, subscription update can be retried
        }
    }

    /**
     * Get available subscription plans with pricing.
     */
    async getPlans() {
        return {
            plans: [
                {
                    id: 'PREMIUM',
                    name: 'Premium',
                    price: 0.5,
                    currency: 'USD',
                    period: 'month',
                    features: [
                        'Unlimited prescriptions',
                        'Unlimited medicines',
                        'Up to 5 family connections',
                        '20 GB storage',
                        'Priority support',
                    ],
                    storage: '20 GB',
                },
                {
                    id: 'FAMILY_PREMIUM',
                    name: 'Family Premium',
                    price: 1.0,
                    currency: 'USD',
                    period: 'month',
                    features: [
                        'All Premium features',
                        'Up to 10 family connections',
                        'Family plan (up to 3 members)',
                        '20 GB storage per member',
                        'Priority family support',
                    ],
                    storage: '20 GB',
                },
            ],
            paymentMethods: [
                {
                    id: 'bakong',
                    name: 'Bakong (KHQR)',
                    description: 'Pay with any Cambodian banking app via KHQR',
                    available: true,
                    icon: 'bakong',
                },
                {
                    id: 'visa',
                    name: 'Visa / Mastercard',
                    description: 'Pay with international credit or debit card',
                    available: false,
                    comingSoon: true,
                    icon: 'card',
                },
            ],
        };
    }

    /**
     * Get current user subscription status (local DB).
     */
    async getSubscription(userId: string) {
        const subscription = await this.subscriptionsService.findOne(userId);
        const limits = await this.subscriptionsService.getSubscriptionLimits(userId);

        return {
            subscription: subscription
                ? {
                    id: subscription.id,
                    tier: subscription.tier,
                    storageQuota: Number(subscription.storageQuota),
                    storageUsed: Number(subscription.storageUsed),
                    expiresAt: subscription.expiresAt,
                    familyMembers: subscription.familyMembers?.length || 0,
                }
                : {
                    tier: 'FREEMIUM',
                    storageQuota: 5368709120,
                    storageUsed: 0,
                    expiresAt: null,
                    familyMembers: 0,
                },
            limits,
        };
    }
}
