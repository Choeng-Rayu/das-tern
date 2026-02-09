import { IsEmail, IsNotEmpty } from 'class-validator';

export class SendEmailDto {
  @IsEmail({}, { message: 'Invalid email address' })
  @IsNotEmpty({ message: 'Email is required' })
  email: string;
}

export class SendWelcomeEmailDto {
  @IsEmail({}, { message: 'Invalid email address' })
  @IsNotEmpty({ message: 'Email is required' })
  email: string;

  @IsNotEmpty({ message: 'Name is required' })
  name: string;
}
