class DoseEvent {
  final String? id;
  final String prescriptionId;
  final String medicationId;
  final String patientId;
  final DateTime scheduledTime;
  final String timePeriod;
  final String? reminderTime;
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
    this.reminderTime,
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
      id: json['id'] is String ? json['id'] as String : null,
      prescriptionId: json['prescriptionId'] is String
          ? json['prescriptionId'] as String
          : '',
      medicationId: json['medicationId'] is String
          ? json['medicationId'] as String
          : '',
      patientId: json['patientId'] is String ? json['patientId'] as String : '',
      scheduledTime: _parseScheduledTime(json),
      timePeriod: json['timePeriod'] is String
          ? json['timePeriod'] as String
          : 'MORNING',
      reminderTime: json['reminderTime'] is String
          ? json['reminderTime'] as String
          : null,
      status: json['status'] is String ? json['status'] as String : 'DUE',
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'].toString())
          : null,
      skipReason: json['skipReason'] is String
          ? json['skipReason'] as String
          : null,
      wasOffline: json['wasOffline'] is bool
          ? json['wasOffline'] as bool
          : false,
      medicationName: json['medicationName'] is String
          ? json['medicationName'] as String
          : (json['medication'] is Map
                ? (json['medication']['medicineName'] is String
                      ? json['medication']['medicineName'] as String
                      : '')
                : ''),
      dosage: json['dosage'] is String ? json['dosage'] as String :
          (json['dosage'] is Map
              ? (json['dosage']['amount']?.toString() ?? '')
              : (json['medication'] is Map
                  ? '${json['medication']['morningDosage'] ?? 0}'
                  : '')),
      medication: json['medication'] is Map
          ? Map<String, dynamic>.from(json['medication'] as Map)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  /// Parse scheduledTime and apply the actual dose time from [dosage.time]
  /// when the raw value resolves to midnight (a common backend pattern where
  /// the date is stored as UTC start-of-day for the local timezone).
  static DateTime _parseScheduledTime(Map<String, dynamic> json) {
    final raw = json['scheduledTime']?.toString() ?? '';
    final base = raw.isNotEmpty ? DateTime.parse(raw) : DateTime.now();
    final local = base.toLocal();

    // Extract HH:MM from dosage.time if available
    String? dosageTime;
    final dosage = json['dosage'];
    if (dosage is Map) {
      dosageTime = dosage['time']?.toString();
    }

    if (dosageTime != null) {
      final parts = dosageTime.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          // Always use dosage.time for the H:MM — the backend stores UTC
          // start-of-local-day in scheduledTime, so only the date part is
          // reliable; the real clock time lives in dosage.time.
          return DateTime(local.year, local.month, local.day, h, m);
        }
      }
    }

    // No dosage.time: if midnight, fall back to period default
    if (local.hour == 0 && local.minute == 0) {
      final period = (json['timePeriod']?.toString() ?? '').toUpperCase();
      final defaultHour = switch (period) {
        'MORNING' => 8,
        'AFTERNOON' => 13,
        'EVENING' => 18,
        'NIGHT' => 21,
        _ => 8,
      };
      return DateTime(local.year, local.month, local.day, defaultHour, 0);
    }

    return local;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'prescriptionId': prescriptionId,
      'medicationId': medicationId,
      'patientId': patientId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'timePeriod': timePeriod,
      if (reminderTime != null) 'reminderTime': reminderTime,
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
