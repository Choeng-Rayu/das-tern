import 'package:flutter/material.dart';
import '../ui/widgets/loading/health_loading_indicator.dart';

/// A singleton service for showing and hiding a global loading overlay.
///
/// This service allows you to show a loading indicator from anywhere in the app
/// without needing access to the BuildContext. It creates a modal barrier that
/// prevents user interaction while loading is in progress.
///
/// Usage:
/// ```dart
/// // Show loading overlay
/// LoadingOverlayService.show(
///   context,
///   message: 'Loading medications...',
/// );
///
/// // Perform async operation
/// await fetchData();
///
/// // Hide loading overlay
/// LoadingOverlayService.hide();
/// ```
///
/// Features:
/// - Singleton pattern for global access
/// - Prevents user interaction while loading
/// - Customizable loading variant and message
/// - Automatic cleanup on dispose
/// - Theme-aware (supports dark mode)
class LoadingOverlayService {
  LoadingOverlayService._();

  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Whether a loading overlay is currently being shown.
  static bool get isShowing => _isShowing;

  /// Shows a global loading overlay with optional message.
  ///
  /// Parameters:
  /// - [context]: BuildContext to access the overlay
  /// - [variant]: The type of loading animation to show
  /// - [message]: Optional message to display below the indicator
  /// - [barrierDismissible]: Whether tapping outside dismisses the overlay
  /// - [barrierColor]: Color of the overlay barrier
  ///
  /// If a loading overlay is already showing, this will update it with the new parameters.
  static void show(
    BuildContext context, {
    HealthLoadingVariant variant = HealthLoadingVariant.heartbeat,
    String? message,
    bool barrierDismissible = false,
    Color? barrierColor,
  }) {
    // If already showing, hide first then show with new parameters
    if (_isShowing) {
      hide();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlay(
        variant: variant,
        message: message,
        barrierDismissible: barrierDismissible,
        barrierColor:
            barrierColor ??
            (isDarkMode
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.85)),
        onDismiss: barrierDismissible ? hide : null,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;
  }

  /// Hides the currently showing loading overlay.
  ///
  /// If no overlay is showing, this method does nothing.
  static void hide() {
    if (_isShowing && _overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  /// Shows a loading overlay and automatically hides it after the future completes.
  ///
  /// This is a convenience method for wrapping async operations with a loading indicator.
  ///
  /// Usage:
  /// ```dart
  /// final result = await LoadingOverlayService.showWhile(
  ///   context,
  ///   future: fetchData(),
  ///   message: 'Loading...',
  /// );
  /// ```
  static Future<T> showWhile<T>(
    BuildContext context, {
    required Future<T> future,
    HealthLoadingVariant variant = HealthLoadingVariant.heartbeat,
    String? message,
    Color? barrierColor,
  }) async {
    show(
      context,
      variant: variant,
      message: message,
      barrierColor: barrierColor,
    );

    try {
      final result = await future;
      return result;
    } finally {
      hide();
    }
  }

  /// Shows a loading overlay for a specific duration.
  ///
  /// Useful for simulating loading states or ensuring minimum loading time.
  ///
  /// Usage:
  /// ```dart
  /// await LoadingOverlayService.showForDuration(
  ///   context,
  ///   duration: Duration(seconds: 2),
  ///   message: 'Processing...',
  /// );
  /// ```
  static Future<void> showForDuration(
    BuildContext context, {
    required Duration duration,
    HealthLoadingVariant variant = HealthLoadingVariant.heartbeat,
    String? message,
    Color? barrierColor,
  }) async {
    show(
      context,
      variant: variant,
      message: message,
      barrierColor: barrierColor,
    );

    await Future.delayed(duration);
    hide();
  }
}

/// Internal widget for the loading overlay.
class _LoadingOverlay extends StatelessWidget {
  final HealthLoadingVariant variant;
  final String? message;
  final bool barrierDismissible;
  final Color barrierColor;
  final VoidCallback? onDismiss;

  const _LoadingOverlay({
    required this.variant,
    this.message,
    required this.barrierDismissible,
    required this.barrierColor,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: barrierDismissible ? onDismiss : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: barrierColor,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent taps from passing through
              child: HealthLoadingIndicator(
                variant: variant,
                size: HealthLoadingSize.large,
                message: message,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
