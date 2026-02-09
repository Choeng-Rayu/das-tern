import { IsString, IsNotEmpty } from 'class-validator';

export class SkipDoseDto {
  @IsString()
  @IsNotEmpty()
  reason: string;
}
