import { UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { createSign, generateKeyPairSync } from 'crypto';
import { AuthService } from './auth.service';

const base64UrlEncode = (value: string | Buffer): string =>
  Buffer.from(value)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

const createTelegramIdToken = (
  payload: Record<string, unknown>,
  kid: string,
  privateKeyPem: string,
): string => {
  const header = { alg: 'RS256', kid, typ: 'JWT' };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signer = createSign('RSA-SHA256');
  signer.update(signingInput);
  signer.end();
  const signature = signer.sign(privateKeyPem);
  return `${signingInput}.${base64UrlEncode(signature)}`;
};

describe('AuthService Telegram Login', () => {
  const mockPrisma = {
    user: {
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    subscription: {
      create: jest.fn(),
    },
  };

  const mockJwtService = {
    sign: jest.fn(),
    verify: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string): string | undefined => {
      const values: Record<string, string> = {
        TELEGRAM_BOT_CLIENT_ID: '8764946066',
        TELEGRAM_BOT_CLIENT_SECRET: 'test-secret',
        JWT_REFRESH_SECRET: 'refresh-secret',
        JWT_REFRESH_EXPIRES_IN: '7d',
      };
      return values[key];
    }),
  };

  const mockOtpService = {
    verifyOtp: jest.fn(),
    generateOtp: jest.fn(),
    storeOtp: jest.fn(),
    sendOtp: jest.fn(),
  };

  const mockEmailService = {
    sendOTP: jest.fn(),
    sendPasswordResetEmail: jest.fn(),
  };

  let authService: AuthService;

  beforeEach(() => {
    jest.clearAllMocks();
    authService = new AuthService(
      mockPrisma as any,
      mockJwtService as any,
      mockConfigService as any,
      mockOtpService as any,
      mockEmailService as any,
    );
  });

  it('creates new Telegram user and returns JWT tokens', async () => {
    const { publicKey, privateKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
    });
    const publicJwk = publicKey.export({ format: 'jwk' }) as JsonWebKey;

    const now = Math.floor(Date.now() / 1000);
    const idToken = createTelegramIdToken(
      {
        iss: 'https://oauth.telegram.org',
        aud: '8764946066',
        sub: '123456789',
        iat: now,
        exp: now + 3600,
        name: 'Telegram User',
        preferred_username: 'telegram_user',
        phone_number: '+85512345678',
      },
      'test-kid',
      privateKey.export({ type: 'pkcs1', format: 'pem' }).toString(),
    );

    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ id_token: idToken }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        }),
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            keys: [
              {
                kty: 'RSA',
                alg: 'RS256',
                kid: 'test-kid',
                n: publicJwk.n,
                e: publicJwk.e,
              },
            ],
          }),
          {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
          },
        ),
      );

    (global as unknown as { fetch: typeof fetch }).fetch =
      fetchMock as unknown as typeof fetch;

    mockPrisma.user.findFirst.mockResolvedValue(null);
    mockPrisma.user.create.mockResolvedValue({
      id: 'user-id',
      role: 'PATIENT',
      firstName: 'Telegram',
      lastName: 'User',
      fullName: 'Telegram User',
      phoneNumber: '85512345678',
      idCardNumber: 'TG_123456789',
      profilePictureUrl: null,
      passwordHash: 'hashed-password',
    });
    mockPrisma.subscription.create.mockResolvedValue({ id: 'sub-id' });
    mockJwtService.sign
      .mockReturnValueOnce('access-token')
      .mockReturnValueOnce('refresh-token');

    const result = await authService.telegramLoginMobile(
      'code',
      'verifier',
      'dastern://auth/telegram/callback',
      'PATIENT' as UserRole,
    );

    expect(result.accessToken).toBe('access-token');
    expect(result.refreshToken).toBe('refresh-token');
    expect(result.user.id).toBe('user-id');
    expect(mockPrisma.user.create).toHaveBeenCalled();
    expect(mockPrisma.subscription.create).toHaveBeenCalled();
  });

  it('accepts numeric audience in Telegram ID token', async () => {
    const { publicKey, privateKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
    });
    const publicJwk = publicKey.export({ format: 'jwk' }) as JsonWebKey;

    const now = Math.floor(Date.now() / 1000);
    const idToken = createTelegramIdToken(
      {
        iss: 'https://oauth.telegram.org/',
        aud: 8764946066,
        sub: 99887766,
        iat: now,
        exp: now + 3600,
        name: 'Numeric Aud User',
      },
      'numeric-kid',
      privateKey.export({ type: 'pkcs1', format: 'pem' }).toString(),
    );

    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ id_token: idToken }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        }),
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            keys: [
              {
                kty: 'RSA',
                alg: 'RS256',
                kid: 'numeric-kid',
                n: publicJwk.n,
                e: publicJwk.e,
              },
            ],
          }),
          {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
          },
        ),
      );

    (global as unknown as { fetch: typeof fetch }).fetch =
      fetchMock as unknown as typeof fetch;

    mockPrisma.user.findFirst.mockResolvedValue(null);
    mockPrisma.user.create.mockResolvedValue({
      id: 'user-2',
      role: 'PATIENT',
      firstName: 'Numeric',
      lastName: 'Aud',
      fullName: 'Numeric Aud User',
      phoneNumber: null,
      idCardNumber: 'TG_99887766',
      profilePictureUrl: null,
      passwordHash: 'hashed-password',
    });
    mockPrisma.subscription.create.mockResolvedValue({ id: 'sub-2' });
    mockJwtService.sign
      .mockReturnValueOnce('access-token-2')
      .mockReturnValueOnce('refresh-token-2');

    const result = await authService.telegramLoginMobile(
      'code',
      'verifier',
      'http://10.212.42.255:3001/api/v1/auth/telegram/callback',
      'PATIENT' as UserRole,
    );

    expect(result.accessToken).toBe('access-token-2');
    expect(mockPrisma.user.create).toHaveBeenCalled();
  });

  it('throws UnauthorizedException when Telegram token exchange fails', async () => {
    const fetchMock = jest.fn().mockResolvedValue(
      new Response('invalid_grant', {
        status: 400,
        headers: { 'Content-Type': 'text/plain' },
      }),
    );
    (global as unknown as { fetch: typeof fetch }).fetch =
      fetchMock as unknown as typeof fetch;

    await expect(
      authService.telegramLoginMobile(
        'bad-code',
        'verifier',
        'dastern://auth/telegram/callback',
      ),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
