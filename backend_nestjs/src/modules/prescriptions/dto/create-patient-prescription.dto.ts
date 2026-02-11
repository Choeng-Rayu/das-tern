import { IsString, IsNotEmpty, IsOptional, IsDateString, IsArray, ValidateNested, IsEnum, IsNumber, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

export class PatientMedicationDto {
  @IsString()
  @IsNotEmpty()
  medicineName: string;

  @IsOptional()
  @IsString()
  medicineNameKhmer?: string;

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
  duration?: { type: string; value?: number | string };

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

export class CreatePatientPrescriptionDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsOptional()
  @IsString()
  doctorName?: string;

  @IsDateString()
  startDate: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsString()
  diagnosis?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PatientMedicationDto)
  medicines: PatientMedicationDto[];
}
