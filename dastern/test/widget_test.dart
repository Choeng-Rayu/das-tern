import 'package:dastern/app.dart';
import 'package:dastern/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the app and advances past the infinite mesh animation by using
/// a fixed duration instead of [pumpAndSettle].
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
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DasTernApp(),
    ),
  );
  // Use pump with a duration instead of pumpAndSettle — the mesh background
  // runs an infinite animation that would cause pumpAndSettle to time out.
  await tester.pump(const Duration(milliseconds: 100));
  return prefs;
}

void main() {
  testWidgets('boots in Khmer and shows home tab title', (tester) async {
    await _bootApp(tester);
    // Title appears in the glass header
    expect(find.text('ទំព័រដើម'), findsWidgets);
  });

  testWidgets('boots in English when prefs say en', (tester) async {
    await _bootApp(tester, locale: 'en');
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('switching locale persists to SharedPreferences', (tester) async {
    final prefs = await _bootApp(tester);

    // Tap the settings icon in the AppBar (first occurrence)
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('រូបរាង'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('អង់គ្លេស'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(prefs.getString('locale'), 'en');
  });

  testWidgets('switching theme persists to SharedPreferences', (tester) async {
    final prefs = await _bootApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('រូបរាង'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('ងងឹត'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(prefs.getString('theme_mode'), 'dark');
  });
}
