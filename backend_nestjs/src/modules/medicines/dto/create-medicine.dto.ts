import { IsString, IsNotEmpty, IsOptional, IsNumber, IsBoolean, IsArray, IsEnum } from 'class-validator';
import { MedicineType, MedicineUnit } from '@prisma/client';

export class CreateMedicineDto {
  @IsString()
  @IsNotEmpty()
  medicineName: string;

  @IsOptional()
  @IsString()
  medicineNameKhmer?: string;

  @IsOptional()
  @IsEnum(MedicineType)
  medicineType?: MedicineType;

  @IsOptional()
  @IsEnum(MedicineUnit)
  unit?: MedicineUnit;

  @IsNumber()
  dosageAmount: number;

  @IsString()
  @IsNotEmpty()
  dosageUnit: string;

  @IsString()
  @IsNotEmpty()
  form: string;

  @IsString()
  @IsNotEmpty()
  frequency: string;

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
