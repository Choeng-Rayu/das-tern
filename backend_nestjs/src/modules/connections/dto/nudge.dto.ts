import { IsString, IsUUID, IsOptional } from 'class-validator';

export class SendNudgeDto {
  @IsUUID()
  patientId: string;

  @IsUUID()
  doseId: string;
}

export class NudgeResponseDto {
  @IsUUID()
  caregiverId: string;

  @IsUUID()
  doseId: string;

  @IsString()
  response: string;
}

export class ToggleAlertsDto {
  @IsString()
  enabled: string; // 'true' or 'false'
}

export class UpdateGracePeriodDto {
  gracePeriodMinutes: number;
}
