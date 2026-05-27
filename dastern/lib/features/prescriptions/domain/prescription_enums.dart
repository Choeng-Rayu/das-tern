/// Prescription lifecycle states.
/// Spec ref: 03-prescription-medication design §6.
enum PrescriptionStatus { draft, active, paused, inactive }

/// Patient gender.
enum Gender { male, female, other }

/// Medicine delivery route.
enum MedicineType { po, oral, injection, topical, other }

/// Dosage unit.
enum MedicineUnit { tablet, capsule, ml, mg, drop, other }

/// Time-of-day slot for a dose.
enum TimePeriod { morning, afternoon, evening, night }

extension PrescriptionStatusX on PrescriptionStatus {
  String get code => name.toUpperCase();
  static PrescriptionStatus fromCode(String? s) =>
      PrescriptionStatus.values.firstWhere(
        (e) => e.code == s?.toUpperCase(),
        orElse: () => PrescriptionStatus.draft,
      );
}

extension GenderX on Gender {
  String get code => name.toUpperCase();
  static Gender fromCode(String? s) => Gender.values.firstWhere(
        (e) => e.code == s?.toUpperCase(),
        orElse: () => Gender.other,
      );
}

extension MedicineTypeX on MedicineType {
  String get code => name.toUpperCase();
  static MedicineType fromCode(String? s) => MedicineType.values.firstWhere(
        (e) => e.code == s?.toUpperCase(),
        orElse: () => MedicineType.oral,
      );
}

extension MedicineUnitX on MedicineUnit {
  String get code => name.toUpperCase();
  static MedicineUnit fromCode(String? s) => MedicineUnit.values.firstWhere(
        (e) => e.code == s?.toUpperCase(),
        orElse: () => MedicineUnit.tablet,
      );
}

extension TimePeriodX on TimePeriod {
  String get code => name.toUpperCase();
  static TimePeriod fromCode(String? s) => TimePeriod.values.firstWhere(
        (e) => e.code == s?.toUpperCase(),
        orElse: () => TimePeriod.morning,
      );
}
