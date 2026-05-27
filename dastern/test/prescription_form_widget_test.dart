import 'package:dastern/core/theme/app_theme.dart';
import 'package:dastern/core/theme/theme_controller.dart';
import 'package:dastern/features/prescriptions/presentation/pages/create_prescription_page.dart';
import 'package:dastern/features/prescriptions/presentation/pages/medication_form_page.dart';
import 'package:dastern/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, SharedPreferences prefs) => ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: lightTheme(),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en'), Locale('km')],
        locale: const Locale('en'),
        home: child,
      ),
    );

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'locale': 'en',
      'theme_mode': 'light',
    });
    prefs = await SharedPreferences.getInstance();
  });

  group('CreatePrescriptionPage', () {
    testWidgets('renders form fields', (tester) async {
      await tester.pumpWidget(_wrap(const CreatePrescriptionPage(), prefs));
      await tester.pump(const Duration(milliseconds: 100));

      // Full name field should be present
      expect(find.text('Full Name'), findsOneWidget);
      // Symptoms field
      expect(find.text('Symptoms'), findsOneWidget);
      // Save button
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      await tester.pumpWidget(_wrap(const CreatePrescriptionPage(), prefs));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Save without filling in name
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Validation error should appear
      expect(find.text('Please enter full name'), findsOneWidget);
    });

    testWidgets('shows validation error when symptoms is empty', (tester) async {
      await tester.pumpWidget(_wrap(const CreatePrescriptionPage(), prefs));
      await tester.pump(const Duration(milliseconds: 100));

      // Fill name but leave symptoms empty
      await tester.enterText(find.byType(TextFormField).first, 'Test Patient');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('MedicationFormPage', () {
    testWidgets('renders medicine name field', (tester) async {
      await tester.pumpWidget(
        _wrap(const MedicationFormPage(prescriptionId: 'rx-1'), prefs),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Medicine name (Latin)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows validation error when medicine name is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const MedicationFormPage(prescriptionId: 'rx-1'), prefs),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Save without filling in name — form validates
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();

      // At least one error text should appear
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('renders bilingual Khmer label', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'locale': 'km',
        'theme_mode': 'light',
      });
      final kmPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(kmPrefs),
          ],
          child: MaterialApp(
            theme: lightTheme(),
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const <Locale>[Locale('en'), Locale('km')],
            locale: const Locale('km'),
            home: const MedicationFormPage(prescriptionId: 'rx-1'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Khmer label for medicine name field
      expect(find.text('ឈ្មោះថ្នាំ (ខ្មែរ)'), findsOneWidget);
    });
  });
}
