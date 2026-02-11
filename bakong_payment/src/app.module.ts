import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaService } from './prisma/prisma.service';
import { PaymentService } from './services/payment.service';
import { SubscriptionService } from './services/subscription.service';
import { PaymentController } from './controllers/payment.controller';
import { SubscriptionController } from './controllers/subscription.controller';
import { HealthController } from './controllers/health.controller';
import { AuthMiddleware } from './middleware/auth.middleware';
import { RateLimitMiddleware } from './middleware/rate-limit.middleware';
import { ActivityLoggerMiddleware } from './middleware/activity-logger.middleware';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
  ],
  controllers: [
    PaymentController,
    SubscriptionController,
    HealthController,
  ],
  providers: [
    PrismaService,
    PaymentService,
    SubscriptionService,
    AuthMiddleware,
    RateLimitMiddleware,
    ActivityLoggerMiddleware,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    // Apply activity logger to all routes (FIRST - to capture everything)
    consumer
      .apply(ActivityLoggerMiddleware)
      .forRoutes('*');

    // Apply auth middleware to all API routes except health endpoints
    consumer
      .apply(AuthMiddleware)
      .exclude(
        'api/health(.*)',  // Exclude all health endpoints
      )
      .forRoutes('api/*');

    // Apply rate limiting to all routes
    consumer
      .apply(RateLimitMiddleware)
      .forRoutes('*');
  }
}
