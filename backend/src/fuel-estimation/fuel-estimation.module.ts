import { Module } from '@nestjs/common';
import { FuelEstimationService } from './fuel-estimation.service';
import { GoogleMapsService } from '../common/services/google-maps.service';

@Module({
  providers: [FuelEstimationService, GoogleMapsService],
  exports: [FuelEstimationService],
})
export class FuelEstimationModule {}
