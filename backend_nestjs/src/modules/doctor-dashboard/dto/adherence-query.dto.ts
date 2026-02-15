import { IsOptional, IsString } from 'class-validator';

export class AdherenceQueryDto {
  @IsOptional()
  @IsString()
  startDate?: string;

  @IsOptional()
  @IsString()
  endDate?: string;
}
