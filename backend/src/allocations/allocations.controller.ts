import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AllocationsService } from './allocations.service';
import { CreateAllocationDto } from './dto/create-allocation.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('allocations')
export class AllocationsController {
  constructor(private allocationsService: AllocationsService) {}

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Post()
  create(@Body() dto: CreateAllocationDto) {
    return this.allocationsService.create(dto);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER, Role.FINANCE)
  @Get()
  findAll(
    @CurrentUser() user: any,
    @Query('month') month?: number,
    @Query('year') year?: number,
  ) {
    const managerId = user.role === Role.MANAGER ? user.id : undefined;
    return this.allocationsService.findAll(month, year, managerId);
  }

  @Get('current/me')
  findMyCurrent(@CurrentUser('id') userId: string) {
    return this.allocationsService.findCurrentByUser(userId);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Get('current/:userId')
  findCurrentByUser(@Param('userId') userId: string) {
    return this.allocationsService.findCurrentByUser(userId);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: { allocatedLiters?: number; allocatedAmount?: number },
  ) {
    return this.allocationsService.update(id, dto);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER, Role.FINANCE)
  @Post(':id/recalculate')
  @HttpCode(HttpStatus.OK)
  recalculate(
    @Param('id') id: string,
    @Body() dto: { workingDays?: number; fuelPricePerLitre?: number },
  ) {
    return this.allocationsService.recalculate(id, dto);
  }
}
