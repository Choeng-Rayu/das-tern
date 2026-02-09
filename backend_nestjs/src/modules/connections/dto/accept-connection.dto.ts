import { IsOptional, IsEnum } from 'class-validator';
import { PermissionLevel } from '@prisma/client';

export class AcceptConnectionDto {
  @IsOptional()
  @IsEnum(PermissionLevel)
  permissionLevel?: PermissionLevel;
}
