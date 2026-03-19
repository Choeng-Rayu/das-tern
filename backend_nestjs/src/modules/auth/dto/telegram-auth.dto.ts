import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, Matches, MaxLength, Min } from 'class-validator';

export class TelegramAuthDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  id: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(128)
  first_name: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  last_name?: string;

  @IsOptional()
  @IsString()
  @Matches(/^[a-zA-Z0-9_]{5,32}$/, { message: 'username must be 5-32 characters and contain only letters, numbers, or underscore' })
  username?: string;

  @IsOptional()
  @IsString()
  @Matches(/^https?:\/\/[^\s]+$/, { message: 'photo_url must be a valid http(s) URL' })
  @MaxLength(2048)
  photo_url?: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  auth_date: number;

  @IsString()
  @Matches(/^[a-f0-9]{64}$/, { message: 'hash must be a 64-character lowercase hexadecimal string' })
  hash: string;
}
