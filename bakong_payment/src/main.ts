import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import logger from './utils/logger';
import * as fs from 'fs';
import * as path from 'path';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });

  // Enable CORS
  app.enableCors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    })
  );

  // Create necessary directories
  const publicDir = path.join(process.cwd(), 'public');
  const qrCodesDir = path.join(publicDir, 'qr-codes');
  const logsDir = path.join(process.cwd(), 'logs');

  await fs.promises.mkdir(publicDir, { recursive: true });
  await fs.promises.mkdir(qrCodesDir, { recursive: true });
  await fs.promises.mkdir(logsDir, { recursive: true });

  // Get port from environment
  const port = process.env.PORT || 3002;

  await app.listen(port);

  logger.info(`🚀 Bakong Payment Service started on port ${port}`, {
    port,
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
  });

  logger.info('📋 Available endpoints:', {
    health: `http://localhost:${port}/api/health`,
    payments: `http://localhost:${port}/api/payments`,
    subscriptions: `http://localhost:${port}/api/subscriptions`,
  });
}

bootstrap().catch((error) => {
  logger.error('Failed to start application', {
    error: error.message,
    stack: error.stack,
  });
  process.exit(1);
});
