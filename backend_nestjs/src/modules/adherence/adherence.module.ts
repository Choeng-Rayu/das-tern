import { Module } from '@nestjs/common';
import { AdherenceService } from './adherence.service';
import { AdherenceController } from './adherence.controller';

@Module({
  controllers: [AdherenceController],
  providers: [AdherenceService],
  exports: [AdherenceService],
})
export class AdherenceModule {}
