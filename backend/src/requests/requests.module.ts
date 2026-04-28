import { Module } from '@nestjs/common';
import { RequestsService } from './requests.service';
import { RequestsController } from './requests.controller';
import { NotificationsModule } from '../notifications/notifications.module';
import { AnomaliesModule } from '../anomalies/anomalies.module';
import { AllocationsModule } from '../allocations/allocations.module';
import { CloudinaryService } from '../common/services/cloudinary.service';
import { FuelEstimationModule } from '../fuel-estimation/fuel-estimation.module';

@Module({
  imports: [NotificationsModule, AnomaliesModule, AllocationsModule, FuelEstimationModule],
  controllers: [RequestsController],
  providers: [RequestsService, CloudinaryService],
  exports: [RequestsService],
})
export class RequestsModule {}
