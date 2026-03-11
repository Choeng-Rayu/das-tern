import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';

void main() {
  // Helper that wraps a widget in a minimal MaterialApp so themes resolve.
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AppButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrap(
        AppButton(label: 'Save', onPressed: () {}),
      ));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(wrap(
        AppButton(label: 'Save', onPressed: () {}, isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label should not be visible while loading.
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(wrap(
        const AppButton(label: 'Disabled'),
      ));
      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('renders full width when isFullWidth is true', (tester) async {
      await tester.pumpWidget(wrap(
        AppButton(label: 'Full', onPressed: () {}, isFullWidth: true),
      ));
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('secondary variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(wrap(
        AppButton(
          label: 'Cancel',
          onPressed: () {},
          variant: AppButtonVariant.secondary,
        ),
      ));
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('ghost variant renders TextButton', (tester) async {
      await tester.pumpWidget(wrap(
        AppButton(
          label: 'Skip',
          onPressed: () {},
          variant: AppButtonVariant.ghost,
        ),
      ));
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('fires onPressed callback on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        AppButton(label: 'Go', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not fire onPressed when isLoading is true',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        AppButton(
          label: 'Go',
          onPressed: () => tapped = true,
          isLoading: true,
        ),
      ));
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(wrap(
        AppButton(
          label: 'Add',
          onPressed: () {},
          icon: Icons.add,
        ),
      ));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
