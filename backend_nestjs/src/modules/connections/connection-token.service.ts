import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { PermissionLevel } from '@prisma/client';
import * as crypto from 'crypto';

export interface TokenValidationResult {
  valid: boolean;
  token?: any;
  patientName?: string;
  permissionLevel?: PermissionLevel;
  error?: string;
}

@Injectable()
export class ConnectionTokenService {
  constructor(private prisma: PrismaService) {}

  /**
   * Generate a unique connection token for a patient.
   * Token is 8 characters, base64url encoded, expires in 24 hours.
   */
  async generateToken(patientId: string, permissionLevel: PermissionLevel) {
    // Verify patient exists
    const patient = await this.prisma.user.findUnique({ where: { id: patientId } });
    if (!patient) {
      throw new NotFoundException('Patient not found');
    }

    // Generate unique 8-character token
    const token = crypto.randomBytes(6).toString('base64url').substring(0, 8).toUpperCase();

    // Set expiration to 24 hours from now
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    return this.prisma.connectionToken.create({
      data: {
        patientId,
        token,
        permissionLevel,
        expiresAt,
      },
    });
  }

  /**
   * Validate a connection token.
   * Checks: exists, not expired, not used.
   */
  async validateToken(tokenString: string): Promise<TokenValidationResult> {
    const tokenRecord = await this.prisma.connectionToken.findUnique({
      where: { token: tokenString.toUpperCase() },
      include: {
        patient: {
          select: { id: true, firstName: true, lastName: true, fullName: true, role: true },
        },
      },
    });

    if (!tokenRecord) {
      return { valid: false, error: 'Invalid token' };
    }

    if (tokenRecord.usedAt) {
      return { valid: false, error: 'Token has already been used' };
    }

    if (new Date() > tokenRecord.expiresAt) {
      return { valid: false, error: 'Token has expired' };
    }

    const patientName = tokenRecord.patient.fullName ||
      `${tokenRecord.patient.firstName || ''} ${tokenRecord.patient.lastName || ''}`.trim();

    return {
      valid: true,
      token: tokenRecord,
      patientName,
      permissionLevel: tokenRecord.permissionLevel,
    };
  }

  /**
   * Consume a token to create a connection.
   * Marks token as used and creates a PENDING connection.
   */
  async consumeToken(tokenString: string, caregiverId: string) {
    const validation = await this.validateToken(tokenString);

    if (!validation.valid) {
      throw new BadRequestException(validation.error);
    }

    const tokenRecord = validation.token;

    // Prevent self-connection
    if (tokenRecord.patientId === caregiverId) {
      throw new BadRequestException('Cannot connect to yourself');
    }

    // Check if connection already exists
    const existingConnection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: caregiverId, recipientId: tokenRecord.patientId },
          { initiatorId: tokenRecord.patientId, recipientId: caregiverId },
        ],
        status: { not: 'REVOKED' },
      },
    });

    if (existingConnection) {
      throw new BadRequestException('Connection already exists');
    }

    // Transaction: mark token as used + create connection
    const [, connection] = await this.prisma.$transaction([
      this.prisma.connectionToken.update({
        where: { id: tokenRecord.id },
        data: { usedAt: new Date(), usedById: caregiverId },
      }),
      this.prisma.connection.create({
        data: {
          initiatorId: caregiverId,
          recipientId: tokenRecord.patientId,
          status: 'PENDING',
          permissionLevel: tokenRecord.permissionLevel,
          metadata: { alertsEnabled: true },
        },
        include: {
          initiator: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true } },
          recipient: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true } },
        },
      }),
    ]);

    return connection;
  }

  /**
   * Cleanup expired tokens (run daily).
   */
  async cleanupExpiredTokens(): Promise<number> {
    const cutoff = new Date();
    cutoff.setHours(cutoff.getHours() - 48);

    const result = await this.prisma.connectionToken.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: new Date() }, usedAt: null },
          { createdAt: { lt: cutoff } },
        ],
      },
    });

    return result.count;
  }

  /**
   * Get active tokens for a patient.
   */
  async getActiveTokens(patientId: string) {
    return this.prisma.connectionToken.findMany({
      where: {
        patientId,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
