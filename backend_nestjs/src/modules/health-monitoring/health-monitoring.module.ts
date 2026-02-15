import { Module } from '@nestjs/common';
import { HealthMonitoringController } from './health-monitoring.controller';
import { HealthMonitoringService } from './health-monitoring.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [HealthMonitoringController],
  providers: [HealthMonitoringService],
  exports: [HealthMonitoringService],
})
export class HealthMonitoringModule {}
