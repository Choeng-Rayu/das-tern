import { IsIn, IsNotEmpty, IsNumber } from 'class-validator';

export class SnoozeReminderDto {
  @IsNotEmpty()
  @IsNumber()
  @IsIn([5, 10, 15])
  durationMinutes: number;
}
