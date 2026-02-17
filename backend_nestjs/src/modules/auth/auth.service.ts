import { Injectable, UnauthorizedException, BadRequestException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../../database/prisma.service';
import { RegisterPatientDto, RegisterDoctorDto } from './dto';
import { OtpService } from './otp.service';
import { EmailService } from '../email/email.service';
import { UserRole } from '@prisma/client';

@Injectable()
export class AuthService {
  private readonly LOCK_DURATION = 15 * 60 * 1000; // 15 minutes
  private readonly MAX_FAILED_ATTEMPTS = 5;
  private readonly BCRYPT_ROUNDS = 12;
  private readonly googleClient: OAuth2Client;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private otpService: OtpService,
    private emailService: EmailService,
  ) {
    const googleClientId = this.configService.get('GOOGLE_CLIENT_ID');
    this.googleClient = new OAuth2Client(googleClientId);
  }

  async validateUser(identifier: string, password: string) {
    // Look up by email if identifier contains '@', otherwise by phone
    const user = identifier.includes('@')
      ? await this.prisma.user.findUnique({ where: { email: identifier } })
      : await this.prisma.user.findUnique({ where: { phoneNumber: identifier } });

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

    const { passwordHash, ...result } = user;
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

    // Check if email already exists
    const existingEmail = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingEmail) {
      throw new ConflictException('Email is already registered');
    }

    // Check if phone number already exists (only if provided)
    if (dto.phoneNumber) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phoneNumber: dto.phoneNumber },
      });

      if (existingPhone) {
        throw new ConflictException('Phone number is already registered');
      }
    }

    // Check if ID card number already exists (only if provided)
    if (dto.idCardNumber) {
      const existingIdCard = await this.prisma.user.findUnique({
        where: { idCardNumber: dto.idCardNumber },
      });

      if (existingIdCard) {
        throw new ConflictException('ID card number is already registered');
      }
    }

    // Hash password
    const passwordHash = await bcrypt.hash(dto.password, this.BCRYPT_ROUNDS);

    // Generate placeholder phone number if not provided
    const phoneNumber = dto.phoneNumber || `nophone_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

    // Create user with PENDING status (requires OTP verification)
    const user = await this.prisma.user.create({
      data: {
        role: 'PATIENT',
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: dto.email,
        phoneNumber,
        passwordHash,
        gender: dto.gender,
        dateOfBirth: new Date(dto.dateOfBirth),
        idCardNumber: dto.idCardNumber || null,
        accountStatus: 'PENDING_VERIFICATION',
      },
    });

    // Generate and send OTP to email
    const otp = this.otpService.generateOtp();
    this.otpService.storeOtp(dto.email, otp);
    try {
      await this.emailService.sendOTP(dto.email, otp);
    } catch (error) {
      // Log but don't fail registration
    }

    return {
      message: 'Registration successful. Please verify your email with the OTP sent.',
      requiresOTP: true,
      userId: user.id,
    };
  }

  async registerDoctor(dto: RegisterDoctorDto) {
    // Check if email already exists
    const existingEmail = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingEmail) {
      throw new ConflictException('Email is already registered');
    }

    // Check if phone number already exists (only if provided)
    if (dto.phoneNumber) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phoneNumber: dto.phoneNumber },
      });

      if (existingPhone) {
        throw new ConflictException('Phone number is already registered');
      }
    }

    // Hash password
    const passwordHash = await bcrypt.hash(dto.password, this.BCRYPT_ROUNDS);

    // Generate placeholder phone number if not provided
    const phoneNumber = dto.phoneNumber || `nophone_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

    // Create doctor with PENDING_VERIFICATION status
    const user = await this.prisma.user.create({
      data: {
        role: 'DOCTOR',
        fullName: dto.fullName,
        email: dto.email,
        phoneNumber,
        passwordHash,
        hospitalClinic: dto.hospitalClinic || null,
        specialty: dto.specialty || null,
        licenseNumber: dto.licenseNumber || null,
        licensePhotoUrl: dto.licensePhotoUrl || null,
        accountStatus: 'PENDING_VERIFICATION',
      },
    });

    // Generate and send OTP to email
    const otp = this.otpService.generateOtp();
    this.otpService.storeOtp(dto.email, otp);
    try {
      await this.emailService.sendOTP(dto.email, otp);
    } catch (error) {
      // Log but don't fail registration
    }

    return {
      message: 'Doctor registration submitted. Please verify your email with the OTP sent.',
      status: 'PENDING_VERIFICATION',
      requiresOTP: true,
      userId: user.id,
    };
  }

  async verifyOtp(identifier: string, otp: string) {
    await this.otpService.verifyOtp(identifier, otp);

    // Look up user by email or phone based on identifier type
    const user = identifier.includes('@')
      ? await this.prisma.user.update({
          where: { email: identifier },
          data: { accountStatus: 'ACTIVE' },
        })
      : await this.prisma.user.update({
          where: { phoneNumber: identifier },
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

    const { passwordHash, ...result } = user;
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

      const { passwordHash, ...result } = user;
      return this.login(result);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  /**
   * Validate Google ID token from mobile apps and create/login user
   * Used for Flutter app Google Sign-In
   */
  async googleLoginMobile(idToken: string, userRole?: UserRole) {
    try {
      // Verify the ID token
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: this.configService.get('GOOGLE_CLIENT_ID'),
      });

      const payload = ticket.getPayload();

      if (!payload || !payload.email || !payload.sub) {
        throw new UnauthorizedException('Invalid Google token');
      }

      const { sub: googleId, email, given_name, family_name, name, picture } = payload;

      // Check if user exists by googleId or email
      let user = await this.prisma.user.findFirst({
        where: {
          OR: [
            { googleId },
            { email },
          ],
        },
      });

      if (!user) {
        // Create new user from Google profile
        const role = userRole || 'PATIENT'; // Default to PATIENT if not specified

        user = await this.prisma.user.create({
          data: {
            googleId,
            email,
            firstName: given_name || name?.split(' ')[0] || 'User',
            lastName: family_name || name?.split(' ')[1] || '',
            fullName: name || `${given_name || ''} ${family_name || ''}`.trim(),
            // phoneNumber is optional for Google users - they can add it later
            passwordHash: await bcrypt.hash(Math.random().toString(36), this.BCRYPT_ROUNDS),
            role,
            accountStatus: 'ACTIVE',
            profilePictureUrl: picture,
          },
        });

        // Create default subscription for patients
        if (role === 'PATIENT') {
          await this.prisma.subscription.create({
            data: {
              userId: user.id,
              tier: 'FREEMIUM',
              storageQuota: 5368709120, // 5GB
              storageUsed: 0,
            },
          });
        }
      } else {
        // Update user with googleId if not set
        const updateData: any = {};
        
        if (!user.googleId) {
          updateData.googleId = googleId;
        }
        
        if (picture && picture !== user.profilePictureUrl) {
          updateData.profilePictureUrl = picture;
        }

        if (Object.keys(updateData).length > 0) {
          user = await this.prisma.user.update({
            where: { id: user.id },
            data: updateData,
          });
        }
      }

      const { passwordHash, ...result } = user;
      return this.login(result);
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Invalid Google token: ' + error.message);
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
          passwordHash: await bcrypt.hash(Math.random().toString(36), this.BCRYPT_ROUNDS),
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

    const { passwordHash, ...result } = user;
    return this.login(result);
  }

  /**
   * Send password reset OTP/token to user via SMS (phone) or email.
   * Supports both phone number and email as identifier.
   */
  async forgotPassword(identifier: string) {
    // Try to find user by phone number first, then email
    let user = await this.prisma.user.findUnique({
      where: { phoneNumber: identifier },
    });

    if (!user) {
      user = await this.prisma.user.findUnique({
        where: { email: identifier },
      });
    }

    if (!user) {
      // Don't reveal whether the user exists
      return {
        message: 'If an account with that identifier exists, a reset code has been sent.',
        sent: true,
      };
    }

    // Generate OTP for phone, token for email
    const otp = this.otpService.generateOtp();
    const token = require('crypto').randomBytes(32).toString('hex');
    const expiresAt = Date.now() + 15 * 60 * 1000; // 15 minutes

    // Store reset token in user record
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        resetToken: token,
        resetTokenExpiry: new Date(expiresAt),
      },
    });

    // Send OTP via SMS if phone, or token link via email
    if (user.email && (identifier === user.email || identifier.includes('@'))) {
      // Store OTP for email verification
      this.otpService.storeOtp(user.email, otp);
      // Send email with reset link
      const resetLink = `${this.configService.get('FRONTEND_URL') || 'http://localhost:3000'}/reset-password?token=${token}`;
      try {
        await this.emailService.sendPasswordResetEmail(user.email, resetLink, otp);
      } catch (error) {
        // Log but don't fail - user can still use OTP
      }
      return {
        message: 'Password reset instructions sent to your email.',
        sent: true,
        method: 'email',
      };
    } else {
      // Store OTP for phone verification
      if (!user.phoneNumber) {
        throw new BadRequestException('User does not have a phone number. Please use email reset.');
      }
      this.otpService.storeOtp(user.phoneNumber, otp);
      // Send OTP via SMS
      await this.otpService.sendOtp(user.phoneNumber);
      return {
        message: 'A reset code has been sent to your phone.',
        sent: true,
        method: 'sms',
      };
    }
  }

  /**
   * Reset password using token or OTP.
   */
  async resetPassword(token: string, newPassword: string) {
    // Try to find user by reset token
    let user = await this.prisma.user.findFirst({
      where: {
        resetToken: token,
        resetTokenExpiry: { gte: new Date() },
      },
    });

    if (!user) {
      // Check if token is actually an OTP - try to find any user with pending OTP
      throw new BadRequestException('Invalid or expired reset token. Please request a new one.');
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, this.BCRYPT_ROUNDS);

    // Update password and clear reset token
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        resetToken: null,
        resetTokenExpiry: null,
        failedLoginAttempts: 0,
        accountStatus: user.accountStatus === 'LOCKED' ? 'ACTIVE' : user.accountStatus,
      },
    });

    return {
      message: 'Password has been reset successfully. You can now log in with your new password.',
    };
  }

  /**
   * Verify OTP and reset password.
   */
  async resetPasswordWithOtp(identifier: string, otp: string, newPassword: string) {
    // Verify OTP
    await this.otpService.verifyOtp(identifier, otp);

    // Find user by email or phone based on identifier type
    const user = identifier.includes('@')
      ? await this.prisma.user.findUnique({ where: { email: identifier } })
      : await this.prisma.user.findUnique({ where: { phoneNumber: identifier } });

    if (!user) {
      throw new BadRequestException('User not found.');
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, this.BCRYPT_ROUNDS);

    // Update password
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        resetToken: null,
        resetTokenExpiry: null,
        failedLoginAttempts: 0,
        accountStatus: user.accountStatus === 'LOCKED' ? 'ACTIVE' : user.accountStatus,
      },
    });

    return {
      message: 'Password has been reset successfully. You can now log in with your new password.',
    };
  }
}
