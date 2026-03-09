import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async send(recipientId: string, type: NotificationType, title: string, message: string, data?: any) {
    return this.prisma.notification.create({
      data: { recipientId, type, title, message, data },
    });
  }

  async findAll(userId: string, unreadOnly = false) {
    return this.prisma.notification.findMany({
      where: {
        recipientId: userId,
        ...(unreadOnly && { isRead: false }),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAsRead(id: string, userId: string) {
    return this.prisma.notification.update({
      where: { id, recipientId: userId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { recipientId: userId, isRead: false },
    });
  }

  async remove(id: string, userId: string) {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification || notification.recipientId !== userId) {
      throw new NotFoundException('Notification not found');
    }
    return this.prisma.notification.delete({ where: { id } });
  }

  async sendMissedDoseAlert(patientId: string, doseId: string, isDelayed = false) {
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: patientId, recipient: { role: 'FAMILY_MEMBER' } },
          { recipientId: patientId, initiator: { role: 'FAMILY_MEMBER' } },
        ],
        status: 'ACCEPTED',
      },
      include: { initiator: true, recipient: true },
    });

    const familyMembers = connections.map(c => 
      c.initiatorId === patientId ? c.recipient : c.initiator
    );

    const dose = await this.prisma.doseEvent.findUnique({
      where: { id: doseId },
      include: { medication: true, patient: true },
    });

    if (!dose) return;

    const title = isDelayed ? 'Delayed Missed Dose Alert' : 'Missed Dose Alert';
    const message = `${dose.patient.firstName || dose.patient.fullName} missed ${dose.medication.medicineName}`;

    for (const family of familyMembers) {
      await this.send(family.id, 'MISSED_DOSE_ALERT', title, message, {
        doseId,
        patientId,
        isDelayed,
        missedAt: dose.scheduledTime,
      });
    }
  }
}
