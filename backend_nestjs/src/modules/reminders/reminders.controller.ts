import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RemindersService } from './reminders.service';
import { ReminderGeneratorService } from './reminder-generator.service';
import { SnoozeHandlerService } from './snooze-handler.service';
import { ReminderConfigService } from './reminder-config.service';
import {
  SnoozeReminderDto,
  UpdateReminderSettingsDto,
  UpdateMedicationReminderTimeDto,
  ToggleMedicationRemindersDto,
  GetReminderHistoryDto,
} from './dto';

@Controller('reminders')
@UseGuards(AuthGuard('jwt'))
export class RemindersController {
  constructor(
    private remindersService: RemindersService,
    private reminderGenerator: ReminderGeneratorService,
    private snoozeHandler: SnoozeHandlerService,
    private reminderConfig: ReminderConfigService,
  ) {}

  @Post('generate/:prescriptionId')
  async generate(
    @Param('prescriptionId') prescriptionId: string,
    @CurrentUser() user: any,
  ) {
    return this.reminderGenerator.generateRemindersForPrescription(prescriptionId);
  }

  @Get('upcoming')
  async getUpcoming(
    @CurrentUser() user: any,
    @Query('days') days?: string,
    @Query('limit') limit?: string,
  ) {
    return this.remindersService.getUpcomingReminders(
      user.id,
      days ? parseInt(days, 10) : 7,
      limit ? parseInt(limit, 10) : 50,
    );
  }

  @Post(':reminderId/snooze')
  async snooze(
    @Param('reminderId') reminderId: string,
    @Body() dto: SnoozeReminderDto,
    @CurrentUser() user: any,
  ) {
    return this.snoozeHandler.snoozeReminder(reminderId, user.id, dto.durationMinutes);
  }

  @Get('history')
  async getHistory(
    @CurrentUser() user: any,
    @Query() query: GetReminderHistoryDto,
  ) {
    return this.remindersService.getReminderHistory(user.id, query);
  }

  @Patch('settings')
  async updateSettings(
    @Body() dto: UpdateReminderSettingsDto,
    @CurrentUser() user: any,
  ) {
    if (dto.gracePeriodMinutes !== undefined) {
      await this.reminderConfig.updateGracePeriod(user.id, dto.gracePeriodMinutes);
    }
    if (dto.repeatRemindersEnabled !== undefined || dto.repeatIntervalMinutes !== undefined) {
      await this.reminderConfig.updateRepeatFrequency(
        user.id,
        dto.repeatRemindersEnabled ?? true,
        dto.repeatIntervalMinutes,
      );
    }
    return this.reminderConfig.getReminderSettings(user.id);
  }

  @Patch('medications/:medicationId/time')
  async updateMedicationTime(
    @Param('medicationId') medicationId: string,
    @Body() dto: UpdateMedicationReminderTimeDto,
    @CurrentUser() user: any,
  ) {
    return this.reminderConfig.updateReminderTime(user.id, medicationId, dto.timePeriod, dto.newTime);
  }

  @Patch('medications/:medicationId/toggle')
  async toggleMedicationReminders(
    @Param('medicationId') medicationId: string,
    @Body() dto: ToggleMedicationRemindersDto,
    @CurrentUser() user: any,
  ) {
    return this.reminderConfig.toggleReminders(user.id, medicationId, dto.enabled);
  }

  @Get('settings')
  async getSettings(@CurrentUser() user: any) {
    return this.reminderConfig.getReminderSettings(user.id);
  }
}
