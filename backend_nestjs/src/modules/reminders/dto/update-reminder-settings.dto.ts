import { IsOptional, IsBoolean, IsInt, IsIn, Min, Max } from 'class-validator';

export class UpdateReminderSettingsDto {
  @IsOptional()
  @IsInt()
  @IsIn([10, 20, 30, 60])
  gracePeriodMinutes?: number;

  @IsOptional()
  @IsBoolean()
  repeatRemindersEnabled?: boolean;

  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(30)
  repeatIntervalMinutes?: number;
}
