import { Controller, Get, Patch, Body, Param, UseGuards, ForbiddenException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('users')
@UseGuards(AuthGuard('jwt'))
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  async getProfile(@CurrentUser() user: any) {
    return this.usersService.findOne(user.id);
  }

  @Get('storage')
  async getStorage(@CurrentUser() user: any) {
    return this.usersService.getStorageInfo(user.id);
  }

  @Get('settings/meal-times')
  async getMealTimes(@CurrentUser() user: any) {
    return this.usersService.getMealTimePreferences(user.id);
  }

  @Get(':id')
  async getUser(@Param('id') id: string, @CurrentUser() user: any) {
    // Only allow users to view their own profile, or doctors to view connected patients
    if (user.id !== id && user.role !== 'DOCTOR') {
      throw new ForbiddenException('You can only view your own profile');
    }
    return this.usersService.findOne(id);
  }

  @Patch('me')
  async updateProfile(@CurrentUser() user: any, @Body() dto: UpdateProfileDto) {
    return this.usersService.update(user.id, dto);
  }

  @Patch('me/grace-period')
  async updateGracePeriod(@CurrentUser() user: any, @Body('gracePeriodMinutes') minutes: number) {
    return this.usersService.updateGracePeriod(user.id, minutes);
  }

  @Patch('settings/meal-times')
  async updateMealTimes(@CurrentUser() user: any, @Body() body: { morningMeal?: string; afternoonMeal?: string; nightMeal?: string }) {
    return this.usersService.updateMealTimePreferences(user.id, body);
  }
}
