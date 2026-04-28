import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  AnomalyType,
  AnomalySeverity,
  AnomalyStatus,
  FuelRequest,
  FuelReceipt,
} from '@prisma/client';

type AnomalyInput = {
  type: AnomalyType;
  severity: AnomalySeverity;
  description: string;
  evidence: object;
};

@Injectable()
export class AnomaliesService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  async checkRequestAnomalies(request: FuelRequest) {
    const anomalies: AnomalyInput[] = [];

    // Rule 1 & 2: Odometer checks
    if (request.odometerBefore !== null && request.odometerAfter !== null) {
      const distance = request.odometerAfter - request.odometerBefore;

      if (distance < 0) {
        anomalies.push({
          type: AnomalyType.ODOMETER_MISMATCH,
          severity: AnomalySeverity.HIGH,
          description: 'Odometer reading decreased — possible tampering',
          evidence: {
            before: request.odometerBefore,
            after: request.odometerAfter,
          },
        });
      } else if (distance > 0) {
        const vehicle = await this.prisma.vehicle.findUnique({
          where: { id: request.vehicleId },
        });
        if (vehicle?.averageKmPerL) {
          const expected = distance / vehicle.averageKmPerL;
          const deviation =
            Math.abs(request.requestedLiters - expected) / expected;
          if (deviation > 0.5) {
            anomalies.push({
              type: AnomalyType.EXCESS_CONSUMPTION,
              severity:
                deviation > 1.0
                  ? AnomalySeverity.HIGH
                  : AnomalySeverity.MEDIUM,
              description: `Fuel usage ${Math.round(deviation * 100)}% above expected for ${distance}km`,
              evidence: {
                distance,
                requested: request.requestedLiters,
                expected: Math.round(expected * 10) / 10,
                deviationPct: Math.round(deviation * 100),
              },
            });
          }
        }
      }
    }

    // Rule 3: Frequency abuse — more than 3 requests in 7 days
    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const recentCount = await this.prisma.fuelRequest.count({
      where: {
        driverId: request.driverId,
        status: { in: ['APPROVED', 'FULFILLED'] },
        createdAt: { gte: cutoff },
      },
    });
    if (recentCount > 3) {
      anomalies.push({
        type: AnomalyType.FREQUENCY_ABUSE,
        severity: AnomalySeverity.MEDIUM,
        description: `${recentCount} requests in past 7 days (limit: 3)`,
        evidence: { count: recentCount, windowDays: 7 },
      });
    }

    await this.persistAnomalies(request.driverId, request.id, anomalies);
  }

  async checkReceiptAnomalies(receipt: FuelReceipt, request: FuelRequest) {
    const anomalies: AnomalyInput[] = [];

    // Rule 4: Receipt liters differ >20% from requested
    if (receipt.litersDispensed && request.requestedLiters) {
      const diff = Math.abs(
        receipt.litersDispensed - request.requestedLiters,
      );
      const pct = diff / request.requestedLiters;
      if (pct > 0.2) {
        anomalies.push({
          type: AnomalyType.FAKE_RECEIPT,
          severity: AnomalySeverity.HIGH,
          description: `Receipt shows ${receipt.litersDispensed}L vs ${request.requestedLiters}L requested`,
          evidence: {
            receiptLiters: receipt.litersDispensed,
            requestedLiters: request.requestedLiters,
            discrepancyPct: Math.round(pct * 100),
          },
        });
      }
    }

    // Rule 5: OCR confidence too low
    if (receipt.ocrConfidence !== null && receipt.ocrConfidence < 0.4) {
      anomalies.push({
        type: AnomalyType.FAKE_RECEIPT,
        severity: AnomalySeverity.MEDIUM,
        description: `Low OCR confidence (${Math.round((receipt.ocrConfidence ?? 0) * 100)}%) — receipt may be invalid`,
        evidence: { confidence: receipt.ocrConfidence },
      });
    }

    await this.persistAnomalies(request.driverId, request.id, anomalies);
  }

  private async persistAnomalies(
    userId: string,
    requestId: string | null,
    anomalies: AnomalyInput[],
  ) {
    if (!anomalies.length) return;

    await this.prisma.anomalyLog.createMany({
      data: anomalies.map((a) => ({
        ...a,
        userId,
        ...(requestId ? { requestId } : {}),
      })),
    });

    // Notify admins for HIGH severity only
    const highSeverity = anomalies.filter(
      (a) => a.severity === AnomalySeverity.HIGH,
    );
    if (highSeverity.length) {
      const admins = await this.prisma.user.findMany({
        where: { role: { in: ['SUPER_ADMIN', 'MANAGER'] }, isActive: true },
        select: { id: true },
      });
      await Promise.all(
        admins.map((a) =>
          this.notifications.create(a.id, {
            title: 'High Severity Anomaly Detected',
            message: highSeverity.map((x) => x.description).join('; '),
            type: 'ANOMALY_HIGH',
            metadata: { requestId, userId },
          }),
        ),
      );
    }
  }

  async checkVarianceAnomaly(params: {
    id: string;
    driverId: string;
    requestedLiters: number;
    expectedFuel: number;
    overPct: number;
  }) {
    await this.persistAnomalies(params.driverId, params.id, [
      {
        type: AnomalyType.EXCESS_CONSUMPTION,
        severity: AnomalySeverity.HIGH,
        description: `Requested ${params.requestedLiters}L is ${params.overPct}% above estimated ${params.expectedFuel}L`,
        evidence: {
          requestedLiters: params.requestedLiters,
          expectedFuel: params.expectedFuel,
          overPercent: params.overPct,
        },
      },
    ]);
  }

  async logAnomaly(params: {
    userId: string;
    requestId?: string;
    type: AnomalyType;
    severity: AnomalySeverity;
    description: string;
    evidence?: object;
  }) {
    const anomaly: AnomalyInput = {
      type: params.type,
      severity: params.severity,
      description: params.description,
      evidence: params.evidence ?? {},
    };
    await this.persistAnomalies(params.userId, params.requestId ?? null, [anomaly]);
  }

  async findAll(status?: string, userId?: string) {
    return this.prisma.anomalyLog.findMany({
      where: {
        ...(status ? { status: status as AnomalyStatus } : {}),
        ...(userId ? { userId } : {}),
      },
      include: {
        user: { select: { id: true, fullName: true, department: true } },
        request: {
          select: { id: true, requestedLiters: true, createdAt: true },
        },
      },
      orderBy: [{ severity: 'desc' }, { createdAt: 'desc' }],
    });
  }

  async resolve(id: string, resolvedBy: string, resolution: string) {
    return this.prisma.anomalyLog.update({
      where: { id },
      data: {
        status: AnomalyStatus.RESOLVED,
        resolvedBy,
        resolution,
        resolvedAt: new Date(),
      },
    });
  }
}
