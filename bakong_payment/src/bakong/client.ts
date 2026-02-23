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
     * Calls Bakong API: POST /check_transaction_by_md5
     * @param md5Hash - MD5 hash of QR code
     * @returns Payment status
     */
    async checkPayment(md5Hash: string): Promise<PaymentStatus> {
        logger.info('Checking payment status', { md5Hash });

        try {
            const response = await retry(
                async () => {
                    // Correct Bakong API endpoint: POST with md5 in body
                    return await this.client.post('/check_transaction_by_md5', { md5: md5Hash });
                },
                {
                    maxRetries: 3,
                    initialDelay: BAKONG_API_RETRY_DELAYS[0],
                    exponentialBackoff: true,
                }
            );

            const data = response.data;

            // Bakong API: responseCode 0 = PAID, non-zero = not yet paid
            if (data.responseCode === 0 && data.data) {
                const paymentData = data.data;
                const paymentStatus: PaymentStatus = {
                    md5Hash,
                    status: 'PAID',
                    amount: parseFloat(paymentData.amount) || 0,
                    currency: paymentData.currency || 'USD',
                    paidAt: paymentData.acknowledgedDateMs
                        ? new Date(paymentData.acknowledgedDateMs)
                        : new Date(),
                    bakongData: {
                        fromAccountId: paymentData.fromAccountId || '',
                        toAccountId: paymentData.toAccountId || '',
                        hash: paymentData.hash || '',
                        description: paymentData.description || '',
                    },
                };

                logger.info('Payment confirmed as PAID', {
                    md5Hash,
                    status: paymentStatus.status,
                });

                return paymentStatus;
            } else {
                // Payment not yet made
                logger.info('Payment status: PENDING/UNPAID', { md5Hash, responseCode: data.responseCode });
                return {
                    md5Hash,
                    status: 'PENDING',
                    amount: 0,
                    currency: 'USD',
                };
            }
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
     * Generates a Bakong deep link (short link) for the given QR code
     * Calls Bakong API: POST /generate_deeplink_by_qr
     * @param qrCode - KHQR string
     * @param options - Deep link options
     * @returns Short link URL or null on failure
     */
    async generateDeeplink(
        qrCode: string,
        options?: { callback?: string; appIconUrl?: string; appName?: string }
    ): Promise<string | null> {
        logger.info('Generating deep link via Bakong API');

        try {
            const response = await this.client.post('/generate_deeplink_by_qr', {
                qr: qrCode,
                sourceInfo: {
                    appIconUrl: options?.appIconUrl || 'https://bakong.nbc.gov.kh/images/logo.svg',
                    appName: options?.appName || 'Das Tern',
                    appDeepLinkCallback: options?.callback || 'https://bakong.nbc.org.kh',
                },
            });

            const data = response.data;
            if (data.responseCode === 0 && data.data?.shortLink) {
                logger.info('Deep link generated successfully');
                return data.data.shortLink;
            }

            logger.warn('Deep link generation: API returned no shortLink', {
                responseCode: data.responseCode,
                responseMessage: data.responseMessage,
            });
            return null;
        } catch (error) {
            logger.error('Failed to generate deep link via Bakong API', {
                error: (error as Error).message,
            });
            return null;
        }
    }

    /**
     * Checks multiple payment statuses in bulk (max 50)
     * Calls Bakong API: POST /check_transaction_by_md5_list
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
                    // Bakong API expects a plain array of md5 strings
                    return await this.client.post('/check_transaction_by_md5_list', md5Hashes);
                },
                {
                    maxRetries: 3,
                    initialDelay: BAKONG_API_RETRY_DELAYS[0],
                    exponentialBackoff: true,
                }
            );

            const data = response.data;
            // Successful paid entries have status 'SUCCESS' in the data array
            const results: PaymentStatus[] = (data.data || []).map((item: any) => ({
                md5Hash: item.md5,
                status: item.status === 'SUCCESS' ? 'PAID' : 'PENDING',
                amount: 0,
                currency: 'USD',
            } as PaymentStatus));

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
