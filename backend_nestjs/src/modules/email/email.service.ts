import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import * as validator from 'validator';

@Injectable()
export class EmailService {
  private transporter;
  private readonly logger = new Logger(EmailService.name);
  private readonly emailConfigured: boolean;
  private readonly fromEmail: string;
  private readonly fromName: string;

  constructor(private configService: ConfigService) {
    const emailUser = configService.get<string>('GMAIL_USER', '');
    const emailPass = configService.get<string>('GMAIL_APP_PASSWORD', '');
    this.fromEmail = emailUser || 'noreply@dastern.com';
    this.fromName = configService.get<string>('EMAIL_FROM_NAME', 'Das Tern');

    this.emailConfigured = !!emailUser && !!emailPass;

    if (this.emailConfigured) {
      this.transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false,
        auth: {
          user: emailUser,
          pass: emailPass,
        },
      });
      this.logger.log('✅ Gmail SMTP configured — emails will be sent via Gmail');
    } else {
      this.logger.warn(
        '⚠️  Gmail credentials not configured — emails will be logged to console only.',
      );
    }
  }

  private validateAndSanitizeEmail(email: string): string {
    if (!validator.isEmail(email)) {
      throw new BadRequestException('Invalid email address');
    }
    return validator.normalizeEmail(email) || email;
  }

  private async send(to: string, subject: string, html: string): Promise<void> {
    if (!this.emailConfigured) {
      this.logger.warn(`[NO-EMAIL] Would have sent "${subject}" to ${to} — Gmail not configured`);
      console.log(`\n📧 Email Preview:\nTo: ${to}\nSubject: ${subject}\n`);
      return;
    }
    await this.transporter.sendMail({
      from: `"${this.fromName}" <${this.fromEmail}>`,
      to,
      subject,
      html,
    });
  }

  async sendOTP(email: string, otp: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);

    if (!this.emailConfigured) {
      this.logger.log(`[DEV] OTP for ${sanitizedEmail}: ${otp}`);
      console.log(`\n📧 OTP Email to ${sanitizedEmail}:\n🔐 OTP Code: ${otp}\n`);
      return;
    }

    await this.send(
      sanitizedEmail,
      'Your OTP Code - Das Tern',
      `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2D5BFF;">Das Tern - OTP Verification</h2>
          <p>Your verification code is:</p>
          <h1 style="color: #2D5BFF; font-size: 32px; letter-spacing: 5px;">${otp}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p style="color: #666; font-size: 12px;">If you didn't request this code, please ignore this email.</p>
        </div>
      `,
    );
  }

  async sendTestEmail(email: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);

    await this.send(
      sanitizedEmail,
      'Test Email - Das Tern',
      `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2D5BFF;">✅ Test Email Successful!</h1>
          <p>Email configuration is working correctly.</p>
          <p>From: ${this.fromEmail}</p>
          <p>To: ${sanitizedEmail}</p>
        </div>
      `,
    );
  }

  async sendWelcomeEmail(email: string, name: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);
    const sanitizedName = validator.escape(name);

    await this.send(
      sanitizedEmail,
      'Welcome to Das Tern!',
      `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #2D5BFF;">Welcome to Das Tern, ${sanitizedName}! 🎉</h1>
          <p>Thank you for registering with Das Tern - your medication management companion.</p>
          <p>We're here to help you never miss a dose!</p>
          <p>Get started by adding your first medication.</p>
        </div>
      `,
    );
  }

  async sendPasswordResetEmail(email: string, resetLink: string, otp: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);

    await this.send(
      sanitizedEmail,
      'Password Reset - Das Tern',
      `
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
    );
  }
}
