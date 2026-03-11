import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/core/widgets/app_bottom_nav.dart';
import 'package:das_tern_mcp/core/widgets/app_header.dart';
import 'package:das_tern_mcp/l10n/app_localizations.dart';

// Wraps [child] in a MaterialApp with localization delegates so that
// AppLocalizations.of(context) resolves correctly during tests.
Widget wrapWithL10n(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('AppScaffold', () {
    testWidgets('renders body content', (tester) async {
      await tester.pumpWidget(wrapWithL10n(
        const AppScaffold(
          title: 'Test',
          body: Text('Hello body'),
        ),
      ));
      await tester.pump();
      expect(find.text('Hello body'), findsOneWidget);
    });

    testWidgets('shows AppHeader when title is provided', (tester) async {
      await tester.pumpWidget(wrapWithL10n(
        const AppScaffold(
          title: 'My Title',
          showBottomNav: false,
          body: SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('hides AppHeader when title is null', (tester) async {
      await tester.pumpWidget(wrapWithL10n(
        const AppScaffold(
          showBottomNav: false,
          body: SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('shows AppBottomNav when showBottomNav is true',
        (tester) async {
      await tester.pumpWidget(wrapWithL10n(
        AppScaffold(
          showBottomNav: true,
          onBottomNavTap: (_) {},
          body: const SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      expect(find.byType(AppBottomNav), findsOneWidget);
    });

    testWidgets('hides AppBottomNav when showBottomNav is false',
        (tester) async {
      await tester.pumpWidget(wrapWithL10n(
        const AppScaffold(
          showBottomNav: false,
          body: SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      expect(find.byType(AppBottomNav), findsNothing);
    });

    testWidgets('calls onBottomNavTap when a tab is tapped', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(wrapWithL10n(
        AppScaffold(
          currentIndex: 0,
          showBottomNav: true,
          onBottomNavTap: (i) => tappedIndex = i,
          body: const SizedBox.shrink(),
        ),
      ));
      await tester.pump();

      // Tap the second tab item (index 1 — Medications).
      final navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      navBar.onTap!(1);
      expect(tappedIndex, 1);
    });

    testWidgets('renders floatingActionButton when provided', (tester) async {
      await tester.pumpWidget(wrapWithL10n(
        AppScaffold(
          showBottomNav: false,
          body: const SizedBox.shrink(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('currentIndex is forwarded to AppBottomNav', (tester) async {
      await tester.pumpWidget(wrapWithL10n(
        AppScaffold(
          currentIndex: 3,
          showBottomNav: true,
          onBottomNavTap: (_) {},
          body: const SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
      expect(nav.currentIndex, 3);
    });
  });
}
