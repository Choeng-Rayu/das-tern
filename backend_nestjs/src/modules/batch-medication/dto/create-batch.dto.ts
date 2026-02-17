import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsArray,
  IsEnum,
  IsNumber,
  IsBoolean,
  ValidateNested,
  Matches,
} from 'class-validator';
import { Type } from 'class-transformer';
import { MedicineType, MedicineUnit } from '@prisma/client';

export class BatchMedicationItemDto {
  @IsString()
  @IsNotEmpty()
  medicineName: string;

  @IsString()
  @IsOptional()
  medicineNameKhmer?: string;

  @IsEnum(MedicineType)
  @IsOptional()
  medicineType?: MedicineType;

  @IsEnum(MedicineUnit)
  @IsOptional()
  unit?: MedicineUnit;

  @IsNumber()
  @IsOptional()
  dosageAmount?: number;

  @IsString()
  @IsOptional()
  frequency?: string;

  @IsNumber()
  @IsOptional()
  durationDays?: number;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  additionalNote?: string;

  @IsBoolean()
  @IsOptional()
  beforeMeal?: boolean;

  @IsBoolean()
  @IsOptional()
  isPRN?: boolean;
}

export class CreateBatchDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'scheduledTime must be in HH:mm format',
  })
  scheduledTime: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BatchMedicationItemDto)
  medicines: BatchMedicationItemDto[];
}
