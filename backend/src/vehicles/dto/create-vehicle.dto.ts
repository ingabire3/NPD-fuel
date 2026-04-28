import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { FuelType } from '@prisma/client';

export class CreateVehicleDto {
  @IsString()
  plateNumber: string;

  @IsString()
  make: string;

  @IsString()
  model: string;

  @IsNumber()
  year: number;

  @IsEnum(FuelType)
  fuelType: FuelType;

  @IsNumber()
  @Min(1)
  tankCapacity: number;

  @IsOptional()
  @IsNumber()
  averageKmPerL?: number;

  @IsOptional()
  @IsString()
  assignedDriverId?: string;
}
