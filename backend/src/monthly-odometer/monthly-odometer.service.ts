import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../common/services/cloudinary.service';
import { AnomaliesService } from '../anomalies/anomalies.service';
import { AnomalyType, AnomalySeverity, Role } from '@prisma/client';

const MAX_REALISTIC_MONTHLY_KM = 10000;

@Injectable()
export class MonthlyOdometerService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService,
    private anomalies: AnomaliesService,
  ) {}

  async recordStart(
    userId: string,
    vehicleId: string,
    month: number,
    year: number,
    startOdometer: number,
    file?: Express.Multer.File,
  ) {
    await this.validateVehicleOwnership(userId, vehicleId);

    let startImageUrl: string | undefined;
    if (file) {
      startImageUrl = await this.cloudinary.uploadBuffer(file.buffer, 'npd/monthly-odometer');
    }

    return this.prisma.monthlyOdometerReading.upsert({
      where: { userId_vehicleId_month_year: { userId, vehicleId, month, year } },
      create: { userId, vehicleId, month, year, startOdometer, startImageUrl },
      update: { startOdometer, ...(startImageUrl ? { startImageUrl } : {}) },
    });
  }

  async recordEnd(
    userId: string,
    vehicleId: string,
    month: number,
    year: number,
    endOdometer: number,
    file?: Express.Multer.File,
  ) {
    await this.validateVehicleOwnership(userId, vehicleId);

    const reading = await this.prisma.monthlyOdometerReading.findUnique({
      where: { userId_vehicleId_month_year: { userId, vehicleId, month, year } },
    });

    if (!reading) {
      throw new BadRequestException('Start odometer must be recorded before end odometer');
    }
    if (!reading.startOdometer) {
      throw new BadRequestException('Start odometer value is missing');
    }
    if (endOdometer <= reading.startOdometer) {
      throw new BadRequestException(
        `End odometer (${endOdometer}) must be greater than start (${reading.startOdometer})`,
      );
    }

    const actualDistanceKm = Math.round((endOdometer - reading.startOdometer) * 10) / 10;

    let endImageUrl: string | undefined;
    if (file) {
      endImageUrl = await this.cloudinary.uploadBuffer(file.buffer, 'npd/monthly-odometer');
    }

    const updated = await this.prisma.monthlyOdometerReading.update({
      where: { id: reading.id },
      data: { endOdometer, actualDistanceKm, ...(endImageUrl ? { endImageUrl } : {}) },
    });

    if (actualDistanceKm > MAX_REALISTIC_MONTHLY_KM) {
      await this.anomalies.logAnomaly({
        userId,
        type: AnomalyType.ODOMETER_MISMATCH,
        severity: AnomalySeverity.HIGH,
        description: `Unrealistic monthly odometer jump: ${actualDistanceKm}km for ${month}/${year}`,
        evidence: {
          startOdometer: reading.startOdometer,
          endOdometer,
          actualDistanceKm,
          month,
          year,
        },
      });
    }

    return updated;
  }

  async getReading(userId: string, vehicleId: string, month: number, year: number) {
    const reading = await this.prisma.monthlyOdometerReading.findUnique({
      where: { userId_vehicleId_month_year: { userId, vehicleId, month, year } },
      include: {
        user: { select: { id: true, fullName: true } },
        vehicle: { select: { id: true, plateNumber: true } },
      },
    });
    if (!reading) throw new NotFoundException('Odometer reading not found for this period');
    return reading;
  }

  async findAll(requestingUser: { id: string; role: string }, filters: {
    month?: number;
    year?: number;
    userId?: string;
  }) {
    const now = new Date();
    const month = filters.month ? Number(filters.month) : now.getMonth() + 1;
    const year = filters.year ? Number(filters.year) : now.getFullYear();

    let userFilter: object = {};

    if (requestingUser.role === Role.DRIVER) {
      userFilter = { userId: requestingUser.id };
    } else if (requestingUser.role === Role.MANAGER) {
      userFilter = { user: { managerId: requestingUser.id } };
    } else if (filters.userId) {
      userFilter = { userId: filters.userId };
    }

    return this.prisma.monthlyOdometerReading.findMany({
      where: { month, year, ...userFilter },
      include: {
        user: { select: { id: true, fullName: true, department: true } },
        vehicle: { select: { id: true, plateNumber: true, make: true, model: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  private async validateVehicleOwnership(userId: string, vehicleId: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
      select: { assignedDriverId: true },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');
    if (vehicle.assignedDriverId !== userId) {
      throw new ForbiddenException('Vehicle is not assigned to you');
    }
  }
}
