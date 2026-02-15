import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PrescriptionsService } from './prescriptions.service';
import { CreatePrescriptionDto, UpdatePrescriptionDto, CreatePatientPrescriptionDto } from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '@prisma/client';

@Controller('prescriptions')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class PrescriptionsController {
  constructor(private prescriptionsService: PrescriptionsService) {}

  @Get()
  async findAll(
    @CurrentUser() user: any,
    @Query('status') status?: string,
    @Query('patientId') patientId?: string,
  ) {
    return this.prescriptionsService.findAll(user.id, user.role, { status, patientId });
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.prescriptionsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.DOCTOR)
  async create(@CurrentUser() user: any, @Body() dto: CreatePrescriptionDto) {
    return this.prescriptionsService.create(user.id, dto);
  }

  @Post('patient')
  @Roles(UserRole.PATIENT)
  async createPatientPrescription(
    @CurrentUser() user: any,
    @Body() dto: CreatePatientPrescriptionDto,
  ) {
    return this.prescriptionsService.createPatientPrescription(user.id, dto);
  }

  @Patch(':id')
  @Roles(UserRole.DOCTOR)
  async update(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: UpdatePrescriptionDto) {
    return this.prescriptionsService.update(id, user.id, dto);
  }

  @Post(':id/urgent-update')
  @Roles(UserRole.DOCTOR)
  async urgentUpdate(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: UpdatePrescriptionDto) {
    return this.prescriptionsService.urgentUpdate(id, user.id, dto);
  }

  @Post(':id/confirm')
  @Roles(UserRole.PATIENT)
  async confirm(@Param('id') id: string, @CurrentUser() user: any) {
    return this.prescriptionsService.confirm(id, user.id);
  }

  @Post(':id/retake')
  @Roles(UserRole.PATIENT)
  async retake(@Param('id') id: string, @CurrentUser() user: any, @Body('reason') reason: string) {
    return this.prescriptionsService.retake(id, user.id, reason);
  }

  @Delete(':id')
  @Roles(UserRole.PATIENT)
  async deletePrescription(@Param('id') id: string, @CurrentUser() user: any) {
    return this.prescriptionsService.deletePrescription(id, user.id);
  }

  @Post(':id/pause')
  @Roles(UserRole.PATIENT)
  async pausePrescription(@Param('id') id: string, @CurrentUser() user: any) {
    return this.prescriptionsService.pausePrescription(id, user.id);
  }

  @Post(':id/resume')
  @Roles(UserRole.PATIENT)
  async resumePrescription(@Param('id') id: string, @CurrentUser() user: any) {
    return this.prescriptionsService.resumePrescription(id, user.id);
  }

  @Post(':id/reject')
  @Roles(UserRole.PATIENT)
  async rejectPrescription(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body('reason') reason?: string,
  ) {
    return this.prescriptionsService.rejectPrescription(id, user.id, reason);
  }
}
