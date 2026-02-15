import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { OcrService } from './ocr.service';
import { OcrController } from './ocr.controller';
import { PrescriptionsModule } from '../prescriptions/prescriptions.module';

@Module({
  imports: [HttpModule, PrescriptionsModule],
  controllers: [OcrController],
  providers: [OcrService],
  exports: [OcrService],
})
export class OcrModule {}
