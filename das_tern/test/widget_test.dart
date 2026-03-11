import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:das_tern/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
