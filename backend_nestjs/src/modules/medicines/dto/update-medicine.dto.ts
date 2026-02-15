import { IsString, IsOptional, IsNumber, IsBoolean, IsArray, IsEnum } from 'class-validator';
import { MedicineType, MedicineUnit } from '@prisma/client';

export class UpdateMedicineDto {
  @IsOptional()
  @IsString()
  medicineName?: string;

  @IsOptional()
  @IsString()
  medicineNameKhmer?: string;

  @IsOptional()
  @IsEnum(MedicineType)
  medicineType?: MedicineType;

  @IsOptional()
  @IsEnum(MedicineUnit)
  unit?: MedicineUnit;

  @IsOptional()
  @IsNumber()
  dosageAmount?: number;

  @IsOptional()
  @IsString()
  dosageUnit?: string;

  @IsOptional()
  @IsString()
  form?: string;

  @IsOptional()
  @IsString()
  frequency?: string;

  @IsOptional()
  @IsArray()
  scheduleTimes?: { timePeriod: string; time: string }[];

  @IsOptional()
  @IsNumber()
  durationDays?: number;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  additionalNote?: string;

  @IsOptional()
  @IsString()
  instructions?: string;

  @IsOptional()
  @IsBoolean()
  beforeMeal?: boolean;

  @IsOptional()
  @IsBoolean()
  isPRN?: boolean;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}
