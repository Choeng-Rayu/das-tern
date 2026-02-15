import { PaymentStatus as PrismaPaymentStatus, PlanType as PrismaPlanType } from '@prisma/client';

// Re-export Prisma enums
export { PrismaPaymentStatus as PaymentStatus, PrismaPlanType as PlanType };

export interface PaymentInitiationParams {
    userId: string;
    planType: 'PREMIUM' | 'FAMILY_PREMIUM';
    amount: number;
    currency: 'USD' | 'KHR';
    billNumber?: string;        // Optional, will be generated if not provided
    isUpgrade?: boolean;
    isRenewal?: boolean;
    callback?: string;          // Success callback URL
    appIconUrl?: string;
    appName?: string;
}

export interface MonitorOptions {
    timeout?: number;           // Total monitoring timeout (default: 300000ms = 5 min)
    interval?: number;          // Check interval (default: 5000ms = 5 sec)
    maxAttempts?: number;       // Max check attempts (default: 60)
    priority?: 'low' | 'normal' | 'high';
}

export interface PaymentTransactionDto {
    id: string;
    userId: string;
    billNumber: string;
    md5Hash: string;
    amount: number;
    currency: string;
    status: PrismaPaymentStatus;
    planType: PrismaPlanType;
    qrCode?: string;
    qrImagePath?: string;
    deepLink?: string;
    bakongData?: any;
    isUpgrade: boolean;
    isRenewal: boolean;
    proratedAmount?: number;
    checkAttempts: number;
    lastCheckedAt?: Date;
    createdAt: Date;
    updatedAt: Date;
    paidAt?: Date;
    expiredAt?: Date;
}

export interface CreateSubscriptionParams {
    userId: string;
    planType: 'PREMIUM' | 'FAMILY_PREMIUM';
    paymentTransactionId: string;
    paidAt: Date;
}

export interface UpgradeParams {
    userId: string;
    newPlanType: 'FAMILY_PREMIUM';
    currentPlanType: 'PREMIUM';
}

export interface DowngradeParams {
    userId: string;
    newPlanType: 'PREMIUM';
    currentPlanType: 'FAMILY_PREMIUM';
}
