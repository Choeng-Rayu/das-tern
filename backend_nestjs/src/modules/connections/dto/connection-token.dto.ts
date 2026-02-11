import { IsEnum, IsString, Length } from 'class-validator';
import { PermissionLevel } from '@prisma/client';

export class GenerateTokenDto {
  @IsEnum(PermissionLevel)
  permissionLevel: PermissionLevel;
}

export class ValidateTokenDto {
  @IsString()
  @Length(1, 20)
  token: string;
}

export class ConsumeTokenDto {
  @IsString()
  @Length(1, 20)
  token: string;
}
