import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { DosesService } from './doses.service';
import { DosesController } from './doses.controller';
import { MissedDoseJob } from './missed-dose.job';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuditModule } from '../audit/audit.module';
import { PrismaService } from '../../database/prisma.service';

@Module({
  imports: [ScheduleModule.forRoot(), NotificationsModule, AuditModule],
  controllers: [DosesController],
  providers: [DosesService, MissedDoseJob, PrismaService],
  exports: [DosesService],
})
export class DosesModule {}
