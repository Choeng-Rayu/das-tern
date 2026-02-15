import { IsNotEmpty, IsString, IsUUID } from 'class-validator';

export class CreateDoctorNoteDto {
  @IsUUID()
  @IsNotEmpty()
  patientId: string;

  @IsString()
  @IsNotEmpty()
  content: string;
}
