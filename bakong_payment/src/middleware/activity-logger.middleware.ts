import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';
import * as crypto from 'crypto';

@Injectable()
export class ActivityLoggerMiddleware implements NestMiddleware {
    use(req: Request, res: Response, next: NextFunction) {
        const startTime = Date.now();
        const requestId = crypto.randomBytes(8).toString('hex');

        // Add request ID to request object for tracing
        (req as any).requestId = requestId;

        // Extract request details
        const requestDetails = {
            requestId,
            method: req.method,
            path: req.path,
            url: req.url,
            query: req.query,
            ip: this.getClientIp(req),
            userAgent: req.headers['user-agent'],
            timestamp: new Date().toISOString(),
        };

        // Log request body for POST/PUT/PATCH (excluding sensitive data)
        if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
            requestDetails['body'] = this.sanitizeBody(req.body);
        }

        // Log incoming request
        logger.info('Incoming request', requestDetails);

        // Capture response
        const originalSend = res.send;
        let responseBody: any;

        res.send = function (body: any): Response {
            responseBody = body;
            return originalSend.call(this, body);
        };

        // Log response on finish
        res.on('finish', () => {
            const duration = Date.now() - startTime;

            const responseDetails = {
                requestId,
                method: req.method,
                path: req.path,
                statusCode: res.statusCode,
                duration: `${duration}ms`,
                ip: requestDetails.ip,
                timestamp: new Date().toISOString(),
            };

            // Add response body for errors
            if (res.statusCode >= 400) {
                try {
                    responseDetails['response'] = JSON.parse(responseBody || '{}');
                } catch (e) {
                    // Ignore parse errors
                }
            }

            // Log based on status code
            if (res.statusCode >= 500) {
                logger.error('Server error response', responseDetails);
            } else if (res.statusCode >= 400) {
                logger.warn('Client error response', responseDetails);
            } else {
                logger.info('Successful response', responseDetails);
            }

            // Log slow requests (>1s)
            if (duration > 1000) {
                logger.warn('Slow request detected', {
                    ...responseDetails,
                    level: 'PERFORMANCE',
                });
            }
        });

        next();
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
     * Sanitizes request body to remove sensitive data
     */
    private sanitizeBody(body: any): any {
        if (!body) return {};

        const sanitized = { ...body };
        const sensitiveFields = [
            'password',
            'apiKey',
            'token',
            'secret',
            'authorization',
            'qrCode', // Can be very long
        ];

        for (const key of Object.keys(sanitized)) {
            if (sensitiveFields.some(s => key.toLowerCase().includes(s))) {
                sanitized[key] = '[REDACTED]';
            }
        }

        return sanitized;
    }
}
