import 'package:flutter/material.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';

/// Size presets for [AppAvatar].
enum AppAvatarSize { small, medium, large, xLarge }

/// Circular avatar that shows a [CachedNetworkImage] when [imageUrl] is
/// provided, or falls back to the first letter(s) of [name] rendered inside
/// a coloured circle.
///
/// Usage:
/// ```dart
/// AppAvatar(name: 'John Doe', size: AppAvatarSize.medium)
/// AppAvatar(imageUrl: 'https://…/photo.jpg', name: 'John Doe')
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.medium,
    this.backgroundColor,
  });

  final String? imageUrl;
  final String? name;
  final AppAvatarSize size;
  final Color? backgroundColor;

  double get _diameter {
    switch (size) {
      case AppAvatarSize.small:
        return 32;
      case AppAvatarSize.medium:
        return 48;
      case AppAvatarSize.large:
        return 64;
      case AppAvatarSize.xLarge:
        return 96;
    }
  }

  double get _fontSize => _diameter * 0.38;

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = _diameter;
    final Color bg = backgroundColor ?? AppColors.primaryBlue;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(diameter, bg),
        ),
      );
    }

    return _initialsCircle(diameter, bg);
  }

  Widget _initialsCircle(double diameter, Color bg) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
