import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence key for the active [ThemeMode]. Used by [ThemeModeController]
/// when reading/writing to [SharedPreferences].
const String _kThemeModeKey = 'theme_mode';

/// Provides a singleton [SharedPreferences] instance.
///
/// Override this provider in tests with `ProviderScope(overrides: [...])`
/// to inject a mock or in-memory implementation.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError(
        'sharedPreferencesProvider must be overridden in main.dart with the '
        'value returned from SharedPreferences.getInstance().',
      ),
    );

/// Controls the active [ThemeMode] (light / dark / system).
///
/// On read, the controller hydrates from [SharedPreferences] so the user's
/// last choice survives a cold start. On write, it persists the new value
/// asynchronously — the UI never has to wait.
///
/// Spec ref: 09-design-system-localization §Requirement 12.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    final String? saved = prefs.getString(_kThemeModeKey);
    return ThemeMode.values.firstWhere(
      (ThemeMode m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  /// Updates the active [ThemeMode] and persists the choice.
  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.setString(_kThemeModeKey, mode.name);
  }
}

final StateNotifierProvider<ThemeModeController, ThemeMode>
themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
      (Ref ref) => ThemeModeController(ref.watch(sharedPreferencesProvider)),
    );
