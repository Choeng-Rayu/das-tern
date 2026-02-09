import { Controller, Post, Body, UseGuards, Get, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { OtpService } from './otp.service';
import { 
  LoginDto, 
  RegisterPatientDto, 
  RegisterDoctorDto, 
  RefreshTokenDto,
  SendOtpDto,
  VerifyOtpDto 
} from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private otpService: OtpService,
  ) {}

  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 attempts per minute
  async login(@Body() loginDto: LoginDto) {
    const user = await this.authService.validateUser(
      loginDto.phoneNumber,
      loginDto.password,
    );
    return this.authService.login(user);
  }

  @Post('register/patient')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 registrations per minute
  async registerPatient(@Body() dto: RegisterPatientDto) {
    return this.authService.registerPatient(dto);
  }

  @Post('register/doctor')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 registrations per minute
  async registerDoctor(@Body() dto: RegisterDoctorDto) {
    return this.authService.registerDoctor(dto);
  }

  @Post('otp/send')
  @Throttle({ default: { limit: 3, ttl: 300000 } }) // 3 OTP requests per 5 minutes
  async sendOtp(@Body() dto: SendOtpDto) {
    const result = await this.otpService.sendOtp(dto.phoneNumber);
    return {
      message: 'OTP sent successfully',
      expiresIn: result.expiresIn,
    };
  }

  @Post('otp/verify')
  @Throttle({ default: { limit: 5, ttl: 300000 } }) // 5 OTP verifications per 5 minutes
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto.phoneNumber, dto.otp);
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto.refreshToken);
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
}
