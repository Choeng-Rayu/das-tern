import { Controller, Get, Patch, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { DosesService } from './doses.service';
import { MarkDoseTakenDto, SkipDoseDto, SyncDosesDto } from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('doses')
@UseGuards(AuthGuard('jwt'))
export class DosesController {
  constructor(private dosesService: DosesService) {}

  @Get('schedule')
  async getSchedule(
    @CurrentUser() user: any,
    @Query('date') date?: string,
    @Query('groupBy') groupBy?: string,
  ) {
    return this.dosesService.getSchedule(user.id, date, groupBy);
  }

  @Get('today')
  async getTodaysDoses(@CurrentUser() user: any) {
    return this.dosesService.getTodaysDoses(user.id);
  }

  @Get('upcoming')
  async getUpcomingDose(@CurrentUser() user: any) {
    return this.dosesService.getUpcomingDose(user.id);
  }

  @Get('history')
  async getHistory(
    @CurrentUser() user: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.dosesService.getHistory(user.id, startDate, endDate);
  }

  @Patch(':id/taken')
  async markTaken(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: MarkDoseTakenDto) {
    return this.dosesService.markTaken(id, user.id, dto.takenAt, dto.offline);
  }

  @Post(':id/taken')
  async markDoseTaken(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: MarkDoseTakenDto) {
    return this.dosesService.markTaken(id, user.id, dto.takenAt, dto.offline);
  }

  @Patch(':id/skipped')
  async skip(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: SkipDoseDto) {
    return this.dosesService.skip(id, user.id, dto.reason);
  }

  @Post(':id/skip')
  async skipDosePost(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: SkipDoseDto) {
    return this.dosesService.skip(id, user.id, dto.reason);
  }

  @Post('sync')
  async syncOfflineDoses(@CurrentUser() user: any, @Body() dto: SyncDosesDto) {
    return this.dosesService.syncOfflineDoses(user.id, dto.events);
  }
}
