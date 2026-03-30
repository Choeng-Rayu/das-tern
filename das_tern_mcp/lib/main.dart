import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'services/logger_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';

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
