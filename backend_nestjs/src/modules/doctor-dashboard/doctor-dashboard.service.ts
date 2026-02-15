import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AdherenceService, AdherenceResult } from './adherence.service';
import { DoctorNotesService } from './doctor-notes.service';
import { AdherenceFilter, PatientListQueryDto } from './dto/patient-list-query.dto';

export interface DashboardOverview {
  totalPatients: number;
  patientsNeedingAttention: number;
  todayAlerts: any[];
  recentActivity: any[];
  pendingRequests: number;
}

export interface PatientListItem {
  id: string;
  firstName: string | null;
  lastName: string | null;
  fullName: string | null;
  age: number | null;
  gender: string | null;
  phoneNumber: string;
  activePrescriptions: number;
  adherencePercentage: number;
  adherenceLevel: string;
  lastActivity: Date | null;
  connectionId: string;
}

@Injectable()
export class DoctorDashboardService {
  constructor(
    private prisma: PrismaService,
    private auditService: AuditService,
    private notificationsService: NotificationsService,
    private adherenceService: AdherenceService,
    private doctorNotesService: DoctorNotesService,
  ) {}

  /**
   * Get the doctor's dashboard overview.
   */
  async getDashboardOverview(doctorId: string): Promise<DashboardOverview> {
    // Get accepted connections (patients)
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: doctorId, recipient: { role: 'PATIENT' } },
          { recipientId: doctorId, initiator: { role: 'PATIENT' } },
        ],
        status: 'ACCEPTED',
      },
      include: {
        initiator: { select: { id: true, role: true } },
        recipient: { select: { id: true, role: true } },
      },
    });

    const patientIds = connections.map((c) =>
      c.initiator.role === 'PATIENT' ? c.initiatorId : c.recipientId,
    );

    // Get adherence for all patients
    const adherenceMap = await this.adherenceService.getBatchAdherence(patientIds);
    const needingAttention = Array.from(adherenceMap.values()).filter(
      (a) => a.overallPercentage < 70,
    ).length;

    // Get missed dose alerts
    const alerts = await this.adherenceService.detectMissedDoseAlerts(patientIds);

    // Get pending connection requests count
    const pendingRequests = await this.prisma.connection.count({
      where: {
        OR: [
          { recipientId: doctorId, status: 'PENDING' },
        ],
      },
    });

    // Get recent activity (last 10 audit logs)
    const recentActivity = await this.prisma.auditLog.findMany({
      where: { actorId: doctorId },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    return {
      totalPatients: patientIds.length,
      patientsNeedingAttention: needingAttention,
      todayAlerts: alerts,
      recentActivity,
      pendingRequests,
    };
  }

  /**
   * Get list of doctor's patients with adherence and filtering.
   */
  async getPatientList(
    doctorId: string,
    query: PatientListQueryDto,
  ): Promise<{ patients: PatientListItem[]; total: number; page: number }> {
    const page = query.page || 1;
    const limit = query.limit || 20;

    // Get accepted connections (patients)
    const connections = await this.prisma.connection.findMany({
      where: {
        OR: [
          { initiatorId: doctorId, recipient: { role: 'PATIENT' } },
          { recipientId: doctorId, initiator: { role: 'PATIENT' } },
        ],
        status: 'ACCEPTED',
      },
      include: {
        initiator: {
          select: {
            id: true, firstName: true, lastName: true, fullName: true,
            phoneNumber: true, gender: true, dateOfBirth: true, role: true,
          },
        },
        recipient: {
          select: {
            id: true, firstName: true, lastName: true, fullName: true,
            phoneNumber: true, gender: true, dateOfBirth: true, role: true,
          },
        },
      },
    });

    // Build patient list with adherence
    let patients: PatientListItem[] = [];

    for (const conn of connections) {
      const patient = conn.initiator.role === 'PATIENT' ? conn.initiator : conn.recipient;
      const adherence = await this.adherenceService.calculateAdherence(patient.id);

      // Active prescriptions count
      const activePrescriptions = await this.prisma.prescription.count({
        where: { patientId: patient.id, status: 'ACTIVE' },
      });

      // Search filter
      if (query.search) {
        const search = query.search.toLowerCase();
        const name = `${patient.firstName || ''} ${patient.lastName || ''} ${patient.fullName || ''}`.toLowerCase();
        if (!name.includes(search) && !patient.phoneNumber.includes(search)) {
          continue;
        }
      }

      // Last activity
      const lastDose = await this.prisma.doseEvent.findFirst({
        where: { patientId: patient.id },
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      });

      patients.push({
        id: patient.id,
        firstName: patient.firstName,
        lastName: patient.lastName,
        fullName: patient.fullName,
        age: patient.dateOfBirth ? this.calculateAge(patient.dateOfBirth) : null,
        gender: patient.gender,
        phoneNumber: patient.phoneNumber,
        activePrescriptions,
        adherencePercentage: adherence.overallPercentage,
        adherenceLevel: adherence.level,
        lastActivity: lastDose?.updatedAt || null,
        connectionId: conn.id,
      });
    }

    // Filter by adherence level
    if (query.adherenceFilter) {
      patients = patients.filter((p) => p.adherenceLevel === query.adherenceFilter);
    }

    // Filter by prescription status
    if (query.prescriptionStatus) {
      patients = patients.filter((p) => {
        if (query.prescriptionStatus === 'active') return p.activePrescriptions > 0;
        return true;
      });
    }

    // Sorting
    const sortBy = query.sortBy || 'adherencePercentage';
    const sortOrder = query.sortOrder || 'asc';
    patients.sort((a, b) => {
      let aVal: any = (a as any)[sortBy];
      let bVal: any = (b as any)[sortBy];
      if (aVal == null) aVal = sortOrder === 'asc' ? Infinity : -Infinity;
      if (bVal == null) bVal = sortOrder === 'asc' ? Infinity : -Infinity;
      if (typeof aVal === 'string') aVal = aVal.toLowerCase();
      if (typeof bVal === 'string') bVal = bVal.toLowerCase();
      return sortOrder === 'asc' ? (aVal > bVal ? 1 : -1) : (aVal < bVal ? 1 : -1);
    });

    const total = patients.length;
    const paginated = patients.slice((page - 1) * limit, page * limit);

    return { patients: paginated, total, page };
  }

  /**
   * Get detailed patient info (requires active connection).
   */
  async getPatientDetails(doctorId: string, patientId: string) {
    // Verify connection
    const connection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: doctorId, recipientId: patientId },
          { initiatorId: patientId, recipientId: doctorId },
        ],
        status: 'ACCEPTED',
      },
    });

    if (!connection) {
      throw new ForbiddenException('No active connection with this patient');
    }

    // Patient info
    const patient = await this.prisma.user.findUnique({
      where: { id: patientId },
      select: {
        id: true, firstName: true, lastName: true, fullName: true,
        phoneNumber: true, email: true, gender: true, dateOfBirth: true,
      },
    });

    if (!patient) {
      throw new NotFoundException('Patient not found');
    }

    // Prescriptions
    const prescriptions = await this.prisma.prescription.findMany({
      where: {
        patientId,
        OR: [{ doctorId }, { doctorId: null }],
      },
      include: { medications: true },
      orderBy: { createdAt: 'desc' },
    });

    // Adherence
    const adherence = await this.adherenceService.calculateAdherence(patientId);
    const adherenceTimeline = await this.adherenceService.getAdherenceTimeline(patientId);

    // Doctor notes
    const notes = await this.doctorNotesService.findAll(doctorId, patientId);

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'DATA_ACCESS',
      resourceType: 'User',
      resourceId: patientId,
      details: { action: 'VIEW_PATIENT_DETAILS' },
    });

    return {
      patient: {
        ...patient,
        age: patient.dateOfBirth ? this.calculateAge(patient.dateOfBirth) : null,
      },
      prescriptions,
      adherence,
      adherenceTimeline,
      notes,
      connectionId: connection.id,
    };
  }

  /**
   * Get adherence data for a specific patient.
   */
  async getPatientAdherence(
    doctorId: string,
    patientId: string,
    startDate?: string,
    endDate?: string,
  ) {
    // Verify connection
    const connection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: doctorId, recipientId: patientId },
          { initiatorId: patientId, recipientId: doctorId },
        ],
        status: 'ACCEPTED',
      },
    });

    if (!connection) {
      throw new ForbiddenException('No active connection with this patient');
    }

    const start = startDate ? new Date(startDate) : undefined;
    const end = endDate ? new Date(endDate) : undefined;

    const adherence = await this.adherenceService.calculateAdherence(patientId, start, end);
    const timeline = await this.adherenceService.getAdherenceTimeline(patientId);
    const alerts = await this.adherenceService.detectMissedDoseAlerts([patientId]);

    return { ...adherence, timeline, alerts };
  }

  /**
   * Accept a pending connection request (doctor accepting patient).
   */
  async acceptConnectionRequest(doctorId: string, connectionId: string) {
    const connection = await this.prisma.connection.findUnique({
      where: { id: connectionId },
      include: {
        initiator: { select: { id: true, fullName: true, firstName: true } },
      },
    });

    if (!connection) {
      throw new NotFoundException('Connection request not found');
    }

    if (connection.recipientId !== doctorId) {
      throw new ForbiddenException('Only the recipient can accept');
    }

    if (connection.status !== 'PENDING') {
      throw new ForbiddenException('Connection is not pending');
    }

    const updated = await this.prisma.connection.update({
      where: { id: connectionId },
      data: { status: 'ACCEPTED', acceptedAt: new Date() },
      include: {
        initiator: { select: { id: true, fullName: true, firstName: true, role: true } },
        recipient: { select: { id: true, fullName: true, firstName: true, role: true } },
      },
    });

    // Notify the patient
    await this.notificationsService.send(
      connection.initiatorId,
      'CONNECTION_REQUEST',
      'Connection Accepted',
      'Your doctor has accepted your connection request.',
      { connectionId },
    );

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'CONNECTION_ACCEPT',
      resourceType: 'Connection',
      resourceId: connectionId,
      details: { patientId: connection.initiatorId },
    });

    return updated;
  }

  /**
   * Reject a pending connection request.
   */
  async rejectConnectionRequest(doctorId: string, connectionId: string, reason?: string) {
    const connection = await this.prisma.connection.findUnique({
      where: { id: connectionId },
    });

    if (!connection) {
      throw new NotFoundException('Connection request not found');
    }

    if (connection.recipientId !== doctorId) {
      throw new ForbiddenException('Only the recipient can reject');
    }

    const updated = await this.prisma.connection.update({
      where: { id: connectionId },
      data: { status: 'REVOKED', revokedAt: new Date() },
    });

    // Notify the patient
    await this.notificationsService.send(
      connection.initiatorId,
      'CONNECTION_REQUEST',
      'Connection Declined',
      reason || 'Your connection request was declined.',
    );

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'CONNECTION_REVOKE',
      resourceType: 'Connection',
      resourceId: connectionId,
      details: { reason, patientId: connection.initiatorId },
    });

    return updated;
  }

  /**
   * Disconnect from a patient.
   */
  async disconnectPatient(doctorId: string, connectionId: string, reason: string) {
    const connection = await this.prisma.connection.findUnique({
      where: { id: connectionId },
    });

    if (!connection) {
      throw new NotFoundException('Connection not found');
    }

    if (connection.initiatorId !== doctorId && connection.recipientId !== doctorId) {
      throw new ForbiddenException('Access denied');
    }

    const updated = await this.prisma.connection.update({
      where: { id: connectionId },
      data: { status: 'REVOKED', revokedAt: new Date() },
    });

    // Determine patient ID
    const patientId =
      connection.initiatorId === doctorId
        ? connection.recipientId
        : connection.initiatorId;

    // Notify the patient
    await this.notificationsService.send(
      patientId,
      'CONNECTION_REQUEST',
      'Doctor Disconnected',
      reason || 'Your doctor has ended the connection.',
      { connectionId },
    );

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'DOCTOR_DISCONNECT',
      resourceType: 'Connection',
      resourceId: connectionId,
      details: { reason, patientId },
    });

    return updated;
  }

  /**
   * Get pending connection requests for the doctor.
   */
  async getPendingRequests(doctorId: string) {
    return this.prisma.connection.findMany({
      where: {
        recipientId: doctorId,
        status: 'PENDING',
      },
      include: {
        initiator: {
          select: {
            id: true, firstName: true, lastName: true, fullName: true,
            phoneNumber: true, gender: true, dateOfBirth: true,
          },
        },
      },
      orderBy: { requestedAt: 'desc' },
    });
  }

  private calculateAge(dateOfBirth: Date): number {
    const today = new Date();
    let age = today.getFullYear() - dateOfBirth.getFullYear();
    const monthDiff = today.getMonth() - dateOfBirth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dateOfBirth.getDate())) {
      age--;
    }
    return age;
  }

  /**
   * Get prescriptions created by or assigned to this doctor.
   */
  async getDoctorPrescriptions(
    doctorId: string,
    query: { status?: string; page?: number; limit?: number },
  ) {
    const page = query.page || 1;
    const limit = query.limit || 20;

    const where: any = {
      OR: [
        { doctorId },
        {
          patient: {
            OR: [
              { initiatedConnections: { some: { recipientId: doctorId, status: 'ACCEPTED' } } },
              { receivedConnections: { some: { initiatorId: doctorId, status: 'ACCEPTED' } } },
            ],
          },
        },
      ],
    };

    if (query.status) {
      where.status = query.status.toUpperCase();
    }

    const [prescriptions, total] = await Promise.all([
      this.prisma.prescription.findMany({
        where,
        include: {
          medications: true,
          patient: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              fullName: true,
              phoneNumber: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.prescription.count({ where }),
    ]);

    return { prescriptions, total, page };
  }

  /**
   * Get a specific prescription detail (doctor must be connected to the patient).
   */
  async getDoctorPrescriptionDetail(doctorId: string, prescriptionId: string) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
      include: {
        medications: true,
        patient: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            fullName: true,
            phoneNumber: true,
            gender: true,
            dateOfBirth: true,
          },
        },
        versions: {
          orderBy: { versionNumber: 'desc' },
          take: 5,
        },
      },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    // Verify doctor access
    if (prescription.doctorId !== doctorId) {
      const connection = await this.prisma.connection.findFirst({
        where: {
          OR: [
            { initiatorId: doctorId, recipientId: prescription.patientId },
            { initiatorId: prescription.patientId, recipientId: doctorId },
          ],
          status: 'ACCEPTED',
        },
      });

      if (!connection) {
        throw new ForbiddenException('No access to this prescription');
      }
    }

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'DATA_ACCESS',
      resourceType: 'Prescription',
      resourceId: prescriptionId,
      details: { action: 'VIEW_PRESCRIPTION_DETAIL' },
    });

    return prescription;
  }
}
