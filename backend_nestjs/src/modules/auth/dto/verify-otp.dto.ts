import { IsString, IsNotEmpty, Matches, Length } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  identifier: string;

  @IsString()
  @Length(4, 4)
  @Matches(/^\d{4}$/, { message: 'OTP must be exactly 4 digits' })
  otp: string;
}
