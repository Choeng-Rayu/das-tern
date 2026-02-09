import { IsString, IsNotEmpty, Matches } from 'class-validator';

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+855\d{8,9}$/, { message: 'Phone number must start with +855' })
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^.{6,}$/, { message: 'Password must be at least 6 characters' })
  password: string;
}
