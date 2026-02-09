import { IsString, IsNotEmpty, IsEnum, IsInt, IsArray, ValidateNested, IsOptional, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';
import { Gender } from '@prisma/client';

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
  @ValidateNested()
  @Type(() => DosageDto)
  morningDosage?: DosageDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => DosageDto)
  daytimeDosage?: DosageDto;

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
