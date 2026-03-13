// Barrel file for all enums matching the backend Prisma schema.

enum UserRole { patient, doctor, familyMember }

enum Gender { male, female, other }

enum AppLanguage { khmer, english }

enum AppTheme { light, dark }

enum AccountStatus { active, pendingVerification, verified, rejected, locked }

enum ConnectionStatus { pending, accepted, revoked }

enum PermissionLevel { notAllowed, request, selected, allowed }

enum PrescriptionStatus { draft, active, paused, inactive }

enum TimePeriod { morning, afternoon, evening, night }

enum DoseEventStatus { due, takenOnTime, takenLate, missed, skipped }

enum SubscriptionTier { freemium, premium, familyPremium }

enum NotificationType {
  connectionRequest,
  prescriptionUpdate,
  missedDoseAlert,
  urgentPrescriptionChange,
  familyAlert,
  vitalAnomaly,
  emergencyAlert,
  reminderEscalation,
  doseConfirmed,
}

// ── Helpers ──

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'PATIENT':
      return UserRole.patient;
    case 'DOCTOR':
      return UserRole.doctor;
    case 'FAMILY_MEMBER':
      return UserRole.familyMember;
    default:
      return UserRole.patient;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.patient:
      return 'PATIENT';
    case UserRole.doctor:
      return 'DOCTOR';
    case UserRole.familyMember:
      return 'FAMILY_MEMBER';
  }
}

Gender genderFromString(String value) {
  switch (value) {
    case 'MALE':
      return Gender.male;
    case 'FEMALE':
      return Gender.female;
    default:
      return Gender.other;
  }
}

String genderToString(Gender gender) {
  switch (gender) {
    case Gender.male:
      return 'MALE';
    case Gender.female:
      return 'FEMALE';
    case Gender.other:
      return 'OTHER';
  }
}

DoseEventStatus doseStatusFromString(String value) {
  switch (value) {
    case 'DUE':
      return DoseEventStatus.due;
    case 'TAKEN_ON_TIME':
      return DoseEventStatus.takenOnTime;
    case 'TAKEN_LATE':
      return DoseEventStatus.takenLate;
    case 'MISSED':
      return DoseEventStatus.missed;
    case 'SKIPPED':
      return DoseEventStatus.skipped;
    default:
      return DoseEventStatus.due;
  }
}

String doseStatusToString(DoseEventStatus status) {
  switch (status) {
    case DoseEventStatus.due:
      return 'DUE';
    case DoseEventStatus.takenOnTime:
      return 'TAKEN_ON_TIME';
    case DoseEventStatus.takenLate:
      return 'TAKEN_LATE';
    case DoseEventStatus.missed:
      return 'MISSED';
    case DoseEventStatus.skipped:
      return 'SKIPPED';
  }
}

PrescriptionStatus prescriptionStatusFromString(String value) {
  switch (value) {
    case 'DRAFT':
      return PrescriptionStatus.draft;
    case 'ACTIVE':
      return PrescriptionStatus.active;
    case 'PAUSED':
      return PrescriptionStatus.paused;
    case 'INACTIVE':
      return PrescriptionStatus.inactive;
    default:
      return PrescriptionStatus.draft;
  }
}

ConnectionStatus connectionStatusFromString(String value) {
  switch (value) {
    case 'PENDING':
      return ConnectionStatus.pending;
    case 'ACCEPTED':
      return ConnectionStatus.accepted;
    case 'REVOKED':
      return ConnectionStatus.revoked;
    default:
      return ConnectionStatus.pending;
  }
}

NotificationType notificationTypeFromString(String value) {
  switch (value) {
    case 'CONNECTION_REQUEST':
      return NotificationType.connectionRequest;
    case 'PRESCRIPTION_UPDATE':
      return NotificationType.prescriptionUpdate;
    case 'MISSED_DOSE_ALERT':
      return NotificationType.missedDoseAlert;
    case 'URGENT_PRESCRIPTION_CHANGE':
      return NotificationType.urgentPrescriptionChange;
    case 'FAMILY_ALERT':
      return NotificationType.familyAlert;
    case 'VITAL_ANOMALY':
      return NotificationType.vitalAnomaly;
    case 'EMERGENCY_ALERT':
      return NotificationType.emergencyAlert;
    case 'REMINDER_ESCALATION':
      return NotificationType.reminderEscalation;
    case 'DOSE_CONFIRMED':
      return NotificationType.doseConfirmed;
    default:
      return NotificationType.familyAlert;
  }
}

String notificationTypeToString(NotificationType type) {
  switch (type) {
    case NotificationType.connectionRequest:
      return 'CONNECTION_REQUEST';
    case NotificationType.prescriptionUpdate:
      return 'PRESCRIPTION_UPDATE';
    case NotificationType.missedDoseAlert:
      return 'MISSED_DOSE_ALERT';
    case NotificationType.urgentPrescriptionChange:
      return 'URGENT_PRESCRIPTION_CHANGE';
    case NotificationType.familyAlert:
      return 'FAMILY_ALERT';
    case NotificationType.vitalAnomaly:
      return 'VITAL_ANOMALY';
    case NotificationType.emergencyAlert:
      return 'EMERGENCY_ALERT';
    case NotificationType.reminderEscalation:
      return 'REMINDER_ESCALATION';
    case NotificationType.doseConfirmed:
      return 'DOSE_CONFIRMED';
  }
}
