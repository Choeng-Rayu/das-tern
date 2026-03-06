class ReminderSettings {
  final int gracePeriodMinutes;
  final bool repeatRemindersEnabled;
  final int repeatIntervalMinutes;
  final List<MedicationReminderSetting> medicationSettings;

  ReminderSettings({
    this.gracePeriodMinutes = 30,
    this.repeatRemindersEnabled = true,
    this.repeatIntervalMinutes = 10,
    this.medicationSettings = const [],
  });

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      gracePeriodMinutes: json['gracePeriodMinutes'] as int? ?? 30,
      repeatRemindersEnabled: json['repeatRemindersEnabled'] as bool? ?? true,
      repeatIntervalMinutes: json['repeatIntervalMinutes'] as int? ?? 10,
      medicationSettings: (json['medicationSettings'] as List?)
              ?.map((m) => MedicationReminderSetting.fromJson(
                  Map<String, dynamic>.from(m)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gracePeriodMinutes': gracePeriodMinutes,
      'repeatRemindersEnabled': repeatRemindersEnabled,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'medicationSettings': medicationSettings.map((m) => m.toJson()).toList(),
    };
  }

  ReminderSettings copyWith({
    int? gracePeriodMinutes,
    bool? repeatRemindersEnabled,
    int? repeatIntervalMinutes,
    List<MedicationReminderSetting>? medicationSettings,
  }) {
    return ReminderSettings(
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      repeatRemindersEnabled:
          repeatRemindersEnabled ?? this.repeatRemindersEnabled,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      medicationSettings: medicationSettings ?? this.medicationSettings,
    );
  }
}

class MedicationReminderSetting {
  final String medicationId;
  final String medicationName;
  final bool remindersEnabled;
  final Map<String, String>? customTimes;

  MedicationReminderSetting({
    required this.medicationId,
    this.medicationName = '',
    this.remindersEnabled = true,
    this.customTimes,
  });

  factory MedicationReminderSetting.fromJson(Map<String, dynamic> json) {
    return MedicationReminderSetting(
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String? ?? '',
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      customTimes: json['customTimes'] != null
          ? Map<String, String>.from(json['customTimes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'remindersEnabled': remindersEnabled,
      if (customTimes != null) 'customTimes': customTimes,
    };
  }
}
