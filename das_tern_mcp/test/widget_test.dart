// Basic Flutter widget test for DasTern MCP app.

import 'package:flutter_test/flutter_test.dart';

import 'package:das_tern_mcp/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const DasTernApp());
    // Pump one frame — avoids pumpAndSettle timeout from async service init
    await tester.pump();
    // App widget tree is present
    expect(find.byType(DasTernApp), findsOneWidget);
  });
}
