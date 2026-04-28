import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AnomalyStatus, AnomalySeverity, FuelVariance, SystemRecommendation } from '@prisma/client';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getStats(userId: string, role: string) {
    if (role === 'DRIVER') return this.getDriverStats(userId);
    if (role === 'FINANCE') return this.getFinanceStats();
    return this.getAdminStats();
  }

  private async getDriverStats(userId: string) {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    const [myRequests, myPending, myFulfilled, allocation] = await Promise.all([
      this.prisma.fuelRequest.count({ where: { driverId: userId } }),
      this.prisma.fuelRequest.count({ where: { driverId: userId, status: 'PENDING' } }),
      this.prisma.fuelRequest.count({ where: { driverId: userId, status: 'FULFILLED' } }),
      this.prisma.fuelAllocation.findFirst({
        where: {
          userId,
          month: currentMonth,
          year: currentYear,
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      myRequests,
      myPending,
      myFulfilled,
      remainingLiters: allocation ? Number(allocation.remainingLiters) : 0,
    };
  }

  private async getFinanceStats() {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    const [totalAllocations, totalReceipts, openAnomalies, allocData] = await Promise.all([
      this.prisma.fuelAllocation.count({ where: { month: currentMonth, year: currentYear } }),
      this.prisma.fuelReceipt.count(),
      this.prisma.anomalyLog.count({ where: { status: AnomalyStatus.OPEN } }),
      this.prisma.fuelAllocation.aggregate({
        _sum: { allocatedAmount: true, allocatedLiters: true, usedLiters: true },
        where: { month: currentMonth, year: currentYear },
      }),
    ]);

    return {
      totalAllocations,
      totalReceipts,
      openAnomalies,
      totalBudget: Number(allocData._sum.allocatedAmount ?? 0),
      totalAllocatedLiters: Number(allocData._sum.allocatedLiters ?? 0),
      totalUsedLiters: Number(allocData._sum.usedLiters ?? 0),
    };
  }

  private async getAdminStats() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [pendingRequests, totalVehicles, anomalyCount, fulfilledToday] = await Promise.all([
      this.prisma.fuelRequest.count({ where: { status: 'PENDING' } }),
      this.prisma.vehicle.count({ where: { isActive: true } }),
      this.prisma.anomalyLog.count({ where: { status: AnomalyStatus.OPEN } }),
      this.prisma.fuelRequest.count({
        where: { status: 'FULFILLED', fulfilledAt: { gte: today } },
      }),
    ]);

    return { pendingRequests, totalVehicles, anomalyCount, fulfilledToday };
  }

  async getExpectedVsActual(month?: number, year?: number) {
    const now = new Date();
    const safeMonth = Number(month) || now.getMonth() + 1;
    const safeYear = Number(year) || now.getFullYear();

    const allocations = await this.prisma.fuelAllocation.findMany({
      where: { month: safeMonth, year: safeYear },
      include: {
        user: { select: { id: true, fullName: true, department: true } },
        vehicle: { select: { plateNumber: true } },
      },
    });

    return allocations.map((a) => ({
      driverId: a.userId,
      driverName: (a as any).user?.fullName,
      department: (a as any).user?.department,
      vehicle: (a as any).vehicle?.plateNumber,
      expectedFuel: a.monthlyExpectedFuel ?? null,
      allocatedLiters: Number(a.allocatedLiters),
      usedLiters: Number(a.usedLiters),
      remainingLiters: Number(a.remainingLiters),
      utilizationPct: a.allocatedLiters
        ? Math.round((Number(a.usedLiters) / Number(a.allocatedLiters)) * 100)
        : 0,
    }));
  }

  async getFuelTrends(userId?: string, months = 6) {
    const now = new Date();

    const periods = Array.from({ length: months }, (_, i) => {
      const d = new Date(now.getFullYear(), now.getMonth() - (months - 1 - i), 1);
      return { month: d.getMonth() + 1, year: d.getFullYear() };
    });

    const results = await Promise.all(
      periods.map(async ({ month: m, year: y }) => {
        const [agg, anomalyCount] = await Promise.all([
          this.prisma.fuelAllocation.aggregate({
            _sum: { allocatedLiters: true, usedLiters: true },
            where: { month: m, year: y, ...(userId ? { userId } : {}) },
          }),
          this.prisma.anomalyLog.count({
            where: {
              createdAt: { gte: new Date(y, m - 1, 1), lt: new Date(y, m, 1) },
              ...(userId ? { userId } : {}),
            },
          }),
        ]);
        return {
          month: m,
          year: y,
          allocatedLiters: Number(agg._sum.allocatedLiters ?? 0),
          usedLiters: Number(agg._sum.usedLiters ?? 0),
          anomalyCount,
        };
      }),
    );

    return results;
  }

  async getSuspiciousDrivers() {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [suspiciousRequests, highAnomalies] = await Promise.all([
      this.prisma.fuelRequest.groupBy({
        by: ['driverId'],
        where: {
          fuelVariance: FuelVariance.SUSPICIOUS,
          createdAt: { gte: monthStart },
        },
        _count: { id: true },
      }),
      this.prisma.anomalyLog.groupBy({
        by: ['userId'],
        where: {
          severity: AnomalySeverity.HIGH,
          status: AnomalyStatus.OPEN,
        },
        _count: { id: true },
      }),
    ]);

    const driverIds = [
      ...new Set([
        ...suspiciousRequests.map((r) => r.driverId),
        ...highAnomalies.map((a) => a.userId),
      ]),
    ];

    if (!driverIds.length) return [];

    const drivers = await this.prisma.user.findMany({
      where: { id: { in: driverIds } },
      select: { id: true, fullName: true, department: true },
    });

    return drivers.map((d) => ({
      driverId: d.id,
      name: d.fullName,
      department: d.department,
      suspiciousRequestCount:
        suspiciousRequests.find((r) => r.driverId === d.id)?._count.id ?? 0,
      openHighAnomalies:
        highAnomalies.find((a) => a.userId === d.id)?._count.id ?? 0,
    }));
  }

  async getAIClassificationSummary(month?: number, year?: number) {
    const now = new Date();
    const safeMonth = Number(month) || now.getMonth() + 1;
    const safeYear = Number(year) || now.getFullYear();
    const monthStart = new Date(safeYear, safeMonth - 1, 1);
    const monthEnd = new Date(safeYear, safeMonth, 1);

    const where = { createdAt: { gte: monthStart, lt: monthEnd } };

    const [byVariance, byRecommendation] = await Promise.all([
      this.prisma.fuelRequest.groupBy({
        by: ['fuelVariance'],
        where,
        _count: { id: true },
      }),
      this.prisma.fuelRequest.groupBy({
        by: ['systemRecommendation'],
        where,
        _count: { id: true },
      }),
    ]);

    return {
      month: safeMonth,
      year: safeYear,
      variance: {
        NORMAL: byVariance.find((v) => v.fuelVariance === FuelVariance.NORMAL)?._count.id ?? 0,
        WARNING: byVariance.find((v) => v.fuelVariance === FuelVariance.WARNING)?._count.id ?? 0,
        SUSPICIOUS: byVariance.find((v) => v.fuelVariance === FuelVariance.SUSPICIOUS)?._count.id ?? 0,
      },
      recommendation: {
        APPROVE: byRecommendation.find((r) => r.systemRecommendation === SystemRecommendation.APPROVE)?._count.id ?? 0,
        FLAG: byRecommendation.find((r) => r.systemRecommendation === SystemRecommendation.FLAG)?._count.id ?? 0,
        REJECT: byRecommendation.find((r) => r.systemRecommendation === SystemRecommendation.REJECT)?._count.id ?? 0,
      },
    };
  }
}
