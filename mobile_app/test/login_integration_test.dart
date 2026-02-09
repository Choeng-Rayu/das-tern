import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  group('Login Screen Logic Tests', () {
    testWidgets('Login screen displays all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify login screen elements
      expect(find.text('das-tern'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('Form validation prevents empty submission', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap login without entering data
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.text('Please enter phone number or email'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Initially hidden
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Toggle to visible
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Toggle back to hidden
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Text input works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Enter text in phone/email field
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);

      // Enter text in password field
      await tester.enterText(find.byType(TextFormField).last, 'Password123');
      expect(find.text('Password123'), findsOneWidget);
    });
  });
}
