import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import * as validator from 'validator';

@Injectable()
export class EmailService {
  private transporter;

  constructor(private configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth: {
        user: this.configService.get('SENDGRID_FROM_EMAIL'),
        pass: this.configService.get('SENDGRID_API_KEY'),
      },
    });
  }

  private validateAndSanitizeEmail(email: string): string {
    if (!validator.isEmail(email)) {
      throw new BadRequestException('Invalid email address');
    }
    return validator.normalizeEmail(email) || email;
  }

  async sendOTP(email: string, otp: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);
    
    await this.transporter.sendMail({
      from: `"Das Tern" <${this.configService.get('SENDGRID_FROM_EMAIL')}>`,
      to: sanitizedEmail,
      subject: 'Your OTP Code - Das Tern',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2D5BFF;">Das Tern - OTP Verification</h2>
          <p>Your verification code is:</p>
          <h1 style="color: #2D5BFF; font-size: 32px; letter-spacing: 5px;">${otp}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p style="color: #666; font-size: 12px;">If you didn't request this code, please ignore this email.</p>
        </div>
      `,
    });
  }

  async sendTestEmail(email: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);
    
    await this.transporter.sendMail({
      from: `"Das Tern" <${this.configService.get('SENDGRID_FROM_EMAIL')}>`,
      to: sanitizedEmail,
      subject: 'Test Email - Das Tern',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2D5BFF;">✅ Test Email Successful!</h1>
          <p>Email configuration is working correctly.</p>
          <p>From: ${this.configService.get('SENDGRID_FROM_EMAIL')}</p>
          <p>To: ${sanitizedEmail}</p>
        </div>
      `,
    });
  }

  async sendWelcomeEmail(email: string, name: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);
    const sanitizedName = validator.escape(name);
    
    await this.transporter.sendMail({
      from: `"Das Tern" <${this.configService.get('SENDGRID_FROM_EMAIL')}>`,
      to: sanitizedEmail,
      subject: 'Welcome to Das Tern!',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2D5BFF;">Welcome to Das Tern, ${sanitizedName}! 🎉</h1>
          <p>Thank you for registering with Das Tern - your medication management companion.</p>
          <p>We're here to help you never miss a dose!</p>
          <p>Get started by adding your first medication.</p>
        </div>
      `,
    });
  }

  async sendPasswordResetEmail(email: string, resetLink: string, otp: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);

    await this.transporter.sendMail({
      from: `"Das Tern" <${this.configService.get('SENDGRID_FROM_EMAIL')}>`,
      to: sanitizedEmail,
      subject: 'Password Reset - Das Tern',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2D5BFF;">Das Tern - Password Reset</h2>
          <p>We received a request to reset your password.</p>
          <p>Your reset code is:</p>
          <h1 style="color: #2D5BFF; font-size: 32px; letter-spacing: 5px;">${otp}</h1>
          <p>Or click the link below to reset your password:</p>
          <a href="${resetLink}" style="display: inline-block; background-color: #2D5BFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 16px 0;">Reset Password</a>
          <p>This link and code will expire in 15 minutes.</p>
          <p style="color: #666; font-size: 12px;">If you didn't request this, please ignore this email. Your password will remain unchanged.</p>
        </div>
      `,
    });
  }
}
