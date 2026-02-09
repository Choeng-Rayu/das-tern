class DoseEvent {
  final String? id;
  final String prescriptionId;
  final String medicationId;
  final String patientId;
  final DateTime scheduledTime;
  final String timePeriod;
  final DateTime reminderTime;
  final String status;
  final DateTime? takenAt;
  final String? skipReason;
  final bool wasOffline;
  final String medicationName;
  final String dosage;
  final Map<String, dynamic>? medication;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoseEvent({
    this.id,
    required this.prescriptionId,
    required this.medicationId,
    required this.patientId,
    required this.scheduledTime,
    required this.timePeriod,
    required this.reminderTime,
    required this.status,
    this.takenAt,
    this.skipReason,
    this.wasOffline = false,
    this.medicationName = '',
    this.dosage = '',
    this.medication,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoseEvent.fromJson(Map<String, dynamic> json) {
    return DoseEvent(
      id: json['id'] as String?,
      prescriptionId: json['prescriptionId'] as String,
      medicationId: json['medicationId'] as String,
      patientId: json['patientId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      timePeriod: json['timePeriod'] as String,
      reminderTime: DateTime.parse(json['reminderTime'] as String),
      status: json['status'] as String,
      takenAt: json['takenAt'] != null ? DateTime.parse(json['takenAt'] as String) : null,
      skipReason: json['skipReason'] as String?,
      wasOffline: json['wasOffline'] as bool? ?? false,
      medicationName: json['medicationName'] as String? ??
          (json['medication'] is Map ? json['medication']['medicineName'] as String? ?? '' : ''),
      dosage: json['dosage'] as String? ??
          (json['medication'] is Map ? '${json['medication']['morningDosage'] ?? 0}' : ''),
      medication: json['medication'] is Map ? Map<String, dynamic>.from(json['medication']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'prescriptionId': prescriptionId,
      'medicationId': medicationId,
      'patientId': patientId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'timePeriod': timePeriod,
      'reminderTime': reminderTime.toIso8601String(),
      'status': status,
      if (takenAt != null) 'takenAt': takenAt!.toIso8601String(),
      if (skipReason != null) 'skipReason': skipReason,
      'wasOffline': wasOffline,
      'medicationName': medicationName,
      'dosage': dosage,
      if (medication != null) 'medication': medication,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
