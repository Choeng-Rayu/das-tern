import {
  Controller,
  Post,
  Get,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import { HttpService } from '@nestjs/axios';
import { OcrService } from './ocr.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '@prisma/client';
import { firstValueFrom } from 'rxjs';

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const ALLOWED_MIMETYPES = ['image/png', 'image/jpeg', 'image/jpg', 'application/pdf'];

@Controller('ocr')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class OcrController {
  constructor(
    private ocrService: OcrService,
    private httpService: HttpService,
  ) {}

  /**
   * POST /ocr/scan
   * Upload a prescription image, extract data via OCR, and create a prescription.
   * Available to PATIENT role.
   */
  @Post('scan')
  @Roles(UserRole.PATIENT)
  @UseInterceptors(FileInterceptor('file'))
  async scanPrescription(
    @CurrentUser() user: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded. Send a prescription image as multipart "file" field.');
    }

    if (file.size > MAX_FILE_SIZE) {
      throw new BadRequestException(`File too large. Maximum size is ${MAX_FILE_SIZE / 1024 / 1024}MB.`);
    }

    if (!ALLOWED_MIMETYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `Unsupported file type: ${file.mimetype}. Use PNG, JPEG, or PDF.`,
      );
    }

    return this.ocrService.scanAndCreatePrescription(
      user.id,
      file.buffer,
      file.originalname,
      file.mimetype,
    );
  }

  /**
   * POST /ocr/extract
   * Extract prescription data from image without creating a prescription.
   * Returns the raw OCR extraction result for preview/review before saving.
   * Available to PATIENT role.
   */
  @Post('extract')
  @Roles(UserRole.PATIENT)
  @UseInterceptors(FileInterceptor('file'))
  async extractOnly(
    @CurrentUser() user: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded.');
    }

    if (file.size > MAX_FILE_SIZE) {
      throw new BadRequestException(`File too large. Maximum size is ${MAX_FILE_SIZE / 1024 / 1024}MB.`);
    }

    if (!ALLOWED_MIMETYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `Unsupported file type: ${file.mimetype}. Use PNG, JPEG, or PDF.`,
      );
    }

    return this.ocrService.extractPrescription(file.buffer, file.originalname, file.mimetype);
  }

  /**
   * GET /ocr/health
   * Check if the OCR service is available.
   */
  @Get('health')
  async checkOcrHealth() {
    try {
      const { data } = await firstValueFrom(
        this.httpService.get(`${this.ocrService.ocrBaseUrl}/api/v1/health`, { timeout: 5000 }),
      );
      return { status: 'ok', ocr_service: data };
    } catch {
      return { status: 'unavailable', message: 'Cannot connect to OCR service' };
    }
  }
}
