import { IsNotEmpty, IsString } from 'class-validator';

export class UpdateDoctorNoteDto {
  @IsString()
  @IsNotEmpty()
  content: string;
}
