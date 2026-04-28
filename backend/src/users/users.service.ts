import {
  Injectable,
  ConflictException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GoogleMapsService } from '../common/services/google-maps.service';
import * as bcrypt from 'bcryptjs';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateLocationDto } from './dto/update-location.dto';

const USER_SELECT = {
  id: true,
  fullName: true,
  email: true,
  role: true,
  department: true,
  phone: true,
  isActive: true,
  createdAt: true,
};

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private prisma: PrismaService,
    private googleMaps: GoogleMapsService,
  ) {}

  async create(dto: CreateUserDto) {
    const email = dto.email.toLowerCase().trim();
    const exists = await this.prisma.user.findUnique({
      where: { email },
    });
    if (exists) throw new ConflictException('Email already registered');

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const { password, ...data } = dto;

    return this.prisma.user.create({
      data: { ...data, email, passwordHash, isActive: true, approvalStatus: 'APPROVED' as any },
      select: USER_SELECT,
    });
  }

  async findAll(role?: string) {
    return this.prisma.user.findMany({
      where: {
        isActive: true,
        ...(role ? { role: role as any } : {}),
      },
      select: USER_SELECT,
      orderBy: { fullName: 'asc' },
    });
  }

  async findByManager(managerId: string) {
    return this.prisma.user.findMany({
      where: { managerId, isActive: true },
      select: USER_SELECT,
      orderBy: { fullName: 'asc' },
    });
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        ...USER_SELECT,
        manager: { select: { id: true, fullName: true, email: true } },
        vehicles: {
          select: { id: true, plateNumber: true, make: true, model: true },
        },
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async update(id: string, dto: Partial<CreateUserDto>) {
    await this.findOne(id);
    const data: any = { ...dto };
    if (dto.password) {
      data.passwordHash = await bcrypt.hash(dto.password, 12);
      delete data.password;
    }
    return this.prisma.user.update({ where: { id }, data, select: USER_SELECT });
  }

  async updateLocation(id: string, dto: UpdateLocationDto) {
    await this.findOne(id);
    return this.prisma.user.update({
      where: { id },
      data: {
        homeLat: dto.homeLat,
        homeLng: dto.homeLng,
        workLat: dto.workLat,
        workLng: dto.workLng,
      },
      select: {
        id: true,
        fullName: true,
        homeLat: true,
        homeLng: true,
        workLat: true,
        workLng: true,
      },
    });
  }

  async deactivate(id: string) {
    await this.findOne(id);
    return this.prisma.user.update({
      where: { id },
      data: { isActive: false },
      select: { id: true, fullName: true, isActive: true },
    });
  }

  async findPending() {
    return this.prisma.user.findMany({
      where: { approvalStatus: 'PENDING' as any, role: 'DRIVER' },
      select: {
        ...USER_SELECT,
        approvalStatus: true,
        homeLat: true,
        homeLng: true,
        workLat: true,
        workLng: true,
        vehicles: { select: { id: true, plateNumber: true, make: true, model: true, fuelType: true, averageKmPerL: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async approve(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if ((user as any).approvalStatus === 'APPROVED') {
      throw new BadRequestException('User is already approved');
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { isActive: true, approvalStatus: 'APPROVED' as any },
      select: { id: true, fullName: true, email: true, role: true, isActive: true, approvalStatus: true },
    });

    // Auto-calculate daily distance (non-blocking)
    if (user.homeLat && user.homeLng && user.workLat && user.workLng) {
      this.calculateAndStoreDailyDistance(userId).catch((err) =>
        this.logger.warn(`Distance calc failed for ${userId}: ${err.message}`),
      );
    }

    return updated;
  }

  async reject(userId: string, reason?: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    return this.prisma.user.update({
      where: { id: userId },
      data: { isActive: false, approvalStatus: 'REJECTED' as any },
      select: { id: true, fullName: true, email: true, approvalStatus: true },
    });
  }

  async calculateAndStoreDailyDistance(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (user.dailyDistanceKm) {
      return { id: user.id, fullName: user.fullName, dailyDistanceKm: user.dailyDistanceKm, cached: true };
    }

    if (!user.homeLat || !user.homeLng || !user.workLat || !user.workLng) {
      throw new BadRequestException('Home and work coordinates must be set before calculating distance');
    }

    const oneWayKm =
      (await this.googleMaps.getDistanceKm(user.homeLat, user.homeLng, user.workLat, user.workLng)) ??
      this.haversineDistance(user.homeLat, user.homeLng, user.workLat, user.workLng);

    const dailyDistanceKm = Math.round(oneWayKm * 2 * 10) / 10;

    return this.prisma.user.update({
      where: { id: userId },
      data: { dailyDistanceKm },
      select: { id: true, fullName: true, dailyDistanceKm: true },
    });
  }

  async resetDailyDistance(userId: string) {
    await this.findOne(userId);
    return this.prisma.user.update({
      where: { id: userId },
      data: { dailyDistanceKm: null },
      select: { id: true, fullName: true, dailyDistanceKm: true },
    });
  }

  private haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}
