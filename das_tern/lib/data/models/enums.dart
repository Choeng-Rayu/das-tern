// ── User & Account ──

enum UserRole {
  patient,
  doctor,
  familyMember;

  static UserRole fromString(String value) => switch (value.toUpperCase()) {
    'PATIENT' => UserRole.patient,
    'DOCTOR' => UserRole.doctor,
    'FAMILY_MEMBER' || 'FAMILY' => UserRole.familyMember,
    _ => UserRole.patient,
  };

  String toApiString() => switch (this) {
    UserRole.patient => 'PATIENT',
    UserRole.doctor => 'DOCTOR',
    UserRole.familyMember => 'FAMILY_MEMBER',
  };
}

enum Gender {
  male,
  female,
  other;

  static Gender fromString(String value) => switch (value.toUpperCase()) {
    'MALE' => Gender.male,
    'FEMALE' => Gender.female,
    _ => Gender.other,
  };

  String toApiString() => name.toUpperCase();
}

enum AccountStatus {
  active,
  pendingVerification,
  verified,
  rejected,
  locked;

  static AccountStatus fromString(String value) =>
      switch (value.toUpperCase()) {
        'ACTIVE' => AccountStatus.active,
        'PENDING_VERIFICATION' => AccountStatus.pendingVerification,
        'VERIFIED' => AccountStatus.verified,
        'REJECTED' => AccountStatus.rejected,
        'LOCKED' => AccountStatus.locked,
        _ => AccountStatus.active,
      };
}

// ── Prescription & Medication ──

enum PrescriptionStatus {
  draft,
  active,
  paused,
  inactive;

  static PrescriptionStatus fromString(String value) =>
      switch (value.toUpperCase()) {
        'DRAFT' => PrescriptionStatus.draft,
        'ACTIVE' => PrescriptionStatus.active,
        'PAUSED' => PrescriptionStatus.paused,
        'INACTIVE' => PrescriptionStatus.inactive,
        _ => PrescriptionStatus.draft,
      };

  String toApiString() => name.toUpperCase();
}

enum MedicineType {
  po,
  oral,
  injection,
  topical,
  other;

  static MedicineType fromString(String value) => switch (value.toUpperCase()) {
    'PO' => MedicineType.po,
    'ORAL' => MedicineType.oral,
    'INJECTION' => MedicineType.injection,
    'TOPICAL' => MedicineType.topical,
    _ => MedicineType.other,
  };

  String toApiString() => name.toUpperCase();
}

enum MedicineUnit {
  tablet,
  capsule,
  ml,
  mg,
  drop,
  other;

  static MedicineUnit fromString(String value) => switch (value.toUpperCase()) {
    'TABLET' => MedicineUnit.tablet,
    'CAPSULE' => MedicineUnit.capsule,
    'ML' => MedicineUnit.ml,
    'MG' => MedicineUnit.mg,
    'DROP' => MedicineUnit.drop,
    _ => MedicineUnit.other,
  };

  String toApiString() => name.toUpperCase();
}

// ── Dose Events ──

enum DoseEventStatus {
  due,
  takenOnTime,
  takenLate,
  missed,
  skipped;

  static DoseEventStatus fromString(String value) =>
      switch (value.toUpperCase()) {
        'DUE' => DoseEventStatus.due,
        'TAKEN_ON_TIME' => DoseEventStatus.takenOnTime,
        'TAKEN_LATE' => DoseEventStatus.takenLate,
        'MISSED' => DoseEventStatus.missed,
        'SKIPPED' => DoseEventStatus.skipped,
        _ => DoseEventStatus.due,
      };

  String toApiString() => switch (this) {
    DoseEventStatus.due => 'DUE',
    DoseEventStatus.takenOnTime => 'TAKEN_ON_TIME',
    DoseEventStatus.takenLate => 'TAKEN_LATE',
    DoseEventStatus.missed => 'MISSED',
    DoseEventStatus.skipped => 'SKIPPED',
  };
}

// ── Connections ──

enum ConnectionStatus {
  pending,
  accepted,
  revoked;

  static ConnectionStatus fromString(String value) =>
      switch (value.toUpperCase()) {
        'PENDING' => ConnectionStatus.pending,
        'ACCEPTED' => ConnectionStatus.accepted,
        'REVOKED' => ConnectionStatus.revoked,
        _ => ConnectionStatus.pending,
      };

  String toApiString() => name.toUpperCase();
}

enum PermissionLevel {
  notAllowed,
  request,
  selected,
  allowed;

  static PermissionLevel fromString(String value) =>
      switch (value.toUpperCase()) {
        'NOT_ALLOWED' => PermissionLevel.notAllowed,
        'REQUEST' => PermissionLevel.request,
        'SELECTED' => PermissionLevel.selected,
        'ALLOWED' => PermissionLevel.allowed,
        _ => PermissionLevel.notAllowed,
      };

  String toApiString() => switch (this) {
    PermissionLevel.notAllowed => 'NOT_ALLOWED',
    PermissionLevel.request => 'REQUEST',
    PermissionLevel.selected => 'SELECTED',
    PermissionLevel.allowed => 'ALLOWED',
  };
}

// ── Health Monitoring ──

enum VitalType {
  bloodPressure,
  glucose,
  heartRate,
  weight,
  temperature,
  spo2;

  static VitalType fromString(String value) => switch (value.toUpperCase()) {
    'BLOOD_PRESSURE' => VitalType.bloodPressure,
    'GLUCOSE' => VitalType.glucose,
    'HEART_RATE' => VitalType.heartRate,
    'WEIGHT' => VitalType.weight,
    'TEMPERATURE' => VitalType.temperature,
    'SPO2' => VitalType.spo2,
    _ => VitalType.heartRate,
  };

  String toApiString() => switch (this) {
    VitalType.bloodPressure => 'BLOOD_PRESSURE',
    VitalType.glucose => 'GLUCOSE',
    VitalType.heartRate => 'HEART_RATE',
    VitalType.weight => 'WEIGHT',
    VitalType.temperature => 'TEMPERATURE',
    VitalType.spo2 => 'SPO2',
  };
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical;

  static AlertSeverity fromString(String value) =>
      switch (value.toUpperCase()) {
        'LOW' => AlertSeverity.low,
        'MEDIUM' => AlertSeverity.medium,
        'HIGH' => AlertSeverity.high,
        'CRITICAL' => AlertSeverity.critical,
        _ => AlertSeverity.low,
      };

  String toApiString() => name.toUpperCase();
}

// ── Subscription ──

enum SubscriptionTier {
  freemium,
  premium,
  familyPremium;

  static SubscriptionTier fromString(String value) =>
      switch (value.toUpperCase()) {
        'FREEMIUM' || 'FREE' => SubscriptionTier.freemium,
        'PREMIUM' => SubscriptionTier.premium,
        'FAMILY_PREMIUM' => SubscriptionTier.familyPremium,
        _ => SubscriptionTier.freemium,
      };

  String toApiString() => switch (this) {
    SubscriptionTier.freemium => 'FREEMIUM',
    SubscriptionTier.premium => 'PREMIUM',
    SubscriptionTier.familyPremium => 'FAMILY_PREMIUM',
  };
}

// ── Notifications ──

enum NotificationType {
  connectionRequest,
  prescriptionUpdate,
  missedDoseAlert,
  urgentPrescriptionChange,
  familyAlert;

  static NotificationType fromString(String value) => switch (value
      .toUpperCase()) {
    'CONNECTION_REQUEST' => NotificationType.connectionRequest,
    'PRESCRIPTION_UPDATE' => NotificationType.prescriptionUpdate,
    'MISSED_DOSE_ALERT' => NotificationType.missedDoseAlert,
    'URGENT_PRESCRIPTION_CHANGE' => NotificationType.urgentPrescriptionChange,
    'FAMILY_ALERT' => NotificationType.familyAlert,
    _ => NotificationType.prescriptionUpdate,
  };

  String toApiString() => switch (this) {
    NotificationType.connectionRequest => 'CONNECTION_REQUEST',
    NotificationType.prescriptionUpdate => 'PRESCRIPTION_UPDATE',
    NotificationType.missedDoseAlert => 'MISSED_DOSE_ALERT',
    NotificationType.urgentPrescriptionChange => 'URGENT_PRESCRIPTION_CHANGE',
    NotificationType.familyAlert => 'FAMILY_ALERT',
  };
}

// ── App Preferences ──

enum AppLanguage {
  khmer,
  english;

  static AppLanguage fromString(String value) => switch (value.toLowerCase()) {
    'km' || 'khmer' => AppLanguage.khmer,
    _ => AppLanguage.english,
  };
}
