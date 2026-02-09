import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuditService } from './audit.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('audit')
@UseGuards(AuthGuard('jwt'))
export class AuditController {
  constructor(private auditService: AuditService) {}

  @Get()
  async findAll(
    @CurrentUser() user: any,
    @Query('resourceType') resourceType?: string,
    @Query('actionType') actionType?: string,
  ) {
    return this.auditService.findAll(user.id, { resourceType, actionType: actionType as any });
  }
}
