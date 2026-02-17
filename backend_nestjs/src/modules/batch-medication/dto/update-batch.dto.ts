import { IsString, IsOptional, IsBoolean, Matches } from 'class-validator';

export class UpdateBatchDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'scheduledTime must be in HH:mm format',
  })
  scheduledTime?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
