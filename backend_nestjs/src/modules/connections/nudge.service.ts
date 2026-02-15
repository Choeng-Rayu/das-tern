import { Injectable, BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditService } from '../audit/audit.service';

export interface NudgeResult {
  success: boolean;
  message: string;
  remainingNudges?: number;
  rateLimitExceeded?: boolean;
}

@Injectable()
export class NudgeService {
  private readonly MAX_NUDGES_PER_DOSE = 2;

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
    private auditService: AuditService,
  ) {}

  /**
   * Send a nudge from a caregiver to a patient about a specific dose.
   */
  async sendNudge(caregiverId: string, patientId: string, doseId: string): Promise<NudgeResult> {
    // Verify connection exists and is accepted
    const connection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: caregiverId, recipientId: patientId },
          { initiatorId: patientId, recipientId: caregiverId },
        ],
        status: 'ACCEPTED',
      },
      include: {
        initiator: { select: { id: true, firstName: true, fullName: true } },
        recipient: { select: { id: true, firstName: true, fullName: true } },
      },
    });

    if (!connection) {
      throw new ForbiddenException('No active connection with this patient');
    }

    // Check permission level - must be SELECTED or ALLOWED
    if (connection.permissionLevel === 'NOT_ALLOWED' || connection.permissionLevel === 'REQUEST') {
      throw new ForbiddenException('Insufficient permission to send nudges');
    }

    // Verify dose exists
    const dose = await this.prisma.doseEvent.findUnique({
      where: { id: doseId },
      include: { medication: true },
    });

    if (!dose) {
      throw new NotFoundException('Dose event not found');
    }

    if (dose.patientId !== patientId) {
      throw new ForbiddenException('Dose does not belong to this patient');
    }

    // Check rate limit
    const rateLimitCheck = this.checkRateLimit(connection, doseId);
    if (rateLimitCheck.rateLimitExceeded) {
      throw new BadRequestException(`Nudge limit reached. Maximum ${this.MAX_NUDGES_PER_DOSE} nudges per dose.`);
    }

    // Record the nudge
    await this.recordNudge(connection.id, caregiverId, doseId);

    // Get caregiver name
    const caregiver = connection.initiatorId === caregiverId
      ? connection.initiator : connection.recipient;
    const caregiverName = caregiver.fullName || caregiver.firstName || 'A caregiver';

    // Send notification to patient
    await this.notificationsService.send(
      patientId,
      'FAMILY_ALERT',
      'Gentle Reminder',
      `${caregiverName} is checking in about your ${dose.medication.medicineName} dose`,
      {
        type: 'nudge',
        caregiverId,
        doseEventId: doseId,
        medicationName: dose.medication.medicineName,
      },
    );

    // Log audit
    await this.auditService.log({
      actorId: caregiverId,
      actionType: 'NOTIFICATION_SENT',
      resourceType: 'Nudge',
      resourceId: doseId,
      details: {
        patientId,
        connectionId: connection.id,
        doseId,
        medicationName: dose.medication.medicineName,
      },
    });

    const remaining = this.MAX_NUDGES_PER_DOSE - (rateLimitCheck.currentCount + 1);

    return {
      success: true,
      message: 'Nudge sent successfully',
      remainingNudges: remaining,
    };
  }

  /**
   * Respond to a nudge (patient acknowledges).
   */
  async respondToNudge(patientId: string, caregiverId: string, doseId: string, response: string) {
    const caregiver = await this.prisma.user.findUnique({
      where: { id: caregiverId },
      select: { id: true, firstName: true, fullName: true },
    });

    const patient = await this.prisma.user.findUnique({
      where: { id: patientId },
      select: { id: true, firstName: true, fullName: true },
    });

    if (!caregiver || !patient) {
      throw new NotFoundException('User not found');
    }

    const patientName = patient.fullName || patient.firstName || 'Patient';

    // Notify caregiver of the response
    await this.notificationsService.send(
      caregiverId,
      'FAMILY_ALERT',
      'Nudge Response',
      `${patientName} responded: "${response}"`,
      {
        type: 'nudge_response',
        patientId,
        doseEventId: doseId,
        response,
      },
    );

    return { success: true, message: 'Response sent' };
  }

  /**
   * Check if the caregiver has exceeded the nudge rate limit for a dose.
   */
  private checkRateLimit(connection: any, doseId: string): { rateLimitExceeded: boolean; currentCount: number } {
    const metadata = (connection.metadata as any) || {};
    const nudges = metadata.nudges || {};
    const key = `${connection.initiatorId === connection.recipientId ? '' : ''}${doseId}`;
    const currentCount = nudges[key] || 0;

    return {
      rateLimitExceeded: currentCount >= this.MAX_NUDGES_PER_DOSE,
      currentCount,
    };
  }

  /**
   * Record a nudge in the connection metadata.
   */
  private async recordNudge(connectionId: string, caregiverId: string, doseId: string) {
    const connection = await this.prisma.connection.findUnique({ where: { id: connectionId } });
    if (!connection) return;
    const metadata = (connection.metadata as any) || {};
    const nudges = metadata.nudges || {};
    const key = doseId;
    nudges[key] = (nudges[key] || 0) + 1;

    await this.prisma.connection.update({
      where: { id: connectionId },
      data: {
        metadata: { ...metadata, nudges, lastNudgeSent: new Date().toISOString() },
      },
    });
  }
}
