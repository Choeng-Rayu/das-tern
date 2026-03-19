import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_links/app_links.dart';

import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/dose_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/doctor_dashboard_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/health_monitoring_provider.dart';
import 'providers/batch_provider.dart';
import 'providers/adherence_provider.dart';
import 'providers/shell_tab_controller.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'services/logger_service.dart';
import 'ui/theme/light_theme.dart';
import 'ui/theme/dark_theme.dart';
import 'ui/theme/theme_provider.dart';
import 'utils/app_router.dart';
import 'l10n/app_localizations.dart';

/// Global navigator key so NotificationService can push routes
/// without a BuildContext (e.g. when a notification is tapped).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  final log = LoggerService.instance;
  // Capture Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    log.error(
      'FlutterError',
      'Uncaught Flutter error',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  log.info('App', 'Starting DAS TERN MCP App');
  WidgetsFlutterBinding.ensureInitialized();

  const isWeb = bool.fromEnvironment('dart.library.js_util');

  final useFfiDatabase =
      !isWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  if (useFfiDatabase) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    log.debug('App', 'Loading environment variables');
    await dotenv.load(fileName: '.env');
    log.success('App', 'Environment loaded');

    // Initialize offline services
    log.info('App', 'Initializing services');
    await NotificationService.instance.init();
    await SyncService.instance.startListening();
    log.success('App', 'Services initialized');

    // Wire up notification tap handler — navigates to the patient home tab
    // (dose schedule) so the user can see the relevant dose.
    NotificationService.instance.onNotificationTapped = (payload) {
      log.info('App', 'Notification tapped', {'payload': payload});
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRouter.patientHome,
        (route) => false,
      );
    };

    runApp(const DasTernApp());
  } catch (e, stack) {
    log.error('App', 'Failed to initialize app', e, stack);
    rethrow;
  }
}

class DasTernApp extends StatefulWidget {
  const DasTernApp({super.key});

  @override
  State<DasTernApp> createState() => _DasTernAppState();
}

class _DasTernAppState extends State<DasTernApp> with WidgetsBindingObserver {
  final LoggerService _log = LoggerService.instance;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _deepLinkSubscription;
  bool _isHandlingTelegramCallback = false;
  bool get _isWidgetTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Process any pending notification actions that were queued while the
    // app was closed (e.g. user tapped "Mark as Taken" from a notification).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingActions();
      _initializeDeepLinks();
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
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

  Future<void> _initializeDeepLinks() async {
    if (_isWidgetTestEnvironment) {
      _log.debug('DeepLink', 'Skipping deep link initialization in tests');
      return;
    }

    _log.info('DeepLink', 'Initializing deep link listeners');

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleIncomingDeepLink(initialUri, source: 'cold_start');
      }
    } catch (e, stack) {
      _log.error('DeepLink', 'Failed to read initial deep link', e, stack);
    }

    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingDeepLink(uri, source: 'warm_start');
      },
      onError: (Object e) {
        _log.error('DeepLink', 'Warm deep link stream error', e);
      },
    );
  }

  Future<void> _handleIncomingDeepLink(Uri uri, {required String source}) async {
    _log.info('DeepLink', 'Incoming URI', {
      'source': source,
      'uri': uri.toString(),
    });

    final isTelegramLoginCallback =
        uri.scheme == 'myapp' &&
        (uri.host == 'login-success' ||
            uri.path == '/login-success' ||
            uri.path == 'login-success');

    if (!isTelegramLoginCallback) {
      _log.debug('DeepLink', 'Ignoring unmatched deep link URI', {
        'uri': uri.toString(),
      });
      return;
    }

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      _log.error(
        'DeepLink',
        'Missing token in Telegram callback deep link',
        Exception('Missing token'),
      );
      return;
    }

    await _handleTelegramLoginSuccess(token);
  }

  Future<void> _handleTelegramLoginSuccess(String token) async {
    if (_isHandlingTelegramCallback) {
      _log.warning('DeepLink', 'Telegram callback is already being processed');
      return;
    }

    _isHandlingTelegramCallback = true;
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        _log.error(
          'DeepLink',
          'Navigator context unavailable while handling Telegram callback',
          Exception('Missing navigator context'),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool callbackResult = false;
      try {
        callbackResult = await authProvider.handleTelegramCallback(token);
      } catch (e, stack) {
        _log.error('DeepLink', 'AuthProvider.handleTelegramCallback failed', e, stack);
        return;
      }

      final isSuccess = callbackResult || authProvider.isAuthenticated;
      if (!isSuccess) {
        _log.warning(
          'DeepLink',
          'Telegram callback did not authenticate user',
          {'result': callbackResult.toString()},
        );
        return;
      }

      final role = (authProvider.userRole ?? '').toUpperCase();
      final targetRoute =
          role == 'DOCTOR' ? AppRouter.doctorHome : AppRouter.patientHome;

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        targetRoute,
        (route) => false,
      );

      _log.success('DeepLink', 'Telegram callback handled successfully', {
        'role': role,
        'targetRoute': targetRoute,
      });
    } catch (e, stack) {
      _log.error('DeepLink', 'Unexpected Telegram deep link handling error', e, stack);
    } finally {
      _isHandlingTelegramCallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..loadThemePreference(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..loadLocalePreference(),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DoseProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DoctorDashboardProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => HealthMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => AdherenceProvider()),
        ChangeNotifierProvider(create: (_) => ShellTabController()),
        ChangeNotifierProvider.value(value: SyncService.instance),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Das Tern',
            debugShowCheckedModeBanner: false,

            // Theme
            theme: lightTheme,
            darkTheme: darkTheme,
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
