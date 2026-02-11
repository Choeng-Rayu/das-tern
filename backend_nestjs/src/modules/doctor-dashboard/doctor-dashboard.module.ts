import { Module } from '@nestjs/common';
import { DoctorDashboardController } from './doctor-dashboard.controller';
import { DoctorDashboardService } from './doctor-dashboard.service';
import { AdherenceService } from './adherence.service';
import { DoctorNotesService } from './doctor-notes.service';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [AuditModule, NotificationsModule],
  controllers: [DoctorDashboardController],
  providers: [DoctorDashboardService, AdherenceService, DoctorNotesService],
  exports: [DoctorDashboardService, AdherenceService, DoctorNotesService],
})
export class DoctorDashboardModule {}
