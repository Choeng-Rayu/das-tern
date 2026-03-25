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
    // Gmail Configuration (Production Priority)
    const gmailUser = configService.get<string>('GMAIL_USER', '');
    const gmailAppPassword = configService.get<string>('GMAIL_APP_PASSWORD', '');
    
    // SendGrid Fallback
    const sendgridApiKey = configService.get<string>('SENDGRID_API_KEY', '');
    
    this.fromEmail = configService.get<string>('SENDGRID_FROM_EMAIL', gmailUser || 'noreply@dastern.com');
    this.fromName = configService.get<string>('SENDGRID_FROM_NAME', 'Das Tern');

    // Prioritize Gmail for production
    if (gmailUser && gmailAppPassword) {
      this.emailConfigured = true;
      this.transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false,
        auth: {
          user: gmailUser,
          pass: gmailAppPassword,
        },
        tls: {
          rejectUnauthorized: true,
        },
      });
      this.logger.log('✅ Gmail SMTP configured — emails will be sent via Gmail');
    } else if (sendgridApiKey) {
      this.emailConfigured = true;
      this.transporter = nodemailer.createTransport({
        host: 'smtp.sendgrid.net',
        port: 587,
        secure: false,
        auth: {
          user: 'apikey',
          pass: sendgridApiKey,
        },
      });
      this.logger.log('✅ SendGrid SMTP configured — emails will be sent via SendGrid');
    } else {
      this.emailConfigured = false;
      this.logger.warn(
        '⚠️  Email credentials not configured — emails will be logged to console only.',
      );
    }
  }

  private validateAndSanitizeEmail(email: string): string {
    if (!validator.isEmail(email)) {
      throw new BadRequestException('Invalid email address');
    }
    return validator.normalizeEmail(email) || email;
  }

  private async send(to: string, subject: string, html: string, text?: string): Promise<void> {
    if (!this.emailConfigured) {
      this.logger.warn(`[NO-EMAIL] Would have sent "${subject}" to ${to} — Email not configured`);
      console.log(`\n📧 Email Preview:\nTo: ${to}\nSubject: ${subject}\n`);
      return;
    }

    if (!this.transporter) {
      this.logger.error('Email transporter not initialized');
      throw new BadRequestException('Email service unavailable');
    }

    try {
      const info = await this.transporter.sendMail({
        from: {
          name: this.fromName,
          address: this.fromEmail,
        },
        to,
        subject,
        text: text || this.htmlToText(html),
        html,
        headers: {
          'X-Mailer': 'Das Tern App',
          'X-Priority': '3',
          'Precedence': 'bulk',
        },
      });
      
      this.logger.log(`✅ Email sent successfully to ${to}`);
      this.logger.debug(`Message ID: ${info.messageId}`);
    } catch (error) {
      this.logger.error(`Failed to send email to ${to}:`, error.message);
      throw new BadRequestException(`Failed to send email: ${error.message}`);
    }
  }

  private htmlToText(html: string): string {
    return html
      .replace(/<[^>]*>/g, '')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .trim();
  }

  async sendOTP(email: string, otp: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);

    if (!this.emailConfigured) {
      this.logger.log(`[DEV] OTP for ${sanitizedEmail}: ${otp}`);
      console.log(`\n📧 OTP Email to ${sanitizedEmail}:\n🔐 OTP Code: ${otp}\n`);
      return;
    }

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 28px;">Das Tern</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0;">Medication Management</p>
        </div>
        <div style="background: #ffffff; padding: 40px 30px; border: 1px solid #e0e0e0; border-top: none;">
          <h2 style="color: #333; margin-top: 0;">Verification Code</h2>
          <p style="color: #666; font-size: 16px; line-height: 1.5;">Use the code below to verify your email address:</p>
          <div style="background: #f8f9fa; border-radius: 8px; padding: 25px; text-align: center; margin: 25px 0;">
            <h1 style="color: #667eea; font-size: 42px; letter-spacing: 8px; margin: 0; font-weight: bold;">${otp}</h1>
          </div>
          <p style="color: #666; font-size: 14px; line-height: 1.5;">This code will expire in <strong>10 minutes</strong>.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
          <p style="color: #999; font-size: 12px; line-height: 1.5;">
            If you didn't request this code, you can safely ignore this email. Your account is secure.
          </p>
        </div>
        <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            © 2026 Das Tern. All rights reserved.<br>
            This is an automated message, please do not reply.
          </p>
        </div>
      </div>
    `;

    const text = `Das Tern - Verification Code\n\nYour verification code is: ${otp}\n\nThis code will expire in 10 minutes.\n\nIf you didn't request this code, you can safely ignore this email.`;

    await this.send(sanitizedEmail, 'Your Verification Code - Das Tern', html, text);
  }

  async sendTestEmail(email: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 28px;">Das Tern</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0;">Medication Management</p>
        </div>
        <div style="background: #ffffff; padding: 40px 30px; border: 1px solid #e0e0e0; border-top: none; text-align: center;">
          <h2 style="color: #333; margin-top: 0;">✅ Test Email Successful!</h2>
          <p style="color: #666; font-size: 16px; line-height: 1.5;">Your email configuration is working correctly.</p>
          <div style="background: #e8f5e9; border-left: 4px solid #4caf50; padding: 15px; margin: 20px 0; text-align: left;">
            <p style="margin: 0; color: #2e7d32; font-size: 14px;">
              <strong>From:</strong> ${this.fromEmail}<br>
              <strong>To:</strong> ${sanitizedEmail}<br>
              <strong>Sent:</strong> ${new Date().toLocaleString()}
            </p>
          </div>
          <p style="color: #666; font-size: 14px; line-height: 1.5;">You're all set to receive important notifications about your medications.</p>
        </div>
        <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            © 2026 Das Tern. All rights reserved.<br>
            This is an automated message, please do not reply.
          </p>
        </div>
      </div>
    `;

    const text = `Das Tern - Test Email\n\nTest email successful!\n\nFrom: ${this.fromEmail}\nTo: ${sanitizedEmail}\nSent: ${new Date().toLocaleString()}\n\nYou're all set to receive important notifications.`;

    await this.send(sanitizedEmail, 'Test Email - Das Tern Configuration', html, text);
  }

  async sendWelcomeEmail(email: string, name: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);
    const sanitizedName = validator.escape(name);

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 28px;">Das Tern</h1>
        </div>
        <div style="background: #ffffff; padding: 40px 30px; border: 1px solid #e0e0e0; border-top: none;">
          <h2 style="color: #333; margin-top: 0;">Welcome to Das Tern, ${sanitizedName}! 🎉</h2>
          <p style="color: #666; font-size: 16px; line-height: 1.5;">
            Thank you for joining Das Tern - your personal medication management companion.
          </p>
          <div style="background: #f3e5f5; border-radius: 8px; padding: 20px; margin: 25px 0;">
            <h3 style="color: #7b1fa2; margin-top: 0;">What's next?</h3>
            <ul style="color: #666; padding-left: 20px; line-height: 1.8;">
              <li>Add your medications</li>
              <li>Set up reminders</li>
              <li>Track your adherence</li>
              <li>Connect with healthcare providers</li>
            </ul>
          </div>
          <p style="color: #666; font-size: 14px; line-height: 1.5;">
            We're here to help you never miss a dose!
          </p>
        </div>
        <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            © 2026 Das Tern. All rights reserved.<br>
            This is an automated message, please do not reply.
          </p>
        </div>
      </div>
    `;

    const text = `Welcome to Das Tern, ${sanitizedName}!\n\nThank you for joining Das Tern - your personal medication management companion.\n\nWhat's next?\n- Add your medications\n- Set up reminders\n- Track your adherence\n- Connect with healthcare providers\n\nWe're here to help you never miss a dose!`;

    await this.send(sanitizedEmail, 'Welcome to Das Tern!', html, text);
  }

  async sendPasswordResetEmail(email: string, resetLink: string, otp: string) {
    const sanitizedEmail = this.validateAndSanitizeEmail(email);

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 28px;">Das Tern</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0;">Password Reset</p>
        </div>
        <div style="background: #ffffff; padding: 40px 30px; border: 1px solid #e0e0e0; border-top: none;">
          <h2 style="color: #333; margin-top: 0;">Reset Your Password</h2>
          <p style="color: #666; font-size: 16px; line-height: 1.5;">We received a request to reset your password. Use the code below or click the button:</p>
          <div style="background: #f8f9fa; border-radius: 8px; padding: 25px; text-align: center; margin: 25px 0;">
            <p style="color: #999; font-size: 12px; margin: 0 0 10px 0;">RESET CODE</p>
            <h1 style="color: #667eea; font-size: 42px; letter-spacing: 8px; margin: 0; font-weight: bold;">${otp}</h1>
          </div>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetLink}" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 40px; text-decoration: none; border-radius: 25px; font-weight: bold; font-size: 16px;">Reset Password</a>
          </div>
          <div style="background: #fff3e0; border-left: 4px solid #ff9800; padding: 15px; margin: 20px 0;">
            <p style="margin: 0; color: #e65100; font-size: 14px;">
              <strong>⚠️ Security:</strong> This link and code will expire in <strong>15 minutes</strong>.
            </p>
          </div>
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
          <p style="color: #999; font-size: 12px; line-height: 1.5;">
            If you didn't request this reset, please ignore this email. Your password will remain unchanged and your account is secure.
          </p>
        </div>
        <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center;">
          <p style="color: #999; font-size: 12px; margin: 0;">
            © 2026 Das Tern. All rights reserved.<br>
            This is an automated message, please do not reply.
          </p>
        </div>
      </div>
    `;

    const text = `Das Tern - Password Reset\n\nWe received a request to reset your password.\n\nYour reset code is: ${otp}\n\nOr use this link: ${resetLink}\n\n⚠️ This link and code will expire in 15 minutes.\n\nIf you didn't request this reset, please ignore this email. Your password will remain unchanged.`;

    await this.send(sanitizedEmail, 'Password Reset - Das Tern', html, text);
  }
}
