import { Injectable, ConflictException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateConnectionDto, AcceptConnectionDto } from './dto';
import { PermissionLevel } from '@prisma/client';

@Injectable()
export class ConnectionsService {
  constructor(private prisma: PrismaService) {}

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
      throw new ConflictException('Connection already exists');
    }

    return this.prisma.connection.create({
      data: {
        initiatorId,
        recipientId: dto.targetUserId,
        status: 'PENDING',
      },
      include: {
        initiator: { select: { id: true, fullName: true, role: true } },
        recipient: { select: { id: true, fullName: true, role: true } },
      },
    });
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

    return this.prisma.connection.update({
      where: { id },
      data: {
        status: 'ACCEPTED',
        acceptedAt: new Date(),
        permissionLevel: dto.permissionLevel || 'ALLOWED',
      },
    });
  }

  async revoke(id: string, userId: string) {
    const connection = await this.prisma.connection.findUnique({ where: { id } });

    if (!connection) {
      throw new NotFoundException('Connection not found');
    }

    if (connection.initiatorId !== userId && connection.recipientId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return this.prisma.connection.update({
      where: { id },
      data: { status: 'REVOKED', revokedAt: new Date() },
    });
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
}
