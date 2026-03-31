import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// The standard border radius for glass dialogs and bottom sheets.
const double _kGlassDialogRadius = 28.0;

/// The standard blur sigma for the glass effect.
const double _kGlassBlurSigma = 20.0;

/// Shows a dialog with iOS 26 Liquid Glass styling.
///
/// This is a drop-in replacement for [showDialog] that wraps content
/// in a translucent, blurred glass container.
///
/// ## Example
///
/// ```dart
/// showGlassDialog(
///   context: context,
///   builder: (context) => AppGlassAlertDialog(
///     title: Text('Confirm'),
///     content: Text('Are you sure?'),
///     actions: [
///       TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
///       TextButton(onPressed: () => Navigator.pop(context, true), child: Text('OK')),
///     ],
///   ),
/// );
/// ```
///
/// ## Parameters
///
/// - [context]: The build context.
/// - [builder]: A builder that returns the dialog content widget.
/// - [barrierDismissible]: Whether tapping outside dismisses the dialog.
/// - [barrierColor]: The color of the modal barrier behind the dialog.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black54,
    builder: (context) {
      return _GlassDialogContainer(child: builder(context));
    },
  );
}

/// Internal container widget that applies glass styling to dialog content.
class _GlassDialogContainer extends StatelessWidget {
  const _GlassDialogContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassFillColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.60);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.12);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.10);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kGlassDialogRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 24.0,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kGlassDialogRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _kGlassBlurSigma,
              sigmaY: _kGlassBlurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    glassFillColor,
                    glassFillColor.withValues(
                      alpha: (glassFillColor.a * 0.8).clamp(0.0, 1.0),
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(_kGlassDialogRadius),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass-styled alert dialog implementing the iOS 26 Liquid Glass aesthetic.
///
/// This widget provides a drop-in replacement for [AlertDialog] with
/// translucent glass styling that adapts to light and dark themes.
///
/// ## Example
///
/// ```dart
/// AppGlassAlertDialog(
///   icon: Icon(Icons.warning_amber_rounded),
///   title: Text('Delete Item'),
///   content: Text('This action cannot be undone.'),
///   actions: [
///     TextButton(
///       onPressed: () => Navigator.pop(context),
///       child: Text('Cancel'),
///     ),
///     TextButton(
///       onPressed: () => Navigator.pop(context, true),
///       child: Text('Delete'),
///     ),
///   ],
/// )
/// ```
///
/// ## Parameters
///
/// - [title]: The dialog title widget (typically a [Text]).
/// - [content]: The main content of the dialog.
/// - [actions]: A list of action buttons displayed at the bottom.
/// - [icon]: An optional icon displayed above the title.
class AppGlassAlertDialog extends StatelessWidget {
  /// Creates a glass-styled alert dialog.
  const AppGlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.icon,
  });

  /// The dialog title, typically a [Text] widget.
  final Widget? title;

  /// The content to display in the center of the dialog.
  final Widget? content;

  /// The action buttons to display at the bottom of the dialog.
  final List<Widget>? actions;

  /// An optional icon to display above the title.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(size: 32, color: theme.colorScheme.primary),
              child: icon!,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (title != null) ...[
            DefaultTextStyle(
              style: textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              child: title!,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (content != null) ...[
            DefaultTextStyle(
              style: textTheme.bodyMedium!,
              textAlign: TextAlign.center,
              child: content!,
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: action,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet with iOS 26 Liquid Glass styling.
///
/// This is a replacement for [showModalBottomSheet] that applies
/// a translucent, blurred glass effect with rounded top corners.
///
/// ## Example
///
/// ```dart
/// showGlassBottomSheet(
///   context: context,
///   builder: (context) => AppGlassBottomSheetContent(
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         ListTile(title: Text('Option 1')),
///         ListTile(title: Text('Option 2')),
///       ],
///     ),
///   ),
/// );
/// ```
///
/// ## Parameters
///
/// - [context]: The build context.
/// - [builder]: A builder that returns the bottom sheet content widget.
/// - [isDismissible]: Whether tapping outside dismisses the sheet.
/// - [enableDrag]: Whether the sheet can be dragged up/down.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _GlassBottomSheetContainer(child: builder(context));
    },
  );
}

/// Internal container widget that applies glass styling to bottom sheet content.
class _GlassBottomSheetContainer extends StatelessWidget {
  const _GlassBottomSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassFillColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.60);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.12);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.10);

    final topRadius = BorderRadius.only(
      topLeft: const Radius.circular(_kGlassDialogRadius),
      topRight: const Radius.circular(_kGlassDialogRadius),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: topRadius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24.0,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: topRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _kGlassBlurSigma,
            sigmaY: _kGlassBlurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  glassFillColor,
                  glassFillColor.withValues(
                    alpha: (glassFillColor.a * 0.8).clamp(0.0, 1.0),
                  ),
                ],
              ),
              borderRadius: topRadius,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A helper widget for glass bottom sheet content.
///
/// This widget includes a drag handle indicator at the top,
/// safe area padding, and standard content padding.
///
/// ## Example
///
/// ```dart
/// showGlassBottomSheet(
///   context: context,
///   builder: (context) => AppGlassBottomSheetContent(
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         Text('Bottom Sheet Title'),
///         SizedBox(height: 16),
///         Text('Content goes here'),
///       ],
///     ),
///   ),
/// );
/// ```
class AppGlassBottomSheetContent extends StatelessWidget {
  /// Creates a glass bottom sheet content wrapper.
  const AppGlassBottomSheetContent({super.key, required this.child});

  /// The content to display inside the bottom sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final handleColor = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.20);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          // Content with padding
          Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
        ],
      ),
    );
  }
}
