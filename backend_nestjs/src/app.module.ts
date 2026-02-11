import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { CacheModule } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-redis-store';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ConnectionsModule } from './modules/connections/connections.module';
import { PrescriptionsModule } from './modules/prescriptions/prescriptions.module';
import { DosesModule } from './modules/doses/doses.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AuditModule } from './modules/audit/audit.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { EmailModule } from './modules/email/email.module';
import { DoctorDashboardModule } from './modules/doctor-dashboard/doctor-dashboard.module';
import { MedicinesModule } from './modules/medicines/medicines.module';
import { AdherenceModule } from './modules/adherence/adherence.module';
import { BakongPaymentModule } from './modules/bakong-payment/bakong-payment.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 100,
    }]),
    CacheModule.register({
      isGlobal: true,
      store: redisStore as any,
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || undefined,
      ttl: 300,
    }),
    DatabaseModule,
    AuthModule,
    UsersModule,
    ConnectionsModule,
    PrescriptionsModule,
    DosesModule,
    NotificationsModule,
    AuditModule,
    SubscriptionsModule,
    EmailModule,
    DoctorDashboardModule,
    MedicinesModule,
    AdherenceModule,
    BakongPaymentModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule { }
