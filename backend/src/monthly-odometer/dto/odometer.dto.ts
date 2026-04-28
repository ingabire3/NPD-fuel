import { IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class RecordOdometerDto {
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
  odometer: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}
