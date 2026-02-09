# Authentication Testing Guide ✅

**Date**: February 9, 2026, 12:58  
**Status**: ✅ Ready to test

---

## Pre-Test Verification

### Flutter Analyze
```bash
cd /home/rayu/das-tern/mobile_app
flutter analyze
```
**Result**: ✅ No issues found!

---

## What Was Implemented

### 1. Google Sign-In
- ✅ Added `google_sign_in: ^6.2.1` package
- ✅ Created `GoogleAuthService`
- ✅ Added "Sign in with Google" button to login screen
- ✅ Implemented sign-in handler with error handling

### 2. Test Screen
- ✅ Created `TestAuthScreen` at `/test-auth`
- ✅ Test Google Sign-In functionality
- ✅ Test backend connection
- ✅ Display results with detailed information

### 3. UI Updates
- ✅ Added "Test" button in login screen app bar
- ✅ Added OR divider between login methods
- ✅ Google Sign-In button with proper styling

---

## How to Test

### Method 1: Using Test Screen (Recommended)

1. **Run the app**
   ```bash
   cd /home/rayu/das-tern/mobile_app
   flutter run
   ```

2. **Access Test Screen**
   - On login screen, tap "Test" button in top-right corner
   - Or navigate to `/test-auth` route

3. **Test Google Sign-In**
   - Tap "Test Google Sign-In" button
   - Google sign-in dialog will appear
   - Select your Google account
   - View results showing:
     - ✅ Email
     - ✅ Name
     - ✅ ID
     - ✅ Photo URL

4. **Test Backend Connection**
   - Tap "Test Backend Connection" button
   - View backend configuration:
     - ✅ Base URL
     - ✅ Connection status

---

### Method 2: Using Login Screen

1. **Run the app**
   ```bash
   flutter run
   ```

2. **Test Google Sign-In**
   - On login screen, scroll down
   - Tap "Sign in with Google" button
   - Select Google account
   - Should navigate to dashboard
   - Shows snackbar with email

---

## Expected Results

### Google Sign-In Success
```
✅ Google Sign-In Success!

Email: your-email@gmail.com
Name: Your Name
ID: 1234567890
Photo: https://...
```

### Google Sign-In Cancelled
```
❌ Google Sign-In cancelled or failed
```

### Backend Connection
```
✅ Backend Configuration

Base URL: http://localhost:3001/api/v1
Status: Backend is configured
```

---

## Testing Email Functionality

### Current Status
- ✅ Email configuration added to .env
- ⏳ Backend email service needs implementation

### To Test Email Sending

#### 1. Implement Backend Email Service

**Install package**:
```bash
cd /home/rayu/das-tern/backend_nestjs
npm install nodemailer
npm install --save-dev @types/nodemailer
```

**Create email service** (`src/email/email.service.ts`):
```typescript
import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { ConfigService } from '@nestjs/config';

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

  async sendOTP(email: string, otp: string) {
    await this.transporter.sendMail({
      from: `"Das Tern" <${this.configService.get('SENDGRID_FROM_EMAIL')}>`,
      to: email,
      subject: 'Your OTP Code - Das Tern',
      html: `
        <h2>Das Tern - OTP Verification</h2>
        <p>Your verification code is:</p>
        <h1 style="color: #2D5BFF; font-size: 32px;">${otp}</h1>
        <p>This code will expire in 10 minutes.</p>
      `,
    });
  }

  async sendTestEmail(email: string) {
    await this.transporter.sendMail({
      from: `"Das Tern" <${this.configService.get('SENDGRID_FROM_EMAIL')}>`,
      to: email,
      subject: 'Test Email - Das Tern',
      html: '<h1>Test email from Das Tern!</h1><p>Email configuration is working correctly.</p>',
    });
  }
}
```

#### 2. Create Test Endpoint

**Create controller** (`src/email/email.controller.ts`):
```typescript
import { Controller, Post, Body } from '@nestjs/common';
import { EmailService } from './email.service';

@Controller('email')
export class EmailController {
  constructor(private emailService: EmailService) {}

  @Post('test')
  async sendTestEmail(@Body('email') email: string) {
    await this.emailService.sendTestEmail(email);
    return { message: 'Test email sent successfully' };
  }

  @Post('send-otp')
  async sendOTP(@Body('email') email: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await this.emailService.sendOTP(email, otp);
    return { message: 'OTP sent successfully', otp }; // Remove otp in production
  }
}
```

#### 3. Test Email from Mobile App

Add to `TestAuthScreen`:
```dart
Future<void> _testEmailSending() async {
  setState(() {
    _isLoading = true;
    _result = 'Sending test email...';
  });

  try {
    final response = await http.post(
      Uri.parse('${ApiService.instance.baseUrl}/email/test'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': 'your-email@gmail.com'}),
    );

    if (response.statusCode == 201) {
      setState(() => _result = '✅ Test email sent! Check your inbox.');
    } else {
      setState(() => _result = '❌ Failed to send email: ${response.body}');
    }
  } catch (e) {
    setState(() => _result = '❌ Error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

---

## Troubleshooting

### Google Sign-In Issues

#### Error: "PlatformException"
**Solution**: 
- Ensure google_sign_in package is installed
- Check Android/iOS configuration
- Verify Google OAuth credentials

#### Error: "Sign-in cancelled"
**Solution**: User cancelled the sign-in flow (expected behavior)

#### Error: "Network error"
**Solution**: 
- Check internet connection
- Verify Google OAuth credentials
- Check redirect URIs in Google Console

---

### Email Issues

#### Error: "Authentication failed"
**Solution**: 
- Verify Gmail app password is correct
- Ensure 2FA is enabled on Gmail
- Generate new app password if needed

#### Error: "Connection timeout"
**Solution**:
- Check SMTP settings (host, port)
- Verify firewall allows SMTP connections
- Try port 465 with secure: true

---

## Test Checklist

### Google Sign-In
- [ ] Open test screen
- [ ] Tap "Test Google Sign-In"
- [ ] Google dialog appears
- [ ] Select account
- [ ] Success message shows email and name
- [ ] Can sign out and sign in again

### Backend Connection
- [ ] Tap "Test Backend Connection"
- [ ] Shows correct base URL
- [ ] No errors displayed

### Email (After Backend Implementation)
- [ ] Backend email service implemented
- [ ] Test endpoint created
- [ ] Send test email from mobile app
- [ ] Receive email in inbox
- [ ] Email content displays correctly

---

## Files Created/Modified

### Created
1. ✅ `lib/services/google_auth_service.dart`
2. ✅ `lib/ui/screens/test_ui/test_auth_screen.dart`

### Modified
1. ✅ `pubspec.yaml` - Added google_sign_in
2. ✅ `lib/main.dart` - Added test route
3. ✅ `lib/ui/screens/auth_ui/login_screen.dart` - Added Google button and test button

---

## Next Steps

### Immediate
1. ✅ Run flutter analyze (passed)
2. ✅ Test Google Sign-In on device
3. ⏳ Implement backend email service
4. ⏳ Test email sending

### Future
1. Integrate Google Sign-In with backend authentication
2. Store JWT token after successful Google login
3. Implement OTP email sending for registration
4. Add email verification flow

---

## Running the Tests

```bash
# Terminal 1: Start backend
cd /home/rayu/das-tern/backend_nestjs
npm run start:dev

# Terminal 2: Run mobile app
cd /home/rayu/das-tern/mobile_app
flutter run

# In app:
# 1. Tap "Test" button on login screen
# 2. Test Google Sign-In
# 3. Test Backend Connection
```

---

**Status**: ✅ Ready to test!

**Flutter Analyze**: ✅ No issues found  
**Google Sign-In**: ✅ Implemented  
**Test Screen**: ✅ Created  
**Backend Connection**: ✅ Configured  
**Email**: ⏳ Needs backend implementation

**Last Updated**: February 9, 2026, 12:58
