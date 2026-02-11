import logger from './logger';

export interface RetryOptions {
    maxRetries: number;
    initialDelay: number; // milliseconds
    maxDelay?: number; // milliseconds
    exponentialBackoff?: boolean;
    onRetry?: (error: Error, attempt: number) => void;
}

/**
 * Retries a function with exponential backoff
 * @param fn - Function to retry
 * @param options - Retry options
 * @returns Result of the function
 */
export async function retry<T>(
    fn: () => Promise<T>,
    options: RetryOptions
): Promise<T> {
    const {
        maxRetries,
        initialDelay,
        maxDelay = 30000, // 30 seconds max delay
        exponentialBackoff = true,
        onRetry,
    } = options;

    let lastError: Error;
    let delay = initialDelay;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error as Error;

            if (attempt === maxRetries) {
                logger.error('Max retries reached', {
                    error: lastError.message,
                    stack: lastError.stack,
                    attempts: attempt + 1,
                });
                throw lastError;
            }

            // Calculate delay for next attempt
            if (exponentialBackoff) {
                delay = Math.min(initialDelay * Math.pow(2, attempt), maxDelay);
            }

            logger.warn('Retrying operation', {
                attempt: attempt + 1,
                maxRetries,
                delayMs: delay,
                error: lastError.message,
            });

            if (onRetry) {
                onRetry(lastError, attempt + 1);
            }

            // Wait before next attempt
            await sleep(delay);
        }
    }

    throw lastError!;
}

/**
 * Sleep for specified milliseconds
 * @param ms - Milliseconds to sleep
 */
export function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Exponential backoff delays for 3 retries (used for webhooks)
 * Delays: 1s, 2s, 4s
 */
export const WEBHOOK_RETRY_DELAYS = [1000, 2000, 4000];

/**
 * Exponential backoff delays for database retries
 * Delays: 100ms, 200ms, 400ms
 */
export const DATABASE_RETRY_DELAYS = [100, 200, 400];

/**
 * Exponential backoff delays for Bakong API retries
 * Delays: 1s, 2s, 4s
 */
export const BAKONG_API_RETRY_DELAYS = [1000, 2000, 4000];
