import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class MissedDoseJob {
  private readonly logger = new Logger(MissedDoseJob.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
    private auditService: AuditService,
  ) {}

  /**
   * Runs every 5 minutes to detect doses past their grace period.
   * Updates DUE → MISSED and triggers notifications.
   */
  @Cron('*/5 * * * *')
  async execute() {
    this.logger.debug('Running missed dose detection job...');

    try {
      const missedDoses = await this.findOverdueDoses();

      if (missedDoses.length === 0) {
        this.logger.debug('No missed doses found');
        return;
      }

      this.logger.log(`Found ${missedDoses.length} missed doses`);

      for (const dose of missedDoses) {
        await this.markAsMissed(dose);
        await this.notifyPatient(dose);
        await this.triggerCaregiverAlerts(dose);
        await this.logAudit(dose);
      }
    } catch (error) {
      this.logger.error('Error in missed dose detection job', error);
    }
  }

  /**
   * Find all DUE doses past their grace period.
   */
  private async findOverdueDoses() {
    const now = new Date();

    // Get all DUE doses with patient's grace period
    const dueDoses = await this.prisma.doseEvent.findMany({
      where: {
        status: 'DUE',
      },
      include: {
        patient: {
          select: {
            id: true, firstName: true, lastName: true, fullName: true,
            gracePeriodMinutes: true,
          },
        },
        medication: {
          select: { id: true, medicineName: true, medicineNameKhmer: true },
        },
        prescription: {
          select: { id: true },
        },
      },
    });

    // Filter doses where scheduledTime + gracePeriod < now
    return dueDoses.filter(dose => {
      const gracePeriod = dose.patient.gracePeriodMinutes || 30;
      const deadline = new Date(dose.scheduledTime.getTime() + gracePeriod * 60 * 1000);
      return deadline < now;
    });
  }

  /**
   * Mark a dose as MISSED.
   */
  private async markAsMissed(dose: any) {
    await this.prisma.doseEvent.update({
      where: { id: dose.id },
      data: { status: 'MISSED' },
    });
  }

  /**
   * Send missed dose notification to the patient.
   */
  private async notifyPatient(dose: any) {
    const patientName = dose.patient.fullName ||
      `${dose.patient.firstName || ''} ${dose.patient.lastName || ''}`.trim();
    const medName = dose.medication.medicineName;
    const time = dose.scheduledTime.toLocaleTimeString('en-US', {
      hour: '2-digit', minute: '2-digit',
    });

    await this.notificationsService.send(
      dose.patientId,
      'MISSED_DOSE_ALERT',
      'Missed Dose',
      `${patientName} missed the ${time} dose of ${medName}`,
      {
        doseEventId: dose.id,
        patientId: dose.patientId,
        prescriptionId: dose.prescriptionId,
        medicationName: medName,
        scheduledTime: dose.scheduledTime.toISOString(),
      },
    );
  }

  /**
   * Send MISSED_DOSE_ALERT to all connected caregivers who have alerts enabled.
   */
  private async triggerCaregiverAlerts(dose: any) {
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: dose.patientId },
          { recipientId: dose.patientId },
        ],
        status: 'ACCEPTED',
      },
      include: {
        initiator: { select: { id: true, firstName: true, fullName: true, role: true } },
        recipient: { select: { id: true, firstName: true, fullName: true, role: true } },
      },
    });

    const patientName = dose.patient.fullName ||
      `${dose.patient.firstName || ''} ${dose.patient.lastName || ''}`.trim();
    const medName = dose.medication.medicineName;
    const time = dose.scheduledTime.toLocaleTimeString('en-US', {
      hour: '2-digit', minute: '2-digit',
    });

    for (const conn of connections) {
      // Determine caregiver (the user who is NOT the patient)
      const caregiverId = conn.initiatorId === dose.patientId
        ? conn.recipientId : conn.initiatorId;

      // Check if alerts are enabled for this connection
      const metadata = conn.metadata as any;
      if (metadata && metadata.alertsEnabled === false) {
        continue;
      }

      await this.notificationsService.send(
        caregiverId,
        'MISSED_DOSE_ALERT',
        'Missed Dose Alert',
        `${patientName} missed the ${time} dose of ${medName}`,
        {
          doseEventId: dose.id,
          patientId: dose.patientId,
          prescriptionId: dose.prescriptionId,
          medicationName: medName,
          scheduledTime: dose.scheduledTime.toISOString(),
        },
      );
    }
  }

  /**
   * Log audit entry for missed dose.
   */
  private async logAudit(dose: any) {
    await this.auditService.log({
      actionType: 'DOSE_MISSED',
      resourceType: 'DoseEvent',
      resourceId: dose.id,
      details: {
        patientId: dose.patientId,
        medicationId: dose.medicationId,
        scheduledTime: dose.scheduledTime.toISOString(),
        gracePeriodMinutes: dose.patient.gracePeriodMinutes,
      },
    });
  }
}
