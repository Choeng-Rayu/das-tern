# Google OAuth Configuration ✅

**Date**: February 9, 2026, 12:55  
**Status**: ✅ Google OAuth credentials configured

---

## Google OAuth Credentials

### Project Information
- **Project ID**: decoded-shadow-467701-c9
- **Client ID**: 843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
- **Client Secret**: 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

### Authorized URLs
- **Redirect URI**: http://localhost:3001/api/v1/auth/google/callback
- **JavaScript Origins**: 
  - http://localhost:3000
  - http://localhost:3001

---

## Configuration Files Updated

### 1. Backend NestJS (.env)
**File**: `/home/rayu/das-tern/backend_nestjs/.env`

```env
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GOOGLE_CALLBACK_URL=http://localhost:3001/api/v1/auth/google/callback
```

### 2. Mobile App (.env)
**File**: `/home/rayu/das-tern/mobile_app/.env`

```env
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GOOGLE_REDIRECT_URI=http://localhost:3001/api/v1/auth/google/callback
```

### 3. Main Project (.env)
**File**: `/home/rayu/das-tern/.env`

```env
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
```

---

## Backend Implementation (NestJS)

### 1. Install Required Packages

```bash
cd backend_nestjs
npm install @nestjs/passport passport passport-google-oauth20
npm install --save-dev @types/passport-google-oauth20
```

### 2. Create Google Strategy

**File**: `src/auth/strategies/google.strategy.ts`

```typescript
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(private configService: ConfigService) {
    super({
      clientID: configService.get('GOOGLE_CLIENT_ID'),
      clientSecret: configService.get('GOOGLE_CLIENT_SECRET'),
      callbackURL: configService.get('GOOGLE_CALLBACK_URL'),
      scope: ['email', 'profile'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: any,
    done: VerifyCallback,
  ): Promise<any> {
    const { name, emails, photos } = profile;
    const user = {
      email: emails[0].value,
      firstName: name.givenName,
      lastName: name.familyName,
      picture: photos[0].value,
      accessToken,
    };
    done(null, user);
  }
}
```

### 3. Create Auth Controller

**File**: `src/auth/auth.controller.ts`

```typescript
import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Controller('auth')
export class AuthController {
  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth(@Req() req) {
    // Initiates Google OAuth flow
  }

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthRedirect(@Req() req) {
    // Handle Google OAuth callback
    return {
      message: 'User information from Google',
      user: req.user,
    };
  }
}
```

### 4. Register Strategy in Auth Module

**File**: `src/auth/auth.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { GoogleStrategy } from './strategies/google.strategy';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  imports: [PassportModule],
  controllers: [AuthController],
  providers: [AuthService, GoogleStrategy],
})
export class AuthModule {}
```

---

## Mobile App Implementation (Flutter)

### 1. Add Google Sign-In Package

**File**: `pubspec.yaml`

```yaml
dependencies:
  google_sign_in: ^6.2.1
```

### 2. Configure Android

**File**: `android/app/build.gradle`

Add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

**File**: `android/build.gradle`

Add to dependencies:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

### 3. Create Google Sign-In Service

**File**: `lib/services/google_auth_service.dart`

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._init();
  GoogleAuthService._init();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      print('Error signing in with Google: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
```

### 4. Update Login Screen

**File**: `lib/ui/screens/auth_ui/login_screen.dart`

Add Google Sign-In button:

```dart
import '../../services/google_auth_service.dart';

// In the build method, add:
ElevatedButton.icon(
  onPressed: () async {
    final account = await GoogleAuthService.instance.signIn();
    if (account != null) {
      // Send account.id and account.email to backend
      // Backend will verify and create/login user
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  },
  icon: Icon(Icons.login),
  label: Text('Sign in with Google'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
)
```

---

## OAuth Flow

### 1. Web/Backend Flow
```
User clicks "Sign in with Google"
    ↓
Redirect to: http://localhost:3001/api/v1/auth/google
    ↓
Google login page
    ↓
User authenticates
    ↓
Redirect to: http://localhost:3001/api/v1/auth/google/callback
    ↓
Backend receives user info
    ↓
Create/login user
    ↓
Return JWT token
```

### 2. Mobile App Flow
```
User taps "Sign in with Google"
    ↓
Google Sign-In SDK opens
    ↓
User authenticates
    ↓
App receives Google account info
    ↓
Send to backend: POST /api/v1/auth/google/mobile
    ↓
Backend verifies with Google
    ↓
Return JWT token
    ↓
Navigate to dashboard
```

---

## API Endpoints

### Backend Endpoints

```typescript
// Initiate Google OAuth (Web)
GET /api/v1/auth/google

// Google OAuth callback (Web)
GET /api/v1/auth/google/callback

// Mobile Google Sign-In
POST /api/v1/auth/google/mobile
Body: {
  "idToken": "google-id-token",
  "email": "user@example.com"
}
```

---

## Security Considerations

### 1. Client Secret
- ⚠️ **Never expose** client secret in mobile app
- ✅ Only use in backend
- ✅ Mobile app only needs client ID

### 2. Token Verification
- Backend must verify Google ID token
- Use Google's token verification API
- Check token expiration

### 3. HTTPS in Production
- Use HTTPS for all OAuth redirects
- Update redirect URIs in Google Console
- Update .env files for production

---

## Production Configuration

### Update Google Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project: decoded-shadow-467701-c9
3. Navigate to: APIs & Services → Credentials
4. Add authorized redirect URIs:
   ```
   https://api.dastern.com/api/v1/auth/google/callback
   ```
5. Add authorized JavaScript origins:
   ```
   https://dastern.com
   https://api.dastern.com
   ```

### Update .env Files

**Production .env**:
```env
GOOGLE_CLIENT_ID=843394511734-ub1dp6r0gmrga6utud5bfktael59bfiu.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GOOGLE_CALLBACK_URL=https://api.dastern.com/api/v1/auth/google/callback
```

---

## Testing

### 1. Test Backend OAuth Flow

```bash
# Start backend
cd backend_nestjs
npm run start:dev

# Open browser
http://localhost:3001/api/v1/auth/google
```

### 2. Test Mobile App

```bash
# Run app
cd mobile_app
flutter run

# Tap "Sign in with Google" button
# Should open Google sign-in
```

---

## Troubleshooting

### Error: redirect_uri_mismatch
**Solution**: Ensure redirect URI in Google Console matches exactly:
```
http://localhost:3001/api/v1/auth/google/callback
```

### Error: invalid_client
**Solution**: Check client ID and secret are correct in .env

### Mobile app not opening Google Sign-In
**Solution**: 
- Ensure google_sign_in package is installed
- Check Android/iOS configuration
- Verify client ID in .env

---

## Summary

✅ **Configuration**: Complete  
✅ **Backend .env**: Updated  
✅ **Mobile .env**: Updated  
✅ **Main .env**: Updated  

**Next Steps**:
1. Install required packages in backend
2. Implement Google Strategy in NestJS
3. Add google_sign_in to Flutter app
4. Test OAuth flow
5. Update for production URLs

---

**Status**: ✅ Google OAuth credentials configured and ready!

**Last Updated**: February 9, 2026, 12:55
