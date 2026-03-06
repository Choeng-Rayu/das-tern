import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { RemindersController } from './reminders.controller';
import { RemindersService } from './reminders.service';
import { ReminderGeneratorService } from './reminder-generator.service';
import { ReminderSchedulerJob } from './reminder-scheduler.job';
import { SnoozeHandlerService } from './snooze-handler.service';
import { ReminderConfigService } from './reminder-config.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [ScheduleModule.forRoot(), NotificationsModule, AuditModule],
  controllers: [RemindersController],
  providers: [
    RemindersService,
    ReminderGeneratorService,
    ReminderSchedulerJob,
    SnoozeHandlerService,
    ReminderConfigService,
  ],
  exports: [RemindersService, ReminderGeneratorService],
})
export class RemindersModule {}
