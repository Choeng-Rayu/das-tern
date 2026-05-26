// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Das Tern';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonOk => 'OK';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonOffline => 'Offline';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeWelcome => 'Welcome to Das Tern';

  @override
  String get homeWelcomeSubtitle =>
      'Your medication management, under your control.';

  @override
  String get homePlaceholder => 'Feature modules are still being scaffolded.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageKm => 'ខ្មែរ';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get dosesTaken => 'Taken';

  @override
  String get dosesMissed => 'Missed';

  @override
  String get dosesSkipped => 'Skipped';

  @override
  String get dosesSnooze => 'Snooze';

  @override
  String get adherenceGreenZone => '≥90%';

  @override
  String get adherenceYellowZone => '70–89%';

  @override
  String get adherenceRedZone => '<70%';

  @override
  String get errorsNetwork => 'No connection — please retry';

  @override
  String get errorsPermissionDenied => 'Permission denied';

  @override
  String get errorsUnknown => 'Something went wrong — please try again';
}
