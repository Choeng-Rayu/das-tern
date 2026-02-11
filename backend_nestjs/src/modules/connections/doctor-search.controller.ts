import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ConnectionsService } from './connections.service';

@Controller('doctors')
@UseGuards(AuthGuard('jwt'))
export class DoctorSearchController {
  constructor(private connectionsService: ConnectionsService) {}

  @Get('search')
  async searchDoctors(
    @Query('query') query: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.connectionsService.searchDoctors(
      query || '',
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }
}
