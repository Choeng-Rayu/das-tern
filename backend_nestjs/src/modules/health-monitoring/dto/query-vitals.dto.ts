import { IsOptional, IsEnum, IsDateString, IsString } from 'class-validator';
import { VitalType } from '@prisma/client';

export class QueryVitalsDto {
  @IsOptional()
  @IsEnum(VitalType)
  vitalType?: VitalType;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsString()
  period?: string; // 'daily', 'weekly', 'monthly'
}
