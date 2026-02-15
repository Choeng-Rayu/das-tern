// Legacy enum kept for backward compatibility with local Medication model
enum MedicationType {
  regular,
  prn,
}

extension MedicationTypeExtension on MedicationType {
  String toJson() => name;

  static MedicationType fromJson(String value) {
    return MedicationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicationType.regular,
    );
  }
}

// New enums matching backend Prisma schema

enum MedicineType {
  po,
  oral,
  injection,
  topical,
  other;

  String toJson() => name.toUpperCase();

  static MedicineType fromJson(String value) {
    return MedicineType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => MedicineType.oral,
    );
  }

  String get displayName {
    switch (this) {
      case MedicineType.po:
        return 'PO';
      case MedicineType.oral:
        return 'Oral';
      case MedicineType.injection:
        return 'Injection';
      case MedicineType.topical:
        return 'Topical';
      case MedicineType.other:
        return 'Other';
    }
  }
}

enum MedicineUnit {
  tablet,
  capsule,
  ml,
  mg,
  drop,
  other;

  String toJson() => name.toUpperCase();

  static MedicineUnit fromJson(String value) {
    return MedicineUnit.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => MedicineUnit.tablet,
    );
  }

  String get displayName {
    switch (this) {
      case MedicineUnit.tablet:
        return 'Tablet';
      case MedicineUnit.capsule:
        return 'Capsule';
      case MedicineUnit.ml:
        return 'mL';
      case MedicineUnit.mg:
        return 'mg';
      case MedicineUnit.drop:
        return 'Drop';
      case MedicineUnit.other:
        return 'Other';
    }
  }
}

enum VitalType {
  bloodPressure,
  glucose,
  heartRate,
  weight,
  temperature,
  spo2;

  String toJson() {
    switch (this) {
      case VitalType.bloodPressure:
        return 'BLOOD_PRESSURE';
      case VitalType.glucose:
        return 'GLUCOSE';
      case VitalType.heartRate:
        return 'HEART_RATE';
      case VitalType.weight:
        return 'WEIGHT';
      case VitalType.temperature:
        return 'TEMPERATURE';
      case VitalType.spo2:
        return 'SPO2';
    }
  }

  static VitalType fromJson(String value) {
    switch (value.toUpperCase()) {
      case 'BLOOD_PRESSURE':
        return VitalType.bloodPressure;
      case 'GLUCOSE':
        return VitalType.glucose;
      case 'HEART_RATE':
        return VitalType.heartRate;
      case 'WEIGHT':
        return VitalType.weight;
      case 'TEMPERATURE':
        return VitalType.temperature;
      case 'SPO2':
        return VitalType.spo2;
      default:
        return VitalType.heartRate;
    }
  }

  String get displayName {
    switch (this) {
      case VitalType.bloodPressure:
        return 'Blood Pressure';
      case VitalType.glucose:
        return 'Glucose';
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.weight:
        return 'Weight';
      case VitalType.temperature:
        return 'Temperature';
      case VitalType.spo2:
        return 'SpO2';
    }
  }

  String get unit {
    switch (this) {
      case VitalType.bloodPressure:
        return 'mmHg';
      case VitalType.glucose:
        return 'mg/dL';
      case VitalType.heartRate:
        return 'bpm';
      case VitalType.weight:
        return 'kg';
      case VitalType.temperature:
        return '\u00B0C';
      case VitalType.spo2:
        return '%';
    }
  }
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical;

  String toJson() => name.toUpperCase();

  static AlertSeverity fromJson(String value) {
    return AlertSeverity.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => AlertSeverity.low,
    );
  }

  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}
