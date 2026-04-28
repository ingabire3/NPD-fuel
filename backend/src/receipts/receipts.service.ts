import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../common/services/cloudinary.service';
import { AiService } from '../common/services/ai.service';
import { AnomaliesService } from '../anomalies/anomalies.service';
import { RequestStatus } from '@prisma/client';

@Injectable()
export class ReceiptsService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService,
    private aiService: AiService,
    private anomalies: AnomaliesService,
  ) {}

  async uploadReceipt(
    requestId: string,
    file: Express.Multer.File,
    uploaderId: string,
    uploaderRole: string,
  ) {
    const request = await this.prisma.fuelRequest.findUnique({
      where: { id: requestId },
    });
    if (!request) throw new NotFoundException('Request not found');
    if (request.status !== RequestStatus.FULFILLED) {
      throw new BadRequestException(
        'Can only upload receipt for fulfilled requests',
      );
    }
    // Drivers can only upload receipts for their own requests
    if (uploaderRole === 'DRIVER' && request.driverId !== uploaderId) {
      throw new ForbiddenException('You can only upload receipts for your own requests');
    }

    const existing = await this.prisma.fuelReceipt.findUnique({
      where: { requestId },
    });
    if (existing) {
      throw new BadRequestException(
        'Receipt already uploaded for this request',
      );
    }

    const imageUrl = await this.cloudinary.uploadBuffer(
      file.buffer,
      'npd/receipts',
    );

    // OCR is non-blocking — receipt saved even if AI is down
    let ocrData: any = null;
    let confidence: number | null = null;
    try {
      const result = await this.aiService.extractReceiptOcr(imageUrl);
      ocrData = result?.data;
      confidence = result?.confidence ?? null;
    } catch {
      // AI service unavailable — continue without OCR
    }

    // Smart rule: future date validation
    if (ocrData?.date) {
      const receiptDate = new Date(ocrData.date);
      if (receiptDate > new Date()) {
        throw new BadRequestException('Receipt date cannot be in the future');
      }
    }

    // Smart rule: duplicate receipt detection (same station + amount + date within driver's history)
    if (ocrData?.stationName && ocrData?.amount && ocrData?.date) {
      const duplicate = await this.prisma.fuelReceipt.findFirst({
        where: {
          stationName: ocrData.stationName,
          amountPaid: ocrData.amount,
          receiptDate: new Date(ocrData.date),
          request: { driverId: request.driverId },
        },
      });
      if (duplicate) {
        throw new ConflictException(
          'Duplicate receipt detected: same station, amount, and date already recorded',
        );
      }
    }

    const receipt = await this.prisma.fuelReceipt.create({
      data: {
        requestId,
        imageUrl,
        ocrRawData: ocrData,
        ocrConfidence: confidence,
        stationName: ocrData?.stationName ?? null,
        litersDispensed: ocrData?.liters ?? null,
        amountPaid: ocrData?.amount ?? null,
        receiptDate: ocrData?.date ? new Date(ocrData.date) : null,
      },
    });

    await this.anomalies.checkReceiptAnomalies(receipt, request);
    return receipt;
  }

  async findAll(userId: string, role: string) {
    let where: any = {};
    if (role === 'DRIVER') {
      where = { request: { driverId: userId } };
    } else if (role === 'MANAGER') {
      where = { request: { driver: { managerId: userId } } };
    }
    // SUPER_ADMIN and FINANCE: no filter, see all
    return this.prisma.fuelReceipt.findMany({
      where,
      include: {
        request: {
          select: {
            id: true,
            driverId: true,
            vehicle: { select: { plateNumber: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findByRequest(requestId: string) {
    const receipt = await this.prisma.fuelReceipt.findUnique({
      where: { requestId },
    });
    if (!receipt) throw new NotFoundException('Receipt not found');
    return receipt;
  }
}
