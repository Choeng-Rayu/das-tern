// lib/core/widgets/app_header.dart
//
// RxCam Global Widget System — Glass Navigation Bar
// iOS 26 Liquid Glass aesthetic
//
// Requirements: 7.1–7.11

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Glass navigation bar for the top of every screen.
///
/// Implements [PreferredSizeWidget] so it can be used directly as
/// [Scaffold.appBar]. Renders a `BackdropFilter` blur with a specular bottom
/// border that adapts to light and dark mode.
///
/// ```dart
/// AppScaffold(
///   title: 'Medications',
///   showBackButton: true,
///   actions: [IconButton(icon: Icon(Icons.search), ...)],
/// )
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.subtitle,
    this.actions,
  });

  /// Screen title text (Req 7.5)
  final String title;

  /// Shows a back chevron in [AppColors.primary] when true (Req 7.6)
  final bool showBackButton;

  /// Optional subtitle rendered below the title with ellipsis (Req 7.7)
  final String? subtitle;

  /// Optional trailing action widgets, each wrapped in a 44×44 touch target (Req 7.8)
  final List<Widget>? actions;

  /// ~72 dp — toolbar + status-bar padding (Req 7.1)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.glassWhite,
            border: Border(
              bottom: BorderSide(color: colors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false, // Req 7.9 — respect status bar, not bottom bar
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Back button — 44×44 touch target (Req 7.6)
                  if (showBackButton)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.maybePop(context),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.chevron_left,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  // Title + subtitle column
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.headlineMediumResolved(context),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodyMediumResolved(context),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons — each wrapped in 44×44 (Req 7.8)
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!
                          .map(
                            (a) => SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(child: a),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
