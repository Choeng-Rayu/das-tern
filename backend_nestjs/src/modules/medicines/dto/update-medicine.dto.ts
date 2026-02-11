import { IsString, IsNotEmpty, IsOptional, IsNumber, IsBoolean, IsArray } from 'class-validator';

export class UpdateMedicineDto {
  @IsOptional()
  @IsString()
  medicineName?: string;

  @IsOptional()
  @IsString()
  medicineNameKhmer?: string;

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
