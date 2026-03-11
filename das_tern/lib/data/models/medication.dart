class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.frequency,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double dosage;
  final String unit;
  final String frequency;
  final bool isActive;

  Medication copyWith({
    String? id,
    String? name,
    double? dosage,
    String? unit,
    String? frequency,
    bool? isActive,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
    );
  }
}
