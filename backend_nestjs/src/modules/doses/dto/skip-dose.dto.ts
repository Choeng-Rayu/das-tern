import { IsString, IsOptional } from 'class-validator';

export class SkipDoseDto {
  @IsOptional()
  @IsString()
  reason?: string;
}
