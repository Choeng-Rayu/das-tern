import { Controller, Get, Post, Patch, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { MedicinesService } from './medicines.service';
import { CreateMedicineDto, UpdateMedicineDto } from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller()
@UseGuards(AuthGuard('jwt'))
export class MedicinesController {
  constructor(private medicinesService: MedicinesService) {}

  @Post('prescriptions/:prescriptionId/medicines')
  async addMedicine(
    @Param('prescriptionId') prescriptionId: string,
    @CurrentUser() user: any,
    @Body() dto: CreateMedicineDto,
  ) {
    return this.medicinesService.addMedicine(prescriptionId, user.id, dto);
  }

  @Get('prescriptions/:prescriptionId/medicines')
  async getMedicines(
    @Param('prescriptionId') prescriptionId: string,
    @CurrentUser() user: any,
  ) {
    return this.medicinesService.getMedicines(prescriptionId, user.id);
  }

  @Get('medicines/:id')
  async getMedicineById(@Param('id') id: string, @CurrentUser() user: any) {
    return this.medicinesService.getMedicineById(id, user.id);
  }

  @Patch('medicines/:id')
  async updateMedicine(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() dto: UpdateMedicineDto,
  ) {
    return this.medicinesService.updateMedicine(id, user.id, dto);
  }

  @Delete('medicines/:id')
  async deleteMedicine(@Param('id') id: string, @CurrentUser() user: any) {
    return this.medicinesService.deleteMedicine(id, user.id);
  }

  @Get('medicines/archived')
  async getArchivedMedicines(@CurrentUser() user: any) {
    return this.medicinesService.getArchivedMedicines(user.id);
  }

  @Get('medicines/:id/doses')
  async getDosesForMedicine(@Param('id') id: string, @CurrentUser() user: any) {
    return this.medicinesService.getDosesForMedicine(id, user.id);
  }
}
