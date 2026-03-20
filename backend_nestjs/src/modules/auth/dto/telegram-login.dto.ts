import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { UserRole } from '@prisma/client';

export class TelegramLoginDto {
  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @IsNotEmpty()
  codeVerifier: string;

  @IsString()
  @IsNotEmpty()
  redirectUri: string;

  @IsOptional()
  @IsEnum(UserRole)
  userRole?: UserRole;
}
