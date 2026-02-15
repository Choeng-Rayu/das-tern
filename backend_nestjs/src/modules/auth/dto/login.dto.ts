import { IsString, IsNotEmpty, Matches } from 'class-validator';

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+\d{1,4}\d{6,14}$/, { message: 'Phone number must include country code (e.g. +855...)' })
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^.{6,}$/, { message: 'Password must be at least 6 characters' })
  password: string;
}
