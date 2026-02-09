import { IsOptional, IsEnum, IsString } from 'class-validator';
import { Language, Theme } from '@prisma/client';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsString()
  email?: string;

  @IsOptional()
  @IsEnum(Language)
  language?: Language;

  @IsOptional()
  @IsEnum(Theme)
  theme?: Theme;

  @IsOptional()
  @IsString()
  hospitalClinic?: string;

  @IsOptional()
  @IsString()
  specialty?: string;
}
