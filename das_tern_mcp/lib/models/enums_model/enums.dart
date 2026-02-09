// Barrel file for all enums matching the backend Prisma schema.

enum UserRole { patient, doctor, familyMember }

enum Gender { male, female, other }

enum AppLanguage { khmer, english }

enum AppTheme { light, dark }

enum AccountStatus { active, pendingVerification, verified, rejected, locked }

enum ConnectionStatus { pending, accepted, revoked }

enum PermissionLevel { notAllowed, request, selected, allowed }

enum PrescriptionStatus { draft, active, paused, inactive }

enum TimePeriod { daytime, night }

enum DoseEventStatus { due, takenOnTime, takenLate, missed, skipped }

enum SubscriptionTier { freemium, premium, familyPremium }

enum NotificationType {
  connectionRequest,
  prescriptionUpdate,
  missedDoseAlert,
  urgentPrescriptionChange,
  familyAlert,
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
