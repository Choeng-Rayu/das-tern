import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/theme/theme_controller.dart';

/// Entry point.
///
/// Steps:
/// 1. Bind the Flutter binding so plugins can run before `runApp`.
/// 2. Hydrate [SharedPreferences] (theme + locale persistence).
/// 3. Read [AppConfig] from `--dart-define`s.
/// 4. Hand off to [DasTernApp] inside a [ProviderScope].
///
/// Subsequent foundation tasks (sync engine, Supabase init, Sentry init)
/// add their own awaitables here in the order shown by `00-overview`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Persistent prefs (used by theme + locale controllers).
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // 2) Read environment-time config (Supabase URL / anon key / Sentry DSN).
  final AppConfig config = AppConfig.fromEnvironment();

  // Surface a friendly warning during dev if Supabase config is missing,
  // but don't crash — the foundation scaffold runs without it.
  if (!config.hasSupabaseConfig) {
    appLogger.w(
      'SUPABASE_URL / SUPABASE_ANON_KEY not set. Pass them via '
      '--dart-define when running. The app will still launch.',
    );
  }

  // Supabase initialization.
  if (config.hasSupabaseConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  }

  // TODO(sentry):   sentry_flutter init — added in Phase 5 observability.

  runApp(
    ProviderScope(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DasTernApp(),
    ),
  );
}
