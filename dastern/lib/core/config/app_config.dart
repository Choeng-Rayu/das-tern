/// Compile-time application configuration sourced from `--dart-define`.
///
/// Read once at startup (in `main.dart`) and passed through Riverpod so
/// the rest of the app never reaches into `String.fromEnvironment` directly.
///
/// Required defines for any non-debug build:
/// - `SUPABASE_URL`
/// - `SUPABASE_ANON_KEY`
///
/// Optional:
/// - `SENTRY_DSN`     — enables Sentry in release builds when present
/// - `APP_ENV`        — one of `dev`, `staging`, `prod` (default: `dev`)
///
/// Spec ref: 00-overview §Requirement 7, §Requirement 9.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.environment,
    required this.sentryDsn,
    required this.googleWebClientId,
    required this.telegramBotClientId,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      environment: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
      sentryDsn: String.fromEnvironment('SENTRY_DSN'),
      googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      telegramBotClientId: String.fromEnvironment('TELEGRAM_BOT_CLIENT_ID'),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String environment;
  final String sentryDsn;
  final String googleWebClientId;
  final String telegramBotClientId;

  bool get isProduction => environment == 'prod';
  bool get isStaging => environment == 'staging';
  bool get isDev => environment == 'dev';
  bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasSentry => sentryDsn.isNotEmpty;
}
