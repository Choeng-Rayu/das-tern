import { Controller, Get, Patch, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { NotificationsService } from './notifications.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('notifications')
@UseGuards(AuthGuard('jwt'))
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Get()
  async findAll(@CurrentUser() user: any, @Query('unreadOnly') unreadOnly?: string) {
    const notifications = await this.notificationsService.findAll(user.id, unreadOnly === 'true');
    const unreadCount = await this.notificationsService.getUnreadCount(user.id);
    return { notifications, unreadCount };
  }

  @Patch(':id/read')
  async markAsRead(@Param('id') id: string, @CurrentUser() user: any) {
    return this.notificationsService.markAsRead(id, user.id);
  }
}
