import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { RecordVitalDto, QueryVitalsDto, UpdateThresholdDto, TriggerEmergencyDto } from './dto';
import { DEFAULT_THRESHOLDS } from './constants/default-thresholds';
import { AlertSeverity, VitalType } from '@prisma/client';

@Injectable()
export class HealthMonitoringService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  async recordVital(patientId: string, dto: RecordVitalDto) {
    // Check thresholds and flag abnormal
    const threshold = await this.getThresholdForVital(patientId, dto.vitalType);
    const isAbnormal = this.checkAbnormal(dto.value, dto.valueSecondary ?? null, threshold);

    // Create the vital record
    const vital = await this.prisma.healthVital.create({
      data: {
        patientId,
        vitalType: dto.vitalType,
        value: dto.value,
        valueSecondary: dto.valueSecondary,
        unit: dto.unit,
        measuredAt: dto.measuredAt ? new Date(dto.measuredAt) : new Date(),
        notes: dto.notes,
        isAbnormal,
        source: dto.source || 'manual',
      },
    });

    // If abnormal, create alert and notify
    if (isAbnormal) {
      await this.createAnomalyAlert(patientId, vital);
    }

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'VITAL_RECORDED',
        resourceType: 'HealthVital',
        resourceId: vital.id,
        details: {
          vitalType: dto.vitalType,
          value: dto.value,
          valueSecondary: dto.valueSecondary,
          isAbnormal,
        },
      },
    });

    return vital;
  }

  async getVitals(patientId: string, query: QueryVitalsDto) {
    const where: any = { patientId };

    if (query.vitalType) {
      where.vitalType = query.vitalType;
    }
    if (query.startDate || query.endDate) {
      where.measuredAt = {};
      if (query.startDate) where.measuredAt.gte = new Date(query.startDate);
      if (query.endDate) where.measuredAt.lte = new Date(query.endDate);
    }

    return this.prisma.healthVital.findMany({
      where,
      orderBy: { measuredAt: 'desc' },
      take: 100,
    });
  }

  async getLatestVitals(patientId: string) {
    const vitalTypes: VitalType[] = ['BLOOD_PRESSURE', 'GLUCOSE', 'HEART_RATE', 'WEIGHT', 'TEMPERATURE', 'SPO2'];

    const results = await Promise.all(
      vitalTypes.map(type =>
        this.prisma.healthVital.findFirst({
          where: { patientId, vitalType: type },
          orderBy: { measuredAt: 'desc' },
        }),
      ),
    );

    return results.filter(Boolean);
  }

  async getVitalById(id: string, userId: string) {
    const vital = await this.prisma.healthVital.findUnique({
      where: { id },
    });

    if (!vital) {
      throw new NotFoundException('Vital record not found');
    }

    // Check access: own vital or connected user
    if (vital.patientId !== userId) {
      await this.verifyConnection(userId, vital.patientId);
    }

    return vital;
  }

  async deleteVital(id: string, patientId: string) {
    const vital = await this.prisma.healthVital.findUnique({
      where: { id },
    });

    if (!vital) {
      throw new NotFoundException('Vital record not found');
    }

    if (vital.patientId !== patientId) {
      throw new ForbiddenException('Access denied');
    }

    await this.prisma.healthVital.delete({ where: { id } });

    return { message: 'Vital record deleted successfully' };
  }

  async getTrends(patientId: string, query: QueryVitalsDto) {
    if (!query.vitalType) {
      throw new ForbiddenException('vitalType is required for trends');
    }

    const period = query.period || 'daily';
    const endDate = query.endDate ? new Date(query.endDate) : new Date();
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);

    let truncUnit: string;
    switch (period) {
      case 'weekly': truncUnit = 'week'; break;
      case 'monthly': truncUnit = 'month'; break;
      default: truncUnit = 'day'; break;
    }

    const results = await this.prisma.$queryRawUnsafe<
      { date: Date; avg_value: number; min_value: number; max_value: number; avg_secondary: number | null; count: number }[]
    >(
      `SELECT
        DATE_TRUNC($1, measured_at) as date,
        AVG(value) as avg_value,
        MIN(value) as min_value,
        MAX(value) as max_value,
        AVG(value_secondary) as avg_secondary,
        COUNT(*)::int as count
      FROM health_vitals
      WHERE patient_id = $2::uuid
        AND vital_type = $3
        AND measured_at >= $4
        AND measured_at <= $5
      GROUP BY DATE_TRUNC($1, measured_at)
      ORDER BY date`,
      truncUnit,
      patientId,
      query.vitalType,
      startDate,
      endDate,
    );

    // Get threshold for reference lines
    const threshold = await this.getThresholdForVital(patientId, query.vitalType as VitalType);

    return {
      vitalType: query.vitalType,
      period,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      threshold,
      data: results.map(r => ({
        date: r.date,
        avgValue: Number(r.avg_value),
        minValue: Number(r.min_value),
        maxValue: Number(r.max_value),
        avgSecondary: r.avg_secondary ? Number(r.avg_secondary) : null,
        count: r.count,
      })),
    };
  }

  async getThresholds(patientId: string) {
    const customThresholds = await this.prisma.vitalThreshold.findMany({
      where: { patientId },
    });

    // Merge with defaults
    const vitalTypes: VitalType[] = ['BLOOD_PRESSURE', 'GLUCOSE', 'HEART_RATE', 'WEIGHT', 'TEMPERATURE', 'SPO2'];

    return vitalTypes.map(type => {
      const custom = customThresholds.find(t => t.vitalType === type);
      const defaults = DEFAULT_THRESHOLDS[type];
      return {
        vitalType: type,
        minValue: custom?.minValue ?? defaults?.min ?? null,
        maxValue: custom?.maxValue ?? defaults?.max ?? null,
        minSecondary: custom?.minSecondary ?? defaults?.minSecondary ?? null,
        maxSecondary: custom?.maxSecondary ?? defaults?.maxSecondary ?? null,
        isCustom: !!custom,
      };
    });
  }

  async updateThreshold(patientId: string, dto: UpdateThresholdDto) {
    const threshold = await this.prisma.vitalThreshold.upsert({
      where: {
        patientId_vitalType: {
          patientId,
          vitalType: dto.vitalType,
        },
      },
      update: {
        minValue: dto.minValue,
        maxValue: dto.maxValue,
        minSecondary: dto.minSecondary,
        maxSecondary: dto.maxSecondary,
      },
      create: {
        patientId,
        vitalType: dto.vitalType,
        minValue: dto.minValue,
        maxValue: dto.maxValue,
        minSecondary: dto.minSecondary,
        maxSecondary: dto.maxSecondary,
      },
    });

    return threshold;
  }

  async getAlerts(patientId: string, resolved?: boolean) {
    const where: any = { patientId };
    if (resolved !== undefined) {
      where.isResolved = resolved;
    }

    return this.prisma.healthAlert.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        vital: true,
      },
      take: 50,
    });
  }

  async resolveAlert(id: string, userId: string) {
    const alert = await this.prisma.healthAlert.findUnique({
      where: { id },
    });

    if (!alert) {
      throw new NotFoundException('Alert not found');
    }

    // Allow patient or connected doctor to resolve
    if (alert.patientId !== userId) {
      await this.verifyConnection(userId, alert.patientId);
    }

    return this.prisma.healthAlert.update({
      where: { id },
      data: {
        isResolved: true,
        resolvedAt: new Date(),
        resolvedBy: userId,
      },
    });
  }

  async triggerEmergency(patientId: string, dto: TriggerEmergencyDto) {
    // Create CRITICAL alert
    const alert = await this.prisma.healthAlert.create({
      data: {
        patientId,
        alertType: 'EMERGENCY_MANUAL',
        severity: 'CRITICAL',
        message: dto.message,
      },
    });

    // Send to ALL connected users regardless of permission
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: patientId, status: 'ACCEPTED' },
          { recipientId: patientId, status: 'ACCEPTED' },
        ],
      },
      include: {
        initiator: { select: { id: true, fullName: true, firstName: true } },
        recipient: { select: { id: true, fullName: true, firstName: true } },
      },
    });

    const patient = await this.prisma.user.findUnique({
      where: { id: patientId },
      select: { fullName: true, firstName: true },
    });
    const patientName = patient?.fullName || patient?.firstName || 'A patient';

    const notifiedUsers: string[] = [];
    for (const conn of connections) {
      const connectedUser = conn.initiatorId === patientId ? conn.recipient : conn.initiator;
      await this.notifications.send(
        connectedUser.id,
        'EMERGENCY_ALERT',
        'EMERGENCY',
        `${patientName}: ${dto.message}`,
        {
          alertId: alert.id,
          patientId,
          location: dto.location,
        },
      );
      notifiedUsers.push(connectedUser.id);
    }

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: patientId,
        actorRole: 'PATIENT',
        actionType: 'EMERGENCY_TRIGGERED',
        resourceType: 'HealthAlert',
        resourceId: alert.id,
        details: {
          message: dto.message,
          location: dto.location,
          notifiedUsers: notifiedUsers.length,
        },
      },
    });

    return { alert, notifiedCount: notifiedUsers.length };
  }

  async getPatientVitals(requesterId: string, patientId: string, query: QueryVitalsDto) {
    // Verify connection
    await this.verifyConnection(requesterId, patientId);

    return this.getVitals(patientId, query);
  }

  async getPatientTrends(requesterId: string, patientId: string, query: QueryVitalsDto) {
    await this.verifyConnection(requesterId, patientId);
    return this.getTrends(patientId, query);
  }

  // ── Private helpers ──

  private async getThresholdForVital(patientId: string, vitalType: VitalType) {
    const custom = await this.prisma.vitalThreshold.findUnique({
      where: {
        patientId_vitalType: { patientId, vitalType },
      },
    });

    const defaults = DEFAULT_THRESHOLDS[vitalType];

    return {
      minValue: custom?.minValue ?? defaults?.min ?? null,
      maxValue: custom?.maxValue ?? defaults?.max ?? null,
      minSecondary: custom?.minSecondary ?? defaults?.minSecondary ?? null,
      maxSecondary: custom?.maxSecondary ?? defaults?.maxSecondary ?? null,
    };
  }

  private checkAbnormal(
    value: number,
    secondary: number | null,
    threshold: { minValue: number | null; maxValue: number | null; minSecondary?: number | null; maxSecondary?: number | null },
  ): boolean {
    if (threshold.minValue != null && value < threshold.minValue) return true;
    if (threshold.maxValue != null && value > threshold.maxValue) return true;
    if (secondary != null) {
      if (threshold.minSecondary != null && secondary < threshold.minSecondary) return true;
      if (threshold.maxSecondary != null && secondary > threshold.maxSecondary) return true;
    }
    return false;
  }

  private determineSeverity(vital: any): AlertSeverity {
    const defaults = DEFAULT_THRESHOLDS[vital.vitalType];
    if (!defaults || defaults.max == null) return 'MEDIUM';

    const deviation = Math.abs(vital.value - (defaults.max + (defaults.min || 0)) / 2);
    const range = (defaults.max - (defaults.min || 0)) / 2;

    if (range === 0) return 'MEDIUM';
    const ratio = deviation / range;

    if (ratio > 2) return 'CRITICAL';
    if (ratio > 1.5) return 'HIGH';
    if (ratio > 1) return 'MEDIUM';
    return 'LOW';
  }

  private async createAnomalyAlert(patientId: string, vital: any) {
    const severity = this.determineSeverity(vital);
    const secondaryStr = vital.valueSecondary ? `/${vital.valueSecondary}` : '';

    const alert = await this.prisma.healthAlert.create({
      data: {
        patientId,
        vitalId: vital.id,
        alertType: 'ANOMALY',
        severity,
        message: `Abnormal ${vital.vitalType.replace('_', ' ')}: ${vital.value}${secondaryStr} ${vital.unit}`,
      },
    });

    // Notify patient
    await this.notifications.send(
      patientId,
      'VITAL_ANOMALY',
      'Abnormal Vital Reading',
      alert.message,
      { alertId: alert.id, vitalId: vital.id },
    );

    // Notify connected doctors and family members
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: patientId, status: 'ACCEPTED' },
          { recipientId: patientId, status: 'ACCEPTED' },
        ],
      },
      include: {
        initiator: { select: { id: true } },
        recipient: { select: { id: true } },
      },
    });

    for (const conn of connections) {
      const connectedUserId = conn.initiatorId === patientId ? conn.recipientId : conn.initiatorId;
      if (conn.permissionLevel !== 'NOT_ALLOWED') {
        await this.notifications.send(
          connectedUserId,
          'VITAL_ANOMALY',
          'Patient Vital Alert',
          alert.message,
          { alertId: alert.id, patientId, vitalId: vital.id },
        );
      }
    }

    return alert;
  }

  private async verifyConnection(requesterId: string, patientId: string) {
    const connection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: requesterId, recipientId: patientId },
          { initiatorId: patientId, recipientId: requesterId },
        ],
        status: 'ACCEPTED',
      },
    });

    if (!connection) {
      throw new ForbiddenException('No active connection with this patient');
    }

    return connection;
  }
}
