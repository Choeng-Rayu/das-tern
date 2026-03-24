// lib/core/widgets/app_avatar.dart
//
// RxCam Global Widget System — User Avatar
// iOS 26 Liquid Glass aesthetic — glass ring border
//
// Requirements: 13.1–13.7

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// User avatar with a glass ring border that adapts to light and dark mode.
///
/// - Shows network image when [imageUrl] is provided (Req 13.1).
/// - Falls back to [initials] or '?' on image error or null URL (Req 13.2).
/// - Glass ring uses active `glassBorder` token at 1.5 px (Req 13.3).
/// - Minimum 44×44 dp touch target when [onTap] is provided (Req 13.7).
///
/// ```dart
/// AppAvatar(initials: 'AB', radius: 28, onTap: () => openProfile())
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 24,
    this.onTap,
  });

  final String? imageUrl;
  final String? initials;

  /// Circle radius — defaults to 24 dp (Req 13.6)
  final double radius;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Enforce 44×44 dp touch target when interactive (Req 13.7)
    final size = radius * 2;
    final touchSize = onTap != null ? size.clamp(44.0, double.infinity) : size;

    final avatar = SizedBox(
      width: touchSize,
      height: touchSize,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Mode-aware gradient ring (Req 13.4, 13.5)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.glassWhite, Colors.transparent],
            ),
            border: Border.all(
              color: colors.glassBorder,
              width: 1.5, // specular ring (Req 13.3)
            ),
          ),
          child: ClipOval(
            child: _buildContent(context, colors),
          ),
        ),
      ),
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: avatar,
    );
  }

  Widget _buildContent(BuildContext context, dynamic colors) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsWidget(context),
      );
    }
    return _initialsWidget(context);
  }

  Widget _initialsWidget(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.20),
      child: Center(
        child: Text(
          initials ?? '?',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
