import { IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateAllocationDto {
  @IsString()
  userId: string;

  @IsString()
  vehicleId: string;

  @IsInt()
  @Min(1)
  @Max(12)
  month: number;

  @IsInt()
  @Min(2024)
  year: number;

  @IsNumber()
  @Min(0)
  allocatedLiters: number;

  @IsNumber()
  @Min(0)
  allocatedAmount: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(31)
  workingDays?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  fuelPricePerLitre?: number;
}
