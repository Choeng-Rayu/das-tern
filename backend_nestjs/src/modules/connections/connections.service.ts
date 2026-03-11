import { Injectable, ConflictException, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateConnectionDto, AcceptConnectionDto } from './dto';
import { PermissionLevel } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ConnectionsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async create(initiatorId: string, dto: CreateConnectionDto) {
    // Check if connection already exists
    const existing = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId, recipientId: dto.targetUserId },
          { initiatorId: dto.targetUserId, recipientId: initiatorId },
        ],
      },
    });

    if (existing) {
      if (existing.status === 'ACCEPTED') {
        throw new ConflictException('Connection already accepted');
      }
      if (existing.status === 'PENDING') {
        throw new ConflictException('Connection request already pending');
      }
      // REVOKED: allow re-requesting by resetting the existing connection
      const connection = await this.prisma.connection.update({
        where: { id: existing.id },
        data: {
          initiatorId,
          recipientId: dto.targetUserId,
          status: 'PENDING',
          acceptedAt: null,
          revokedAt: null,
        },
        include: {
          initiator: { select: { id: true, fullName: true, firstName: true, role: true } },
          recipient: { select: { id: true, fullName: true, role: true } },
        },
      });

      const initiatorName = connection.initiator.fullName || connection.initiator.firstName || 'A user';
      await this.notificationsService.send(
        dto.targetUserId,
        'CONNECTION_REQUEST',
        'Connection Request',
        `${initiatorName} wants to connect with you.`,
        { connectionId: connection.id, initiatorId },
      );

      return connection;
    }

    const connection = await this.prisma.connection.create({
      data: {
        initiatorId,
        recipientId: dto.targetUserId,
        status: 'PENDING',
      },
      include: {
        initiator: { select: { id: true, fullName: true, firstName: true, role: true } },
        recipient: { select: { id: true, fullName: true, role: true } },
      },
    });

    // Notify the recipient about the connection request
    const initiatorName = connection.initiator.fullName || connection.initiator.firstName || 'A user';
    await this.notificationsService.send(
      dto.targetUserId,
      'CONNECTION_REQUEST',
      'Connection Request',
      `${initiatorName} wants to connect with you.`,
      { connectionId: connection.id, initiatorId },
    );

    return connection;
  }

  async findAll(userId: string, status?: string) {
    return this.prisma.connection.findMany({
      where: {
        OR: [{ initiatorId: userId }, { recipientId: userId }],
        ...(status && { status: status as any }),
      },
      include: {
        initiator: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true, phoneNumber: true } },
        recipient: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true, phoneNumber: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async accept(id: string, userId: string, dto: AcceptConnectionDto) {
    const connection = await this.prisma.connection.findUnique({ where: { id } });

    if (!connection) {
      throw new NotFoundException('Connection not found');
    }

    if (connection.recipientId !== userId) {
      throw new ForbiddenException('Only recipient can accept connection');
    }

    const updated = await this.prisma.connection.update({
      where: { id },
      data: {
        status: 'ACCEPTED',
        acceptedAt: new Date(),
        permissionLevel: dto.permissionLevel || 'ALLOWED',
      },
      include: {
        recipient: { select: { id: true, fullName: true, firstName: true } },
      },
    });

    // Notify the initiator (doctor) that the connection was accepted
    const recipientName = updated.recipient.fullName || updated.recipient.firstName || 'A user';
    await this.notificationsService.send(
      connection.initiatorId,
      'CONNECTION_REQUEST',
      'Connection Accepted',
      `${recipientName} has accepted your connection request.`,
      { connectionId: id },
    );

    return updated;
  }

  async revoke(id: string, userId: string) {
    const connection = await this.prisma.connection.findUnique({ where: { id } });

    if (!connection) {
      throw new NotFoundException('Connection not found');
    }

    if (connection.initiatorId !== userId && connection.recipientId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    const updated = await this.prisma.connection.update({
      where: { id },
      data: { status: 'REVOKED', revokedAt: new Date() },
      include: {
        initiator: { select: { id: true, fullName: true, firstName: true } },
        recipient: { select: { id: true, fullName: true, firstName: true } },
      },
    });

    // Notify the other party about the revocation
    const isInitiator = connection.initiatorId === userId;
    const otherUserId = isInitiator ? connection.recipientId : connection.initiatorId;
    const revokerName = isInitiator
      ? (updated.initiator.fullName || updated.initiator.firstName || 'A user')
      : (updated.recipient.fullName || updated.recipient.firstName || 'A user');
    await this.notificationsService.send(
      otherUserId,
      'CONNECTION_REQUEST',
      'Connection Revoked',
      `${revokerName} has declined the connection request.`,
      { connectionId: id },
    );

    return updated;
  }

  async updatePermission(id: string, patientId: string, permissionLevel: PermissionLevel) {
    const connection = await this.prisma.connection.findUnique({ where: { id } });

    if (!connection) {
      throw new NotFoundException('Connection not found');
    }

    // Only patient can update permission
    if (connection.recipientId !== patientId && connection.initiatorId !== patientId) {
      throw new ForbiddenException('Only patient can update permissions');
    }

    return this.prisma.connection.update({
      where: { id },
      data: { permissionLevel },
    });
  }

  async checkPermission(doctorId: string, patientId: string): Promise<PermissionLevel> {
    const connection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: doctorId, recipientId: patientId },
          { initiatorId: patientId, recipientId: doctorId },
        ],
        status: 'ACCEPTED',
      },
    });

    return connection?.permissionLevel || 'NOT_ALLOWED';
  }

  // ============================
  // Family Connection Methods
  // ============================

  /**
   * Get connected caregivers for a patient (with alertsEnabled).
   */
  async getCaregivers(patientId: string) {
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: patientId },
          { recipientId: patientId },
        ],
        status: 'ACCEPTED',
      },
      include: {
        initiator: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true, phoneNumber: true } },
        recipient: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true, phoneNumber: true } },
      },
    });

    return connections.map(conn => {
      const isPatientInitiator = conn.initiatorId === patientId;
      const caregiver = isPatientInitiator ? conn.recipient : conn.initiator;
      const metadata = conn.metadata as any;

      return {
        connectionId: conn.id,
        caregiver,
        permissionLevel: conn.permissionLevel,
        alertsEnabled: metadata?.alertsEnabled ?? true,
        acceptedAt: conn.acceptedAt,
        lastAlertSent: metadata?.lastAlertSent || null,
      };
    });
  }

  /**
   * Get connected patients for a caregiver.
   */
  async getConnectedPatients(caregiverId: string) {
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: caregiverId },
          { recipientId: caregiverId },
        ],
        status: 'ACCEPTED',
      },
      include: {
        initiator: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true } },
        recipient: { select: { id: true, firstName: true, lastName: true, fullName: true, role: true } },
      },
    });

    return connections.map(conn => {
      const isCaregiverInitiator = conn.initiatorId === caregiverId;
      const patient = isCaregiverInitiator ? conn.recipient : conn.initiator;

      return {
        connectionId: conn.id,
        patient,
        permissionLevel: conn.permissionLevel,
      };
    });
  }

  /**
   * Toggle alerts for a specific connection.
   */
  async toggleAlerts(connectionId: string, userId: string, enabled: boolean) {
    const connection = await this.prisma.connection.findUnique({ where: { id: connectionId } });

    if (!connection) {
      throw new NotFoundException('Connection not found');
    }

    if (connection.initiatorId !== userId && connection.recipientId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    const metadata = (connection.metadata as any) || {};
    metadata.alertsEnabled = enabled;

    return this.prisma.connection.update({
      where: { id: connectionId },
      data: { metadata },
    });
  }

  /**
   * Get caregiver limit based on subscription tier.
   */
  async getCaregiverLimit(patientId: string): Promise<{ current: number; max: number }> {
    const subscription = await this.prisma.subscription.findUnique({
      where: { userId: patientId },
    });

    const tier = subscription?.tier || 'FREEMIUM';
    let max: number;

    switch (tier) {
      case 'FREEMIUM': max = 2; break;
      case 'PREMIUM': max = 5; break;
      case 'FAMILY_PREMIUM': max = 10; break;
      default: max = 2;
    }

    const current = await this.prisma.connection.count({
      where: {
        OR: [
          { initiatorId: patientId },
          { recipientId: patientId },
        ],
        status: { in: ['PENDING', 'ACCEPTED'] },
      },
    });

    return { current, max };
  }

  /**
   * Validate if a patient can add more caregivers.
   */
  async validateCaregiverLimit(patientId: string): Promise<boolean> {
    const { current, max } = await this.getCaregiverLimit(patientId);
    return current < max;
  }

  /**
   * Get connection history from audit logs.
   */
  async getConnectionHistory(userId: string, filter?: string) {
    // Map ConnectionStatus values to AuditActionType values
    const statusToActionTypeMap: Record<string, string> = {
      'PENDING': 'CONNECTION_REQUEST',
      'ACCEPTED': 'CONNECTION_ACCEPT',
      'REVOKED': 'CONNECTION_REVOKE',
    };

    let actionTypes: string[];
    if (filter) {
      // Map the filter to the correct audit action type
      const mappedType = statusToActionTypeMap[filter] || filter;
      actionTypes = [mappedType];
    } else {
      actionTypes = [
        'CONNECTION_REQUEST',
        'CONNECTION_ACCEPT',
        'CONNECTION_REVOKE',
        'PERMISSION_CHANGE',
      ];
    }

    return this.prisma.auditLog.findMany({
      where: {
        actorId: userId,
        actionType: { in: actionTypes as any },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  // ============================
  // Doctor Search Methods
  // ============================

  async searchDoctors(query: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const where: any = {
      role: 'DOCTOR' as any,
      accountStatus: { in: ['ACTIVE', 'VERIFIED'] },
    };

    if (query) {
      where.OR = [
        { fullName: { contains: query, mode: 'insensitive' } },
        { hospitalClinic: { contains: query, mode: 'insensitive' } },
        { licenseNumber: { contains: query, mode: 'insensitive' } },
        { specialty: { contains: query, mode: 'insensitive' } },
      ];
    }

    const [doctors, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          id: true,
          fullName: true,
          firstName: true,
          lastName: true,
          hospitalClinic: true,
          specialty: true,
          licenseNumber: true,
          accountStatus: true,
        },
        skip,
        take: limit,
        orderBy: { fullName: 'asc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return { doctors, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getDoctorConnections(patientId: string) {
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: patientId, recipient: { role: 'DOCTOR' } },
          { recipientId: patientId, initiator: { role: 'DOCTOR' } },
        ],
        status: { in: ['PENDING', 'ACCEPTED'] },
      },
      include: {
        initiator: { select: { id: true, fullName: true, firstName: true, lastName: true, role: true, hospitalClinic: true, specialty: true } },
        recipient: { select: { id: true, fullName: true, firstName: true, lastName: true, role: true, hospitalClinic: true, specialty: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return connections.map(conn => {
      const isPatientInitiator = conn.initiatorId === patientId;
      const doctor = isPatientInitiator ? conn.recipient : conn.initiator;
      return {
        connectionId: conn.id,
        doctor,
        status: conn.status,
        permissionLevel: conn.permissionLevel,
        acceptedAt: conn.acceptedAt,
        createdAt: conn.createdAt,
      };
    });
  }

  async getFamilyConnections(patientId: string) {
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: patientId, recipient: { role: 'FAMILY_MEMBER' } },
          { recipientId: patientId, initiator: { role: 'FAMILY_MEMBER' } },
        ],
        status: { in: ['PENDING', 'ACCEPTED'] },
      },
      include: {
        initiator: { select: { id: true, fullName: true, firstName: true, lastName: true, role: true, phoneNumber: true } },
        recipient: { select: { id: true, fullName: true, firstName: true, lastName: true, role: true, phoneNumber: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return connections.map(conn => {
      const isPatientInitiator = conn.initiatorId === patientId;
      const familyMember = isPatientInitiator ? conn.recipient : conn.initiator;
      const metadata = conn.metadata as any;
      return {
        connectionId: conn.id,
        familyMember,
        status: conn.status,
        permissionLevel: conn.permissionLevel,
        alertsEnabled: metadata?.alertsEnabled ?? true,
        acceptedAt: conn.acceptedAt,
        createdAt: conn.createdAt,
      };
    });
  }

  // ============================
  // Patient Search (for Doctors)
  // ============================

  async searchPatients(query: string) {
    if (!query || query.trim().length < 3) {
      throw new BadRequestException('Search query must be at least 3 characters');
    }

    const trimmed = query.trim();

    const patient = await this.prisma.user.findFirst({
      where: {
        role: 'PATIENT',
        OR: [
          { phoneNumber: trimmed },
          { phoneNumber: trimmed.startsWith('+') ? trimmed : `+${trimmed}` },
          { email: { equals: trimmed, mode: 'insensitive' } },
          { email: { contains: trimmed, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        fullName: true,
        phoneNumber: true,
        email: true,
        gender: true,
      },
    });

    if (!patient) {
      throw new NotFoundException('No patient found with that phone number or email');
    }

    return patient;
  }
}
