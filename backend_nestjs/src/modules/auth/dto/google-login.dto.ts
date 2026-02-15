import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';
import { UserRole } from '@prisma/client';

export class GoogleLoginDto {
  @IsString()
  @IsNotEmpty()
  idToken: string;

  @IsOptional()
  @IsEnum(UserRole)
  userRole?: UserRole;
}
