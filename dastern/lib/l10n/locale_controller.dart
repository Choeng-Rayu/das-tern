import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/theme_controller.dart';

const String _kLocaleKey = 'locale';

const List<Locale> kSupportedLocales = <Locale>[
  Locale('km'),
  Locale('en'),
];

const Locale kDefaultLocale = Locale('km');

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
