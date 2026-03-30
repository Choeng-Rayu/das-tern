import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/adherence_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/batch_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/doctor_dashboard_provider.dart';
import 'providers/dose_provider.dart';
import 'providers/health_monitoring_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/shell_tab_controller.dart';
import 'providers/subscription_provider.dart';
import 'services/api_service.dart';
import 'services/database_service.dart';
import 'services/logger_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'ui/theme/theme_provider.dart';

/// Global navigator key so NotificationService can push routes
/// without a BuildContext (e.g. when a notification is tapped).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DasTernApp extends StatefulWidget {
  const DasTernApp({super.key});

  @override
  State<DasTernApp> createState() => _DasTernAppState();
}

class _DasTernAppState extends State<DasTernApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Process any pending notification actions that were queued while the
    // app was closed (e.g. user tapped "Mark as Taken" from a notification).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingActions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App returned to foreground — process any queued notification actions.
      _processPendingActions();
    }
  }

  /// Retrieve queued notification actions (mark_taken / skip / snooze)
  /// from SharedPreferences and dispatch them to the DoseProvider.
  Future<void> _processPendingActions() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final doseProvider = Provider.of<DoseProvider>(context, listen: false);
    await doseProvider.processPendingNotificationActions();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService.instance),
        Provider<DatabaseService>(create: (_) => DatabaseService.instance),
        Provider<NotificationService>(
          create: (_) => NotificationService.instance,
        ),
        ChangeNotifierProvider<SyncService>.value(
          value: SyncService.instance,
        ),
        Provider<LoggerService>(create: (_) => LoggerService.instance),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..loadThemePreference(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..loadLocalePreference(),
        ),
        ChangeNotifierProxyProvider4<
          ApiService,
          DatabaseService,
          NotificationService,
          LoggerService,
          AuthProvider
        >(
          create: (context) => AuthProvider(
            apiService: context.read<ApiService>(),
            databaseService: context.read<DatabaseService>(),
            notificationService: context.read<NotificationService>(),
            loggerService: context.read<LoggerService>(),
          ),
          update: (_, api, database, notification, logger, previous) =>
              previous!,
        ),
        ChangeNotifierProxyProvider5<
          ApiService,
          DatabaseService,
          NotificationService,
          SyncService,
          LoggerService,
          DoseProvider
        >(
          create: (context) => DoseProvider(
            apiService: context.read<ApiService>(),
            databaseService: context.read<DatabaseService>(),
            notificationService: context.read<NotificationService>(),
            syncService: context.read<SyncService>(),
            loggerService: context.read<LoggerService>(),
          ),
          update: (_, api, database, notification, sync, logger, previous) =>
              previous!,
        ),
        ChangeNotifierProxyProvider3<
          ApiService,
          DatabaseService,
          SyncService,
          PrescriptionProvider
        >(
          create: (context) => PrescriptionProvider(
            apiService: context.read<ApiService>(),
            databaseService: context.read<DatabaseService>(),
            syncService: context.read<SyncService>(),
          ),
          update: (_, api, database, sync, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<ApiService, ConnectionProvider>(
          create: (context) =>
              ConnectionProvider(apiService: context.read<ApiService>()),
          update: (_, api, previous) => previous!,
        ),
        ChangeNotifierProxyProvider2<
          ApiService,
          LoggerService,
          NotificationProvider
        >(
          create: (context) => NotificationProvider(
            apiService: context.read<ApiService>(),
            loggerService: context.read<LoggerService>(),
          ),
          update: (_, api, logger, previous) => previous!,
        ),
        ChangeNotifierProxyProvider2<
          ApiService,
          LoggerService,
          DoctorDashboardProvider
        >(
          create: (context) => DoctorDashboardProvider(
            apiService: context.read<ApiService>(),
            loggerService: context.read<LoggerService>(),
          ),
          update: (_, api, logger, previous) => previous!,
        ),
        ChangeNotifierProxyProvider2<
          ApiService,
          LoggerService,
          SubscriptionProvider
        >(
          create: (context) => SubscriptionProvider(
            apiService: context.read<ApiService>(),
            loggerService: context.read<LoggerService>(),
          ),
          update: (_, api, logger, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<ApiService, HealthMonitoringProvider>(
          create: (context) =>
              HealthMonitoringProvider(apiService: context.read<ApiService>()),
          update: (_, api, previous) => previous!,
        ),
        ChangeNotifierProxyProvider4<
          ApiService,
          DatabaseService,
          SyncService,
          NotificationService,
          BatchProvider
        >(
          create: (context) => BatchProvider(
            apiService: context.read<ApiService>(),
            databaseService: context.read<DatabaseService>(),
            syncService: context.read<SyncService>(),
            notificationService: context.read<NotificationService>(),
          ),
          update: (_, api, database, sync, notification, previous) =>
              previous!,
        ),
        ChangeNotifierProxyProvider<ApiService, AdherenceProvider>(
          create: (context) =>
              AdherenceProvider(apiService: context.read<ApiService>()),
          update: (_, api, previous) => previous!,
        ),
        ChangeNotifierProvider(create: (_) => ShellTabController()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Das Tern',
            debugShowCheckedModeBanner: false,

            // Theme
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,

            // Localization
            locale: localeProvider.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Routing
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
