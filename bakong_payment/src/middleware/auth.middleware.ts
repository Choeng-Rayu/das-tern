import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { createClient, RedisClientType } from 'redis';
import { hash } from '../utils/encryption';
import logger from '../utils/logger';

@Injectable()
export class AuthMiddleware implements NestMiddleware {
    private redisClient: RedisClientType | null = null;
    private failedAttempts: Map<string, { count: number; timestamp: number }> = new Map();

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
                logger.error('Redis client error', { error: err.message });
            });

            await this.redisClient.connect();
            logger.info('Redis client connected for auth middleware');
        } catch (error) {
            logger.warn('Redis not available, using in-memory cache', {
                error: (error as Error).message,
            });
        }
    }

    async use(req: Request, res: Response, next: NextFunction) {
        const apiKey = this.extractApiKey(req);
        const clientIp = this.getClientIp(req);

        // Check if IP is blocked
        if (this.isIpBlocked(clientIp)) {
            logger.warn('Blocked IP attempt', {
                ip: clientIp,
                path: req.path,
                level: 'SECURITY',
            });

            // Create security audit log
            this.logSecurityEvent(clientIp, 'IP_BLOCKED', req);

            throw new UnauthorizedException('Too many failed authentication attempts. IP blocked.');
        }

        // Validate API key
        if (!apiKey) {
            this.recordFailedAttempt(clientIp);
            this.logSecurityEvent(clientIp, 'MISSING_API_KEY', req);
            throw new UnauthorizedException('API key required');
        }

        const isValid = await this.validateApiKey(apiKey);

        if (!isValid) {
            this.recordFailedAttempt(clientIp);
            this.logSecurityEvent(clientIp, 'INVALID_API_KEY', req);
            throw new UnauthorizedException('Invalid API key');
        }

        // Reset failed attempts on successful authentication
        this.resetFailedAttempts(clientIp);

        // Add API key info to request
        (req as any).apiKey = apiKey;
        (req as any).authenticated = true;

        logger.info('API request authenticated', {
            path: req.path,
            method: req.method,
            ip: clientIp,
        });

        next();
    }

    /**
     * Extracts API key from Authorization header
     * Expected format: "Bearer <api_key>"
     */
    private extractApiKey(req: Request): string | null {
        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return null;
        }

        const parts = authHeader.split(' ');
        if (parts.length !== 2 || parts[0] !== 'Bearer') {
            return null;
        }

        return parts[1];
    }

    /**
     * Validates API key against environment variable
     * Uses Redis cache for performance
     */
    private async validateApiKey(apiKey: string): Promise<boolean> {
        const expectedApiKey = process.env.MAIN_BACKEND_API_KEY;

        if (!expectedApiKey) {
            logger.error('MAIN_BACKEND_API_KEY not configured');
            return false;
        }

        // Check Redis cache first
        const cacheKey = `api_key:${hash(apiKey)}`;

        if (this.redisClient) {
            try {
                const cached = await this.redisClient.get(cacheKey);
                if (cached === 'valid') {
                    return true;
                }
                if (cached === 'invalid') {
                    return false;
                }
            } catch (error) {
                logger.warn('Redis cache check failed', {
                    error: (error as Error).message,
                });
            }
        }

        // Validate API key
        const isValid = apiKey === expectedApiKey;

        // Cache result in Redis (TTL: 5 minutes)
        if (this.redisClient) {
            try {
                await this.redisClient.setEx(
                    cacheKey,
                    300, // 5 minutes
                    isValid ? 'valid' : 'invalid'
                );
            } catch (error) {
                logger.warn('Redis cache set failed', {
                    error: (error as Error).message,
                });
            }
        }

        return isValid;
    }

    /**
     * Records failed authentication attempt for an IP
     */
    private recordFailedAttempt(ip: string): void {
        const existing = this.failedAttempts.get(ip);
        const now = Date.now();

        if (existing) {
            // Reset if last attempt was more than 5 minutes ago
            if (now - existing.timestamp > 5 * 60 * 1000) {
                this.failedAttempts.set(ip, { count: 1, timestamp: now });
            } else {
                this.failedAttempts.set(ip, {
                    count: existing.count + 1,
                    timestamp: now,
                });
            }
        } else {
            this.failedAttempts.set(ip, { count: 1, timestamp: now });
        }

        const attempts = this.failedAttempts.get(ip)!;
        logger.warn('Failed authentication attempt', {
            ip,
            attempts: attempts.count,
            level: 'SECURITY',
        });
    }

    /**
     * Resets failed attempts for an IP
     */
    private resetFailedAttempts(ip: string): void {
        this.failedAttempts.delete(ip);
    }

    /**
     * Checks if IP is blocked (10+ failed attempts in 5 minutes)
     */
    private isIpBlocked(ip: string): boolean {
        const attempts = this.failedAttempts.get(ip);

        if (!attempts) {
            return false;
        }

        const now = Date.now();
        const fiveMinutesAgo = now - 5 * 60 * 1000;

        // Block if 10 or more attempts in last 5 minutes
        return attempts.count >= 10 && attempts.timestamp > fiveMinutesAgo;
    }

    /**
     * Gets client IP address from request
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
     * Logs security event
     */
    private logSecurityEvent(ip: string, eventType: string, req: Request): void {
        logger.warn('Security event', {
            level: 'SECURITY',
            eventType,
            ip,
            path: req.path,
            method: req.method,
            userAgent: req.headers['user-agent'],
            timestamp: new Date().toISOString(),
        });
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
