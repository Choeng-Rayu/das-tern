import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  health(): object {
    return {
      status: 'healthy',
      service: 'dastern-backend',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }
}
