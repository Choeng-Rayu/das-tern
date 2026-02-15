import { IsEnum, IsNumber, IsOptional, IsString, IsDateString } from 'class-validator';
import { VitalType } from '@prisma/client';

export class RecordVitalDto {
  @IsEnum(VitalType)
  vitalType: VitalType;

  @IsNumber()
  value: number;

  @IsOptional()
  @IsNumber()
  valueSecondary?: number;

  @IsString()
  unit: string;

  @IsOptional()
  @IsDateString()
  measuredAt?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  source?: string;
}
