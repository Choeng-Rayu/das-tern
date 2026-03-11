class Reminder {
  const Reminder({
    required this.id,
    required this.medicationName,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final String id;
  final String medicationName;
  final int hour;
  final int minute;
  final bool enabled;
}
