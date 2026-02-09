import { IsString, IsNotEmpty, Matches } from 'class-validator';

export class SendOtpDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+855\d{8,9}$/, { message: 'Phone number must start with +855' })
  phoneNumber: string;
}
