import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify login screen elements are present
    expect(find.text('das-tern'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Phone/email and password fields
    expect(find.byIcon(Icons.visibility_off), findsOneWidget); // Password visibility toggle
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Find and tap login button without entering data
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.text('Please enter phone number or email'), findsOneWidget);
    expect(find.text('Please enter password'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Find password field
    final passwordFields = find.byType(TextFormField);
    expect(passwordFields, findsNWidgets(2));

    // Find and tap visibility toggle
    final visibilityToggle = find.byIcon(Icons.visibility_off);
    expect(visibilityToggle, findsOneWidget);
    
    await tester.tap(visibilityToggle);
    await tester.pumpAndSettle();

    // Verify icon changed to visibility (password visible)
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}

