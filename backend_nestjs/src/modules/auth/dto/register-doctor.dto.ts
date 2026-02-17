import { IsString, IsNotEmpty, IsEnum, Matches, IsOptional, IsEmail, MinLength } from 'class-validator';

export enum DoctorSpecialty {
  GENERAL_PRACTICE = 'GENERAL_PRACTICE',
  INTERNAL_MEDICINE = 'INTERNAL_MEDICINE',
  CARDIOLOGY = 'CARDIOLOGY',
  ENDOCRINOLOGY = 'ENDOCRINOLOGY',
  DERMATOLOGY = 'DERMATOLOGY',
  PEDIATRICS = 'PEDIATRICS',
  PSYCHIATRY = 'PSYCHIATRY',
  SURGERY = 'SURGERY',
  NEUROLOGY = 'NEUROLOGY',
  OPHTHALMOLOGY = 'OPHTHALMOLOGY',
  OTHER = 'OTHER',
}

export class RegisterDoctorDto {
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsOptional()
  @Matches(/^\+\d{1,4}\d{6,14}$/, { message: 'Phone number must include country code (e.g. +855...)' })
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  hospitalClinic?: string;

  @IsEnum(DoctorSpecialty)
  @IsOptional()
  specialty?: DoctorSpecialty;

  @IsString()
  @IsOptional()
  licenseNumber?: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'Password must be at least 6 characters' })
  password: string;

  @IsString()
  @IsOptional()
  licensePhotoUrl?: string;
}
