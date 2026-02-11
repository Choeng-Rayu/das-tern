import { IsEnum, IsOptional, IsString } from 'class-validator';

export enum BakongPlanType {
    PREMIUM = 'PREMIUM',
    FAMILY_PREMIUM = 'FAMILY_PREMIUM',
}

export class CreateBakongPaymentDto {
    @IsEnum(BakongPlanType)
    planType: BakongPlanType;

    @IsOptional()
    @IsString()
    appName?: string;
}

export class CheckPaymentStatusDto {
    @IsString()
    md5Hash: string;
}

// Response types (not validated, just typed)
export interface BakongPaymentResponse {
    success: boolean;
    payment: {
        transactionId: string;
        md5Hash: string;
        qrCode: string;
        deepLink?: string;
        amount: number;
        currency: string;
        status: string;
        expiresAt: string;
    };
}

export interface BakongStatusResponse {
    success: boolean;
    payment: {
        transactionId: string;
        status: string;
        amount: number;
        paidAt?: string;
    };
    subscription?: {
        id: string;
        userId: string;
        planType: string;
        status: string;
        startDate: string;
        nextBillingDate: string;
    };
}
