import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../../database/prisma.service';
import { TelegramHashVerifier } from './telegram-hash-verifier.service';

export interface TelegramAuthData {
  id: number;
  first_name: string;
  last_name?: string;
  username?: string;
  photo_url?: string;
  auth_date: number;
  hash?: string;
  email?: string;
}

interface TelegramOidcTokenResponse {
  access_token?: string;
  id_token?: string;
  token_type?: string;
  expires_in?: number;
}

interface UserWithTelegramProfile {
  id: string;
  email: string | null;
  firstName: string | null;
  lastName: string | null;
  fullName: string | null;
  profilePictureUrl: string | null;
  telegramId?: string | null;
  telegramUsername?: string | null;
  telegramFirstName?: string | null;
  telegramLastName?: string | null;
  telegramPhotoUrl?: string | null;
}

interface TelegramMappedFields {
  telegramId: string;
  telegramUsername: string | null;
  telegramFirstName: string;
  telegramLastName: string | null;
  telegramPhotoUrl: string | null;
  firstName: string;
  lastName: string | null;
  fullName: string | null;
  profilePictureUrl: string | null;
  email?: string;
}

@Injectable()
export class TelegramAuthService {
  private static readonly BCRYPT_ROUNDS = 12;
  private static readonly PREMIUM_TRIAL_STORAGE_BYTES = 21_474_836_480;
  private readonly logger = new Logger(TelegramAuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly telegramHashVerifier: TelegramHashVerifier,
  ) {}

  async exchangeCodeForTelegramAuthData(
    code: string,
    redirectUri: string,
  ): Promise<TelegramAuthData> {
    if (!code || !redirectUri) {
      throw new BadRequestException('Invalid Telegram OIDC callback parameters');
    }

    const clientId = process.env.TELEGRAM_BOT_CLIENT_ID?.trim();
    const clientSecret = process.env.TELEGRAM_BOT_CLIENT_SECRET?.trim();

    if (!clientId || !clientSecret) {
      throw new InternalServerErrorException('Telegram OAuth credentials are not configured');
    }

    const auth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
    const body = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,
      client_id: clientId,
    });

    const tokenResponse = await fetch('https://oauth.telegram.org/token', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.toString(),
    });

    if (!tokenResponse.ok) {
      const errText = await tokenResponse.text();
      this.logger.warn(`Telegram token exchange failed: ${tokenResponse.status} ${errText}`);
      throw new UnauthorizedException('Invalid Telegram authorization code');
    }

    const tokenData = (await tokenResponse.json()) as TelegramOidcTokenResponse;
    if (!tokenData.id_token) {
      throw new UnauthorizedException('Missing Telegram ID token in OAuth response');
    }

    const payload = this.decodeJwtPayload(tokenData.id_token);

    if (payload.iss !== 'https://oauth.telegram.org') {
      throw new UnauthorizedException('Invalid Telegram token issuer');
    }

    if (`${payload.aud ?? ''}` !== clientId) {
      throw new UnauthorizedException('Invalid Telegram token audience');
    }

    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== 'number' || payload.exp < now) {
      throw new UnauthorizedException('Telegram ID token has expired');
    }

    const rawId = payload.id ?? payload.sub;
    const telegramId = Number.parseInt(String(rawId), 10);
    if (!Number.isInteger(telegramId) || telegramId <= 0) {
      throw new UnauthorizedException('Invalid Telegram user id in token');
    }

    const fullName = typeof payload.name === 'string' ? payload.name.trim() : '';
    const [firstName, ...restNames] = fullName.length > 0 ? fullName.split(' ') : ['Telegram'];
    const lastName = restNames.join(' ').trim() || undefined;

    return {
      id: telegramId,
      first_name: firstName || 'Telegram',
      last_name: lastName,
      username:
        typeof payload.preferred_username === 'string'
          ? payload.preferred_username
          : undefined,
      photo_url: typeof payload.picture === 'string' ? payload.picture : undefined,
      auth_date: typeof payload.iat === 'number' ? payload.iat : now,
    };
  }

  async validateTelegramAuth(data: TelegramAuthData): Promise<void> {
    this.validateInputShape(data, true);

    const isAuthDateValid = this.telegramHashVerifier.validateAuthDate(data.auth_date);
    if (!isAuthDateValid) {
      this.logger.warn(`Telegram auth rejected: expired auth_date for telegramId=${data.id}`);
      throw new UnauthorizedException('Authentication data has expired');
    }

    const isHashValid = this.telegramHashVerifier.verifyHash(
      data as unknown as Record<string, unknown> & { hash: string },
    );
    if (!isHashValid) {
      this.logger.warn(`Telegram auth rejected: hash mismatch for telegramId=${data.id}`);
      throw new UnauthorizedException('Invalid authentication data');
    }
  }

  async findOrCreateUser(data: TelegramAuthData): Promise<any> {
    this.validateInputShape(data, false);

    const telegramId = String(data.id);

    const existingByTelegramId = (await this.prisma.user.findFirst({
      where: { telegramId } as unknown as Prisma.UserWhereInput,
    })) as UserWithTelegramProfile | null;

    if (existingByTelegramId) {
      const mappedData = this.mapTelegramFields(data, { includeEmail: false });
      const updateData = this.getChangedTelegramProfileFields(existingByTelegramId, mappedData);

      if (Object.keys(updateData).length === 0) {
        return existingByTelegramId;
      }

      return this.prisma.user.update({
        where: { id: existingByTelegramId.id },
        data: updateData as unknown as Prisma.UserUpdateInput,
      });
    }

    const normalizedEmail = this.normalizeEmail(data.email);
    if (normalizedEmail) {
      const existingByEmail = await this.prisma.user.findUnique({
        where: { email: normalizedEmail },
      });

      if (existingByEmail) {
        return this.linkTelegramToExistingUser(existingByEmail.id, {
          ...data,
          email: normalizedEmail,
        });
      }
    }

    const randomPassword = randomBytes(32).toString('hex');
    const passwordHash = await bcrypt.hash(randomPassword, TelegramAuthService.BCRYPT_ROUNDS);
    const mappedData = this.mapTelegramFields(data);

    try {
      const createdUser = await this.prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            role: 'PATIENT',
            accountStatus: 'ACTIVE',
            passwordHash,
            ...mappedData,
          } as unknown as Prisma.UserCreateInput,
        });

        const trialEndDate = new Date();
        trialEndDate.setMonth(trialEndDate.getMonth() + 1);

        await tx.subscription.create({
          data: {
            userId: newUser.id,
            tier: 'PREMIUM',
            storageQuota: TelegramAuthService.PREMIUM_TRIAL_STORAGE_BYTES,
            storageUsed: 0,
            expiresAt: trialEndDate,
            hasUsedTrial: true,
          },
        });

        return newUser;
      });

      return createdUser;
    } catch (error: unknown) {
      this.logger.error(
        `Failed to create Telegram user for telegramId=${telegramId}`,
        error instanceof Error ? error.stack : String(error),
      );
      throw new InternalServerErrorException('Failed to create user account');
    }
  }

  async linkTelegramToExistingUser(userId: string, telegramData: TelegramAuthData): Promise<any> {
    if (!userId || typeof userId !== 'string') {
      throw new BadRequestException('Malformed user identifier');
    }

    this.validateInputShape(telegramData, false);

    const mappedData = this.mapTelegramFields(telegramData);

    return this.prisma.user.update({
      where: { id: userId },
      data: mappedData as unknown as Prisma.UserUpdateInput,
    });
  }

  private validateInputShape(data: TelegramAuthData, requireHash: boolean): void {
    if (!data || typeof data !== 'object') {
      throw new BadRequestException('Malformed Telegram authentication data');
    }

    if (!Number.isInteger(data.id) || data.id <= 0) {
      throw new BadRequestException('Malformed Telegram authentication data');
    }

    if (typeof data.first_name !== 'string' || data.first_name.trim().length === 0) {
      throw new BadRequestException('Malformed Telegram authentication data');
    }

    if (!Number.isInteger(data.auth_date) || data.auth_date <= 0) {
      throw new BadRequestException('Malformed Telegram authentication data');
    }

    if (requireHash && (typeof data.hash !== 'string' || data.hash.trim().length === 0)) {
      throw new BadRequestException('Malformed Telegram authentication data');
    }

    if (data.email !== undefined && this.normalizeEmail(data.email) === null) {
      throw new BadRequestException('Malformed Telegram authentication data');
    }
  }

  private mapTelegramFields(
    telegramData: TelegramAuthData,
    options?: { includeEmail?: boolean },
  ): TelegramMappedFields {
    const firstName = telegramData.first_name.trim();
    const lastName = telegramData.last_name?.trim() || null;
    const fullName = [firstName, lastName].filter(Boolean).join(' ').trim();
    const normalizedEmail = this.normalizeEmail(telegramData.email);
    const includeEmail = options?.includeEmail ?? true;

    return {
      telegramId: String(telegramData.id),
      telegramUsername: telegramData.username?.trim() || null,
      telegramFirstName: firstName,
      telegramLastName: lastName,
      telegramPhotoUrl: telegramData.photo_url?.trim() || null,
      firstName,
      lastName,
      fullName: fullName.length > 0 ? fullName : null,
      profilePictureUrl: telegramData.photo_url?.trim() || null,
      ...(includeEmail && normalizedEmail ? { email: normalizedEmail } : {}),
    };
  }

  private getChangedTelegramProfileFields(
    user: UserWithTelegramProfile,
    mappedData: TelegramMappedFields,
  ): Partial<TelegramMappedFields> {
    const updateData: Partial<TelegramMappedFields> = {};

    if (user.telegramUsername !== mappedData.telegramUsername) {
      updateData.telegramUsername = mappedData.telegramUsername;
    }

    if (user.telegramFirstName !== mappedData.telegramFirstName) {
      updateData.telegramFirstName = mappedData.telegramFirstName;
    }

    if (user.telegramLastName !== mappedData.telegramLastName) {
      updateData.telegramLastName = mappedData.telegramLastName;
    }

    if (user.telegramPhotoUrl !== mappedData.telegramPhotoUrl) {
      updateData.telegramPhotoUrl = mappedData.telegramPhotoUrl;
    }

    if (user.firstName !== mappedData.firstName) {
      updateData.firstName = mappedData.firstName;
    }

    if (user.lastName !== mappedData.lastName) {
      updateData.lastName = mappedData.lastName;
    }

    if (user.fullName !== mappedData.fullName) {
      updateData.fullName = mappedData.fullName;
    }

    if (user.profilePictureUrl !== mappedData.profilePictureUrl) {
      updateData.profilePictureUrl = mappedData.profilePictureUrl;
    }

    return updateData;
  }

  private normalizeEmail(email?: string): string | null {
    if (email === undefined) {
      return null;
    }

    if (typeof email !== 'string') {
      return null;
    }

    const normalized = email.trim().toLowerCase();

    if (normalized.length === 0) {
      return null;
    }

    return normalized;
  }

  private decodeJwtPayload(token: string): Record<string, any> {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new UnauthorizedException('Invalid Telegram ID token format');
    }

    try {
      const payloadBase64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const pad = payloadBase64.length % 4;
      const normalized = payloadBase64 + (pad === 0 ? '' : '='.repeat(4 - pad));
      const payloadJson = Buffer.from(normalized, 'base64').toString('utf8');
      return JSON.parse(payloadJson) as Record<string, any>;
    } catch {
      throw new UnauthorizedException('Invalid Telegram ID token payload');
    }
  }
}
