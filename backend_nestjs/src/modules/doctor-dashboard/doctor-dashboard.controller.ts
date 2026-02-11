import {
  Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { DoctorDashboardService } from './doctor-dashboard.service';
import { DoctorNotesService } from './doctor-notes.service';
import { CreateDoctorNoteDto, UpdateDoctorNoteDto, PatientListQueryDto, AdherenceQueryDto } from './dto';

@Controller('doctor')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles(UserRole.DOCTOR)
export class DoctorDashboardController {
  constructor(
    private dashboardService: DoctorDashboardService,
    private notesService: DoctorNotesService,
  ) {}

  // ── Dashboard Overview ──

  @Get('dashboard')
  async getDashboard(@CurrentUser() user: any) {
    return this.dashboardService.getDashboardOverview(user.id);
  }

  // ── Patient Management ──

  @Get('patients')
  async getPatients(@CurrentUser() user: any, @Query() query: PatientListQueryDto) {
    return this.dashboardService.getPatientList(user.id, query);
  }

  @Get('patients/:patientId/details')
  async getPatientDetails(
    @CurrentUser() user: any,
    @Param('patientId') patientId: string,
  ) {
    return this.dashboardService.getPatientDetails(user.id, patientId);
  }

  @Get('patients/:patientId/adherence')
  async getPatientAdherence(
    @CurrentUser() user: any,
    @Param('patientId') patientId: string,
    @Query() query: AdherenceQueryDto,
  ) {
    return this.dashboardService.getPatientAdherence(
      user.id, patientId, query.startDate, query.endDate,
    );
  }

  // ── Connection Management ──

  @Get('connections/pending')
  async getPendingConnections(@CurrentUser() user: any) {
    return this.dashboardService.getPendingRequests(user.id);
  }

  @Post('connections/:connectionId/accept')
  async acceptConnection(
    @CurrentUser() user: any,
    @Param('connectionId') connectionId: string,
  ) {
    return this.dashboardService.acceptConnectionRequest(user.id, connectionId);
  }

  @Post('connections/:connectionId/reject')
  async rejectConnection(
    @CurrentUser() user: any,
    @Param('connectionId') connectionId: string,
    @Body('reason') reason?: string,
  ) {
    return this.dashboardService.rejectConnectionRequest(user.id, connectionId, reason);
  }

  @Post('connections/:connectionId/disconnect')
  async disconnectPatient(
    @CurrentUser() user: any,
    @Param('connectionId') connectionId: string,
    @Body('reason') reason: string,
  ) {
    return this.dashboardService.disconnectPatient(user.id, connectionId, reason);
  }

  // ── Doctor Notes ──

  @Post('notes')
  async createNote(@CurrentUser() user: any, @Body() dto: CreateDoctorNoteDto) {
    return this.notesService.create(user.id, dto);
  }

  @Get('notes')
  async getNotes(
    @CurrentUser() user: any,
    @Query('patientId') patientId: string,
  ) {
    return this.notesService.findAll(user.id, patientId);
  }

  @Patch('notes/:noteId')
  async updateNote(
    @CurrentUser() user: any,
    @Param('noteId') noteId: string,
    @Body() dto: UpdateDoctorNoteDto,
  ) {
    return this.notesService.update(noteId, user.id, dto);
  }

  @Delete('notes/:noteId')
  async deleteNote(
    @CurrentUser() user: any,
    @Param('noteId') noteId: string,
  ) {
    return this.notesService.delete(noteId, user.id);
  }

  // ── Doctor Prescriptions ──

  @Get('prescriptions')
  async getPrescriptions(
    @CurrentUser() user: any,
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.dashboardService.getDoctorPrescriptions(user.id, {
      status,
      page: page ? parseInt(page, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }

  @Get('prescriptions/:prescriptionId')
  async getPrescriptionDetail(
    @CurrentUser() user: any,
    @Param('prescriptionId') prescriptionId: string,
  ) {
    return this.dashboardService.getDoctorPrescriptionDetail(user.id, prescriptionId);
  }
}
