import 'package:dastern/app.dart';
import 'package:dastern/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps `DasTernApp` with a pre-seeded [SharedPreferences] override so
/// theme + locale are deterministic regardless of the host machine's
/// platform locale.
Future<SharedPreferences> _bootApp(
  WidgetTester tester, {
  String locale = 'km',
  String themeMode = 'light',
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'locale': locale,
    'theme_mode': themeMode,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DasTernApp(),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  testWidgets(
    'DasTernApp boots in Khmer locale and shows the home AppBar title',
    (WidgetTester tester) async {
      await _bootApp(tester);
      // Khmer for "Dashboard" / "Home"
      expect(find.text('ផ្ទាំងគ្រប់គ្រង'), findsOneWidget);
    },
  );

  testWidgets('DasTernApp boots in English when SharedPreferences says en', (
    WidgetTester tester,
  ) async {
    await _bootApp(tester, locale: 'en');
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets(
    'Settings → Appearance switches locale to English without restart',
    (WidgetTester tester) async {
      final prefs = await _bootApp(tester);

      // Open settings via the AppBar action.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Open Appearance from the settings list (tap by Khmer label).
      await tester.tap(find.text('ការបង្ហាញ'));
      await tester.pumpAndSettle();

      // Switch language to English (tap the English radio tile).
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // The change is persisted to SharedPreferences immediately.
      expect(prefs.getString('locale'), 'en');
    },
  );

  testWidgets('Settings → Appearance switches theme to dark and persists', (
    WidgetTester tester,
  ) async {
    final prefs = await _bootApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ការបង្ហាញ'));
    await tester.pumpAndSettle();

    // Khmer "Dark"
    await tester.tap(find.text('ងងឹត'));
    await tester.pumpAndSettle();

    expect(prefs.getString('theme_mode'), 'dark');
  });
}
