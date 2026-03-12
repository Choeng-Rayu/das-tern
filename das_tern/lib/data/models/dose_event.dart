import 'package:das_tern/data/models/enums.dart';

class DoseEvent {
  const DoseEvent({
    required this.id,
    required this.prescriptionId,
    required this.medicationId,
    required this.patientId,
    required this.scheduledTime,
    required this.medicationName,
    required this.dosage,
    this.timePeriod = '',
    this.reminderTime,
    this.status = DoseEventStatus.due,
    this.takenAt,
    this.skipReason,
    this.wasOffline = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String prescriptionId;
  final String medicationId;
  final String patientId;
  final DateTime scheduledTime;
  final String timePeriod;
  final DateTime? reminderTime;
  final DoseEventStatus status;
  final DateTime? takenAt;
  final String? skipReason;
  final bool wasOffline;
  final String medicationName;
  final String dosage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDue => status == DoseEventStatus.due;
  bool get isTaken =>
      status == DoseEventStatus.takenOnTime ||
      status == DoseEventStatus.takenLate;
  bool get isMissed => status == DoseEventStatus.missed;
  bool get isSkipped => status == DoseEventStatus.skipped;

  factory DoseEvent.fromJson(Map<String, dynamic> json) {
    return DoseEvent(
      id: (json['id'] ?? '').toString(),
      prescriptionId: json['prescriptionId'] as String? ?? '',
      medicationId: json['medicationId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      scheduledTime:
          DateTime.tryParse(json['scheduledTime'] as String? ?? '') ??
          DateTime.now(),
      timePeriod: json['timePeriod'] as String? ?? '',
      reminderTime: json['reminderTime'] != null
          ? DateTime.tryParse(json['reminderTime'] as String)
          : null,
      status: DoseEventStatus.fromString(json['status'] as String? ?? 'DUE'),
      takenAt: json['takenAt'] != null
          ? DateTime.tryParse(json['takenAt'] as String)
          : null,
      skipReason: json['skipReason'] as String?,
      wasOffline: json['wasOffline'] as bool? ?? false,
      medicationName: json['medicationName'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'prescriptionId': prescriptionId,
    'medicationId': medicationId,
    'patientId': patientId,
    'scheduledTime': scheduledTime.toIso8601String(),
    'timePeriod': timePeriod,
    if (reminderTime != null) 'reminderTime': reminderTime!.toIso8601String(),
    'status': status.toApiString(),
    if (takenAt != null) 'takenAt': takenAt!.toIso8601String(),
    if (skipReason != null) 'skipReason': skipReason,
    'wasOffline': wasOffline,
    'medicationName': medicationName,
    'dosage': dosage,
  };

  DoseEvent copyWith({
    String? id,
    String? prescriptionId,
    String? medicationId,
    String? patientId,
    DateTime? scheduledTime,
    String? timePeriod,
    DateTime? reminderTime,
    DoseEventStatus? status,
    DateTime? takenAt,
    String? skipReason,
    bool? wasOffline,
    String? medicationName,
    String? dosage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoseEvent(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicationId: medicationId ?? this.medicationId,
      patientId: patientId ?? this.patientId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      timePeriod: timePeriod ?? this.timePeriod,
      reminderTime: reminderTime ?? this.reminderTime,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      skipReason: skipReason ?? this.skipReason,
      wasOffline: wasOffline ?? this.wasOffline,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
