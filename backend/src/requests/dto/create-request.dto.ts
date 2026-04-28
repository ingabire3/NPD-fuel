import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateRequestDto {
  @IsString()
  vehicleId: string;

  @IsNumber()
  @Min(1)
  requestedLiters: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  requestedAmount?: number;

  @IsString()
  purpose: string;

  @IsOptional()
  @IsString()
  tripDescription?: string;

  @IsOptional()
  @IsNumber()
  odometerBefore?: number;

  @IsOptional()
  @IsString()
  odometerImageUrl?: string;
}
