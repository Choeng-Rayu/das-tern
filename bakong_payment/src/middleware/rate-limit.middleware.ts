import { Injectable, NestMiddleware, HttpException, HttpStatus } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { createClient, RedisClientType } from 'redis';
import logger from '../utils/logger';

interface RateLimitConfig {
    windowMs: number;      // Time window in milliseconds
    maxRequests: number;   // Max requests per window
}

@Injectable()
export class RateLimitMiddleware implements NestMiddleware {
    private redisClient: RedisClientType | null = null;
    private inMemoryStore: Map<string, { count: number; resetTime: number }> = new Map();

    // Default: 100 requests per minute
    private config: RateLimitConfig = {
        windowMs: 60 * 1000,  // 1 minute
        maxRequests: 100,
    };

    constructor() {
        this.initRedis();
    }

    private async initRedis() {
        try {
            this.redisClient = createClient({
                url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`,
                password: process.env.REDIS_PASSWORD || undefined,
            });

            this.redisClient.on('error', (err) => {
                logger.error('Redis client error in rate limiter', { error: err.message });
            });

            await this.redisClient.connect();
            logger.info('Redis client connected for rate limiting');
        } catch (error) {
            logger.warn('Redis not available for rate limiting, using in-memory store', {
                error: (error as Error).message,
            });
        }
    }

    async use(req: Request, res: Response, next: NextFunction) {
        const key = this.generateKey(req);
        const now = Date.now();

        try {
            if (this.redisClient) {
                await this.checkRateLimitRedis(key, now, req, res, next);
            } else {
                this.checkRateLimitMemory(key, now, req, res, next);
            }
        } catch (error) {
            logger.error('Rate limit check failed', {
                error: (error as Error).message,
            });
            // Fail open - allow request if rate limiting system fails
            next();
        }
    }

    /**
     * Checks rate limit using Redis
     */
    private async checkRateLimitRedis(
        key: string,
        now: number,
        req: Request,
        res: Response,
        next: NextFunction
    ): Promise<void> {
        const redisKey = `rate_limit:${key}`;

        try {
            // Increment counter
            const count = await this.redisClient!.incr(redisKey);

            // Set expiry on first request
            if (count === 1) {
                await this.redisClient!.expire(redisKey, Math.ceil(this.config.windowMs / 1000));
            }

            // Get TTL for reset time calculation
            const ttl = await this.redisClient!.ttl(redisKey);
            const resetTime = now + (ttl * 1000);

            // Set rate limit headers
            res.setHeader('X-RateLimit-Limit', this.config.maxRequests.toString());
            res.setHeader('X-RateLimit-Remaining', Math.max(0, this.config.maxRequests - count).toString());
            res.setHeader('X-RateLimit-Reset', new Date(resetTime).toISOString());

            // Check if limit exceeded
            if (count > this.config.maxRequests) {
                logger.warn('Rate limit exceeded', {
                    key,
                    count,
                    limit: this.config.maxRequests,
                    path: req.path,
                    level: 'SECURITY',
                });

                res.setHeader('Retry-After', Math.ceil(ttl).toString());

                throw new HttpException(
                    {
                        statusCode: HttpStatus.TOO_MANY_REQUESTS,
                        message: 'Too many requests. Please try again later.',
                        retryAfter: ttl,
                    },
                    HttpStatus.TOO_MANY_REQUESTS
                );
            }

            next();
        } catch (error) {
            if (error instanceof HttpException) {
                throw error;
            }
            logger.error('Redis rate limit error', {
                error: (error as Error).message,
            });
            next(); // Fail open
        }
    }

    /**
     * Checks rate limit using in-memory store (fallback)
     */
    private checkRateLimitMemory(
        key: string,
        now: number,
        req: Request,
        res: Response,
        next: NextFunction
    ): void {
        const existing = this.inMemoryStore.get(key);

        let count = 1;
        let resetTime = now + this.config.windowMs;

        if (existing) {
            if (now > existing.resetTime) {
                // Window expired, reset
                count = 1;
                resetTime = now + this.config.windowMs;
            } else {
                // Within window, increment
                count = existing.count + 1;
                resetTime = existing.resetTime;
            }
        }

        this.inMemoryStore.set(key, { count, resetTime });

        // Cleanup old entries periodically
        if (Math.random() < 0.01) { // 1% chance to clean up
            this.cleanupMemoryStore(now);
        }

        // Set rate limit headers
        res.setHeader('X-RateLimit-Limit', this.config.maxRequests.toString());
        res.setHeader('X-RateLimit-Remaining', Math.max(0, this.config.maxRequests - count).toString());
        res.setHeader('X-RateLimit-Reset', new Date(resetTime).toISOString());

        // Check if limit exceeded
        if (count > this.config.maxRequests) {
            const retryAfter = Math.ceil((resetTime - now) / 1000);

            logger.warn('Rate limit exceeded (memory)', {
                key,
                count,
                limit: this.config.maxRequests,
                path: req.path,
                level: 'SECURITY',
            });

            res.setHeader('Retry-After', retryAfter.toString());

            throw new HttpException(
                {
                    statusCode: HttpStatus.TOO_MANY_REQUESTS,
                    message: 'Too many requests. Please try again later.',
                    retryAfter,
                },
                HttpStatus.TOO_MANY_REQUESTS
            );
        }

        next();
    }

    /**
     * Generates rate limit key based on API key or IP
     */
    private generateKey(req: Request): string {
        // Use API key if authenticated
        const authenticated = (req as any).authenticated;
        const apiKey = (req as any).apiKey;

        if (authenticated && apiKey) {
            return `api:${apiKey.substring(0, 10)}`; // Use first 10 chars as identifier
        }

        // Fall back to IP address
        const ip = this.getClientIp(req);
        return `ip:${ip}`;
    }

    /**
     * Gets client IP address
     */
    private getClientIp(req: Request): string {
        const forwarded = req.headers['x-forwarded-for'];

        if (forwarded) {
            const ips = (forwarded as string).split(',');
            return ips[0].trim();
        }

        return req.socket.remoteAddress || 'unknown';
    }

    /**
     * Cleans up expired entries from in-memory store
     */
    private cleanupMemoryStore(now: number): void {
        const toDelete: string[] = [];

        for (const [key, value] of this.inMemoryStore.entries()) {
            if (now > value.resetTime) {
                toDelete.push(key);
            }
        }

        toDelete.forEach((key) => this.inMemoryStore.delete(key));

        if (toDelete.length > 0) {
            logger.debug('Cleaned up expired rate limit entries', {
                count: toDelete.length,
            });
        }
    }

    /**
     * Cleanup method to close Redis connection
     */
    async onModuleDestroy() {
        if (this.redisClient) {
            await this.redisClient.quit();
        }
    }
}
