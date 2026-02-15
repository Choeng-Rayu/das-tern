import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ConnectionsService } from './connections.service';
import { ConnectionTokenService } from './connection-token.service';
import { NudgeService } from './nudge.service';
import { CreateConnectionDto, AcceptConnectionDto, GenerateTokenDto, ValidateTokenDto, ConsumeTokenDto, SendNudgeDto, NudgeResponseDto } from './dto';
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

  @Post('tokens/generate')
  async generateToken(@CurrentUser() user: any, @Body() dto: GenerateTokenDto) {
    return this.tokenService.generateToken(user.id, dto.permissionLevel);
  }

  @Post('tokens/validate')
  async validateToken(@Body() dto: ValidateTokenDto) {
    return this.tokenService.validateToken(dto.token);
  }

  @Post('tokens/consume')
  async consumeToken(@CurrentUser() user: any, @Body() dto: ConsumeTokenDto) {
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
}
