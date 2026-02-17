import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'l10n/app_localizations.dart';
import 'ui/theme/main_them.dart';
import 'ui/theme/light_mode.dart';
import 'ui/theme/dart_mode.dart';
import 'providers/locale_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/dose_event_provider_v2.dart';
import 'ui/screens/auth_ui/login_screen.dart';
import 'ui/screens/auth_ui/patient_register_step1_screen.dart';
import 'ui/screens/auth_ui/patient_register_step2_screen.dart';
import 'ui/screens/auth_ui/patient_register_step3_screen.dart';
import 'ui/screens/patient_ui/patient_main_screen.dart';
import 'ui/screens/doctor_ui/doctor_main_screen.dart';
import 'ui/screens/test_ui/test_auth_screen.dart';
import 'ui/screens/auth_ui/account_recovery_screen.dart';
import 'ui/screens/auth_ui/doctor_register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Show web warning if running on web
    if (kIsWeb) {
      return MaterialApp(
        title: 'DasTern',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                  SizedBox(height: 24),
                  Text(
                    'Web Platform Not Supported',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This app requires SQLite and local notifications, which are not available on web browsers.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Please run on:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text('• Android Emulator', style: TextStyle(fontSize: 16)),
                  Text('• iOS Simulator', style: TextStyle(fontSize: 16)),
                  Text('• Physical Device', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To run on Android:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('1. Start Android emulator'),
                        Text('2. Run: flutter run'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..loadThemePreference(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..loadLocalePreference(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrescriptionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DoseEventProviderV2(),
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'DasTern',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('km'),
            ],
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const PatientMainScreen(),
              '/register/step1': (context) => const PatientRegisterStep1Screen(),
              '/register/step2': (context) => const PatientRegisterStep2Screen(),
              '/register/step3': (context) => const PatientRegisterStep3Screen(),
              '/doctor/dashboard': (context) => const DoctorMainScreen(),
              '/register/doctor': (context) => const DoctorRegisterScreen(),
              '/forgot-password': (context) => const AccountRecoveryScreen(),
              '/test-auth': (context) => const TestAuthScreen(),
            },
          );
        },
      ),
    );
  }
}

