import { IsString, IsNotEmpty, IsOptional, IsNumber, IsBoolean, IsArray } from 'class-validator';

export class CreateMedicineDto {
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
