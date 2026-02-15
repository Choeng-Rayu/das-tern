import { Module } from '@nestjs/common';
import { ConnectionsService } from './connections.service';
import { ConnectionTokenService } from './connection-token.service';
import { NudgeService } from './nudge.service';
import { ConnectionsController } from './connections.controller';
import { DoctorSearchController } from './doctor-search.controller';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [NotificationsModule, AuditModule],
  controllers: [ConnectionsController, DoctorSearchController],
  providers: [ConnectionsService, ConnectionTokenService, NudgeService],
  exports: [ConnectionsService, ConnectionTokenService, NudgeService],
})
export class ConnectionsModule {}
