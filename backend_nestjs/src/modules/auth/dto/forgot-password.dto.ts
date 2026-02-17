import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class ForgotPasswordDto {
  @IsString()
  @IsNotEmpty()
  identifier: string; // phone number or email
}
