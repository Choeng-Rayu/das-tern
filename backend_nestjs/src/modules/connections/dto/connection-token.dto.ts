import { IsEnum, IsIn, IsOptional, IsString, Length } from 'class-validator';
import { PermissionLevel } from '@prisma/client';

export class GenerateTokenDto {
  @IsEnum(PermissionLevel)
  permissionLevel: PermissionLevel;

  /**
   * Target role for the connection token.
   * - 'FAMILY_MEMBER': Token for family member connections (default)
   * - 'DOCTOR': Token for doctor connections
   */
  @IsOptional()
  @IsString()
  @IsIn(['FAMILY_MEMBER', 'DOCTOR'])
  targetRole?: string;
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

/**
 * DTO for doctor consuming a patient-generated connection token.
 * Used in the new doctor connection flow where:
 * 1. Patient generates token/QR
 * 2. Doctor scans and consumes it
 * 3. Patient approves the connection
 */
export class DoctorConsumeTokenDto {
  @IsString()
  @Length(1, 20)
  token: string;
}
