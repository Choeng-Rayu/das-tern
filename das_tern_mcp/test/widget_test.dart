// Basic Flutter widget test for DasTern MCP app.

import 'package:flutter_test/flutter_test.dart';

import 'package:das_tern_mcp/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const DasTernApp());
    // Verify splash screen loads
    await tester.pumpAndSettle();
  });
}
