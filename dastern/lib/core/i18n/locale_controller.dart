import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_controller.dart';

/// Persistence key for the active locale's language code.
const String _kLocaleKey = 'locale';

/// Locales the app ships with. Keep this aligned with `pubspec.yaml`'s
/// `flutter_localizations` setup and `MaterialApp.supportedLocales`.
const List<Locale> kSupportedLocales = <Locale>[Locale('km'), Locale('en')];

/// Default locale when neither the user nor the device specifies a
/// supported one. Khmer is the team-agreed default per the product
/// requirements.
const Locale kDefaultLocale = Locale('km');

/// Controls the active [Locale].
///
/// Initial value priority:
/// 1. The user's previously saved choice in [SharedPreferences].
/// 2. The device locale, if it matches one of [kSupportedLocales].
/// 3. [kDefaultLocale] (Khmer).
///
/// Spec ref: 09-design-system-localization §Requirement 5, §Requirement 6.
class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._prefs, {Locale? deviceLocale})
    : super(_initial(_prefs, deviceLocale));

  final SharedPreferences _prefs;

  static Locale _initial(SharedPreferences prefs, Locale? deviceLocale) {
    final String? saved = prefs.getString(_kLocaleKey);
    if (saved != null) {
      final Locale? match = kSupportedLocales
          .where((Locale l) => l.languageCode == saved)
          .firstOrNull;
      if (match != null) return match;
    }
    if (deviceLocale != null) {
      final Locale? match = kSupportedLocales
          .where((Locale l) => l.languageCode == deviceLocale.languageCode)
          .firstOrNull;
      if (match != null) return match;
    }
    return kDefaultLocale;
  }

  /// Updates the active [Locale] and persists the choice.
  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    state = locale;
    await _prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final StateNotifierProvider<LocaleController, Locale> localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>(
      (Ref ref) => LocaleController(
        ref.watch(sharedPreferencesProvider),
        deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
      ),
    );

extension on Iterable<Locale> {
  Locale? get firstOrNull => isEmpty ? null : first;
}
