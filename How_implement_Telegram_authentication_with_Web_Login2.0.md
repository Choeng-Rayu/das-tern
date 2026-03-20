# How to Implement Telegram Authentication with Web Login 2.0

> A complete, step-by-step guide based on a real production implementation.  
> Stack: **NestJS (backend)** + **Flutter (mobile client)**  
> Protocol: **OpenID Connect (OIDC) + Authorization Code Flow + PKCE**

---

## Table of Contents

1. [Overview & Architecture](#1-overview--architecture)
2. [Prerequisites](#2-prerequisites)
3. [Step 1 — Register Your Bot with BotFather](#3-step-1--register-your-bot-with-botfather)
4. [Step 2 — Configure Environment Variables](#4-step-2--configure-environment-variables)
5. [Step 3 — Set Up the Database Schema](#5-step-3--set-up-the-database-schema)
6. [Step 4 — Build the NestJS Backend](#6-step-4--build-the-nestjs-backend)
   - 4a. DTO Validation
   - 4b. Callback Controller Endpoint
   - 4c. Token Exchange & ID Token Verification
   - 4d. User Find / Create Logic
7. [Step 5 — Build the Flutter Mobile Client](#7-step-5--build-the-flutter-mobile-client)
   - 5a. Dependencies
   - 5b. Android Deep Link Setup
   - 5c. iOS Deep Link Setup
   - 5d. PKCE + State Generation
   - 5e. Open Telegram OAuth in Browser
   - 5f. Listen for the Deep Link Callback
   - 5g. Complete the Login (POST to Backend)
8. [Step 6 — Add UI Buttons](#8-step-6--add-ui-buttons)
9. [Step 7 — Common Pitfalls & Fixes](#9-step-7--common-pitfalls--fixes)
10. [Step 8 — Security Checklist](#10-step-8--security-checklist)
11. [Full Auth Flow Diagram](#11-full-auth-flow-diagram)

---

## 1. Overview & Architecture

Telegram Web Login 2.0 is a modern **OIDC (OpenID Connect)** implementation.  
Unlike the legacy Telegram Login Widget (which used HMAC-SHA256 hash verification), Login 2.0 uses a full **Authorization Code + PKCE** flow and returns a signed **JWT ID token** containing the user's profile.

### Key endpoints

| Purpose | URL |
|---|---|
| Authorization | `https://oauth.telegram.org/auth` |
| Token exchange | `https://oauth.telegram.org/token` |
| JWKS (public keys) | `https://oauth.telegram.org/.well-known/jwks.json` |
| OIDC discovery | `https://oauth.telegram.org/.well-known/openid-configuration` |

### High-level flow

```
Flutter App  →  Telegram OAuth  →  Your Backend  →  Flutter App
    │                 │                  │                │
    │  Open browser   │                  │                │
    │ ──────────────► │                  │                │
    │                 │  User approves   │                │
    │                 │ ───────────────► │                │
    │                 │  code + state    │                │
    │           Deep link fires          │                │
    │ ◄────────────────────────────────                   │
    │  POST {code, codeVerifier}         │                │
    │ ─────────────────────────────────► │                │
    │                 │  Exchange code   │                │
    │                 │  for id_token ── │                │
    │                 │ ◄──────────────  │                │
    │                 │  Verify JWT sig  │                │
    │  App JWT (accessToken + user)      │                │
    │ ◄───────────────────────────────── │                │
    │  Navigate to home screen           │                │
    │ ──────────────────────────────────────────────────► │
```

---

## 2. Prerequisites

- A Telegram account
- A Telegram Bot created via [@BotFather](https://t.me/botfather)
- NestJS backend accessible via a public or LAN IP address (not `localhost` from a mobile device)
- Flutter SDK installed
- PostgreSQL database running

---

## 3. Step 1 — Register Your Bot with BotFather

This is the most critical setup step. If your redirect URI is not registered, Telegram will reject all auth requests.

### 3.1 Create a bot (if you don't have one)

```
1. Open Telegram → search for @BotFather
2. Send: /newbot
3. Follow prompts → choose a name and username (must end in "bot")
4. BotFather gives you: API Token  e.g. 8764946066:AAFhuIq-ohuo69FH51TkW1Mc9ukU7luKg3U
```

Your **Client ID** = the number before the colon in the API token.  
Example: `8764946066:AAFhuIq...` → Client ID = `8764946066`

### 3.2 Configure OAuth for Web Login 2.0

```
1. Send /mybots to BotFather
2. Select your bot (e.g. @dasternbot)
3. Select: Bot Settings
4. Select: Web Login
5. Select: Allowed URLs (or "Configure Login URL")
6. Add your backend callback URL:
   http://YOUR_SERVER_IP:3001/api/v1/auth/telegram/callback
```

> **Important:** The redirect URI Telegram sends codes to must match **exactly** what you register here. If your server IP changes, you must update this.

### 3.3 Get your Client Secret

The **Client Secret** for Telegram Web Login 2.0 is separate from the bot token.  
You can retrieve it from BotFather:

```
1. /mybots → select bot → Bot Settings → API Token
2. The "OAuth Client Secret" is shown under Web Login settings.
   It looks like: Hche_tFl7piYY_Q0rWNWdnM-1qVVk57dB9df9xeOise5nilm4Hia4A
```

---

## 4. Step 2 — Configure Environment Variables

### Backend (`backend_nestjs/.env`)

```bash
# Telegram Web Login 2.0
TELEGRAM_BOT_CLIENT_ID=8764946066
TELEGRAM_BOT_CLIENT_SECRET=Hche_tFl7piYY_Q0rWNWdnM-1qVVk57dB9df9xeOise5nilm4Hia4A
TELEGRAM_BOT_USERNAME=dasternbot
TELEGRAM_BOT_TOKEN=8764946066:AAFhuIq-ohuo69FH51TkW1Mc9ukU7luKg3U

# Where Telegram redirects after user approves (your NestJS endpoint)
TELEGRAM_OAUTH_REDIRECT_URI=http://10.212.42.175:3001/api/v1/auth/telegram/callback

# Where your backend redirects back to the Flutter app (custom scheme)
TELEGRAM_APP_REDIRECT_URI=dastern://auth/telegram/callback
```

### Flutter (`das_tern_mcp/.env`)

```bash
# Backend base URL (use LAN IP, not localhost, for physical devices)
API_BASE_URL=http://10.212.42.175:3001/api/v1

# Telegram credentials (client-side only — no secret here)
TELEGRAM_BOT_CLIENT_ID=8764946066
TELEGRAM_BOT_USERNAME=dasternbot

# Must match TELEGRAM_OAUTH_REDIRECT_URI in backend
TELEGRAM_OAUTH_REDIRECT_URI=http://10.212.42.175:3001/api/v1/auth/telegram/callback

# Must match TELEGRAM_APP_REDIRECT_URI in backend
TELEGRAM_APP_REDIRECT_URI=dastern://auth/telegram/callback
```

---

## 5. Step 3 — Set Up the Database Schema

Add Telegram-related fields to your `users` table. With **Prisma**, update your `schema.prisma`:

```prisma
model User {
  id                String        @id @default(uuid()) @db.Uuid
  role              UserRole
  firstName         String?       @db.VarChar(100)
  lastName          String?       @db.VarChar(100)
  fullName          String?       @db.VarChar(200)
  phoneNumber       String?       @unique @db.VarChar(20)
  email             String?       @unique @db.VarChar(255)
  passwordHash      String        @db.VarChar(255)
  googleId          String?       @unique @db.VarChar(255)

  // Telegram users are identified via idCardNumber = "TG_<telegram_sub>"
  // No separate telegramId column needed — idCardNumber serves as the marker.
  idCardNumber      String?       @unique @db.VarChar(50)

  profilePictureUrl String?
  accountStatus     AccountStatus @default(ACTIVE)
  // ... other fields
  
  @@map("users")
}
```

Then create and apply the migration:

```bash
cd backend_nestjs

# Create migration
npx prisma migrate dev --name add_google_id

# Apply all pending migrations (safe for production)
npx prisma migrate deploy

# Regenerate Prisma client
npx prisma generate
```

> **Gotcha:** Always run `npx prisma migrate deploy` after pulling new code that includes schema changes. If you skip this, Prisma queries will fail with `column does not exist` errors.

### How Telegram users are stored

Telegram users don't have an email, so we store their identity using the `idCardNumber` field as a unique marker:

```
idCardNumber = "TG_<telegram_user_sub>"
Example:     = "TG_123456789"
```

The Telegram `sub` claim (subject) is the user's unique numeric Telegram ID.

---

## 6. Step 4 — Build the NestJS Backend

### 6a. DTO Validation

Create `src/modules/auth/dto/telegram-login.dto.ts`:

```typescript
import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';
import { UserRole } from '@prisma/client';

export class TelegramLoginDto {
  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @IsNotEmpty()
  codeVerifier: string;

  @IsString()
  @IsNotEmpty()
  redirectUri: string;

  @IsOptional()
  @IsEnum(UserRole)
  userRole?: UserRole;
}
```

### 6b. Controller Endpoints

In `src/modules/auth/auth.controller.ts`, add **two** Telegram endpoints:

```typescript
import { Controller, Post, Get, Body, Query, Res } from '@nestjs/common';
import { Response } from 'express';
import { Throttle } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { TelegramLoginDto } from './dto/telegram-login.dto';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private configService: ConfigService,
  ) {}

  /**
   * STEP A: Flutter POSTs here with the authorization code + PKCE verifier.
   * Backend exchanges the code for an ID token and returns the app JWT.
   */
  @Post('telegram')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async telegramLogin(@Body() dto: TelegramLoginDto) {
    return this.authService.telegramLoginMobile(
      dto.code,
      dto.codeVerifier,
      dto.redirectUri,
      dto.userRole,
    );
  }

  /**
   * STEP B: Telegram redirects here after user approval.
   * Backend immediately redirects/serves HTML to open the Flutter app via deep link.
   */
  @Get('telegram/callback')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  telegramOAuthCallback(
    @Query('code') code: string | undefined,
    @Query('state') state: string | undefined,
    @Query('error') error: string | undefined,
    @Res() res: Response,
  ) {
    const appRedirectUri =
      this.configService.get<string>('TELEGRAM_APP_REDIRECT_URI') ||
      'dastern://auth/telegram/callback';

    // Build the deep link URL with code + state
    const redirect = new URL(appRedirectUri);
    if (code)  redirect.searchParams.set('code', code);
    if (state) redirect.searchParams.set('state', state);
    if (error) redirect.searchParams.set('error', error);

    const deepLinkUrl = redirect.toString();

    // ⚠️ KEY INSIGHT: Use an HTML page, NOT a 302 redirect.
    // Android browsers block 302 redirects to custom URI schemes (dastern://).
    // An HTML page with JavaScript + a fallback button works on all platforms.
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Opening App...</title>
</head>
<body>
  <p>Opening Das Tern... <a href="${deepLinkUrl}">Tap here if it doesn't open</a></p>
  <script>
    window.location.href = '${deepLinkUrl}';
  </script>
</body>
</html>`;

    return res.status(200).header('Content-Type', 'text/html').send(html);
  }
}
```

### 6c. Token Exchange & ID Token Verification

In `src/modules/auth/auth.service.ts`:

```typescript
import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createPublicKey, createVerify } from 'crypto';
import * as https from 'https';
import * as http from 'http';
import * as bcrypt from 'bcryptjs';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../database/prisma.service';
import { UserRole } from '@prisma/client';

// ── Type definitions ─────────────────────────────────────────────────────────

interface TelegramJwk {
  kid: string; kty: string; alg: string; use?: string; n?: string; e?: string;
}
interface TelegramJwksResponse { keys: TelegramJwk[]; }
interface TelegramIdTokenPayload {
  iss: string;
  aud: string | number | Array<string | number>;
  sub: string | number;
  exp?: number | string;
  name?: string;
  picture?: string;
  phone_number?: string;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  // Cache JWKS for 5 minutes to avoid hammering Telegram's endpoint
  private telegramJwksCache: TelegramJwksResponse | null = null;
  private telegramJwksCacheExpiry = 0;

  // ── Main entry point called by the controller ───────────────────────────────

  async telegramLoginMobile(
    code: string,
    codeVerifier: string,
    redirectUri: string,
    userRole?: UserRole,
  ) {
    const clientId     = this.configService.get<string>('TELEGRAM_BOT_CLIENT_ID');
    const clientSecret = this.configService.get<string>('TELEGRAM_BOT_CLIENT_SECRET');

    if (!clientId || !clientSecret) {
      throw new UnauthorizedException('Telegram OAuth is not configured on server');
    }

    // ── 1. Exchange authorization code for ID token ───────────────────────────
    const tokenBody = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,     // Must EXACTLY match what Flutter sent to Telegram
      client_id: clientId,
      code_verifier: codeVerifier,   // PKCE verifier — proves the request originated from your app
    });

    const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

    // ⚠️ Use Node's https module, NOT fetch/undici.
    // Reason: undici tries IPv6 first; if IPv6 is unreachable it times out (ETIMEDOUT).
    // Node's https.request with family:4 forces IPv4-only and works reliably.
    const tokenRes = await this.httpsPost('oauth.telegram.org', '/token', {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${basicAuth}`,
    }, tokenBody.toString());

    if (!tokenRes.ok) {
      this.logger.error(`Telegram token exchange failed: ${tokenRes.status} ${tokenRes.body}`);
      throw new UnauthorizedException(
        `Telegram authorization failed (${tokenRes.status}): ${tokenRes.body}`,
      );
    }

    const tokenData = JSON.parse(tokenRes.body) as { id_token?: string };
    if (!tokenData.id_token) {
      throw new UnauthorizedException('Telegram did not return an ID token');
    }

    // ── 2. Verify the ID token (JWT) ─────────────────────────────────────────
    const claims = await this.verifyTelegramIdToken(tokenData.id_token, clientId);

    // ── 3. Find or create user ───────────────────────────────────────────────
    return this.findOrCreateTelegramUser(claims, userRole);
  }

  // ── JWT Verification ────────────────────────────────────────────────────────

  private async verifyTelegramIdToken(
    idToken: string,
    expectedAudience: string,
  ): Promise<TelegramIdTokenPayload> {
    const parts = idToken.split('.');
    if (parts.length !== 3) throw new UnauthorizedException('Malformed Telegram ID token');

    const header    = JSON.parse(Buffer.from(parts[0], 'base64url').toString());
    const payload   = JSON.parse(Buffer.from(parts[1], 'base64url').toString()) as TelegramIdTokenPayload;
    const sigBuffer = Buffer.from(
      parts[2].replace(/-/g, '+').replace(/_/g, '/') +
      '='.repeat((4 - (parts[2].length % 4)) % 4),
      'base64'
    );

    if (header.alg !== 'RS256' || !header.kid) {
      throw new UnauthorizedException('Unsupported Telegram token algorithm');
    }

    // Fetch JWKS and find matching key by kid
    const jwks = await this.getTelegramJwks();
    const jwk  = jwks.keys.find((k) => k.kid === header.kid);
    if (!jwk) throw new UnauthorizedException('Unable to find Telegram signing key');

    // Verify RS256 signature
    const publicKey = createPublicKey({ key: { kty: jwk.kty, kid: jwk.kid, alg: jwk.alg, use: jwk.use, n: jwk.n, e: jwk.e }, format: 'jwk' });
    const verifier  = createVerify('RSA-SHA256');
    verifier.update(`${parts[0]}.${parts[1]}`);
    verifier.end();
    if (!verifier.verify(publicKey, sigBuffer)) {
      throw new UnauthorizedException('Invalid Telegram token signature');
    }

    // Validate claims
    const nowSec = Math.floor(Date.now() / 1000);
    const issuer = (payload.iss || '').replace(/\/$/, '');
    if (issuer !== 'https://oauth.telegram.org') {
      throw new UnauthorizedException('Invalid Telegram token issuer');
    }

    const audience = Array.isArray(payload.aud) ? payload.aud.map(String) : [String(payload.aud)];
    if (!audience.includes(String(expectedAudience))) {
      throw new UnauthorizedException('Invalid Telegram token audience');
    }

    if (Number(payload.exp) <= nowSec) {
      throw new UnauthorizedException('Telegram token has expired');
    }

    payload.sub = String(payload.sub).trim();
    return payload;
  }

  // ── JWKS fetching with cache ────────────────────────────────────────────────

  private async getTelegramJwks(): Promise<TelegramJwksResponse> {
    const now = Date.now();
    if (this.telegramJwksCache && this.telegramJwksCacheExpiry > now) {
      return this.telegramJwksCache;
    }

    const response = await this.httpsGet('oauth.telegram.org', '/.well-known/jwks.json');
    if (!response.ok) throw new UnauthorizedException('Failed to fetch Telegram signing keys');

    const jwks = JSON.parse(response.body) as TelegramJwksResponse;
    if (!jwks.keys?.length) throw new UnauthorizedException('Empty JWKS from Telegram');

    this.telegramJwksCache = jwks;
    this.telegramJwksCacheExpiry = now + 5 * 60 * 1000; // cache 5 minutes
    return jwks;
  }

  // ── User upsert ─────────────────────────────────────────────────────────────

  private async findOrCreateTelegramUser(claims: TelegramIdTokenPayload, userRole?: UserRole) {
    // Use a namespaced marker in idCardNumber to identify Telegram users
    const telegramMarker  = `TG_${claims.sub}`;
    const normalizedPhone = this.normalizePhoneNumber(claims.phone_number);

    let user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { idCardNumber: telegramMarker },
          ...(normalizedPhone ? [{ phoneNumber: normalizedPhone }] : []),
        ],
      },
    });

    const nameParts = (claims.name?.trim() || '').split(' ').filter(Boolean);
    const firstName = nameParts[0] || 'Telegram';
    const lastName  = nameParts.slice(1).join(' ') || '';

    if (!user) {
      // New user: create with a random password hash (user will never type this)
      user = await this.prisma.user.create({
        data: {
          role:             userRole || 'PATIENT',
          firstName,
          lastName,
          fullName:         claims.name?.trim() || firstName,
          phoneNumber:      normalizedPhone,
          idCardNumber:     telegramMarker,
          passwordHash:     await bcrypt.hash(randomBytes(32).toString('hex'), 12),
          accountStatus:    'ACTIVE',
          profilePictureUrl: claims.picture || null,
        },
      });
    } else {
      // Existing user: link Telegram to account and update stale fields
      const updates: Record<string, unknown> = {};
      if (!user.idCardNumber)                           updates.idCardNumber = telegramMarker;
      if (!user.profilePictureUrl && claims.picture)    updates.profilePictureUrl = claims.picture;
      if (Object.keys(updates).length > 0) {
        user = await this.prisma.user.update({ where: { id: user.id }, data: updates });
      }
    }

    const { passwordHash, ...result } = user;
    return this.login(result); // issue app JWT
  }

  // ── IPv4-forced HTTPS helpers ───────────────────────────────────────────────
  // These use family:4 to avoid ETIMEDOUT caused by unreachable IPv6 addresses.

  private httpsGet(host: string, path: string): Promise<{ ok: boolean; status: number; body: string }> {
    return new Promise((resolve, reject) => {
      const req = https.request(
        { hostname: host, path, method: 'GET', family: 4, headers: { 'User-Agent': 'YourApp/1.0' } },
        (res: http.IncomingMessage) => {
          let body = '';
          res.setEncoding('utf8');
          res.on('data', (c: string) => { body += c; });
          res.on('end', () => resolve({ ok: (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300, status: res.statusCode ?? 0, body }));
        },
      );
      req.on('error', reject);
      req.setTimeout(10000, () => req.destroy(new Error('Request timed out')));
      req.end();
    });
  }

  private httpsPost(host: string, path: string, headers: Record<string, string>, body: string): Promise<{ ok: boolean; status: number; body: string }> {
    return new Promise((resolve, reject) => {
      const buf = Buffer.from(body, 'utf8');
      const req = https.request(
        { hostname: host, path, method: 'POST', family: 4, headers: { ...headers, 'Content-Length': buf.length, 'User-Agent': 'YourApp/1.0' } },
        (res: http.IncomingMessage) => {
          let responseBody = '';
          res.setEncoding('utf8');
          res.on('data', (c: string) => { responseBody += c; });
          res.on('end', () => resolve({ ok: (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300, status: res.statusCode ?? 0, body: responseBody }));
        },
      );
      req.on('error', reject);
      req.setTimeout(10000, () => req.destroy(new Error('Request timed out')));
      req.write(buf);
      req.end();
    });
  }

  private normalizePhoneNumber(phone?: string): string | null {
    if (!phone) return null;
    const cleaned = phone.replace(/\D/g, '');
    return cleaned.length >= 7 ? `+${cleaned}` : null;
  }
}
```

---

## 7. Step 5 — Build the Flutter Mobile Client

### 7a. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0         # Load .env file
  crypto: ^3.0.3                  # SHA-256 for PKCE
  url_launcher: ^6.2.5            # Open browser
  app_links: ^6.3.4               # Catch deep links (works on Android + iOS)
  flutter_secure_storage: ^9.2.2  # Store JWT tokens securely
  http: ^1.2.1                    # HTTP calls to your backend
```

Run:
```bash
flutter pub get
```

### 7b. Android Deep Link Setup

In `android/app/src/main/AndroidManifest.xml`, inside the `<activity>` tag:

```xml
<!-- Handle dastern://auth/telegram/callback deep links -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="dastern"
        android:host="auth"
        android:pathPrefix="/telegram/callback" />
</intent-filter>
```

Also ensure the activity has `android:launchMode="singleTop"` to avoid creating a duplicate activity when the deep link fires.

### 7c. iOS Deep Link Setup

In `ios/Runner/Info.plist`, add:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>dastern</string>
    </array>
  </dict>
</array>
```

### 7d. PKCE + State Generation

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

// Generate a random URL-safe base64 string (no padding)
String _generateRandomBase64Url(int byteLength) {
  final random = Random.secure();
  final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

// Derive the PKCE code challenge from the verifier
String _computeCodeChallenge(String codeVerifier) {
  final bytes = utf8.encode(codeVerifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}
```

Usage:
```dart
final state         = _generateRandomBase64Url(16);  // CSRF protection
final codeVerifier  = _generateRandomBase64Url(64);  // PKCE verifier (secret)
final codeChallenge = _computeCodeChallenge(codeVerifier); // sent to Telegram
```

### 7e. Open Telegram OAuth in Browser

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> _startTelegramOAuth() async {
  final clientId         = dotenv.env['TELEGRAM_BOT_CLIENT_ID']!;
  final oauthRedirectUri = dotenv.env['TELEGRAM_OAUTH_REDIRECT_URI']!;
  // ^ This is your BACKEND callback URL, e.g. http://10.x.x.x:3001/api/v1/auth/telegram/callback

  final state         = _generateRandomBase64Url(16);
  final codeVerifier  = _generateRandomBase64Url(64);
  final codeChallenge = _computeCodeChallenge(codeVerifier);

  // Save state + codeVerifier so we can validate when the deep link fires
  _pendingState        = state;
  _pendingCodeVerifier = codeVerifier;

  final authUrl = Uri.https('oauth.telegram.org', '/auth', {
    'client_id':             clientId,
    'redirect_uri':          oauthRedirectUri,
    'response_type':         'code',
    'scope':                 'openid profile phone',
    'state':                 state,
    'code_challenge':        codeChallenge,
    'code_challenge_method': 'S256',
  });

  await launchUrl(authUrl, mode: LaunchMode.externalApplication);
}
```

### 7f. Listen for the Deep Link Callback

Use `app_links` to catch the `dastern://auth/telegram/callback?code=...&state=...` URI:

```dart
import 'package:app_links/app_links.dart';

final AppLinks _appLinks = AppLinks();
StreamSubscription<Uri>? _linkSubscription;
Completer<Uri>? _callbackCompleter;

void _initDeepLinkListener() {
  // Handle app already open → stream
  _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
    _handleIncomingUri(uri);
  });

  // Handle cold start (app was closed, then opened by the deep link)
  _appLinks.getInitialLink().then((uri) {
    if (uri != null) _handleIncomingUri(uri);
  });
}

void _handleIncomingUri(Uri uri) {
  // Only handle our Telegram callback deep link
  if (uri.scheme == 'dastern' &&
      uri.host == 'auth' &&
      uri.path == '/telegram/callback') {
    _callbackCompleter?.complete(uri);
  }
}
```

### 7g. Complete the Login (POST to Backend)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<bool> signInWithTelegram() async {
  try {
    // 1. Start OAuth and initialize a completer to await the callback
    _callbackCompleter = Completer<Uri>();
    await _startTelegramOAuth();

    // 2. Wait for the deep link to fire (timeout after 2 minutes)
    final callbackUri = await _callbackCompleter!.future.timeout(
      const Duration(minutes: 2),
    );

    // 3. Validate CSRF state
    final returnedState = callbackUri.queryParameters['state'];
    if (returnedState != _pendingState) {
      throw Exception('State mismatch — possible CSRF attack');
    }

    // 4. Check for errors from Telegram
    final error = callbackUri.queryParameters['error'];
    if (error != null) throw Exception('Telegram error: $error');

    // 5. Extract the authorization code
    final code = callbackUri.queryParameters['code'];
    if (code == null) throw Exception('No code in callback');

    // 6. POST to your backend to exchange code for app JWT
    final apiBaseUrl      = dotenv.env['API_BASE_URL']!;
    final oauthRedirectUri = dotenv.env['TELEGRAM_OAUTH_REDIRECT_URI']!;

    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/telegram'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code':         code,
        'codeVerifier': _pendingCodeVerifier,
        'redirectUri':  oauthRedirectUri,
        // Optional: 'userRole': 'PATIENT' or 'DOCTOR'
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Login failed');
    }

    // 7. Store tokens and mark authenticated
    final result = jsonDecode(response.body);
    const storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken',  value: result['accessToken']);
    await storage.write(key: 'refreshToken', value: result['refreshToken']);

    return true;
  } catch (e) {
    print('Telegram login error: $e');
    return false;
  } finally {
    _pendingState        = null;
    _pendingCodeVerifier = null;
    _callbackCompleter   = null;
  }
}
```

---

## 8. Step 6 — Add UI Buttons

### Login Screen

```dart
OutlinedButton.icon(
  onPressed: () async {
    final success = await signInWithTelegram();
    if (success) Navigator.pushReplacementNamed(context, '/home');
  },
  icon: const Icon(Icons.send_rounded, color: Color(0xFF229ED9)),
  label: const Text('Sign in with Telegram'),
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: Color(0xFF229ED9), width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  ),
)
```

### Registration Screen

Same button, but optionally pass a `userRole`:

```dart
// For patient registration
await signInWithTelegram(userRole: 'PATIENT');

// For doctor registration
await signInWithTelegram(userRole: 'DOCTOR');
```

---

## 9. Step 7 — Common Pitfalls & Fixes

### ❌ Error: `fetch failed` / `ETIMEDOUT`

**Cause:** Node.js native `fetch` (backed by `undici`) tries Telegram's IPv6 address (`2001:67c:4e8:f004::9`) first. If IPv6 is not routed on your network, it times out. `curl` works because it falls back to IPv4 automatically.

**Fix:** Replace `fetch()` calls with `https.request({ family: 4 })` in your NestJS service. The `family: 4` option forces DNS to resolve only IPv4 addresses.

```typescript
// ❌ This can ETIMEDOUT if your network has no working IPv6
const res = await fetch('https://oauth.telegram.org/token', { ... });

// ✅ This always works — forces IPv4
const res = await this.httpsPost('oauth.telegram.org', '/token', headers, body);
// (using the custom httpsPost helper shown in Step 4c)
```

---

### ❌ Error: `column "users.googleId" does not exist`

**Cause:** Your Prisma schema has been updated with new columns (e.g., `googleId` for Google OAuth) but the actual database was never migrated.

**Fix:**
```bash
cd backend_nestjs

# Check which migrations are pending
npx prisma migrate status

# Apply all pending migrations
npx prisma migrate deploy

# Regenerate Prisma client
npx prisma generate
```

> Always run `npx prisma migrate deploy` after cloning a repo or pulling upstream schema changes.

---

### ❌ Error: `redirect_uri_required` or `Bad Request` from Telegram

**Cause:** The `redirect_uri` you send to `oauth.telegram.org` is not registered in BotFather.

**Fix:**
1. Open [@BotFather](https://t.me/botfather)
2. `/mybots` → select bot → Bot Settings → Web Login → Allowed URLs
3. Add your exact NestJS callback URL, e.g.:  
   `http://10.212.42.175:3001/api/v1/auth/telegram/callback`

---

### ❌ Error: Browser doesn't open the app after Telegram login

**Cause:** Your backend is returning a `302` redirect to `dastern://...`. Most mobile browsers block HTTP redirects to custom URI schemes for security reasons.

**Fix:** Instead of `res.redirect(302, deepLinkUrl)`, return an HTML page that uses JavaScript to navigate:

```typescript
const html = `<!DOCTYPE html><html>
<body>
  <a href="${deepLinkUrl}">Open App</a>
  <script>window.location.href='${deepLinkUrl}';</script>
</body>
</html>`;
return res.status(200).header('Content-Type', 'text/html').send(html);
```

---

### ❌ Error: `state mismatch` in Flutter

**Cause:** The `state` value generated before opening the browser was lost (e.g., variable was overwritten or the provider was recreated).

**Fix:** Store `state` and `codeVerifier` in memory-persistent fields (e.g., class-level variables) before opening the browser, and clear them only after the full flow completes.

---

### ❌ Error: `Telegram did not return an ID token`

**Cause:** The code was already used (codes are single-use), or the `code_verifier` doesn't match the `code_challenge` that was sent to Telegram.

**Fix:** Ensure:
- `codeVerifier` in the POST to your backend is the exact same string used to compute `codeChallenge` that was sent to Telegram.
- Each login attempt generates a **fresh** `state` + `codeVerifier` pair.

---

## 10. Step 8 — Security Checklist

| Check | Why it matters |
|---|---|
| ✅ Validate `state` on callback | Prevents CSRF attacks |
| ✅ Use PKCE (`S256`) | Prevents authorization code interception |
| ✅ Verify ID token signature (JWKS) | Proves the token came from Telegram |
| ✅ Check `iss` claim = `https://oauth.telegram.org` | Prevents token substitution |
| ✅ Check `aud` claim = your `client_id` | Prevents tokens issued for other apps |
| ✅ Check `exp` claim (not expired) | Prevents replay of old tokens |
| ✅ Generate random `passwordHash` for OAuth users | Prevents null constraint failures |
| ✅ Store JWT in `flutter_secure_storage` | Encrypted on-device key storage |
| ✅ Rate-limit auth endpoints | Prevents brute-force / token fishing |
| ✅ Use HTTPS in production | Prevents MITM on the callback URL |

---

## 11. Full Auth Flow Diagram

```
Flutter App (mobile)               NestJS Backend              Telegram OIDC Server
        │                                │                              │
        │  1. Generate PKCE:             │                              │
        │     verifier (secret)          │                              │
        │     challenge = SHA256(verifier)                              │
        │     state     = random         │                              │
        │                                │                              │
        │  2. launchUrl (external browser):                             │
        │  GET https://oauth.telegram.org/auth                         │
        │     ?client_id=CLIENT_ID       │                              │
        │     &redirect_uri=http://BACKEND_IP/auth/telegram/callback   │
        │     &response_type=code        │                              │
        │     &scope=openid profile phone                               │
        │     &state=RANDOM_STATE        │                              │
        │     &code_challenge=CHALLENGE  │                              │
        │     &code_challenge_method=S256                               │
        │─────────────────────────────────────────────────────────────►│
        │                                │                              │
        │                                │  3. User taps "Allow"        │
        │                                │◄─────────────────────────── │
        │                                │  GET /auth/telegram/callback  │
        │                                │     ?code=ONE_TIME_CODE      │
        │                                │     &state=RANDOM_STATE      │
        │                                │                              │
        │  4. HTML page opened in browser with JS:                      │
        │     window.location='dastern://auth/telegram/callback         │
        │                       ?code=ONE_TIME_CODE&state=RANDOM_STATE' │
        │◄───────────────────────────────│                              │
        │                                │                              │
        │  5. app_links fires:           │                              │
        │     dastern://auth/telegram/callback?code=...&state=...       │
        │                                │                              │
        │  6. Validate state == RANDOM_STATE (CSRF check)               │
        │                                │                              │
        │  7. POST /auth/telegram ──────►│                              │
        │     { code, codeVerifier,      │                              │
        │       redirectUri }            │                              │
        │                                │  8. POST /token ────────────►│
        │                                │     grant_type=authorization_code
        │                                │     code=ONE_TIME_CODE       │
        │                                │     redirect_uri=BACKEND_URL │
        │                                │     client_id=CLIENT_ID      │
        │                                │     code_verifier=VERIFIER   │
        │                                │     Authorization: Basic ... │
        │                                │◄──── { id_token: JWT } ─────│
        │                                │                              │
        │                                │  9. Verify JWT:              │
        │                                │     a) Fetch JWKS            │
        │                                │     b) Verify RS256 sig      │
        │                                │     c) Check iss/aud/exp     │
        │                                │                              │
        │                                │  10. Find or create user     │
        │                                │      Issue app JWT           │
        │◄──── { accessToken,            │                              │
        │        refreshToken, user } ───│                              │
        │                                │                              │
        │  11. Store tokens in           │                              │
        │      FlutterSecureStorage      │                              │
        │                                │                              │
        │  12. Navigate to home screen   │                              │
        │                                │                              │
```

---

## Tips for Production

1. **Use a fixed domain name** (e.g., via Cloudflare Tunnel or a VPS) instead of a raw IP for the callback URL. IPs change; domain names don't. Register the domain in BotFather once.

2. **HTTPS is required in production.** Telegram will not send codes to HTTP URLs in production mode. For development, IP addresses are accepted.

3. **Handle token refresh.** The app JWT (not the Telegram token) expires based on your `JWT_EXPIRES_IN` setting. Implement a refresh token flow so users stay logged in.

4. **Test the cold-start deep link.** Kill the app completely, then complete the Telegram auth flow. The app should re-open and continue the flow via `getInitialLink()`.

5. **Log Telegram callback calls.** Add logging to your `GET /auth/telegram/callback` endpoint to debug issues in the Telegram redirect step.

---

*Document written based on production implementation in Das Tern — March 2026.*
