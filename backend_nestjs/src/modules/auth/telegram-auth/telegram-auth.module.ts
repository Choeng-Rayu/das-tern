import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TelegramAuthService } from './telegram-auth.service';
import { TelegramHashVerifier } from './telegram-hash-verifier.service';

@Module({
  imports: [JwtModule, ConfigModule],
  providers: [TelegramAuthService, TelegramHashVerifier],
  exports: [TelegramAuthService],
})
export class TelegramAuthModule {}