import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { EmailService } from './email.service';
import { SendEmailDto, SendWelcomeEmailDto } from './dto/send-email.dto';

@Controller('email')
export class EmailController {
  constructor(private emailService: EmailService) {}

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
    
    // TODO: Store OTP in Redis/database for verification
    // await this.cacheManager.set(`otp:${dto.email}`, otp, 600);
    
    return { 
      success: true,
      message: 'OTP sent successfully'
      // ⚠️ OTP removed from response for security
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
