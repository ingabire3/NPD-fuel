import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { MonthlyOdometerService } from './monthly-odometer.service';
import { RecordOdometerDto } from './dto/odometer.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('monthly-odometer')
export class MonthlyOdometerController {
  constructor(private readonly service: MonthlyOdometerService) {}

  @Roles(Role.DRIVER, Role.SUPER_ADMIN)
  @Post('start')
  @UseInterceptors(FileInterceptor('image'))
  recordStart(
    @CurrentUser() user: any,
    @Body() dto: RecordOdometerDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const userId = user.role === Role.SUPER_ADMIN && dto['userId'] ? dto['userId'] : user.id;
    return this.service.recordStart(userId, dto.vehicleId, dto.month, dto.year, dto.odometer, file);
  }

  @Roles(Role.DRIVER, Role.SUPER_ADMIN)
  @Post('end')
  @UseInterceptors(FileInterceptor('image'))
  recordEnd(
    @CurrentUser() user: any,
    @Body() dto: RecordOdometerDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const userId = user.role === Role.SUPER_ADMIN && dto['userId'] ? dto['userId'] : user.id;
    return this.service.recordEnd(userId, dto.vehicleId, dto.month, dto.year, dto.odometer, file);
  }

  @Get()
  findAll(
    @CurrentUser() user: any,
    @Query('month') month?: number,
    @Query('year') year?: number,
    @Query('userId') userId?: string,
  ) {
    return this.service.findAll({ id: user.id, role: user.role }, { month, year, userId });
  }

  @Roles(Role.SUPER_ADMIN, Role.MANAGER, Role.FINANCE)
  @Get(':userId')
  findByUser(
    @Param('userId') userId: string,
    @Query('month') month?: number,
    @Query('year') year?: number,
  ) {
    return this.service.findAll({ id: userId, role: Role.SUPER_ADMIN }, { month, year, userId });
  }
}
