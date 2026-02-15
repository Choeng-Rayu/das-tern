import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AdherenceService } from './adherence.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('adherence')
@UseGuards(AuthGuard('jwt'))
export class AdherenceController {
  constructor(private adherenceService: AdherenceService) {}

  @Get('today')
  async getTodayAdherence(@CurrentUser() user: any) {
    return this.adherenceService.getTodayAdherence(user.id);
  }

  @Get('weekly')
  async getWeeklyAdherence(@CurrentUser() user: any) {
    return this.adherenceService.getWeeklyAdherence(user.id);
  }

  @Get('monthly')
  async getMonthlyAdherence(@CurrentUser() user: any) {
    return this.adherenceService.getMonthlyAdherence(user.id);
  }

  @Get('trends')
  async getAdherenceTrends(@CurrentUser() user: any, @Query('days') days?: string) {
    return this.adherenceService.getAdherenceTrends(user.id, days ? parseInt(days) : 7);
  }

  @Get('prescription/:id')
  async getPrescriptionAdherence(@Param('id') id: string, @CurrentUser() user: any) {
    return this.adherenceService.getPrescriptionAdherence(id, user.id);
  }
}
