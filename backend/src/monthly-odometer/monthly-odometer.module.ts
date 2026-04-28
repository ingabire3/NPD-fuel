import { Module } from '@nestjs/common';
import { MonthlyOdometerService } from './monthly-odometer.service';
import { MonthlyOdometerController } from './monthly-odometer.controller';
import { CloudinaryService } from '../common/services/cloudinary.service';
import { AnomaliesModule } from '../anomalies/anomalies.module';

@Module({
  imports: [AnomaliesModule],
  controllers: [MonthlyOdometerController],
  providers: [MonthlyOdometerService, CloudinaryService],
  exports: [MonthlyOdometerService],
})
export class MonthlyOdometerModule {}
