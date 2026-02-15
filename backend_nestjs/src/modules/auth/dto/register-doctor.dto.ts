import { IsString, IsNotEmpty, IsEnum, Matches } from 'class-validator';

enum DoctorSpecialty {
  GENERAL_PRACTICE = 'GENERAL_PRACTICE',
  INTERNAL_MEDICINE = 'INTERNAL_MEDICINE',
  CARDIOLOGY = 'CARDIOLOGY',
  ENDOCRINOLOGY = 'ENDOCRINOLOGY',
  OTHER = 'OTHER',
}

export class RegisterDoctorDto {
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^\+\d{1,4}\d{6,14}$/, { message: 'Phone number must include country code (e.g. +855...)' })
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  hospitalClinic: string;

  @IsEnum(DoctorSpecialty)
  specialty: DoctorSpecialty;

  @IsString()
  @IsNotEmpty()
  licenseNumber: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^.{6,}$/, { message: 'Password must be at least 6 characters' })
  password: string;

  licensePhotoUrl?: string; // Uploaded separately
}
