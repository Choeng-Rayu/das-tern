import { IsOptional, IsDateString, IsBoolean } from 'class-validator';

export class MarkDoseTakenDto {
  @IsOptional()
  @IsDateString()
  takenAt?: string;

  @IsOptional()
  @IsBoolean()
  offline?: boolean;
}
