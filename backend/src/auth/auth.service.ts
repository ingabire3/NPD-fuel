import {
  Injectable,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.toLowerCase().trim();

    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new ConflictException('Email already registered');

    const plateExists = await this.prisma.vehicle.findUnique({
      where: { plateNumber: dto.plateNumber },
    });
    if (plateExists) throw new ConflictException('Plate number already registered');

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const user = await this.prisma.user.create({
      data: {
        fullName: dto.fullName,
        email,
        phone: dto.phone,
        department: dto.department,
        passwordHash,
        role: 'DRIVER',
        isActive: false,
        approvalStatus: 'PENDING',
        homeLat: dto.homeLat,
        homeLng: dto.homeLng,
        homeAddress: dto.homeAddress,
        workLat: dto.workLat,
        workLng: dto.workLng,
        workAddress: dto.workAddress,
      },
    });

    await this.prisma.vehicle.create({
      data: {
        plateNumber: dto.plateNumber,
        make: dto.vehicleMake,
        model: dto.vehicleModel,
        year: dto.vehicleYear,
        fuelType: dto.fuelType,
        tankCapacity: dto.tankCapacity,
        averageKmPerL: dto.averageKmPerL,
        assignedDriverId: user.id,
      },
    });

    return {
      message: 'Registration submitted successfully. Your account is pending admin approval.',
      userId: user.id,
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase().trim() },
    });

    if (!user) throw new UnauthorizedException('Invalid credentials');

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

    if (!user.isActive) {
      if (user.approvalStatus === 'PENDING') {
        throw new UnauthorizedException('Your account is pending admin approval. Please wait.');
      }
      if (user.approvalStatus === 'REJECTED') {
        throw new UnauthorizedException('Your account has been rejected. Contact the administrator.');
      }
      throw new UnauthorizedException('Account is inactive. Contact the administrator.');
    }

    const tokens = await this.generateTokens(user);
    return {
      ...tokens,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        department: user.department,
      },
    };
  }

  async refresh(refreshToken: string) {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const accessToken = this.jwt.sign(
      {
        sub: stored.user.id,
        email: stored.user.email,
        role: stored.user.role,
      },
      {
        secret: this.config.get<string>('jwt.secret'),
        expiresIn: this.config.get<string>('jwt.expiresIn'),
      },
    );

    return { accessToken, refreshToken };
  }

  async logout(userId: string, refreshToken: string) {
    await this.prisma.refreshToken.deleteMany({
      where: { token: refreshToken, userId },
    });
    return { message: 'Logged out successfully' };
  }

  private async generateTokens(user: {
    id: string;
    email: string;
    role: string;
  }) {
    const accessToken = this.jwt.sign(
      { sub: user.id, email: user.email, role: user.role },
      {
        secret: this.config.get<string>('jwt.secret'),
        expiresIn: this.config.get<string>('jwt.expiresIn'),
      },
    );

    const refreshToken = uuidv4();
    const expiryDays = this.config.get<number>('jwt.refreshExpiryDays');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expiryDays);

    await this.prisma.refreshToken.create({
      data: { token: refreshToken, userId: user.id, expiresAt },
    });

    return { accessToken, refreshToken };
  }
}
