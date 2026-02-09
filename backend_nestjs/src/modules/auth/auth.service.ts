import { Injectable, UnauthorizedException, BadRequestException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../../database/prisma.service';
import { RegisterPatientDto, RegisterDoctorDto } from './dto';
import { OtpService } from './otp.service';

@Injectable()
export class AuthService {
  private readonly LOCK_DURATION = 15 * 60 * 1000; // 15 minutes
  private readonly MAX_FAILED_ATTEMPTS = 5;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private otpService: OtpService,
  ) {}

  async validateUser(phoneNumber: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if account is locked
    if (user.accountStatus === 'LOCKED' && user.lockedUntil) {
      if (new Date() < user.lockedUntil) {
        const remainingMinutes = Math.ceil((user.lockedUntil.getTime() - Date.now()) / 60000);
        throw new UnauthorizedException(`Account is locked. Try again in ${remainingMinutes} minutes.`);
      } else {
        // Unlock account
        await this.prisma.user.update({
          where: { id: user.id },
          data: { accountStatus: 'ACTIVE', failedLoginAttempts: 0, lockedUntil: null },
        });
      }
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    
    if (!isPasswordValid) {
      const failedAttempts = user.failedLoginAttempts + 1;
      
      if (failedAttempts >= this.MAX_FAILED_ATTEMPTS) {
        await this.prisma.user.update({
          where: { id: user.id },
          data: {
            accountStatus: 'LOCKED',
            failedLoginAttempts: failedAttempts,
            lockedUntil: new Date(Date.now() + this.LOCK_DURATION),
          },
        });
        throw new UnauthorizedException('Account locked due to too many failed attempts. Try again in 15 minutes.');
      }

      await this.prisma.user.update({
        where: { id: user.id },
        data: { failedLoginAttempts: failedAttempts },
      });

      throw new UnauthorizedException(`Invalid credentials. ${this.MAX_FAILED_ATTEMPTS - failedAttempts} attempts remaining.`);
    }

    // Reset failed attempts on successful login
    if (user.failedLoginAttempts > 0) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { failedLoginAttempts: 0 },
      });
    }

    const { passwordHash, pinCodeHash, ...result } = user;
    return result;
  }

  async login(user: any) {
    const payload = { sub: user.id, phoneNumber: user.phoneNumber, role: user.role };
    
    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get('JWT_REFRESH_SECRET'),
      expiresIn: this.configService.get('JWT_REFRESH_EXPIRES_IN') || '7d',
    });

    return {
      accessToken,
      refreshToken,
      user,
    };
  }

  async registerPatient(dto: RegisterPatientDto) {
    // Check age requirement (at least 13 years old)
    const birthDate = new Date(dto.dateOfBirth);
    const age = Math.floor((Date.now() - birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
    
    if (age < 13) {
      throw new BadRequestException('You must be at least 13 years old to register');
    }

    // Check if phone number already exists
    const existingUser = await this.prisma.user.findUnique({
      where: { phoneNumber: dto.phoneNumber },
    });

    if (existingUser) {
      throw new ConflictException('Phone number is already registered');
    }

    // Hash password and PIN
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const pinCodeHash = await bcrypt.hash(dto.pinCode, 10);

    // Create user with PENDING status (requires OTP verification)
    const user = await this.prisma.user.create({
      data: {
        role: 'PATIENT',
        firstName: dto.firstName,
        lastName: dto.lastName,
        phoneNumber: dto.phoneNumber,
        passwordHash,
        pinCodeHash,
        gender: dto.gender,
        dateOfBirth: new Date(dto.dateOfBirth),
        idCardNumber: dto.idCardNumber,
        accountStatus: 'PENDING_VERIFICATION',
      },
    });

    // Send OTP
    await this.otpService.sendOtp(dto.phoneNumber);

    return {
      message: 'Registration successful. Please verify your phone number with the OTP sent.',
      requiresOTP: true,
      userId: user.id,
    };
  }

  async registerDoctor(dto: RegisterDoctorDto) {
    // Check if phone number already exists
    const existingUser = await this.prisma.user.findUnique({
      where: { phoneNumber: dto.phoneNumber },
    });

    if (existingUser) {
      throw new ConflictException('Phone number is already registered');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(dto.password, 10);

    // Create doctor with PENDING_VERIFICATION status
    const user = await this.prisma.user.create({
      data: {
        role: 'DOCTOR',
        fullName: dto.fullName,
        phoneNumber: dto.phoneNumber,
        passwordHash,
        hospitalClinic: dto.hospitalClinic,
        specialty: dto.specialty,
        licenseNumber: dto.licenseNumber,
        licensePhotoUrl: dto.licensePhotoUrl,
        accountStatus: 'PENDING_VERIFICATION',
      },
    });

    return {
      message: 'Doctor registration submitted. Your account will be verified by an administrator.',
      status: 'PENDING_VERIFICATION',
      userId: user.id,
    };
  }

  async verifyOtp(phoneNumber: string, otp: string) {
    await this.otpService.verifyOtp(phoneNumber, otp);

    // Update user status to ACTIVE
    const user = await this.prisma.user.update({
      where: { phoneNumber },
      data: { accountStatus: 'ACTIVE' },
    });

    // Create default subscription
    await this.prisma.subscription.create({
      data: {
        userId: user.id,
        tier: 'FREEMIUM',
        storageQuota: 5368709120, // 5GB
        storageUsed: 0,
      },
    });

    const { passwordHash, pinCodeHash, ...result } = user;
    return this.login(result);
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      const { passwordHash, pinCodeHash, ...result } = user;
      return this.login(result);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async googleLogin(profile: any) {
    let user = await this.prisma.user.findUnique({
      where: { email: profile.email },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          email: profile.email,
          firstName: profile.firstName,
          lastName: profile.lastName,
          fullName: profile.displayName,
          phoneNumber: profile.email, // Temporary, should be updated
          passwordHash: await bcrypt.hash(Math.random().toString(36), 10),
          role: 'PATIENT',
          accountStatus: 'ACTIVE',
        },
      });

      // Create default subscription
      await this.prisma.subscription.create({
        data: {
          userId: user.id,
          tier: 'FREEMIUM',
          storageQuota: 5368709120,
          storageUsed: 0,
        },
      });
    }

    const { passwordHash, pinCodeHash, ...result } = user;
    return this.login(result);
  }
}
