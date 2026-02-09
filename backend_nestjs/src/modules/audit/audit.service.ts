import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { AuditActionType, UserRole } from '@prisma/client';

@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  async log(data: {
    actorId?: string;
    actorRole?: UserRole;
    actionType: AuditActionType;
    resourceType: string;
    resourceId?: string;
    details?: any;
    ipAddress?: string;
  }) {
    return this.prisma.auditLog.create({
      data,
    });
  }

  async findAll(userId: string, options?: { resourceType?: string; actionType?: AuditActionType }) {
    return this.prisma.auditLog.findMany({
      where: {
        actorId: userId,
        ...(options?.resourceType && { resourceType: options.resourceType }),
        ...(options?.actionType && { actionType: options.actionType }),
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }
}
