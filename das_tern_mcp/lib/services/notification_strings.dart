/// Locale-aware string provider for push notifications.
///
/// `NotificationService` runs partially in isolates (background callbacks)
/// where `BuildContext` is unavailable, so we cannot use `AppLocalizations`.
/// Instead we read the `'languageCode'` key from `SharedPreferences` —
/// the same key that `LocaleProvider` writes — and return the correct strings.
///
/// Supports: `'en'` (English) and `'km'` (Khmer).
/// Falls back to English for any unknown locale.
class NotificationStrings {
  const NotificationStrings._(this._lang);

  final String _lang;

  bool get _isKm => _lang == 'km';

  // ── Notification titles ───────────────────────────────────────────────────

  String get reminderTitle => _isKm ? 'ការរំលឹកថ្នាំ' : 'Medication Reminder';

  String get reminderRetryTag => _isKm ? ' (រំលឹក)' : ' (Reminder)';

  String get snoozedTitle =>
      _isKm ? 'ការរំលឹកថ្នាំ (ពន្យារ)' : 'Medication Reminder (Snoozed)';

  // ── Time-period labels ────────────────────────────────────────────────────

  String periodLabel(String timePeriod) => switch (timePeriod) {
    'MORNING' => _isKm ? 'ពេលព្រឹក' : 'Morning',
    'AFTERNOON' => _isKm ? 'ពេលរសៀល' : 'Afternoon',
    'EVENING' => _isKm ? 'ពេលល្ងាច' : 'Evening',
    'NIGHT' => _isKm ? 'ពេលយប់' : 'Night',
    _ => _isKm ? 'ថ្នាំ' : 'Dose',
  };

  // ── Notification bodies ───────────────────────────────────────────────────

  String singleBody(String name, String dosage, String period) => _isKm
      ? 'ដល់ពេលញ៉ាំ $name ($dosage) - $period'
      : 'Time to take $name ($dosage) - $period';

  String batchBodyHeader(String period) =>
      _isKm ? 'ថ្នាំ$period:' : '$period medicines:';

  String get snoozedBodySingle => _isKm
      ? 'អ្នកបានពន្យារការរំលឹកថ្នាំ។ សូមផឹកថ្នាំឥឡូវនេះ។'
      : 'You snoozed your medication reminder. Please take your medicine now.';

  String get snoozedBodyBatch => _isKm
      ? 'អ្នកបានពន្យារការរំលឹកថ្នាំ។ សូមផឹកថ្នាំទាំងអស់ឥឡូវនេះ។'
      : 'You snoozed your medication reminder. Please take your medicines now.';

  // ── Action button labels ──────────────────────────────────────────────────

  String get actionMarkTaken => _isKm ? 'សម្គាល់ថាបានទទួលទាន' : 'Mark as Taken';

  String get actionSnooze => _isKm ? 'ពន្យារ ១០ នាទី' : 'Snooze 10min';

  String get actionSkip => _isKm ? 'រំលង' : 'Skip';

  // ── Android channel strings ───────────────────────────────────────────────

  String get channelDoseRemindersName =>
      _isKm ? 'ការរំលឹកថ្នាំ' : 'Dose Reminders';

  String get channelDoseRemindersDesc =>
      _isKm ? 'ការរំលឹកដើម្បីផឹកថ្នាំ' : 'Reminders to take your medication';

  String get channelBatchRemindersName =>
      _isKm ? 'ការរំលឹកក្រុម' : 'Batch Reminders';

  String get channelBatchRemindersDesc => _isKm
      ? 'ការរំលឹកសម្រាប់ក្រុមថ្នាំ'
      : 'Reminders for medication batch groups';

  String get channelGeneralName => _isKm ? 'ទូទៅ' : 'General';

  String get channelGeneralDesc =>
      _isKm ? 'ការជូនដំណឹងទូទៅ' : 'General app notifications';

  // ── Test notification ─────────────────────────────────────────────────────

  String get testTitle => _isKm ? 'ការរំលឹកសាកល្បង' : 'Test Notification';

  String get testBody => _isKm
      ? 'នេះជាការរំលឹកសាកល្បង។ ប៊ូតុងសកម្មភាពដំណើរការបានត្រឹមត្រូវ។'
      : 'This is a test reminder. Action buttons work correctly.';

  // ── Factory ───────────────────────────────────────────────────────────────

  /// Build a [NotificationStrings] instance from a raw language code string.
  /// Accepts `'en'`, `'km'`, or any string (falls back to English).
  factory NotificationStrings.fromCode(String? langCode) =>
      NotificationStrings._(langCode ?? 'en');
}
