import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { RequestsService } from './requests.service';
import { FuelEstimationService } from '../fuel-estimation/fuel-estimation.service';
import { CreateRequestDto } from './dto/create-request.dto';
import { RejectRequestDto } from './dto/reject-request.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role, RequestStatus } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('requests')
export class RequestsController {
  constructor(
    private requestsService: RequestsService,
    private fuelEstimation: FuelEstimationService,
  ) {}

  @Roles(Role.DRIVER, Role.SUPER_ADMIN)
  @Post('odometer-upload')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_, file, cb) => {
        if (!file.mimetype.match(/image\/(jpeg|png|jpg)/)) {
          return cb(new Error('Only JPG/PNG images allowed'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadOdometerImage(@UploadedFile() file: Express.Multer.File) {
    const url = await this.requestsService.uploadOdometerImage(file);
    return { url };
  }

  @Roles(Role.DRIVER, Role.SUPER_ADMIN)
  @Post()
  create(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRequestDto,
  ) {
    return this.requestsService.create(userId, dto);
  }

  @Get()
  findAll(
    @CurrentUser() user: any,
    @Query('status') status?: RequestStatus,
    @Query('driverId') driverId?: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    const filterDriverId = user.role === Role.DRIVER ? user.id : driverId;
    const managerId = user.role === Role.MANAGER ? user.id : undefined;
    return this.requestsService.findAll({
      status,
      driverId: filterDriverId,
      managerId,
      page,
      limit,
    });
  }

  @Roles(Role.DRIVER, Role.SUPER_ADMIN)
  @Get('estimate')
  async getEstimate(
    @CurrentUser('id') userId: string,
    @Query('vehicleId') vehicleId: string,
  ) {
    if (!vehicleId) throw new BadRequestException('vehicleId is required');
    const result = await this.fuelEstimation.estimate(userId, vehicleId);
    return (
      result ?? {
        distanceKm: null,
        expectedFuel: null,
        message: 'Estimation unavailable — set home/work location and vehicle efficiency',
      }
    );
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.requestsService.findOne(id);
  }

  @Roles(Role.FINANCE, Role.SUPER_ADMIN)
  @Patch(':id/approve')
  approve(
    @Param('id') id: string,
    @CurrentUser('id') approverId: string,
  ) {
    return this.requestsService.approve(id, approverId);
  }

  @Roles(Role.FINANCE, Role.SUPER_ADMIN)
  @Patch(':id/reject')
  reject(
    @Param('id') id: string,
    @CurrentUser('id') approverId: string,
    @Body() dto: RejectRequestDto,
  ) {
    return this.requestsService.reject(id, approverId, dto.reason);
  }

  @Roles(Role.MANAGER, Role.SUPER_ADMIN)
  @Patch(':id/fulfill')
  fulfill(
    @Param('id') id: string,
    @Body('odometerAfter') odometerAfter: number,
  ) {
    return this.requestsService.markFulfilled(id, odometerAfter);
  }
}
