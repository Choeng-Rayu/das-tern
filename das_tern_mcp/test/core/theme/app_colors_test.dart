import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:das_tern_mcp/core/theme/app_colors.dart';

void main() {
  test('AppColors key constants have exact values', () {
    expect(AppColors.primary, const Color(0xFF009DFF));
    expect(AppColors.success, const Color(0xFF34C759));
    expect(AppColors.danger, const Color(0xFFFF3B30));
    expect(AppColors.warning, const Color(0xFFFF9500));
    expect(AppColors.info, const Color(0xFF5AC8FA));
    expect(AppColors.lightBackground, const Color(0xFFF2F2F7));
    expect(AppColors.meshDeep, const Color(0xFF050A14));
  });

  testWidgets('AppColors.of resolves expected light color scheme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            final dynamic colors = AppColors.of(context);

            expect(colors.background, AppColors.lightBackground);
            expect(colors.surface, AppColors.lightSurface);
            expect(colors.glassWhite, AppColors.glassWhiteLight);
            expect(colors.glassBorder, AppColors.glassBorderLight);
            expect(colors.glassShadowColor, AppColors.glassShadowLight);
            expect(colors.textPrimary, AppColors.textPrimaryLight);
            expect(colors.textSecondary, AppColors.textSecondaryLight);
            expect(colors.textTertiary, AppColors.textTertiaryLight);

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('AppColors.of resolves expected dark color scheme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (BuildContext context) {
            final dynamic colors = AppColors.of(context);

            expect(colors.background, AppColors.meshDeep);
            expect(colors.surface, AppColors.meshMid);
            expect(colors.glassWhite, AppColors.glassWhiteDark);
            expect(colors.glassBorder, AppColors.glassBorderDark);
            expect(colors.glassShadowColor, AppColors.glassShadow);
            expect(colors.textPrimary, AppColors.textPrimaryDark);
            expect(colors.textSecondary, AppColors.textSecondaryDark);
            expect(colors.textTertiary, AppColors.textTertiaryDark);

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
