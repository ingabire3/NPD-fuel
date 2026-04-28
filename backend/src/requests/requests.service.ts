import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AnomaliesService } from '../anomalies/anomalies.service';
import { AllocationsService } from '../allocations/allocations.service';
import { CloudinaryService } from '../common/services/cloudinary.service';
import { FuelEstimationService } from '../fuel-estimation/fuel-estimation.service';
import { CreateRequestDto } from './dto/create-request.dto';
import { RequestStatus, FuelVariance, SystemRecommendation } from '@prisma/client';

const MAX_EXTRA_THRESHOLD = 1.2;

@Injectable()
export class RequestsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
    private anomalies: AnomaliesService,
    private allocations: AllocationsService,
    private cloudinary: CloudinaryService,
    private fuelEstimation: FuelEstimationService,
  ) {}

  async uploadOdometerImage(file: Express.Multer.File): Promise<string> {
    return this.cloudinary.uploadBuffer(file.buffer, 'npd/odometers');
  }

  async create(driverId: string, dto: CreateRequestDto) {
    // Verify driver is approved before proceeding; also fetch managerId for notifications
    const driverInfo = await this.prisma.user.findUnique({
      where: { id: driverId },
      select: { approvalStatus: true, isActive: true, managerId: true },
    });
    if (!driverInfo?.isActive || driverInfo.approvalStatus !== 'APPROVED') {
      throw new ForbiddenException('Your account must be approved before you can submit fuel requests.');
    }

    const now = new Date();
    // Find any active allocation for this driver this month (vehicle-agnostic)
    const allocation = await this.prisma.fuelAllocation.findFirst({
      where: {
        userId: driverId,
        month: now.getMonth() + 1,
        year: now.getFullYear(),
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!allocation) {
      throw new BadRequestException(
        'No fuel allocation found for your account this month. Contact your manager to create one.',
      );
    }
    if (allocation.remainingLiters < dto.requestedLiters) {
      throw new BadRequestException(
        `Insufficient allocation. Remaining: ${allocation.remainingLiters}L`,
      );
    }

    // Fuel estimation — non-blocking, falls back gracefully if no location/efficiency set
    let estimatedDistance: number | undefined;
    let expectedFuel: number | undefined;
    let fuelVariance: FuelVariance = FuelVariance.NORMAL;

    const estimation = await this.fuelEstimation.estimate(driverId, dto.vehicleId);
    if (estimation) {
      estimatedDistance = estimation.distanceKm;
      expectedFuel = estimation.expectedFuel;
      fuelVariance = this.fuelEstimation.classify(dto.requestedLiters, estimation.expectedFuel);
    }

    const systemRecommendation = this.generateRecommendation(
      dto.requestedLiters,
      expectedFuel ?? null,
      fuelVariance,
      allocation,
    );

    const request = await this.prisma.fuelRequest.create({
      data: {
        driverId,
        vehicleId: dto.vehicleId,
        allocationId: allocation.id,
        requestedLiters: dto.requestedLiters,
        requestedAmount: dto.requestedAmount ?? 0,
        purpose: dto.purpose,
        tripDescription: dto.tripDescription,
        odometerBefore: dto.odometerBefore,
        odometerImageUrl: dto.odometerImageUrl,
        estimatedDistance,
        expectedFuel,
        fuelVariance,
        systemRecommendation,
      },
      include: {
        driver: { select: { fullName: true } },
        vehicle: { select: { plateNumber: true } },
      },
    });

    // Notify Finance team and SUPER_ADMIN (approvers), plus the driver's manager
    const managers = await this.prisma.user.findMany({
      where: {
        isActive: true,
        OR: [
          { role: { in: ['FINANCE', 'SUPER_ADMIN'] } },
          ...(driverInfo.managerId ? [{ id: driverInfo.managerId }] : []),
        ],
      },
      select: { id: true },
    });

    const driverName = (request as any).driver?.fullName ?? driverId;
    const plateName = (request as any).vehicle?.plateNumber ?? dto.vehicleId;

    await Promise.all(
      managers.map((m) =>
        this.notifications.create(m.id, {
          title: 'New Fuel Request',
          message: `${driverName} requested ${dto.requestedLiters}L for ${plateName}`,
          type: 'FUEL_REQUEST_PENDING',
          metadata: { requestId: request.id },
        }),
      ),
    );

    // Log anomaly for suspicious fuel variance
    if (fuelVariance === FuelVariance.SUSPICIOUS && expectedFuel) {
      const overPct = Math.round((dto.requestedLiters / expectedFuel - 1) * 100);
      await this.anomalies.checkVarianceAnomaly({
        id: request.id,
        driverId,
        requestedLiters: dto.requestedLiters,
        expectedFuel,
        overPct,
      });
    }

    return request;
  }

  async findAll(filters: {
    status?: RequestStatus;
    driverId?: string;
    managerId?: string;
    page?: number;
    limit?: number;
  }) {
    const { status, driverId, managerId } = filters;
    const page = Number(filters.page) || 1;
    const limit = Number(filters.limit) || 20;
    const skip = (page - 1) * limit;

    // If manager-scoped, resolve subordinate IDs first
    let driverIdFilter: string | { in: string[] } | undefined;
    if (driverId) {
      driverIdFilter = driverId;
    } else if (managerId) {
      const subs = await this.prisma.user.findMany({
        where: { managerId, isActive: true },
        select: { id: true },
      });
      if (subs.length === 0) return { data: [], total: 0, page, limit };
      driverIdFilter = { in: subs.map((u) => u.id) };
    }

    const where = {
      ...(status ? { status } : {}),
      ...(driverIdFilter ? { driverId: driverIdFilter } : {}),
    };

    const [data, total] = await Promise.all([
      this.prisma.fuelRequest.findMany({
        where,
        include: {
          driver: {
            select: { id: true, fullName: true, department: true },
          },
          vehicle: {
            select: { plateNumber: true, make: true, model: true },
          },
          receipt: { select: { id: true, verificationStatus: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.fuelRequest.count({ where }),
    ]);

    return { data, total, page, limit };
  }

  async findOne(id: string) {
    const req = await this.prisma.fuelRequest.findUnique({
      where: { id },
      include: {
        driver: {
          select: { id: true, fullName: true, email: true, department: true },
        },
        vehicle: true,
        allocation: true,
        receipt: true,
        approver: { select: { id: true, fullName: true } },
        anomalies: true,
      },
    });
    if (!req) throw new NotFoundException('Request not found');
    return req;
  }

  async approve(requestId: string, approverId: string) {
    const req = await this.findOne(requestId);
    if (req.status !== RequestStatus.PENDING) {
      throw new BadRequestException('Only pending requests can be approved');
    }

    const updated = await this.prisma.fuelRequest.update({
      where: { id: requestId },
      data: {
        status: RequestStatus.APPROVED,
        approverId,
        approvedAt: new Date(),
      },
    });

    await this.notifications.create(req.driverId, {
      title: 'Fuel Request Approved',
      message: `Your request for ${req.requestedLiters}L has been approved`,
      type: 'REQUEST_APPROVED',
      metadata: { requestId },
    });

    return updated;
  }

  async reject(requestId: string, approverId: string, reason: string) {
    const req = await this.findOne(requestId);
    if (req.status !== RequestStatus.PENDING) {
      throw new BadRequestException('Only pending requests can be rejected');
    }

    const updated = await this.prisma.fuelRequest.update({
      where: { id: requestId },
      data: {
        status: RequestStatus.REJECTED,
        approverId,
        rejectionReason: reason,
      },
    });

    await this.notifications.create(req.driverId, {
      title: 'Fuel Request Rejected',
      message: `Your request was rejected: ${reason}`,
      type: 'REQUEST_REJECTED',
      metadata: { requestId },
    });

    return updated;
  }

  private generateRecommendation(
    requestedLiters: number,
    expectedFuel: number | null,
    fuelVariance: FuelVariance,
    allocation: { remainingLiters: number | bigint; allocatedLiters: number | bigint },
  ): SystemRecommendation {
    if (fuelVariance === FuelVariance.SUSPICIOUS) return SystemRecommendation.REJECT;
    if (requestedLiters > Number(allocation.remainingLiters)) return SystemRecommendation.REJECT;

    if (expectedFuel && requestedLiters > expectedFuel * MAX_EXTRA_THRESHOLD) {
      return SystemRecommendation.FLAG;
    }
    if (fuelVariance === FuelVariance.WARNING) return SystemRecommendation.FLAG;

    return SystemRecommendation.APPROVE;
  }

  async markFulfilled(requestId: string, odometerAfter: number) {
    const req = await this.findOne(requestId);
    if (req.status !== RequestStatus.APPROVED) {
      throw new BadRequestException('Only approved requests can be fulfilled');
    }
    if (req.odometerBefore != null && odometerAfter <= req.odometerBefore) {
      throw new BadRequestException(
        `End odometer (${odometerAfter}) must be greater than start odometer (${req.odometerBefore})`,
      );
    }

    const updated = await this.prisma.fuelRequest.update({
      where: { id: requestId },
      data: {
        status: RequestStatus.FULFILLED,
        odometerAfter,
        fulfilledAt: new Date(),
      },
    });

    if (req.allocationId) {
      await this.allocations.deductAllocation(
        req.allocationId,
        req.requestedLiters,
      );
    }

    await this.anomalies.checkRequestAnomalies(updated);
    return updated;
  }
}
