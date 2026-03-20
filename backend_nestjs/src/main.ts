import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module';

// Enable BigInt → JSON serialisation (Prisma returns BigInt for large ints)
(BigInt.prototype as any).toJSON = function () {
  return Number(this);
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Security
  app.use(helmet());

  const allowedOrigins = configService.get('ALLOWED_ORIGINS')?.split(',') || [];
  const isDev = configService.get('NODE_ENV') !== 'production';
  app.enableCors({
    // In development allow all origins; in production restrict to the list
    origin: isDev ? true : (allowedOrigins.length > 0 ? allowedOrigins : false),
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // Compression
  app.use(compression());

  // Global prefix
  app.setGlobalPrefix(configService.get('API_PREFIX') || 'api/v1');

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  const port = Number(configService.get('PORT') || 3000);
  const host = configService.get('HOST') || '0.0.0.0';
  await app.listen(port, host);

  const prefix = configService.get('API_PREFIX') || 'api/v1';
  console.log(`🚀 Application is running on: http://localhost:${port}/${prefix}`);
  if (host === '0.0.0.0') {
    console.log(`🌐 Network access enabled on port ${port} (bind: 0.0.0.0)`);
  }
}

bootstrap();
