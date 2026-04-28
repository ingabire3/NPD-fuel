import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('stats')
  getStats(@CurrentUser() user: any) {
    return this.dashboardService.getStats(user.id, user.role);
  }

  @Roles(Role.SUPER_ADMIN, Role.FINANCE, Role.MANAGER)
  @Get('expected-vs-actual')
  getExpectedVsActual(
    @Query('month') month?: number,
    @Query('year') year?: number,
  ) {
    return this.dashboardService.getExpectedVsActual(month, year);
  }

  @Roles(Role.SUPER_ADMIN, Role.FINANCE, Role.MANAGER)
  @Get('fuel-trends')
  getFuelTrends(
    @CurrentUser() user: any,
    @Query('months') months?: number,
    @Query('userId') userId?: string,
  ) {
    const targetUserId = user.role === Role.DRIVER ? user.id : userId;
    return this.dashboardService.getFuelTrends(targetUserId, months ? Number(months) : 6);
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER)
  @Get('suspicious-users')
  getSuspiciousDrivers() {
    return this.dashboardService.getSuspiciousDrivers();
  }

  @Roles(Role.SUPER_ADMIN, Role.FINANCE)
  @Get('ai-summary')
  getAIClassificationSummary(
    @Query('month') month?: number,
    @Query('year') year?: number,
  ) {
    return this.dashboardService.getAIClassificationSummary(month, year);
  }
}
