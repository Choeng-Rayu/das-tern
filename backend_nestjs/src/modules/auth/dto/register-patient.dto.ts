import { IsString, IsNotEmpty, IsEnum, IsDateString, Matches, Length } from 'class-validator';
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
  @IsNotEmpty()
  idCardNumber: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^\+855\d{8,9}$/, { message: 'Phone number must start with +855' })
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^.{6,}$/, { message: 'Password must be at least 6 characters' })
  password: string;

  @IsString()
  @Length(4, 4)
  @Matches(/^\d{4}$/, { message: 'PIN code must be exactly 4 digits' })
  pinCode: string;
}
