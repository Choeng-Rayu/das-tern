import 'package:flutter_test/flutter_test.dart';

import 'package:das_tern_mcp/core/theme/app_spacing.dart';

void main() {
  test('AppSpacing size tokens have exact values', () {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.md, 16);
    expect(AppSpacing.lg, 24);
    expect(AppSpacing.xl, 32);
    expect(AppSpacing.xxl, 48);
  });

  test('AppSpacing radius tokens have exact values', () {
    expect(AppSpacing.radiusSm, 12);
    expect(AppSpacing.radiusMd, 20);
    expect(AppSpacing.radiusLg, 28);
    expect(AppSpacing.radiusXl, 36);
    expect(AppSpacing.radiusFull, 100);
  });
}
