import 'package:flutter/material.dart';

/// Design-system app-bar that implements [PreferredSizeWidget].
///
/// Provides a consistent app-bar across all screens with support for:
/// - [title] string or [titleWidget] override
/// - [subtitle] shown below the title using a [Column] title widget
/// - [showBackButton] (defaults to `false` — override for sub-pages)
/// - [actions] list of trailing icon buttons
/// - Optional [bottom] widget (e.g. [TabBar])
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: AppHeader(
///     title: 'Settings',
///     showBackButton: true,
///     actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
///   ),
/// )
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
    this.elevation,
  });

  /// Plain-text title shown in the app-bar.
  final String? title;

  /// Optional subtitle shown directly below the [title].
  final String? subtitle;

  /// Overrides the built-in title widget entirely.
  final Widget? titleWidget;

  /// Whether to show the back arrow / pop button.
  final bool showBackButton;

  /// Trailing action widgets (icon buttons, menus, etc.).
  final List<Widget>? actions;

  /// Widget shown at the bottom of the app-bar (e.g. [TabBar]).
  final PreferredSizeWidget? bottom;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double? elevation;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveTitle = titleWidget;

    if (effectiveTitle == null && (title != null || subtitle != null)) {
      if (subtitle != null) {
        effectiveTitle = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title!,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      } else {
        effectiveTitle = Text(title!);
      }
    }

    return AppBar(
      title: effectiveTitle,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      bottom: bottom,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      centerTitle: centerTitle,
      elevation: elevation,
    );
  }
}
