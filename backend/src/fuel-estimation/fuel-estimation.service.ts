import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GoogleMapsService } from '../common/services/google-maps.service';
import { FuelVariance } from '@prisma/client';

const BUFFER = 0.15;
const WARNING_THRESHOLD = 1.2;
const SUSPICIOUS_THRESHOLD = 1.5;

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export interface FuelEstimation {
  distanceKm: number;
  expectedFuel: number;
}

@Injectable()
export class FuelEstimationService {
  constructor(
    private prisma: PrismaService,
    private googleMaps: GoogleMapsService,
  ) {}

  async estimate(
    driverId: string,
    vehicleId: string,
  ): Promise<FuelEstimation | null> {
    const [driver, vehicle] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: driverId },
        select: { homeLat: true, homeLng: true, workLat: true, workLng: true },
      }),
      this.prisma.vehicle.findUnique({
        where: { id: vehicleId },
        select: { averageKmPerL: true },
      }),
    ]);

    if (!driver?.homeLat || !driver?.homeLng || !driver?.workLat || !driver?.workLng) {
      return null;
    }
    if (!vehicle?.averageKmPerL) return null;

    const oneWayKm = await this.getOrFetchDistance(
      driver.homeLat,
      driver.homeLng,
      driver.workLat,
      driver.workLng,
    );
    if (!oneWayKm) return null;

    const distanceKm = Math.round(oneWayKm * 2 * 10) / 10;
    const rawFuel = distanceKm / vehicle.averageKmPerL;
    const expectedFuel = Math.round(rawFuel * (1 + BUFFER) * 10) / 10;

    return { distanceKm, expectedFuel };
  }

  classify(requestedLiters: number, expectedFuel: number): FuelVariance {
    const ratio = requestedLiters / expectedFuel;
    if (ratio <= WARNING_THRESHOLD) return FuelVariance.NORMAL;
    if (ratio <= SUSPICIOUS_THRESHOLD) return FuelVariance.WARNING;
    return FuelVariance.SUSPICIOUS;
  }

  private async getOrFetchDistance(
    homeLat: number,
    homeLng: number,
    workLat: number,
    workLng: number,
  ): Promise<number | null> {
    const key =
      `${homeLat.toFixed(4)},${homeLng.toFixed(4)}` +
      `->${workLat.toFixed(4)},${workLng.toFixed(4)}`;

    const cached = await this.prisma.routeCache.findUnique({
      where: { cacheKey: key },
    });
    if (cached) return cached.distanceKm;

    const mapsDistanceKm = await this.googleMaps.getDistanceKm(
      homeLat,
      homeLng,
      workLat,
      workLng,
    );
    // Fall back to Haversine straight-line when Maps API key is absent
    const distanceKm = mapsDistanceKm ?? haversineKm(homeLat, homeLng, workLat, workLng);

    await this.prisma.routeCache.create({
      data: { cacheKey: key, distanceKm },
    });

    return distanceKm;
  }
}
