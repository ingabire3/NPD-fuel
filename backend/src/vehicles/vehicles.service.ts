import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';

@Injectable()
export class VehiclesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateVehicleDto) {
    const exists = await this.prisma.vehicle.findUnique({
      where: { plateNumber: dto.plateNumber },
    });
    if (exists) throw new ConflictException('Plate number already registered');
    return this.prisma.vehicle.create({ data: dto });
  }

  async findAll() {
    return this.prisma.vehicle.findMany({
      where: { isActive: true },
      include: {
        assignedDriver: {
          select: { id: true, fullName: true, email: true },
        },
      },
    });
  }

  async findByDriver(driverId: string) {
    return this.prisma.vehicle.findMany({
      where: { isActive: true, assignedDriverId: driverId },
      include: {
        assignedDriver: { select: { id: true, fullName: true, email: true } },
      },
    });
  }

  async findByManager(managerId: string) {
    return this.prisma.vehicle.findMany({
      where: {
        isActive: true,
        assignedDriver: { managerId },
      },
      include: {
        assignedDriver: { select: { id: true, fullName: true, email: true } },
      },
    });
  }

  async findOne(id: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id },
      include: {
        assignedDriver: { select: { id: true, fullName: true } },
      },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');
    return vehicle;
  }

  async update(id: string, dto: Partial<CreateVehicleDto>) {
    await this.findOne(id);
    return this.prisma.vehicle.update({ where: { id }, data: dto });
  }

  async assignDriver(vehicleId: string, driverId: string) {
    await this.findOne(vehicleId);
    return this.prisma.vehicle.update({
      where: { id: vehicleId },
      data: { assignedDriverId: driverId },
    });
  }
}
