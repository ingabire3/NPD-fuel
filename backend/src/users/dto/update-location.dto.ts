import { IsNumber, Min, Max } from 'class-validator';

export class UpdateLocationDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  homeLat: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  homeLng: number;

  @IsNumber()
  @Min(-90)
  @Max(90)
  workLat: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  workLng: number;
}
