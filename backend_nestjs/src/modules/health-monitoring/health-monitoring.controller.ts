import {
  Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { HealthMonitoringService } from './health-monitoring.service';
import { RecordVitalDto, QueryVitalsDto, UpdateThresholdDto, TriggerEmergencyDto } from './dto';

@Controller('health-monitoring')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class HealthMonitoringController {
  constructor(private service: HealthMonitoringService) {}

  // ── Vitals CRUD ──

  @Post('vitals')
  @Roles('PATIENT')
  async recordVital(@CurrentUser() user: any, @Body() dto: RecordVitalDto) {
    return this.service.recordVital(user.id, dto);
  }

  @Get('vitals')
  async getVitals(@CurrentUser() user: any, @Query() query: QueryVitalsDto) {
    return this.service.getVitals(user.id, query);
  }

  @Get('vitals/latest')
  async getLatestVitals(@CurrentUser() user: any) {
    return this.service.getLatestVitals(user.id);
  }

  @Get('vitals/:id')
  async getVitalById(@Param('id') id: string, @CurrentUser() user: any) {
    return this.service.getVitalById(id, user.id);
  }

  @Delete('vitals/:id')
  @Roles('PATIENT')
  async deleteVital(@Param('id') id: string, @CurrentUser() user: any) {
    return this.service.deleteVital(id, user.id);
  }

  // ── Trends ──

  @Get('trends')
  async getTrends(@CurrentUser() user: any, @Query() query: QueryVitalsDto) {
    return this.service.getTrends(user.id, query);
  }

  @Get('trends/:patientId')
  @Roles('DOCTOR')
  async getPatientTrends(
    @Param('patientId') patientId: string,
    @CurrentUser() user: any,
    @Query() query: QueryVitalsDto,
  ) {
    return this.service.getPatientTrends(user.id, patientId, query);
  }

  // ── Thresholds ──

  @Get('thresholds')
  async getThresholds(@CurrentUser() user: any) {
    return this.service.getThresholds(user.id);
  }

  @Put('thresholds')
  @Roles('PATIENT')
  async updateThreshold(@CurrentUser() user: any, @Body() dto: UpdateThresholdDto) {
    return this.service.updateThreshold(user.id, dto);
  }

  // ── Alerts ──

  @Get('alerts')
  async getAlerts(
    @CurrentUser() user: any,
    @Query('resolved') resolved?: string,
  ) {
    const resolvedBool = resolved === 'true' ? true : resolved === 'false' ? false : undefined;
    return this.service.getAlerts(user.id, resolvedBool);
  }

  @Post('alerts/:id/resolve')
  async resolveAlert(@Param('id') id: string, @CurrentUser() user: any) {
    return this.service.resolveAlert(id, user.id);
  }

  // ── Emergency ──

  @Post('emergency')
  @Roles('PATIENT')
  async triggerEmergency(@CurrentUser() user: any, @Body() dto: TriggerEmergencyDto) {
    return this.service.triggerEmergency(user.id, dto);
  }

  // ── Patient vitals for connected doctor/family ──

  @Get('patients/:patientId/vitals')
  async getPatientVitals(
    @Param('patientId') patientId: string,
    @CurrentUser() user: any,
    @Query() query: QueryVitalsDto,
  ) {
    return this.service.getPatientVitals(user.id, patientId, query);
  }
}
