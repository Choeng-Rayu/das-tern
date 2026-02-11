import * as winston from 'winston';
import * as path from 'path';

// Custom format for activity logs
const activityFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.json()
);

// Custom format for payment/subscription logs
const operationFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.json()
);

// Create Winston logger instance
export const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        winston.format.errors({ stack: true }),
        winston.format.splat(),
        winston.format.json()
    ),
    defaultMeta: { service: 'bakong-payment-service' },
    transports: [
        // Combined log - all logs
        new winston.transports.File({
            filename: 'logs/combined.log',
            maxsize: 10485760, // 10MB
            maxFiles: 5,
        }),

        // Error logs only
        new winston.transports.File({
            filename: 'logs/error.log',
            level: 'error',
            maxsize: 10485760,
            maxFiles: 5,
        }),

        // Activity logs - all HTTP requests/responses
        new winston.transports.File({
            filename: 'logs/activity.log',
            format: activityFormat,
            maxsize: 10485760,
            maxFiles: 5,
        }),

        // Payment operations log
        new winston.transports.File({
            filename: 'logs/payment.log',
            format: operationFormat,
            level: 'info',
            maxsize: 10485760,
            maxFiles: 10, // Keep more payment logs
        }),

        // Subscription operations log
        new winston.transports.File({
            filename: 'logs/subscription.log',
            format: operationFormat,
            level: 'info',
            maxsize: 10485760,
            maxFiles: 10,
        }),

        // Security events log
        new winston.transports.File({
            filename: 'logs/security.log',
            level: 'warn',
            format: winston.format.combine(
                winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
                winston.format.label({ label: 'SECURITY' }),
                winston.format.json()
            ),
            maxsize: 10485760,
            maxFiles: 10,
        }),

        // Performance logs - slow requests, timeouts
        new winston.transports.File({
            filename: 'logs/performance.log',
            format: winston.format.combine(
                winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
                winston.format.label({ label: 'PERFORMANCE' }),
                winston.format.json()
            ),
            maxsize: 5242880, // 5MB
            maxFiles: 3,
        }),

        // Audit log - critical operations
        new winston.transports.File({
            filename: 'logs/audit.log',
            format: winston.format.combine(
                winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
                winston.format.label({ label: 'AUDIT' }),
                winston.format.json()
            ),
            maxsize: 10485760,
            maxFiles: 20, // Keep many audit logs
        }),
    ],
});

// If we're not in production, log to the console as well
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize(),
            winston.format.printf(({ level, message, timestamp, ...metadata }) => {
                let msg = `${timestamp} [${level}]: ${message}`;

                // Add metadata in a more readable format
                const filteredMetadata = { ...metadata };
                delete filteredMetadata.service;
                delete filteredMetadata.label;

                if (Object.keys(filteredMetadata).length > 0) {
                    // Pretty print for console, truncate long values
                    const prettyMeta = JSON.stringify(filteredMetadata, null, 2)
                        .split('\n')
                        .slice(0, 10) // Max 10 lines
                        .join('\n');
                    msg += `\n${prettyMeta}`;
                }

                return msg;
            })
        ),
    }));
}

// Helper functions for specific log types
export const logPayment = (message: string, data: any) => {
    logger.info(message, { ...data, logType: 'PAYMENT' });
};

export const logSubscription = (message: string, data: any) => {
    logger.info(message, { ...data, logType: 'SUBSCRIPTION' });
};

export const logSecurity = (message: string, data: any) => {
    logger.warn(message, { ...data, level: 'SECURITY' });
};

export const logPerformance = (message: string, data: any) => {
    logger.warn(message, { ...data, level: 'PERFORMANCE' });
};

export const logAudit = (message: string, data: any) => {
    logger.info(message, { ...data, level: 'AUDIT' });
};

export default logger;
