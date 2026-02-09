import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ConnectionsService } from './connections.service';
import { CreateConnectionDto, AcceptConnectionDto } from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { PermissionLevel } from '@prisma/client';

@Controller('connections')
@UseGuards(AuthGuard('jwt'))
export class ConnectionsController {
  constructor(private connectionsService: ConnectionsService) {}

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
}
