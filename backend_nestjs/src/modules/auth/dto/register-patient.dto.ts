import { IsString, IsNotEmpty, IsEnum, IsDateString, Matches, IsOptional, IsEmail, MinLength } from 'class-validator';
import { Gender } from '@prisma/client';

export class RegisterPatientDto {
  @IsString()
  @IsNotEmpty()
  lastName: string;

  @IsString()
  @IsNotEmpty()
  firstName: string;

  @IsEnum(Gender)
  gender: Gender;

  @IsDateString()
  dateOfBirth: string;

  @IsString()
  @IsOptional()
  idCardNumber?: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsOptional()
  @Matches(/^\+\d{1,4}\d{6,14}$/, { message: 'Phone number must include country code (e.g. +855...)' })
  phoneNumber?: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'Password must be at least 6 characters' })
  password: string;
}
