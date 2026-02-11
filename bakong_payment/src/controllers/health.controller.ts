import { Controller, Get, HttpStatus, HttpException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BakongClient } from '../bakong/client';
import { createClient } from 'redis';
import logger from '../utils/logger';

@Controller('api/health')
export class HealthController {
    constructor(private readonly prisma: PrismaService) { }

    /**
     * GET /api/health
     * Health check endpoint
     * Returns status of all dependencies
     */
    @Get()
    async healthCheck() {
        const health = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            services: {
                database: { status: 'unknown', message: '' },
                redis: { status: 'unknown', message: '' },
                bakong: { status: 'unknown', message: '' },
            },
        };

        let allHealthy = true;

        // Check database
        try {
            await this.prisma.$queryRaw`SELECT 1`;
            health.services.database = {
                status: 'healthy',
                message: 'Connected to PostgreSQL',
            };
            logger.info('Database health check: OK');
        } catch (error) {
            health.services.database = {
                status: 'unhealthy',
                message: (error as Error).message,
            };
            allHealthy = false;
            logger.error('Database health check failed', {
                error: (error as Error).message,
            });
        }

        // Check Redis
        try {
            const redisClient = createClient({
                url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`,
                password: process.env.REDIS_PASSWORD || undefined,
            });

            await redisClient.connect();
            await redisClient.ping();
            await redisClient.quit();

            health.services.redis = {
                status: 'healthy',
                message: 'Connected to Redis',
            };
            logger.info('Redis health check: OK');
        } catch (error) {
            health.services.redis = {
                status: 'unhealthy',
                message: (error as Error).message,
            };
            allHealthy = false;
            logger.error('Redis health check failed', {
                error: (error as Error).message,
            });
        }

        // Check Bakong API (optional - may fail if not on Cambodia IP)
        try {
            const bakongClient = new BakongClient();
            const isHealthy = await bakongClient.healthCheck();

            if (isHealthy) {
                health.services.bakong = {
                    status: 'healthy',
                    message: 'Bakong API accessible',
                };
            } else {
                health.services.bakong = {
                    status: 'degraded',
                    message: 'Bakong API not responding (may require Cambodia IP)',
                };
            }
            logger.info('Bakong API health check: OK');
        } catch (error) {
            health.services.bakong = {
                status: 'degraded',
                message: 'Bakong API check failed (may require Cambodia IP)',
            };
            // Don't mark as unhealthy since Bakong requires Cambodia IP
            logger.warn('Bakong API health check failed', {
                error: (error as Error).message,
            });
        }

        // Determine overall status
        health.status = allHealthy ? 'healthy' : 'unhealthy';

        // Return appropriate HTTP status
        if (!allHealthy) {
            throw new HttpException(health, HttpStatus.SERVICE_UNAVAILABLE);
        }

        return health;
    }

    /**
     * GET /api/health/ready
     * Readiness probe - checks if service is ready to accept requests
     */
    @Get('ready')
    async readinessCheck() {
        try {
            // Check database connection
            await this.prisma.$queryRaw`SELECT 1`;

            return {
                status: 'ready',
                timestamp: new Date().toISOString(),
            };
        } catch (error) {
            logger.error('Readiness check failed', {
                error: (error as Error).message,
            });

            throw new HttpException(
                {
                    status: 'not ready',
                    error: 'Database not available',
                    timestamp: new Date().toISOString(),
                },
                HttpStatus.SERVICE_UNAVAILABLE
            );
        }
    }

    /**
     * GET /api/health/live
     * Liveness probe - checks if service is running
     */
    @Get('live')
    async livenessCheck() {
        return {
            status: 'alive',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memoryUsage: process.memoryUsage(),
        };
    }
}
