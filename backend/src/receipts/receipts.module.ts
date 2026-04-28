import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ReceiptsService } from './receipts.service';
import { ReceiptsController } from './receipts.controller';
import { CloudinaryService } from '../common/services/cloudinary.service';
import { AiService } from '../common/services/ai.service';
import { AnomaliesModule } from '../anomalies/anomalies.module';

@Module({
  imports: [HttpModule, AnomaliesModule],
  controllers: [ReceiptsController],
  providers: [ReceiptsService, CloudinaryService, AiService],
})
export class ReceiptsModule {}
