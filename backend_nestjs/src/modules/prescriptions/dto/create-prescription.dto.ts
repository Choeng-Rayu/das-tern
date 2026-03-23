import { IsString, IsNotEmpty, IsEnum, IsInt, IsArray, ValidateNested, IsOptional, IsBoolean, IsDateString, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';
import { Gender, MedicineType, MedicineUnit } from '@prisma/client';

export class DosageDto {
  @IsString()
  @IsNotEmpty()
  amount: string;

  @IsBoolean()
  beforeMeal: boolean;
}

export class MedicationDto {
  @IsInt()
  rowNumber: number;

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

  @IsOptional()
  @IsNumber()
  dosageAmount?: number;

  @IsString()
  @IsNotEmpty()
  dosageUnit: string;

  @IsString()
  @IsNotEmpty()
  form: string;

  @IsOptional()
  @IsArray()
  scheduleTimes?: { timePeriod: string; time: string }[];

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  additionalNote?: string;

  @IsOptional()
  @IsString()
  frequency?: string;

  @IsOptional()
  @IsInt()
  durationDays?: number;

  @IsOptional()
  @IsBoolean()
  isPRN?: boolean;

  @IsOptional()
  @IsBoolean()
  beforeMeal?: boolean;

  @IsOptional()
  @ValidateNested()
  @Type(() => DosageDto)
  morningDosage?: DosageDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => DosageDto)
  afternoonDosage?: DosageDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => DosageDto)
  eveningDosage?: DosageDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => DosageDto)
  nightDosage?: DosageDto;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class CreatePrescriptionDto {
  @IsString()
  @IsNotEmpty()
  patientId: string;

  @IsString()
  @IsNotEmpty()
  patientName: string;

  @IsEnum(Gender)
  patientGender: Gender;

  @IsInt()
  patientAge: number;

  @IsString()
  @IsNotEmpty()
  symptoms: string;

  @IsOptional()
  @IsString()
  diagnosis?: string;

  @IsOptional()
  @IsString()
  clinicalNote?: string;

  @IsOptional()
  @IsDateString()
  followUpDate?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MedicationDto)
  medications: MedicationDto[];

  @IsOptional()
  @IsBoolean()
  isUrgent?: boolean;

  @IsOptional()
  @IsString()
  urgentReason?: string;
}
