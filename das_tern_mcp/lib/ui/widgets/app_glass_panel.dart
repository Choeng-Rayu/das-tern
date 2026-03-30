import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A frosted-glass surface widget implementing the iOS 26 Liquid Glass aesthetic.
///
/// This widget creates a translucent, blurred background panel with:
/// - **BackdropFilter blur**: Creates the signature frosted glass effect
/// - **Floating shadow**: Soft shadow outside the clip for depth
/// - **Gradient fill**: White overlay with opacity adjusted for light/dark mode
/// - **Specular border**: Subtle top-edge highlight for glass-like reflection
///
/// ## Usage
///
/// ```dart
/// AppGlassPanel(
///   child: Padding(
///     padding: EdgeInsets.all(AppSpacing.md),
///     child: Text('Content on glass'),
///   ),
/// )
/// ```
///
/// ## Customization
///
/// - [borderRadius]: Controls corner roundness (default: 28.0 for iOS 26 style)
/// - [tint]: Optional color tint overlay on the glass
/// - [blurRadius]: Blur intensity for frosted effect (default: 20.0)
/// - [opacity]: Overall panel opacity (default: 1.0)
/// - [padding]: Internal padding applied to child
///
/// ## Theme Adaptation
///
/// The widget automatically adapts to light/dark mode:
/// - **Light mode**: Whiter glass fill, subtle borders
/// - **Dark mode**: More transparent fill, brighter borders for visibility
class AppGlassPanel extends StatelessWidget {
  /// Creates a frosted-glass panel with the iOS 26 Liquid Glass aesthetic.
  const AppGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.tint,
    this.blurRadius = 20.0,
    this.opacity = 1.0,
    this.padding,
  });

  /// The widget to display inside the glass panel.
  final Widget child;

  /// The border radius of the glass panel corners.
  ///
  /// Default is 28.0 to match iOS 26 Liquid Glass design language.
  /// Use [AppRadius.xxl] (24.0) for consistency with existing app widgets.
  final double borderRadius;

  /// Optional color tint to apply over the glass effect.
  ///
  /// When null, the glass uses a neutral white/transparent appearance.
  /// Use this to create colored glass effects (e.g., success green, error red).
  final Color? tint;

  /// The blur intensity for the frosted glass effect.
  ///
  /// Higher values create more blur (more frosted appearance).
  /// Default is 20.0 for the standard iOS 26 glass look.
  /// Range recommendation: 10.0 (subtle) to 40.0 (heavy frost).
  final double blurRadius;

  /// The overall opacity of the glass panel.
  ///
  /// Use this to fade the entire panel in/out for animations.
  /// Default is 1.0 (fully visible).
  final double opacity;

  /// Optional padding to apply inside the glass panel around the child.
  ///
  /// If null, no padding is applied. Consider using [AppSpacing] values:
  /// - `EdgeInsets.all(AppSpacing.md)` for standard content
  /// - `EdgeInsets.all(AppSpacing.lg)` for cards with more breathing room
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass fill colors adapted for light/dark mode
    final glassFillColor = isDark
        ? Colors.white.withValues(alpha: 0.18) // 18% white for dark mode
        : Colors.white.withValues(alpha: 0.60); // 60% white for light mode

    // Border color for the specular edge highlight
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20) // 20% white border in dark
        : Colors.black.withValues(alpha: 0.12); // 12% black border in light

    // Shadow color for floating depth effect
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25) // 25% black shadow in dark
        : Colors.black.withValues(alpha: 0.10); // 10% black shadow in light

    // Apply tint if provided
    final effectiveFillColor = tint != null
        ? Color.lerp(glassFillColor, tint, 0.3)!
        : glassFillColor;

    return Opacity(
      opacity: opacity,
      child: Container(
        // Floating shadow - applied outside the clip
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
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
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            // Frosted glass blur effect
            filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
            child: Container(
              decoration: BoxDecoration(
                // Gradient fill for glass appearance
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    effectiveFillColor,
                    effectiveFillColor.withValues(
                      alpha: (effectiveFillColor.a * 0.8).clamp(0.0, 1.0),
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                // Specular top-edge border
                border: Border.all(color: borderColor, width: 1.0),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A variant of [AppGlassPanel] designed for card-style content.
///
/// This convenience widget applies standard card padding and uses
/// the app's standard corner radius.
///
/// ## Usage
///
/// ```dart
/// AppGlassCard(
///   child: Column(
///     children: [
///       Text('Card Title'),
///       Text('Card content goes here'),
///     ],
///   ),
/// )
/// ```
class AppGlassCard extends StatelessWidget {
  /// Creates a glass card with standard padding.
  const AppGlassCard({
    super.key,
    required this.child,
    this.tint,
    this.blurRadius = 20.0,
  });

  /// The widget to display inside the glass card.
  final Widget child;

  /// Optional color tint for the glass effect.
  final Color? tint;

  /// The blur intensity (default: 20.0).
  final double blurRadius;

  @override
  Widget build(BuildContext context) {
    return AppGlassPanel(
      borderRadius: AppRadius.xxl,
      tint: tint,
      blurRadius: blurRadius,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

/// A minimal glass surface for subtle background effects.
///
/// Uses reduced blur and opacity for a more subtle glass appearance,
/// suitable for secondary UI elements or layered glass effects.
class AppGlassSurface extends StatelessWidget {
  /// Creates a subtle glass surface.
  const AppGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
  });

  /// The widget to display on the glass surface.
  final Widget child;

  /// The border radius (default: 16.0).
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppGlassPanel(
      borderRadius: borderRadius,
      blurRadius: 12.0,
      opacity: 0.9,
      child: child,
    );
  }
}
