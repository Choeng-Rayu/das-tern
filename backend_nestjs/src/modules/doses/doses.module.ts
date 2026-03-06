import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { DosesService } from './doses.service';
import { DosesController } from './doses.controller';
import { MissedDoseJob } from './missed-dose.job';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuditModule } from '../audit/audit.module';
import { AdherenceModule } from '../adherence/adherence.module';

@Module({
  imports: [ScheduleModule.forRoot(), NotificationsModule, AuditModule, AdherenceModule],
  controllers: [DosesController],
  providers: [DosesService, MissedDoseJob],
  exports: [DosesService],
})
export class DosesModule {}
