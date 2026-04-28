import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('vehicles')
export class VehiclesController {
  constructor(private vehiclesService: VehiclesService) {}

  @Roles(Role.SUPER_ADMIN)
  @Post()
  create(@Body() dto: CreateVehicleDto) {
    return this.vehiclesService.create(dto);
  }

  @Get()
  findAll(@CurrentUser() user: any) {
    if (user.role === Role.DRIVER) return this.vehiclesService.findByDriver(user.id);
    if (user.role === Role.MANAGER) return this.vehiclesService.findByManager(user.id);
    return this.vehiclesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.vehiclesService.findOne(id);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: Partial<CreateVehicleDto>) {
    return this.vehiclesService.update(id, dto);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Patch(':id/assign/:driverId')
  assignDriver(
    @Param('id') id: string,
    @Param('driverId') driverId: string,
  ) {
    return this.vehiclesService.assignDriver(id, driverId);
  }
}
