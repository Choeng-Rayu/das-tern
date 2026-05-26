import 'package:dastern/app.dart';
import 'package:dastern/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  testWidgets('boots in Khmer and shows home tab title', (tester) async {
    await _bootApp(tester);
    expect(find.text('ទំព័រដើម'), findsOneWidget);
  });

  testWidgets('boots in English when prefs say en', (tester) async {
    await _bootApp(tester, locale: 'en');
    // English homeTab key
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('switching locale persists to SharedPreferences', (tester) async {
    final prefs = await _bootApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('រូបរាង')); // appearance in Khmer
    await tester.pumpAndSettle();

    await tester.tap(find.text('អង់គ្លេស')); // english in Khmer
    await tester.pumpAndSettle();

    expect(prefs.getString('locale'), 'en');
  });

  testWidgets('switching theme persists to SharedPreferences', (tester) async {
    final prefs = await _bootApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('រូបរាង'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ងងឹត')); // darkTheme in Khmer
    await tester.pumpAndSettle();

    expect(prefs.getString('theme_mode'), 'dark');
  });
}
