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
