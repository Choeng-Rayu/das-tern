import { IsEnum, IsNumber, IsOptional } from 'class-validator';
import { VitalType } from '@prisma/client';

export class UpdateThresholdDto {
  @IsEnum(VitalType)
  vitalType: VitalType;

  @IsOptional()
  @IsNumber()
  minValue?: number;

  @IsOptional()
  @IsNumber()
  maxValue?: number;

  @IsOptional()
  @IsNumber()
  minSecondary?: number;

  @IsOptional()
  @IsNumber()
  maxSecondary?: number;
}
