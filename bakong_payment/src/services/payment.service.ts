import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BakongKHQR } from '../bakong/khqr';
import { BakongClient, PaymentStatus as BakongPaymentStatus } from '../bakong/client';
import { PaymentInitiationParams, PaymentTransactionDto, MonitorOptions } from '../types/payment.types';
import { PaymentStatus, PlanType } from '@prisma/client';
import logger from '../utils/logger';
import * as crypto from 'crypto';
import * as fs from 'fs/promises';
import * as path from 'path';

@Injectable()
export class PaymentService {
    private bakongClient: BakongClient;

    constructor(private readonly prisma: PrismaService) {
        this.bakongClient = new BakongClient();
    }

    /**
     * Initiates a new payment
     * Generates QR code, stores transaction, and returns payment details
     */
    async initiatePayment(params: PaymentInitiationParams): Promise<PaymentTransactionDto> {
        const {
            userId,
            planType,
            amount,
            currency = 'USD',
            billNumber,
            isUpgrade = false,
            isRenewal = false,
            callback,
            appIconUrl,
            appName,
        } = params;

        logger.info('Initiating payment', {
            userId,
            planType,
            amount,
            currency,
            isUpgrade,
            isRenewal,
        });

        // Generate unique bill number if not provided
        const finalBillNumber = billNumber || this.generateBillNumber();

        // Create KHQR code
        const qrCode = BakongKHQR.createQR({
            bankAccount: process.env.BAKONG_MERCHANT_ID!,
            merchantName: process.env.DEFAULT_MERCHANT_NAME || 'Das Tern',
            merchantCity: process.env.DEFAULT_MERCHANT_CITY || 'Phnom Penh',
            amount,
            currency,
            phoneNumber: process.env.BAKONG_PHONE_NUMBER!,
            billNumber: finalBillNumber,
            storeLabel: 'Das Tern Subscription',
            terminalLabel: 'Web',
            isStatic: false, // Dynamic QR with amount
        });

        // Generate MD5 hash for payment tracking
        const md5Hash = BakongKHQR.generateMD5(qrCode);

        // Generate QR image (base64 data URL)
        const qrImageData = BakongKHQR.generateQRImage(qrCode);
        const qrImagePath = await this.saveQRImage(md5Hash, qrImageData);

        // Generate deep link
        const deepLink = BakongKHQR.generateDeeplink(qrCode, {
            callback,
            appIconUrl,
            appName: appName || 'Das Tern',
        });

        // Create payment transaction in database
        const transaction = await this.prisma.paymentTransaction.create({
            data: {
                userId,
                billNumber: finalBillNumber,
                md5Hash,
                amount,
                currency,
                status: PaymentStatus.PENDING,
                planType: planType as PlanType,
                qrCode,
                qrImagePath,
                deepLink,
                isUpgrade,
                isRenewal,
            },
        });

        // Create initial status history
        await this.prisma.paymentStatusHistory.create({
            data: {
                transactionId: transaction.id,
                oldStatus: null,
                newStatus: PaymentStatus.PENDING,
                reason: 'Payment initiated',
            },
        });

        // Create audit log
        await this.prisma.auditLog.create({
            data: {
                userId,
                action: 'PAYMENT_INITIATED',
                resourceType: 'payment',
                resourceId: transaction.id,
                details: {
                    billNumber: finalBillNumber,
                    amount,
                    currency,
                    planType,
                },
            },
        });

        logger.info('Payment initiated successfully', {
            transactionId: transaction.id,
            md5Hash,
            billNumber: finalBillNumber,
        });

        return this.mapToDto(transaction);
    }

    /**
     * Checks payment status by MD5 hash
     * Updates transaction status if changed
     */
    async checkPaymentStatus(md5Hash: string): Promise<PaymentTransactionDto> {
        logger.info('Checking payment status', { md5Hash });

        // Get transaction from database
        const transaction = await this.prisma.paymentTransaction.findUnique({
            where: { md5Hash },
        });

        if (!transaction) {
            throw new Error(`Payment transaction not found for MD5: ${md5Hash}`);
        }

        // Check with Bakong API
        const bakongStatus = await this.bakongClient.checkPayment(md5Hash);

        // Update transaction if status changed
        if (this.shouldUpdateStatus(transaction.status, bakongStatus.status)) {
            await this.updatePaymentStatus(
                transaction.id,
                transaction.status,
                this.mapBakongStatus(bakongStatus.status),
                bakongStatus.bakongData,
                bakongStatus.paidAt
            );

            // Refetch updated transaction
            const updatedTransaction = await this.prisma.paymentTransaction.findUnique({
                where: { id: transaction.id },
            });

            return this.mapToDto(updatedTransaction!);
        }

        // Update check attempts
        await this.prisma.paymentTransaction.update({
            where: { id: transaction.id },
            data: {
                checkAttempts: { increment: 1 },
                lastCheckedAt: new Date(),
            },
        });

        return this.mapToDto(transaction);
    }

    /**
     * Monitors a payment until completion or timeout
     */
    async monitorPayment(
        transactionId: string,
        options: MonitorOptions = {}
    ): Promise<PaymentTransactionDto> {
        const {
            timeout = 300000, // 5 minutes
            interval = 5000,  // 5 seconds
            maxAttempts = 60,
            priority = 'normal',
        } = options;

        logger.info('Starting payment monitoring', {
            transactionId,
            timeout,
            interval,
            maxAttempts,
            priority,
        });

        const transaction = await this.prisma.paymentTransaction.findUnique({
            where: { id: transactionId },
        });

        if (!transaction) {
            throw new Error(`Payment transaction not found: ${transactionId}`);
        }

        const startTime = Date.now();
        let attempts = 0;

        while (attempts < maxAttempts) {
            // Check if timeout reached
            if (Date.now() - startTime > timeout) {
                logger.warn('Payment monitoring timeout', { transactionId });
                await this.handlePaymentTimeout(transactionId);
                break;
            }

            // Check payment status
            try {
                const updatedTransaction = await this.checkPaymentStatus(transaction.md5Hash);

                // If payment completed or failed, stop monitoring
                if (
                    updatedTransaction.status === PaymentStatus.PAID ||
                    updatedTransaction.status === PaymentStatus.FAILED ||
                    updatedTransaction.status === PaymentStatus.EXPIRED ||
                    updatedTransaction.status === PaymentStatus.CANCELLED
                ) {
                    logger.info('Payment monitoring completed', {
                        transactionId,
                        status: updatedTransaction.status,
                        attempts,
                    });
                    return updatedTransaction;
                }
            } catch (error) {
                logger.error('Error during payment monitoring', {
                    transactionId,
                    error: (error as Error).message,
                });
            }

            // Wait before next check
            await this.sleep(interval);
            attempts++;
        }

        // Return final transaction state
        const finalTransaction = await this.prisma.paymentTransaction.findUnique({
            where: { id: transactionId },
        });

        return this.mapToDto(finalTransaction!);
    }

    /**
     * Handles payment timeout (15 minutes)
     */
    async handlePaymentTimeout(transactionId: string): Promise<void> {
        logger.info('Handling payment timeout', { transactionId });

        const transaction = await this.prisma.paymentTransaction.findUnique({
            where: { id: transactionId },
        });

        if (!transaction) {
            return;
        }

        // Only timeout if still pending
        if (transaction.status === PaymentStatus.PENDING) {
            await this.updatePaymentStatus(
                transactionId,
                PaymentStatus.PENDING,
                PaymentStatus.TIMEOUT,
                undefined,
                undefined,
                'Payment timed out after 15 minutes'
            );
        }
    }

    /**
     * Bulk checks multiple payment statuses
     */
    async bulkCheckPayments(md5Hashes: string[]): Promise<PaymentTransactionDto[]> {
        if (md5Hashes.length === 0) {
            return [];
        }

        logger.info('Bulk checking payments', { count: md5Hashes.length });

        // Get Bakong statuses
        const bakongStatuses = await this.bakongClient.bulkCheckPayments(md5Hashes);

        // Update transactions
        const results: PaymentTransactionDto[] = [];

        for (const bakongStatus of bakongStatuses) {
            try {
                const transaction = await this.prisma.paymentTransaction.findUnique({
                    where: { md5Hash: bakongStatus.md5Hash },
                });

                if (transaction) {
                    if (this.shouldUpdateStatus(transaction.status, bakongStatus.status)) {
                        await this.updatePaymentStatus(
                            transaction.id,
                            transaction.status,
                            this.mapBakongStatus(bakongStatus.status),
                            bakongStatus.bakongData,
                            bakongStatus.paidAt
                        );

                        const updated = await this.prisma.paymentTransaction.findUnique({
                            where: { id: transaction.id },
                        });
                        results.push(this.mapToDto(updated!));
                    } else {
                        results.push(this.mapToDto(transaction));
                    }
                }
            } catch (error) {
                logger.error('Error in bulk check for payment', {
                    md5Hash: bakongStatus.md5Hash,
                    error: (error as Error).message,
                });
            }
        }

        return results;
    }

    /**
     * Updates payment transaction status
     */
    private async updatePaymentStatus(
        transactionId: string,
        oldStatus: PaymentStatus,
        newStatus: PaymentStatus,
        bakongData?: any,
        paidAt?: Date,
        reason?: string
    ): Promise<void> {
        logger.info('Updating payment status', {
            transactionId,
            oldStatus,
            newStatus,
        });

        // Update transaction
        await this.prisma.paymentTransaction.update({
            where: { id: transactionId },
            data: {
                status: newStatus,
                bakongData: bakongData ? bakongData : undefined,
                paidAt: paidAt || (newStatus === PaymentStatus.PAID ? new Date() : undefined),
                expiredAt: newStatus === PaymentStatus.EXPIRED || newStatus === PaymentStatus.TIMEOUT
                    ? new Date()
                    : undefined,
                updatedAt: new Date(),
            },
        });

        // Create status history
        await this.prisma.paymentStatusHistory.create({
            data: {
                transactionId,
                oldStatus,
                newStatus,
                reason: reason || `Status changed from ${oldStatus} to ${newStatus}`,
                metadata: bakongData,
            },
        });

        // Create audit log
        const transaction = await this.prisma.paymentTransaction.findUnique({
            where: { id: transactionId },
        });

        await this.prisma.auditLog.create({
            data: {
                userId: transaction?.userId,
                action: 'PAYMENT_STATUS_CHANGED',
                resourceType: 'payment',
                resourceId: transactionId,
                details: {
                    oldStatus,
                    newStatus,
                    reason,
                },
            },
        });
    }

    /**
     * Determines if status should be updated
     */
    private shouldUpdateStatus(currentStatus: PaymentStatus, newStatus: string): boolean {
        const mapped = this.mapBakongStatus(newStatus);

        // Don't update if already in terminal state
        if (
            currentStatus === PaymentStatus.PAID ||
            currentStatus === PaymentStatus.FAILED ||
            currentStatus === PaymentStatus.CANCELLED
        ) {
            return false;
        }

        // Update if status changed
        return currentStatus !== mapped;
    }

    /**
     * Maps Bakong status to Prisma status
     */
    private mapBakongStatus(bakongStatus: string): PaymentStatus {
        switch (bakongStatus) {
            case 'PAID':
                return PaymentStatus.PAID;
            case 'FAILED':
                return PaymentStatus.FAILED;
            case 'EXPIRED':
                return PaymentStatus.EXPIRED;
            default:
                return PaymentStatus.PENDING;
        }
    }

    /**
     * Generates a unique bill number
     */
    private generateBillNumber(): string {
        const timestamp = Date.now();
        const random = crypto.randomBytes(4).toString('hex');
        return `DT-${timestamp}-${random}`.toUpperCase();
    }

    /**
     * Saves QR code image to file system
     */
    private async saveQRImage(md5Hash: string, imageData: string): Promise<string> {
        const publicDir = path.join(process.cwd(), 'public', 'qr-codes');
        await fs.mkdir(publicDir, { recursive: true });

        const filename = `${md5Hash}.png`;
        const filepath = path.join(publicDir, filename);

        // Extract base64 data from data URL
        const base64Data = imageData.replace(/^data:image\/png;base64,/, '');
        await fs.writeFile(filepath, base64Data, 'base64');

        return `/qr-codes/${filename}`;
    }

    /**
     * Sleep utility
     */
    private sleep(ms: number): Promise<void> {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }

    /**
     * Maps Prisma transaction to DTO
     */
    private mapToDto(transaction: any): PaymentTransactionDto {
        return {
            id: transaction.id,
            userId: transaction.userId,
            billNumber: transaction.billNumber,
            md5Hash: transaction.md5Hash,
            amount: parseFloat(transaction.amount.toString()),
            currency: transaction.currency,
            status: transaction.status,
            planType: transaction.planType,
            qrCode: transaction.qrCode, // KHQR token string (convert to QR image in Flutter)
            qrImagePath: transaction.qrImagePath,
            deepLink: transaction.deepLink,
            bakongData: transaction.bakongData,
            isUpgrade: transaction.isUpgrade,
            isRenewal: transaction.isRenewal,
            proratedAmount: transaction.proratedAmount
                ? parseFloat(transaction.proratedAmount.toString())
                : undefined,
            checkAttempts: transaction.checkAttempts,
            lastCheckedAt: transaction.lastCheckedAt,
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt,
            paidAt: transaction.paidAt,
            expiredAt: transaction.expiredAt,
        };
    }
}
