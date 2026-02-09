enum MedicationStatus {
  draft,
  active,
  paused,
  inactive,
}

extension MedicationStatusExtension on MedicationStatus {
  String toJson() => name;
  
  static MedicationStatus fromJson(String value) {
    return MedicationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicationStatus.draft,
    );
  }
}
