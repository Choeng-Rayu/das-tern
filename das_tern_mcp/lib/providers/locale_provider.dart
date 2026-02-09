import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app locale (language) switching with persistence.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('km'), // Khmer
  ];

  Future<void> loadLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> changeLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
  }
}
