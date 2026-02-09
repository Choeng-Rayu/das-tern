import { Controller, Get, Patch, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { SubscriptionsService } from './subscriptions.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SubscriptionTier } from '@prisma/client';

@Controller('subscriptions')
@UseGuards(AuthGuard('jwt'))
export class SubscriptionsController {
  constructor(private subscriptionsService: SubscriptionsService) {}

  @Get('me')
  async getSubscription(@CurrentUser() user: any) {
    return this.subscriptionsService.findOne(user.id);
  }

  @Patch('tier')
  async updateTier(@CurrentUser() user: any, @Body('tier') tier: SubscriptionTier) {
    return this.subscriptionsService.updateTier(user.id, tier);
  }

  @Post('family/add')
  async addFamilyMember(@CurrentUser() user: any, @Body('memberId') memberId: string) {
    return this.subscriptionsService.addFamilyMember(user.id, memberId);
  }

  @Delete('family/:memberId')
  async removeFamilyMember(@Param('memberId') memberId: string, @CurrentUser() user: any) {
    return this.subscriptionsService.removeFamilyMember(user.id, memberId);
  }
}
