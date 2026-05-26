/// Cambodia-time helpers.
///
/// Reminders default to Asia/Phnom_Penh (UTC+7). When a user has saved a
/// different timezone in `profiles.timezone`, the reminder logic uses that
/// instead — these helpers are only the fallback / default.
///
/// Spec ref: README §"Cambodia timezone is the canonical reminder timezone".
class CambodiaTime {
  const CambodiaTime._();

  /// IANA timezone identifier.
  static const String tzId = 'Asia/Phnom_Penh';

  /// Fixed UTC offset (Cambodia does not observe DST).
  static const Duration offset = Duration(hours: 7);

  /// Default PRN reminder times for users who skip configuration.
  /// Spec ref: README §"PRN Medications".
  static const List<({int hour, int minute, String label})> defaultPrnTimes =
      <({int hour, int minute, String label})>[
        (hour: 7, minute: 30, label: 'morning'),
        (hour: 12, minute: 0, label: 'noon'),
        (hour: 18, minute: 30, label: 'evening'),
        (hour: 21, minute: 30, label: 'night'),
      ];

  /// Converts a UTC [DateTime] into a wall-clock [DateTime] in Cambodia
  /// time (no `tz` package required; uses the fixed offset).
  static DateTime fromUtc(DateTime utc) => utc.toUtc().add(offset);

  /// Converts a Cambodia wall-clock [DateTime] back into UTC.
  static DateTime toUtc(DateTime cambodia) => DateTime.utc(
    cambodia.year,
    cambodia.month,
    cambodia.day,
    cambodia.hour,
    cambodia.minute,
    cambodia.second,
    cambodia.millisecond,
    cambodia.microsecond,
  ).subtract(offset);
}
