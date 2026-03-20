import { Controller, Post, Body, UseGuards, Get, Req, Query, Res } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Throttle } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';
import { Response } from 'express';
import { AuthService } from './auth.service';
import { OtpService } from './otp.service';
import { EmailService } from '../email/email.service';
import {
  LoginDto,
  RegisterPatientDto,
  RegisterDoctorDto,
  RefreshTokenDto,
  SendOtpDto,
  VerifyOtpDto,
  GoogleLoginDto,
  TelegramLoginDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  ChangePasswordDto
} from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private otpService: OtpService,
    private emailService: EmailService,
    private configService: ConfigService,
  ) {}

  @Post('login')
  @Throttle({ default: { limit: 20, ttl: 60000 } }) // 20 attempts per minute (dev)
  async login(@Body() loginDto: LoginDto) {
    const user = await this.authService.validateUser(
      loginDto.identifier,
      loginDto.password,
    );
    return this.authService.login(user);
  }

  @Post('register/patient')
  @Throttle({ default: { limit: 20, ttl: 60000 } }) // 20 registrations per minute (dev)
  async registerPatient(@Body() dto: RegisterPatientDto) {
    return this.authService.registerPatient(dto);
  }

  @Post('register/doctor')
  @Throttle({ default: { limit: 20, ttl: 60000 } }) // 20 registrations per minute (dev)
  async registerDoctor(@Body() dto: RegisterDoctorDto) {
    return this.authService.registerDoctor(dto);
  }

  @Post('otp/send')
  @Throttle({ default: { limit: 3, ttl: 300000 } }) // 3 OTP requests per 5 minutes
  async sendOtp(@Body() dto: SendOtpDto) {
    if (dto.identifier.includes('@')) {
      // Email-based OTP: generate, store, and send via email
      const otp = this.otpService.generateOtp();
      this.otpService.storeOtp(dto.identifier, otp);
      await this.emailService.sendOTP(dto.identifier, otp);
      return { message: 'OTP sent to email', expiresIn: 300 };
    } else {
      // Phone-based OTP: generate, store, and log (SMS integration pending)
      const result = await this.otpService.sendOtp(dto.identifier);
      return { message: 'OTP sent successfully', expiresIn: result.expiresIn };
    }
  }

  @Post('otp/verify')
  @Throttle({ default: { limit: 5, ttl: 300000 } }) // 5 OTP verifications per 5 minutes
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto.identifier, dto.otp);
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }

  @Post('google')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 attempts per minute
  async googleLoginMobile(@Body() dto: GoogleLoginDto) {
    return this.authService.googleLoginMobile(dto.idToken, dto.userRole);
  }

  @Post('telegram')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 attempts per minute
  async telegramLoginMobile(@Body() dto: TelegramLoginDto) {
    return this.authService.telegramLoginMobile(
      dto.code,
      dto.codeVerifier,
      dto.redirectUri,
      dto.userRole,
    );
  }

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

    const redirect = new URL(appRedirectUri);
    if (code) {
      redirect.searchParams.set('code', code);
    }
    if (state) {
      redirect.searchParams.set('state', state);
    }
    if (error) {
      redirect.searchParams.set('error', error);
    }

    this.authService.logTelegramCallback({ code, state, error });

    const deepLinkUrl = redirect.toString();

    // Use HTML page for reliable deep link opening on mobile browsers.
    // Raw 302 redirects to custom URI schemes (dastern://) are often blocked
    // by browsers on Android/iOS. An HTML page with JS + fallback link works
    // across all platforms.
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Opening Das Tern...</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%);
      padding: 20px;
    }
    .card {
      background: white;
      border-radius: 20px;
      padding: 40px 32px;
      text-align: center;
      max-width: 360px;
      width: 100%;
      box-shadow: 0 8px 32px rgba(21,101,192,0.12);
    }
    .icon { font-size: 60px; margin-bottom: 16px; }
    h2 { color: #1565C0; font-size: 22px; margin-bottom: 8px; }
    p { color: #666; font-size: 14px; line-height: 1.5; margin-bottom: 24px; }
    .btn {
      display: inline-block;
      padding: 14px 32px;
      background: #1565C0;
      color: white;
      border-radius: 30px;
      font-size: 16px;
      font-weight: 600;
      text-decoration: none;
      transition: background 0.2s;
    }
    .btn:hover { background: #0D47A1; }
    .spinner {
      width: 32px; height: 32px;
      border: 3px solid #E3F2FD;
      border-top: 3px solid #1565C0;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      margin: 0 auto 16px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">💊</div>
    <h2>Telegram Login Successful</h2>
    <div class="spinner"></div>
    <p>Opening Das Tern app... If it does not open automatically, tap the button below.</p>
    <a href="${deepLinkUrl}" class="btn">Open Das Tern</a>
  </div>
  <script>
    // Attempt deep link immediately
    window.location.href = '${deepLinkUrl}';
    // Hide spinner after 2s if still on page
    setTimeout(() => {
      const s = document.querySelector('.spinner');
      if (s) s.style.display = 'none';
    }, 2000);
  </script>
</body>
</html>`;

    return res.status(200).header('Content-Type', 'text/html').send(html);
  }

  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth() {
    // Initiates Google OAuth flow
  }

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthCallback(@Req() req: any) {
    return this.authService.googleLogin(req.user);
  }

  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  async getProfile(@CurrentUser() user: any) {
    return user;
  }

  @Post('forgot-password')
  @Throttle({ default: { limit: 3, ttl: 300000 } }) // 3 requests per 5 minutes
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto.identifier);
  }

  @Post('reset-password')
  @Throttle({ default: { limit: 5, ttl: 300000 } }) // 5 attempts per 5 minutes
  async resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto.token, dto.newPassword);
  }

  @Post('reset-password-otp')
  @Throttle({ default: { limit: 5, ttl: 300000 } })
  async resetPasswordWithOtp(
    @Body() body: { identifier: string; otp: string; newPassword: string },
  ) {
    return this.authService.resetPasswordWithOtp(
      body.identifier,
      body.otp,
      body.newPassword,
    );
  }

  @Post('change-password')
  @UseGuards(AuthGuard('jwt'))
  @Throttle({ default: { limit: 5, ttl: 300000 } })
  async changePassword(
    @CurrentUser() user: any,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(
      user.id,
      dto.currentPassword,
      dto.newPassword,
    );
  }
}
