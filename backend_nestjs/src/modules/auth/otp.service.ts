import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface OtpData {
  otp: string;
  expiresAt: number;
  attempts: number;
  lastSentAt: number;
}

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  private otpStore = new Map<string, OtpData>();
  private readonly OTP_EXPIRY = 5 * 60 * 1000; // 5 minutes
  private readonly RESEND_COOLDOWN = 60 * 1000; // 60 seconds
  private readonly MAX_ATTEMPTS = 5;

  constructor(private configService: ConfigService) {}

  generateOtp(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  async sendOtp(phoneNumber: string): Promise<{ expiresIn: number }> {
    const existing = this.otpStore.get(phoneNumber);
    const now = Date.now();

    if (existing && now - existing.lastSentAt < this.RESEND_COOLDOWN) {
      throw new BadRequestException(
        `Please wait ${Math.ceil((this.RESEND_COOLDOWN - (now - existing.lastSentAt)) / 1000)} seconds before requesting a new OTP`,
      );
    }

    const otp = this.generateOtp();
    const expiresAt = now + this.OTP_EXPIRY;

    this.otpStore.set(phoneNumber, {
      otp,
      expiresAt,
      attempts: 0,
      lastSentAt: now,
    });

    // TODO: Integrate with SMS provider (Twilio/AWS SNS)
    this.logger.log(`OTP for ${phoneNumber}: ${otp} (expires in 5 minutes)`);
    
    // In development, log OTP. In production, send via SMS
    if (this.configService.get('NODE_ENV') === 'development') {
      console.log(`\n🔐 OTP for ${phoneNumber}: ${otp}\n`);
    }

    return { expiresIn: this.OTP_EXPIRY / 1000 };
  }

  async verifyOtp(phoneNumber: string, otp: string): Promise<boolean> {
    const data = this.otpStore.get(phoneNumber);
    const now = Date.now();

    if (!data) {
      throw new BadRequestException('No OTP found. Please request a new one.');
    }

    if (now > data.expiresAt) {
      this.otpStore.delete(phoneNumber);
      throw new BadRequestException('OTP has expired. Please request a new one.');
    }

    if (data.attempts >= this.MAX_ATTEMPTS) {
      this.otpStore.delete(phoneNumber);
      throw new BadRequestException('Too many failed attempts. Please request a new OTP.');
    }

    data.attempts++;

    if (data.otp !== otp) {
      this.otpStore.set(phoneNumber, data);
      throw new BadRequestException(
        `Invalid OTP. ${this.MAX_ATTEMPTS - data.attempts} attempts remaining.`,
      );
    }

    this.otpStore.delete(phoneNumber);
    return true;
  }

  clearOtp(phoneNumber: string): void {
    this.otpStore.delete(phoneNumber);
  }
}
