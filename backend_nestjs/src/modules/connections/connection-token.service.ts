import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditService } from '../audit/audit.service';
import { PermissionLevel } from '@prisma/client';
import * as crypto from 'crypto';

export type TargetRole = 'FAMILY_MEMBER' | 'DOCTOR';

export interface TokenValidationResult {
  valid: boolean;
  token?: any;
  patientName?: string;
  permissionLevel?: PermissionLevel;
  targetRole?: TargetRole;
  error?: string;
}

@Injectable()
export class ConnectionTokenService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
    private auditService: AuditService,
  ) {}

  /**
   * Generate a unique connection token for a patient.
   * Token is 8 characters, base64url encoded, expires in 24 hours.
   * 
   * The token is now ROLE-AGNOSTIC - whoever scans it (doctor or family member)
   * will create the appropriate connection type based on THEIR role.
   * 
   * @param patientId - The ID of the patient generating the token
   * @param permissionLevel - The permission level for the connection (for family members)
   * @param targetRole - DEPRECATED: Kept for backward compatibility but ignored
   */
  async generateToken(
    patientId: string,
    permissionLevel: PermissionLevel,
    targetRole: TargetRole = 'FAMILY_MEMBER', // Kept for backward compatibility
  ) {
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

    // Store permission level for family members; doctors will have different permissions
    return this.prisma.connectionToken.create({
      data: {
        patientId,
        token,
        permissionLevel,
        targetRole, // Still stored for audit purposes, but not enforced
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
      targetRole: tokenRecord.targetRole as TargetRole,
    };
  }

  /**
   * Consume a token to create a connection.
   * 
   * The connection type is determined by the CONSUMER'S role, not the token's targetRole:
   * - If consumer is DOCTOR: creates a DOCTOR connection (limited access - view only)
   * - If consumer is FAMILY_MEMBER: creates a FAMILY connection (permission level from token)
   * 
   * Both create PENDING connections that the patient must approve.
   */
  async consumeToken(tokenString: string, consumerId: string) {
    const validation = await this.validateToken(tokenString);

    if (!validation.valid) {
      throw new BadRequestException(validation.error);
    }

    const tokenRecord = validation.token;

    // Prevent self-connection
    if (tokenRecord.patientId === consumerId) {
      throw new BadRequestException('Cannot connect to yourself');
    }

    // Get the consumer's role to determine connection type
    const consumer = await this.prisma.user.findUnique({
      where: { id: consumerId },
      select: { id: true, role: true, firstName: true, lastName: true, fullName: true },
    });

    if (!consumer) {
      throw new NotFoundException('User not found');
    }

    // Determine connection type based on consumer's actual role
    const connectionType: TargetRole = consumer.role === 'DOCTOR' ? 'DOCTOR' : 'FAMILY_MEMBER';

    // Validate that the consumer has an allowed role
    if (consumer.role !== 'DOCTOR' && consumer.role !== 'FAMILY_MEMBER') {
      throw new ForbiddenException('Only doctors or family members can use connection tokens');
    }

    // Check if connection already exists
    const existingConnection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: consumerId, recipientId: tokenRecord.patientId },
          { initiatorId: tokenRecord.patientId, recipientId: consumerId },
        ],
        status: { not: 'REVOKED' },
      },
    });

    if (existingConnection) {
      throw new BadRequestException('Connection already exists');
    }

    // Validate subscription limits (only applies to family connections)
    if (connectionType === 'FAMILY_MEMBER') {
      const subscription = await this.prisma.subscription.findUnique({
        where: { userId: tokenRecord.patientId },
      });
      const tier = subscription?.tier || 'FREEMIUM';
      const caregiverLimit = tier === 'FAMILY_PREMIUM' ? 10 : tier === 'PREMIUM' ? 5 : 2;
      const currentFamilyCount = await this.prisma.connection.count({
        where: {
          OR: [
            { initiatorId: tokenRecord.patientId },
            { recipientId: tokenRecord.patientId },
          ],
          status: { in: ['PENDING', 'ACCEPTED'] },
          // Count only family connections
          metadata: { path: ['connectionType'], equals: 'FAMILY_MEMBER' },
        },
      });
      if (currentFamilyCount >= caregiverLimit) {
        throw new ForbiddenException(
          `Family connection limit reached. Your plan allows ${caregiverLimit} family connections.`,
        );
      }
    }

    // Determine permission level:
    // - Family members: use the permission level from the token
    // - Doctors: always use 'NOT_ALLOWED' for medication access (they can only see their own prescriptions)
    const permissionLevel: PermissionLevel = connectionType === 'DOCTOR' 
      ? 'NOT_ALLOWED' // Doctors don't get medication access - they see their own prescriptions only
      : tokenRecord.permissionLevel;

    // Both connection types start as PENDING - patient must approve
    const connectionStatus = 'PENDING';

    // Transaction: mark token as used + create connection
    const [, connection] = await this.prisma.$transaction([
      this.prisma.connectionToken.update({
        where: { id: tokenRecord.id },
        data: { usedAt: new Date(), usedById: consumerId },
      }),
      this.prisma.connection.create({
        data: {
          initiatorId: consumerId,
          recipientId: tokenRecord.patientId,
          status: connectionStatus,
          permissionLevel: permissionLevel,
          metadata: { 
            alertsEnabled: connectionType === 'FAMILY_MEMBER', // Only family gets alerts
            connectionType: connectionType,
          },
        },
        include: {
          initiator: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true } },
          recipient: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true } },
        },
      }),
    ]);

    const initiatorName =
      connection.initiator.fullName || connection.initiator.firstName || 'A user';
    
    const notificationMessage = connectionType === 'DOCTOR'
      ? `Dr. ${initiatorName} wants to connect with you as your healthcare provider.`
      : `${initiatorName} wants to connect with you as a family caregiver.`;

    await this.notificationsService.send(
      tokenRecord.patientId,
      'CONNECTION_REQUEST',
      'Connection Request',
      notificationMessage,
      { connectionId: connection.id, initiatorId: consumerId, connectionType: connectionType },
    );

    await this.auditService.log({
      actorId: consumerId,
      actorRole: connection.initiator.role,
      actionType: 'CONNECTION_REQUEST',
      resourceType: 'Connection',
      resourceId: connection.id,
      details: {
        status: connectionStatus,
        connectionId: connection.id,
        connectionType: connectionType,
        initiatorId: connection.initiatorId,
        recipientId: connection.recipientId,
        initiator: {
          id: connection.initiator.id,
          firstName: connection.initiator.firstName,
          lastName: connection.initiator.lastName,
          fullName: connection.initiator.fullName,
        },
        recipient: {
          id: connection.recipient.id,
          firstName: connection.recipient.firstName,
          lastName: connection.recipient.lastName,
          fullName: connection.recipient.fullName,
        },
      },
    });

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
