import axios, { AxiosInstance } from 'axios';
import { retry, BAKONG_API_RETRY_DELAYS } from '../utils/retry';
import logger from '../utils/logger';

export interface PaymentStatus {
    status: 'PENDING' | 'PAID' | 'FAILED' | 'EXPIRED';
    transactionId?: string;
    md5Hash: string;
    amount: number;
    currency: string;
    paidAt?: Date;
    bakongData?: {
        fromAccountId: string;
        toAccountId: string;
        hash: string;
        description: string;
    };
}

export interface BulkPaymentCheckRequest {
    md5Hashes: string[]; // Max 50
}

export interface BulkPaymentCheckResponse {
    results: PaymentStatus[];
}

/**
 * Bakong API Client for payment verification
 */
export class BakongClient {
    private client: AxiosInstance;
    private developerToken: string;

    constructor() {
        this.developerToken = process.env.BAKONG_DEVELOPER_TOKEN || '';

        if (!this.developerToken) {
            throw new Error('BAKONG_DEVELOPER_TOKEN not configured');
        }

        this.client = axios.create({
            baseURL: process.env.BAKONG_API_URL || 'https://api-bakong.nbc.gov.kh/v1',
            timeout: 30000, // 30 seconds
            headers: {
                'Authorization': `Bearer ${this.developerToken}`,
                'Content-Type': 'application/json',
            },
        });

        // Response interceptor for error handling
        this.client.interceptors.response.use(
            (response) => response,
            (error) => this.handleApiError(error)
        );
    }

    /**
     * Checks payment status by MD5 hash
     * @param md5Hash - MD5 hash of QR code
     * @returns Payment status
     */
    async checkPayment(md5Hash: string): Promise<PaymentStatus> {
        logger.info('Checking payment status', { md5Hash });

        try {
            const response = await retry(
                async () => {
                    return await this.client.get(`/payment/${md5Hash}`);
                },
                {
                    maxRetries: 3,
                    initialDelay: BAKONG_API_RETRY_DELAYS[0],
                    exponentialBackoff: true,
                }
            );

            const data = response.data;

            // Parse Bakong API response
            const paymentStatus: PaymentStatus = {
                md5Hash,
                status: this.mapBakongStatus(data.status),
                transactionId: data.transactionId,
                amount: parseFloat(data.amount),
                currency: data.currency,
                paidAt: data.paidAt ? new Date(data.paidAt) : undefined,
                bakongData: data.bakongData ? {
                    fromAccountId: data.bakongData.fromAccountId,
                    toAccountId: data.bakongData.toAccountId,
                    hash: data.bakongData.hash,
                    description: data.bakongData.description,
                } : undefined,
            };

            logger.info('Payment status retrieved', {
                md5Hash,
                status: paymentStatus.status,
            });

            return paymentStatus;
        } catch (error) {
            logger.error('Failed to check payment status', {
                md5Hash,
                error: (error as Error).message,
            });

            // Return PENDING status if payment not found (404)
            if (axios.isAxiosError(error) && error.response?.status === 404) {
                return {
                    md5Hash,
                    status: 'PENDING',
                    amount: 0,
                    currency: 'USD',
                };
            }

            throw error;
        }
    }

    /**
     * Checks multiple payment statuses in bulk (max 50)
     * @param md5Hashes - Array of MD5 hashes
     * @returns Array of payment statuses
     */
    async bulkCheckPayments(md5Hashes: string[]): Promise<PaymentStatus[]> {
        if (md5Hashes.length === 0) {
            return [];
        }

        if (md5Hashes.length > 50) {
            throw new Error('Bulk check limited to 50 payments at a time');
        }

        logger.info('Bulk checking payment statuses', {
            count: md5Hashes.length,
        });

        try {
            const response = await retry(
                async () => {
                    return await this.client.post('/payment/bulk-check', {
                        md5Hashes,
                    });
                },
                {
                    maxRetries: 3,
                    initialDelay: BAKONG_API_RETRY_DELAYS[0],
                    exponentialBackoff: true,
                }
            );

            const results: PaymentStatus[] = response.data.results.map((item: any) => ({
                md5Hash: item.md5Hash,
                status: this.mapBakongStatus(item.status),
                transactionId: item.transactionId,
                amount: parseFloat(item.amount),
                currency: item.currency,
                paidAt: item.paidAt ? new Date(item.paidAt) : undefined,
                bakongData: item.bakongData,
            }));

            logger.info('Bulk check completed', {
                count: results.length,
            });

            return results;
        } catch (error) {
            logger.error('Failed to bulk check payments', {
                error: (error as Error).message,
            });
            throw error;
        }
    }

    /**
     * Health check for Bakong API
     * @returns True if API is available
     */
    async healthCheck(): Promise<boolean> {
        try {
            const response = await this.client.get('/health');
            return response.status === 200;
        } catch (error) {
            logger.warn('Bakong API health check failed', {
                error: (error as Error).message,
            });
            return false;
        }
    }

    /**
     * Maps Bakong API status to internal status
     * @param bakongStatus - Status from Bakong API
     * @returns Internal status
     */
    private mapBakongStatus(bakongStatus: string): 'PENDING' | 'PAID' | 'FAILED' | 'EXPIRED' {
        switch (bakongStatus?.toUpperCase()) {
            case 'COMPLETED':
            case 'SUCCESS':
            case 'PAID':
                return 'PAID';
            case 'FAILED':
            case 'REJECTED':
                return 'FAILED';
            case 'EXPIRED':
                return 'EXPIRED';
            default:
                return 'PENDING';
        }
    }

    /**
     * Handles Bakong API errors
     * @param error - Axios error
     */
    private handleApiError(error: any): never {
        if (axios.isAxiosError(error)) {
            const status = error.response?.status;
            const data = error.response?.data;

            switch (status) {
                case 400:
                    logger.error('Bakong API: Bad request', { data });
                    throw new Error('Invalid request parameters');

                case 401:
                    logger.error('Bakong API: Unauthorized', { data });
                    throw new Error('Invalid or expired developer token');

                case 403:
                    logger.error('Bakong API: Forbidden - IP not whitelisted', { data });
                    throw new Error('Cambodia IP address required for Bakong API access');

                case 404:
                    // Payment not found - this is normal for pending payments
                    throw error;

                case 429:
                    logger.warn('Bakong API: Rate limited', { data });
                    throw new Error('Rate limit exceeded');

                case 500:
                case 502:
                case 503:
                case 504:
                    logger.error('Bakong API: Server error', { status, data });
                    throw new Error('Bakong API server error');

                default:
                    logger.error('Bakong API: Unknown error', { status, data });
                    throw new Error('Unknown Bakong API error');
            }
        }

        throw error;
    }
}
