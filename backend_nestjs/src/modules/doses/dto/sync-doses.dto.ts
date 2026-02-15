import { IsArray, ValidateNested, IsString, IsDateString, IsOptional, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';

export class OfflineDoseEventDto {
  @IsString()
  localId: string;

  @IsString()
  doseId: string;

  @IsString()
  status: string; // 'TAKEN' | 'SKIPPED'

  @IsDateString()
  takenAt: string;

  @IsOptional()
  @IsString()
  skipReason?: string;

  @IsDateString()
  deviceTimestamp: string;
}

export class SyncDosesDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OfflineDoseEventDto)
  events: OfflineDoseEventDto[];
}
