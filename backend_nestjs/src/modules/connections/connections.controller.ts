import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards, ForbiddenException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ConnectionsService } from './connections.service';
import { ConnectionTokenService, TargetRole } from './connection-token.service';
import { NudgeService } from './nudge.service';
import { CreateConnectionDto, AcceptConnectionDto, GenerateTokenDto, ValidateTokenDto, ConsumeTokenDto, DoctorConsumeTokenDto, SendNudgeDto, NudgeResponseDto } from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { PermissionLevel } from '@prisma/client';

@Controller('connections')
@UseGuards(AuthGuard('jwt'))
export class ConnectionsController {
  constructor(
    private connectionsService: ConnectionsService,
    private tokenService: ConnectionTokenService,
    private nudgeService: NudgeService,
  ) {}

  @Get()
  async findAll(@CurrentUser() user: any, @Query('status') status?: string) {
    return this.connectionsService.findAll(user.id, status);
  }

  @Post()
  async create(@CurrentUser() user: any, @Body() dto: CreateConnectionDto) {
    return this.connectionsService.create(user.id, dto);
  }

  @Patch(':id/accept')
  async accept(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: AcceptConnectionDto) {
    return this.connectionsService.accept(id, user.id, dto);
  }

  @Patch(':id/revoke')
  async revoke(@Param('id') id: string, @CurrentUser() user: any) {
    return this.connectionsService.revoke(id, user.id);
  }

  @Patch(':id/permission')
  async updatePermission(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body('permissionLevel') permissionLevel: PermissionLevel,
  ) {
    return this.connectionsService.updatePermission(id, user.id, permissionLevel);
  }

  // ============================
  // Token Endpoints
  // ============================

  /**
   * Generate a connection token for a patient.
   * The token is ROLE-AGNOSTIC - whoever scans it (doctor or family member)
   * will create the appropriate connection type based on THEIR role.
   * @param targetRole - DEPRECATED: Kept for backward compatibility but ignored
   */
  @Post('tokens/generate')
  async generateToken(@CurrentUser() user: any, @Body() dto: GenerateTokenDto) {
    const targetRole = (dto.targetRole as TargetRole) || 'FAMILY_MEMBER';
    return this.tokenService.generateToken(user.id, dto.permissionLevel, targetRole);
  }

  /**
   * Validate a connection token and return its details.
   * Returns token info - the consuming app uses this to show patient preview.
   */
  @Post('tokens/validate')
  async validateToken(@Body() dto: ValidateTokenDto) {
    return this.tokenService.validateToken(dto.token);
  }

  /**
   * Consume a token to create a pending connection.
   * The connection type is determined by the CONSUMER'S role:
   * - DOCTOR -> creates doctor connection (limited access)
   * - FAMILY_MEMBER -> creates family connection (permission level from token)
   */
  @Post('tokens/consume')
  async consumeToken(@CurrentUser() user: any, @Body() dto: ConsumeTokenDto) {
    return this.tokenService.consumeToken(dto.token, user.id);
  }

  /**
   * Doctor-specific endpoint to consume a patient-generated token.
   * This is an alias for /tokens/consume but validates the user is a DOCTOR first.
   * Flow: Patient generates token/QR -> Doctor scans and consumes -> Patient approves
   */
  @Post('tokens/doctor-consume')
  async doctorConsumeToken(@CurrentUser() user: any, @Body() dto: DoctorConsumeTokenDto) {
    // Verify the user is a DOCTOR
    if (user.role !== 'DOCTOR') {
      throw new ForbiddenException('Only doctors can use this endpoint');
    }
    return this.tokenService.consumeToken(dto.token, user.id);
  }

  @Get('tokens/active')
  async getActiveTokens(@CurrentUser() user: any) {
    return this.tokenService.getActiveTokens(user.id);
  }

  // ============================
  // Family Connection Endpoints
  // ============================

  @Get('caregivers')
  async getCaregivers(@CurrentUser() user: any) {
    return this.connectionsService.getCaregivers(user.id);
  }

  @Get('patients')
  async getConnectedPatients(@CurrentUser() user: any) {
    return this.connectionsService.getConnectedPatients(user.id);
  }

  @Patch(':id/alerts')
  async toggleAlerts(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body('enabled') enabled: boolean,
  ) {
    return this.connectionsService.toggleAlerts(id, user.id, enabled);
  }

  @Get('caregiver-limit')
  async getCaregiverLimit(@CurrentUser() user: any) {
    return this.connectionsService.getCaregiverLimit(user.id);
  }

  @Get('history')
  async getConnectionHistory(@CurrentUser() user: any, @Query('filter') filter?: string) {
    return this.connectionsService.getConnectionHistory(user.id, filter);
  }

  // ============================
  // Nudge Endpoints
  // ============================

  @Post('nudge')
  async sendNudge(@CurrentUser() user: any, @Body() dto: SendNudgeDto) {
    return this.nudgeService.sendNudge(user.id, dto.patientId, dto.doseId);
  }

  @Post('nudge/respond')
  async respondToNudge(@CurrentUser() user: any, @Body() dto: NudgeResponseDto) {
    return this.nudgeService.respondToNudge(user.id, dto.caregiverId, dto.doseId, dto.response);
  }

  // ============================
  // Doctor & Family Connection Endpoints
  // ============================

  @Get('doctors')
  async getDoctorConnections(@CurrentUser() user: any) {
    return this.connectionsService.getDoctorConnections(user.id);
  }

  @Get('family')
  async getFamilyConnections(@CurrentUser() user: any) {
    return this.connectionsService.getFamilyConnections(user.id);
  }

  @Get('search-patient')
  async searchPatient(@Query('query') query: string) {
    return this.connectionsService.searchPatients(query);
  }
}
