import { IsUUID, IsEnum } from 'class-validator';
import { UserRole } from '@prisma/client';

export class CreateConnectionDto {
  @IsUUID()
  targetUserId: string;

  @IsEnum(UserRole)
  targetRole: UserRole;
}
