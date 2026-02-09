import { IsString, IsNotEmpty, Matches, Length } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+855\d{8,9}$/, { message: 'Phone number must start with +855' })
  phoneNumber: string;

  @IsString()
  @Length(4, 4)
  @Matches(/^\d{4}$/, { message: 'OTP must be exactly 4 digits' })
  otp: string;
}
