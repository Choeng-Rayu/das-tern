import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, createHmac, timingSafeEqual } from 'crypto';

@Injectable()
export class TelegramHashVerifier {
  private readonly logger = new Logger(TelegramHashVerifier.name);
  private static readonly TELEGRAM_HASH_HEX_LENGTH = 64;
  private static readonly AUTH_MAX_AGE_SECONDS = 24 * 60 * 60;

  constructor(private readonly configService: ConfigService) {}

  verifyHash(data: Record<string, unknown> & { hash: string }): boolean {
    const providedHash = data.hash;

    if (
      typeof providedHash !== 'string' ||
      providedHash.length !== TelegramHashVerifier.TELEGRAM_HASH_HEX_LENGTH ||
      !/^[a-fA-F0-9]+$/.test(providedHash)
    ) {
      this.logger.warn('Telegram hash verification failed: invalid hash format or length.');
      return false;
    }

    const authDate = this.extractAuthDate(data.auth_date);
    if (authDate === null || !this.validateAuthDate(authDate)) {
      this.logger.warn('Telegram hash verification failed: invalid auth_date.');
      return false;
    }

    const botToken =
      this.configService.get<string>('TELEGRAM_BOT_TOKEN')?.trim() ||
      this.configService.get<string>('TELEGRAM_BOT_API_KEY')?.trim() ||
      '';

    if (!botToken) {
      this.logger.warn('Telegram hash verification failed: bot token is not configured.');
      return false;
    }

    const { hash: _hash, ...payload } = data;
    const dataCheckString = this.createDataCheckString(payload);
    const computedHash = this.computeHash(dataCheckString, botToken);

    const providedHashBuffer = Buffer.from(providedHash.toLowerCase(), 'hex');
    const computedHashBuffer = Buffer.from(computedHash, 'hex');

    if (providedHashBuffer.length !== computedHashBuffer.length) {
      this.logger.warn('Telegram hash verification failed: hash length mismatch.');
      return false;
    }

    const isValid = timingSafeEqual(providedHashBuffer, computedHashBuffer);
    if (!isValid) {
      this.logger.warn('Telegram hash verification failed: signature mismatch.');
    }

    return isValid;
  }

  validateAuthDate(authDate: number): boolean {
    if (!Number.isFinite(authDate) || authDate <= 0) {
      return false;
    }

    const nowInSeconds = Math.floor(Date.now() / 1000);
    if (authDate > nowInSeconds) {
      return false;
    }

    return nowInSeconds - authDate <= TelegramHashVerifier.AUTH_MAX_AGE_SECONDS;
  }

  private createDataCheckString(data: Record<string, unknown>): string {
    const entries = Object.entries(data)
      .filter(([, value]) => value !== undefined && value !== null)
      .sort(([keyA], [keyB]) => keyA.localeCompare(keyB))
      .map(([key, value]) => `${key}=${String(value)}`);

    return entries.join('\n');
  }

  private computeHash(dataCheckString: string, botToken: string): string {
    const secretKey = createHash('sha256').update(botToken).digest();

    return createHmac('sha256', secretKey).update(dataCheckString).digest('hex');
  }

  private extractAuthDate(value: unknown): number | null {
    if (typeof value === 'number' && Number.isInteger(value)) {
      return value;
    }

    if (typeof value === 'string' && /^\d+$/.test(value)) {
      const parsed = Number.parseInt(value, 10);
      return Number.isInteger(parsed) ? parsed : null;
    }

    return null;
  }
}
