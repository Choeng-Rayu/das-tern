import { IsString, IsOptional } from 'class-validator';

export class TriggerEmergencyDto {
  @IsString()
  message: string;

  @IsOptional()
  @IsString()
  location?: string;
}
