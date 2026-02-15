import { Controller, Post, Body, UseGuards, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';
import { Throttle } from '@nestjs/throttler';
import { EmailService } from './email.service';
import { SendEmailDto, SendWelcomeEmailDto } from './dto/send-email.dto';

@Controller('email')
export class EmailController {
  constructor(
    private emailService: EmailService,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
  ) {}

  @Post('test')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 requests per minute
  async sendTestEmail(@Body() dto: SendEmailDto) {
    await this.emailService.sendTestEmail(dto.email);
    return { 
      success: true,
      message: 'Test email sent successfully',
      email: dto.email 
    };
  }

  @Post('send-otp')
  @Throttle({ default: { limit: 3, ttl: 300000 } }) // 3 requests per 5 minutes
  async sendOTP(@Body() dto: SendEmailDto) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await this.emailService.sendOTP(dto.email, otp);

    // Store OTP in Redis with 10 minute expiry
    await this.cacheManager.set(`otp:email:${dto.email}`, otp, 600);

    return {
      success: true,
      message: 'OTP sent successfully'
    };
  }

  @Post('welcome')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests per minute
  async sendWelcomeEmail(@Body() dto: SendWelcomeEmailDto) {
    await this.emailService.sendWelcomeEmail(dto.email, dto.name);
    return { 
      success: true,
      message: 'Welcome email sent successfully' 
    };
  }
}
