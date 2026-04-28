import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  Body,
  UseGuards,
} from '@nestjs/common';
import { AnomaliesService } from './anomalies.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('anomalies')
export class AnomaliesController {
  constructor(private anomaliesService: AnomaliesService) {}

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Get()
  findAll(
    @Query('status') status?: string,
    @Query('userId') userId?: string,
  ) {
    return this.anomaliesService.findAll(status, userId);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Patch(':id/resolve')
  resolve(
    @Param('id') id: string,
    @CurrentUser('id') resolvedBy: string,
    @Body('resolution') resolution: string,
  ) {
    return this.anomaliesService.resolve(id, resolvedBy, resolution);
  }
}
