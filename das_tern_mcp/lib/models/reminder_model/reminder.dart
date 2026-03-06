class Reminder {
  final String id;
  final String patientId;
  final String medicationId;
  final String prescriptionId;
  final DateTime scheduledTime;
  final String timePeriod;
  final String status;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? snoozedUntil;
  final int snoozeCount;
  final int repeatCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String medicationName;
  final String dosage;
  final Map<String, dynamic>? medication;

  Reminder({
    required this.id,
    required this.patientId,
    required this.medicationId,
    required this.prescriptionId,
    required this.scheduledTime,
    required this.timePeriod,
    required this.status,
    this.deliveredAt,
    this.completedAt,
    this.snoozedUntil,
    this.snoozeCount = 0,
    this.repeatCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.medicationName = '',
    this.dosage = '',
    this.medication,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      medicationId: json['medicationId'] as String,
      prescriptionId: json['prescriptionId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      timePeriod: json['timePeriod'] as String,
      status: json['status'] as String,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'] as String)
          : null,
      snoozeCount: json['snoozeCount'] as int? ?? 0,
      repeatCount: json['repeatCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      medicationName: json['medicationName'] as String? ??
          (json['medication'] is Map
              ? json['medication']['medicineName'] as String? ?? ''
              : ''),
      dosage: json['dosage'] as String? ??
          (json['medication'] is Map
              ? '${json['medication']['dosageAmount'] ?? ''}'
              : ''),
      medication: json['medication'] is Map
          ? Map<String, dynamic>.from(json['medication'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'medicationId': medicationId,
      'prescriptionId': prescriptionId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'timePeriod': timePeriod,
      'status': status,
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (snoozedUntil != null)
        'snoozedUntil': snoozedUntil!.toIso8601String(),
      'snoozeCount': snoozeCount,
      'repeatCount': repeatCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'medicationName': medicationName,
      'dosage': dosage,
      if (medication != null) 'medication': medication,
    };
  }

  Reminder copyWith({
    String? id,
    String? patientId,
    String? medicationId,
    String? prescriptionId,
    DateTime? scheduledTime,
    String? timePeriod,
    String? status,
    DateTime? deliveredAt,
    DateTime? completedAt,
    DateTime? snoozedUntil,
    int? snoozeCount,
    int? repeatCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? medicationName,
    String? dosage,
    Map<String, dynamic>? medication,
  }) {
    return Reminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      medicationId: medicationId ?? this.medicationId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      timePeriod: timePeriod ?? this.timePeriod,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      repeatCount: repeatCount ?? this.repeatCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      medication: medication ?? this.medication,
    );
  }
}
