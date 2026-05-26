import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:das_tern_mcp/core/widgets/app_text_field.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AppTextField', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrap(
        const AppTextField(label: 'Email', hint: 'you@example.com'),
      ));
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders hint text inside the field', (tester) async {
      await tester.pumpWidget(wrap(
        const AppTextField(hint: 'Enter value'),
      ));
      expect(find.text('Enter value'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(wrap(
        AppTextField(controller: controller, hint: 'Type here'),
      ));
      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(controller.text, 'hello');
    });

    testWidgets('shows validation error when validator fails', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextField(
              hint: 'Required',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Field is required' : null,
            ),
          ),
        ),
      ));
      // Trigger validation without entering any text.
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Field is required'), findsOneWidget);
    });

    testWidgets('does not show error when validator passes', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'value');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextField(
              controller: controller,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Field is required' : null,
            ),
          ),
        ),
      ));
      final isValid = formKey.currentState!.validate();
      await tester.pump();
      expect(isValid, isTrue);
    });

    testWidgets('renders prefix icon', (tester) async {
      await tester.pumpWidget(wrap(
        const AppTextField(
          prefixIcon: Icon(Icons.search),
        ),
      ));
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders suffix icon', (tester) async {
      await tester.pumpWidget(wrap(
        const AppTextField(
          suffixIcon: Icon(Icons.visibility),
        ),
      ));
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(wrap(
        const AppTextField(hint: 'Disabled', enabled: false),
      ));
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    });
  });
}
