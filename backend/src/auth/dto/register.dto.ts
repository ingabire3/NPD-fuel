import {
  IsEmail,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';
import { FuelType } from '@prisma/client';

export class RegisterDto {
  // ── User fields ───────────────────────────────────────────
  @IsString()
  fullName: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  department?: string;

  // ── Home / work coordinates ────────────────────────────────
  @IsNumber()
  homeLat: number;

  @IsNumber()
  homeLng: number;

  @IsOptional()
  @IsString()
  homeAddress?: string;

  @IsNumber()
  workLat: number;

  @IsNumber()
  workLng: number;

  @IsOptional()
  @IsString()
  workAddress?: string;

  // ── Vehicle details ────────────────────────────────────────
  @IsString()
  plateNumber: string;

  @IsString()
  vehicleMake: string;

  @IsString()
  vehicleModel: string;

  @IsNumber()
  vehicleYear: number;

  @IsEnum(FuelType)
  fuelType: FuelType;

  @IsNumber()
  @Min(1)
  tankCapacity: number;

  @IsOptional()
  @IsNumber()
  @Min(0.1)
  averageKmPerL?: number;
}
