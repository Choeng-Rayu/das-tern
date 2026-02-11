import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { BakongPaymentController } from './bakong-payment.controller';
import { BakongPaymentService } from './bakong-payment.service';
import { DatabaseModule } from '../../database/database.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';

@Module({
    imports: [ConfigModule, DatabaseModule, SubscriptionsModule],
    controllers: [BakongPaymentController],
    providers: [BakongPaymentService],
    exports: [BakongPaymentService],
})
export class BakongPaymentModule { }
