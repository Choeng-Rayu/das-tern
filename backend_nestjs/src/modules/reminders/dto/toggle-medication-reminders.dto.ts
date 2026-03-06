import { IsBoolean, IsNotEmpty } from 'class-validator';

export class ToggleMedicationRemindersDto {
  @IsNotEmpty()
  @IsBoolean()
  enabled: boolean;
}
