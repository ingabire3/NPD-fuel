import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { GoogleMapsService } from '../common/services/google-maps.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService, GoogleMapsService],
  exports: [UsersService],
})
export class UsersModule {}
