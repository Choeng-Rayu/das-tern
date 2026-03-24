// lib/core/providers/locale_provider.dart
//
// RxCam — Locale (language) management with SharedPreferences persistence.
// Supports English ('en') and Khmer ('km').

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app locale switching with persistence.
///
/// Supported locales: English ('en') and Khmer ('km').
///
/// Wire up in [MaterialApp]:
/// ```dart
/// Consumer<LocaleProvider>(
///   builder: (_, lp, __) => MaterialApp(
///     locale: lp.locale,
///     supportedLocales: LocaleProvider.supportedLocales,
///     ...
///   ),
/// )
/// ```
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Returns true when the current locale is Khmer.
  bool get isKhmer => _locale.languageCode == 'km';

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('km'), // Khmer
  ];

  /// Loads saved language preference from [SharedPreferences].
  Future<void> loadLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  /// Switches the app locale and persists the choice.
  Future<void> changeLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
  }

  /// Convenience toggle between English and Khmer.
  Future<void> toggleLocale() async {
    await changeLocale(isKhmer ? const Locale('en') : const Locale('km'));
  }
}
