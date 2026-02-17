import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { BatchMedicationService } from './batch-medication.service';
import { CreateBatchDto, BatchMedicationItemDto } from './dto';
import { UpdateBatchDto } from './dto';

@Controller('batch-medications')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles(UserRole.PATIENT)
export class BatchMedicationController {
  constructor(private readonly batchService: BatchMedicationService) {}

  @Post()
  create(@CurrentUser() user: any, @Body() dto: CreateBatchDto) {
    return this.batchService.createBatch(user.id, dto);
  }

  @Get()
  findAll(@CurrentUser() user: any) {
    return this.batchService.findAllBatches(user.id);
  }

  @Get(':id')
  findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.batchService.findOneBatch(id, user.id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateBatchDto,
  ) {
    return this.batchService.updateBatch(id, user.id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser() user: any, @Param('id') id: string) {
    return this.batchService.deleteBatch(id, user.id);
  }

  @Post(':id/medicines')
  addMedicine(
    @CurrentUser() user: any,
    @Param('id') batchId: string,
    @Body() dto: BatchMedicationItemDto,
  ) {
    return this.batchService.addMedicineToBatch(batchId, user.id, dto);
  }

  @Delete(':id/medicines/:medicineId')
  removeMedicine(
    @CurrentUser() user: any,
    @Param('id') batchId: string,
    @Param('medicineId') medicineId: string,
  ) {
    return this.batchService.removeMedicineFromBatch(batchId, medicineId, user.id);
  }
}
