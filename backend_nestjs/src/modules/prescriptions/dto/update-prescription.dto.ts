import { IsOptional, IsEnum, IsString, IsArray, ValidateNested, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';
import { PrescriptionStatus } from '@prisma/client';
import { MedicationDto } from './create-prescription.dto';

export class UpdatePrescriptionDto {
  @IsOptional()
  @IsEnum(PrescriptionStatus)
  status?: PrescriptionStatus;

  @IsOptional()
  @IsString()
  symptoms?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MedicationDto)
  medications?: MedicationDto[];

  @IsOptional()
  @IsBoolean()
  isUrgent?: boolean;

  @IsOptional()
  @IsString()
  urgentReason?: string;

  @IsOptional()
  @IsString()
  changeReason?: string;
}
