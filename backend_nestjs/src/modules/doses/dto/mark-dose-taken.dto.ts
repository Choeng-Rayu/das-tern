import { IsOptional, IsDateString, IsBoolean, IsUUID } from 'class-validator';

export class MarkDoseTakenDto {
  @IsOptional()
  @IsDateString()
  takenAt?: string;

  @IsOptional()
  @IsBoolean()
  offline?: boolean;

  @IsOptional()
  @IsUUID()
  reminderId?: string;
}
