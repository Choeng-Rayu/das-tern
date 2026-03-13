import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

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
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification || notification.recipientId !== userId) {
      throw new NotFoundException('Notification not found');
    }
    return this.prisma.notification.update({
      where: { id },
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

  /**
   * Send a DOSE_CONFIRMED notification to all connected caregivers,
   * letting them know the patient took their medication.
   *
   * Premium-gated: only sends if patient has PREMIUM or FAMILY_PREMIUM.
   */
  async sendDoseConfirmation(patientId: string, doseId: string) {
    try {
      // ── Premium gate ─────────────────────────────────
      const subscription = await this.prisma.subscription.findUnique({
        where: { userId: patientId },
      });

      const tier = subscription?.tier;
      if (!subscription || (tier !== 'PREMIUM' && tier !== 'FAMILY_PREMIUM')) {
        return; // Silently skip for non-premium
      }

      if (subscription.expiresAt && new Date() > subscription.expiresAt) {
        return; // Subscription expired
      }

      // ── Fetch dose details ───────────────────────────
      const dose = await this.prisma.doseEvent.findUnique({
        where: { id: doseId },
        include: {
          medication: { select: { medicineName: true, medicineNameKhmer: true } },
          patient: { select: { id: true, firstName: true, lastName: true, fullName: true } },
        },
      });

      if (!dose) return;

      const patientName = dose.patient.fullName ||
        `${dose.patient.firstName || ''} ${dose.patient.lastName || ''}`.trim();
      const medName = dose.medication.medicineName;

      // ── Find connected caregivers ────────────────────
      const connections = await this.prisma.connection.findMany({
        where: {
          OR: [
            { initiatorId: patientId },
            { recipientId: patientId },
          ],
          status: 'ACCEPTED',
        },
      });

      for (const conn of connections) {
        const caregiverId = conn.initiatorId === patientId
          ? conn.recipientId : conn.initiatorId;

        const metadata = conn.metadata as any;
        if (metadata && metadata.alertsEnabled === false) {
          continue;
        }

        await this.send(
          caregiverId,
          'DOSE_CONFIRMED',
          'Dose Taken',
          `${patientName} has taken ${medName}`,
          {
            doseId,
            patientId,
            medicationName: medName,
            takenAt: dose.takenAt?.toISOString(),
          },
        );
      }
    } catch (error) {
      // Non-critical — log but don't throw
      this.logger.warn(`Failed to send dose confirmation for dose ${doseId}`, error);
    }
  }
}
