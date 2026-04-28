import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ForbiddenException,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Roles(Role.SUPER_ADMIN)
  @Post()
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Get()
  findAll(@CurrentUser() user: any, @Query('role') role?: string) {
    if (user.role === Role.MANAGER) return this.usersService.findByManager(user.id);
    return this.usersService.findAll(role);
  }

  // ── Static / named routes MUST come before :id param routes ─────────────

  @Roles(Role.SUPER_ADMIN)
  @Get('pending/list')
  findPending() {
    return this.usersService.findPending();
  }

  @Get('me')
  getMe(@CurrentUser() currentUser: any) {
    return this.usersService.findOne(currentUser.id);
  }

  // ── Param routes ─────────────────────────────────────────────────────────

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: Partial<CreateUserDto>) {
    return this.usersService.update(id, dto);
  }

  @Patch(':id/location')
  updateLocation(
    @Param('id') id: string,
    @CurrentUser() currentUser: any,
    @Body() dto: UpdateLocationDto,
  ) {
    if (currentUser.role === Role.DRIVER && currentUser.id !== id) {
      throw new ForbiddenException('Drivers can only update their own location');
    }
    return this.usersService.updateLocation(id, dto);
  }

  @Roles(Role.SUPER_ADMIN)
  @Delete(':id')
  deactivate(@Param('id') id: string) {
    return this.usersService.deactivate(id);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch(':id/approve')
  @HttpCode(HttpStatus.OK)
  approve(@Param('id') id: string) {
    return this.usersService.approve(id);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch(':id/reject')
  @HttpCode(HttpStatus.OK)
  reject(@Param('id') id: string, @Body() body: { reason?: string }) {
    return this.usersService.reject(id, body.reason);
  }

  @Post(':id/calculate-distance')
  @HttpCode(HttpStatus.OK)
  calculateDistance(
    @Param('id') id: string,
    @CurrentUser() currentUser: any,
  ) {
    if (currentUser.role === Role.DRIVER && currentUser.id !== id) {
      throw new ForbiddenException('Drivers can only calculate their own distance');
    }
    return this.usersService.calculateAndStoreDailyDistance(id);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch(':id/reset-distance')
  resetDistance(@Param('id') id: string) {
    return this.usersService.resetDailyDistance(id);
  }
}
