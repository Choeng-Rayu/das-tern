import { IsEnum, IsNotEmpty, Matches } from 'class-validator';

export enum TimePeriodEnum {
  MORNING = 'MORNING',
  DAYTIME = 'DAYTIME',
  NIGHT = 'NIGHT',
}

export class UpdateMedicationReminderTimeDto {
  @IsNotEmpty()
  @IsEnum(TimePeriodEnum)
  timePeriod: TimePeriodEnum;

  @IsNotEmpty()
  @Matches(/^\d{2}:\d{2}$/, { message: 'Time must be in HH:mm format' })
  newTime: string;
}
