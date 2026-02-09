enum DoseStatus {
  due,
  taken,
  takenLate,
  missed,
  skipped,
}

extension DoseStatusExtension on DoseStatus {
  String toJson() => name;
  
  static DoseStatus fromJson(String value) {
    return DoseStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DoseStatus.due,
    );
  }
}
