import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAllocationDto } from './dto/create-allocation.dto';

const DEFAULT_WORKING_DAYS = 22;

@Injectable()
export class AllocationsService {
  constructor(private prisma: PrismaService) {}

  private async computeMonthlyFuel(
    userId: string,
    vehicleId: string,
    workingDays: number,
    fuelPricePerLitre?: number,
  ): Promise<{ monthlyExpectedFuel?: number; totalExpectedCost?: number }> {
    const [driver, vehicle] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId }, select: { dailyDistanceKm: true } }),
      this.prisma.vehicle.findUnique({ where: { id: vehicleId }, select: { averageKmPerL: true } }),
    ]);

    if (!driver?.dailyDistanceKm || !vehicle?.averageKmPerL) return {};

    const monthlyDistance = driver.dailyDistanceKm * workingDays;
    const monthlyExpectedFuel = Math.round((monthlyDistance / vehicle.averageKmPerL) * 10) / 10;
    const totalExpectedCost = fuelPricePerLitre
      ? Math.round(monthlyExpectedFuel * fuelPricePerLitre * 100) / 100
      : undefined;

    return { monthlyExpectedFuel, totalExpectedCost };
  }

  async create(dto: CreateAllocationDto) {
    const exists = await this.prisma.fuelAllocation.findUnique({
      where: {
        userId_vehicleId_month_year: {
          userId: dto.userId,
          vehicleId: dto.vehicleId,
          month: dto.month,
          year: dto.year,
        },
      },
    });
    if (exists) throw new ConflictException('Allocation already exists for this period');

    const workingDays = dto.workingDays ?? DEFAULT_WORKING_DAYS;
    const { monthlyExpectedFuel, totalExpectedCost } = await this.computeMonthlyFuel(
      dto.userId,
      dto.vehicleId,
      workingDays,
      dto.fuelPricePerLitre,
    );

    const { workingDays: _wd, fuelPricePerLitre: _fp, ...rest } = dto;

    return this.prisma.fuelAllocation.create({
      data: {
        ...rest,
        remainingLiters: dto.allocatedLiters,
        workingDays,
        fuelPricePerLitre: dto.fuelPricePerLitre,
        monthlyExpectedFuel,
        totalExpectedCost,
      },
    });
  }

  async recalculate(
    id: string,
    dto: { workingDays?: number; fuelPricePerLitre?: number },
  ) {
    const alloc = await this.prisma.fuelAllocation.findUnique({ where: { id } });
    if (!alloc) throw new NotFoundException('Allocation not found');

    const workingDays = dto.workingDays ?? alloc.workingDays ?? DEFAULT_WORKING_DAYS;
    const fuelPricePerLitre = dto.fuelPricePerLitre ?? alloc.fuelPricePerLitre ?? undefined;

    const { monthlyExpectedFuel, totalExpectedCost } = await this.computeMonthlyFuel(
      alloc.userId,
      alloc.vehicleId,
      workingDays,
      fuelPricePerLitre,
    );

    return this.prisma.fuelAllocation.update({
      where: { id },
      data: { workingDays, fuelPricePerLitre, monthlyExpectedFuel, totalExpectedCost },
    });
  }

  async findAll(month?: number, year?: number, managerId?: string) {
    const now = new Date();
    const safeMonth = Number(month) || now.getMonth() + 1;
    const safeYear = Number(year) || now.getFullYear();
    return this.prisma.fuelAllocation.findMany({
      where: {
        month: safeMonth,
        year: safeYear,
        ...(managerId ? { user: { managerId } } : {}),
      },
      include: {
        user: { select: { id: true, fullName: true, department: true } },
        vehicle: {
          select: { id: true, plateNumber: true, make: true, model: true },
        },
      },
    });
  }

  async findCurrentByUser(userId: string) {
    const now = new Date();
    const allocation = await this.prisma.fuelAllocation.findFirst({
      where: {
        userId,
        month: now.getMonth() + 1,
        year: now.getFullYear(),
      },
      include: {
        vehicle: {
          select: { id: true, plateNumber: true, fuelType: true },
        },
      },
    });
    if (!allocation) {
      throw new NotFoundException('No allocation found for current month');
    }
    return allocation;
  }

  async update(id: string, dto: { allocatedLiters?: number; allocatedAmount?: number }) {
    const alloc = await this.prisma.fuelAllocation.findUnique({ where: { id } });
    if (!alloc) throw new NotFoundException('Allocation not found');

    const newAllocatedLiters = dto.allocatedLiters ?? Number(alloc.allocatedLiters);
    const usedLiters = Number(alloc.usedLiters);
    const newRemainingLiters = newAllocatedLiters - usedLiters;

    return this.prisma.fuelAllocation.update({
      where: { id },
      data: {
        ...(dto.allocatedLiters !== undefined && {
          allocatedLiters: newAllocatedLiters,
          remainingLiters: Math.max(0, newRemainingLiters),
        }),
        ...(dto.allocatedAmount !== undefined && { allocatedAmount: dto.allocatedAmount }),
      },
    });
  }

  async deductAllocation(allocationId: string, liters: number) {
    return this.prisma.fuelAllocation.update({
      where: { id: allocationId },
      data: {
        usedLiters: { increment: liters },
        remainingLiters: { decrement: liters },
      },
    });
  }
}
