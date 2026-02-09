import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/dose_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'ui/theme/light_theme.dart';
import 'ui/theme/dark_theme.dart';
import 'ui/theme/theme_provider.dart';
import 'utils/app_router.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize offline services
  await NotificationService.instance.init();
  await SyncService.instance.startListening();

  runApp(const DasTernApp());
}

class DasTernApp extends StatelessWidget {
  const DasTernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadThemePreference()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadLocalePreference()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadAuthState()),
        ChangeNotifierProvider(create: (_) => DoseProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: SyncService.instance),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
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
