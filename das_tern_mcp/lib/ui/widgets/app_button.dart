import 'package:flutter/material.dart';

/// Reusable global button widget with extensive customization options.
///
/// Supports:
/// - Text and icon (leading or trailing)
/// - Multiple button styles (filled, outlined, text)
/// - Custom shapes and sizes
/// - Loading state
/// - Gradient backgrounds
/// - Full width or auto-sized
/// - Custom colors and borders
///
/// Usage Examples:
/// ```dart
/// // Basic filled button
/// AppButton(
///   text: 'Continue',
///   onPressed: () {},
/// )
///
/// // Button with leading icon
/// AppButton(
///   text: 'Add Item',
///   icon: Icons.add,
///   onPressed: () {},
/// )
///
/// // Button with trailing icon
/// AppButton(
///   text: 'Next',
///   icon: Icons.arrow_forward,
///   iconPosition: IconPosition.trailing,
///   onPressed: () {},
/// )
///
/// // Outlined button
/// AppButton(
///   text: 'Cancel',
///   style: AppButtonStyle.outlined,
///   onPressed: () {},
/// )
///
/// // Custom shape and size
/// AppButton(
///   text: 'Submit',
///   shape: AppButtonShape.pill,
///   size: AppButtonSize.large,
///   onPressed: () {},
/// )
///
/// // Gradient button
/// AppButton(
///   text: 'Premium',
///   gradient: LinearGradient(
///     colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
///   ),
///   onPressed: () {},
/// )
///
/// // Loading state
/// AppButton(
///   text: 'Processing',
///   isLoading: true,
///   onPressed: () {},
/// )
/// ```
class AppButton extends StatelessWidget {
  /// Button text
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Optional icon
  final IconData? icon;

  /// Icon position (leading or trailing)
  final IconPosition iconPosition;

  /// Button style (filled, outlined, text)
  final AppButtonStyle style;

  /// Button shape (rounded, pill, square)
  final AppButtonShape shape;

  /// Button size (small, medium, large)
  final AppButtonSize size;

  /// Whether button should take full width
  final bool fullWidth;

  /// Loading state
  final bool isLoading;

  /// Custom background color (overrides style default)
  final Color? backgroundColor;

  /// Custom text color (overrides style default)
  final Color? textColor;

  /// Custom border color (for outlined style)
  final Color? borderColor;

  /// Custom border width (for outlined style)
  final double? borderWidth;

  /// Custom gradient (overrides backgroundColor)
  final Gradient? gradient;

  /// Custom border radius (overrides shape default)
  final double? borderRadius;

  /// Custom padding (overrides size default)
  final EdgeInsets? padding;

  /// Custom text style
  final TextStyle? textStyle;

  /// Custom icon size
  final double? iconSize;

  /// Space between icon and text
  final double? iconSpacing;

  /// Custom elevation (for filled style)
  final double? elevation;

  /// Whether button is disabled
  final bool disabled;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.style = AppButtonStyle.filled,
    this.shape = AppButtonShape.rounded,
    this.size = AppButtonSize.medium,
    this.fullWidth = true,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize,
    this.iconSpacing,
    this.elevation,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine if button is enabled
    final isEnabled = !disabled && !isLoading && onPressed != null;

    // Get size properties
    final sizeProps = _getSizeProperties();

    // Get style properties
    final styleProps = _getStyleProperties(context, isDark, isEnabled);

    // Build button content
    final content = _buildContent(styleProps);

    // Build button based on style
    Widget button;
    switch (style) {
      case AppButtonStyle.filled:
        button = _buildFilledButton(context, styleProps, content, isEnabled);
        break;
      case AppButtonStyle.outlined:
        button = _buildOutlinedButton(context, styleProps, content, isEnabled);
        break;
      case AppButtonStyle.text:
        button = _buildTextButton(context, styleProps, content, isEnabled);
        break;
    }

    // Wrap with SizedBox if fullWidth
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: sizeProps.height,
        child: button,
      );
    }

    return SizedBox(
      height: sizeProps.height,
      child: button,
    );
  }

  /// Build button content (text + icon + loading)
  Widget _buildContent(_StyleProperties styleProps) {
    if (isLoading) {
      return SizedBox(
        width: styleProps.iconSize,
        height: styleProps.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: styleProps.textColor,
        ),
      );
    }

    final textWidget = Text(
      text,
      style: textStyle ??
          TextStyle(
            fontSize: styleProps.fontSize,
            fontWeight: styleProps.fontWeight,
            color: styleProps.textColor,
          ),
    );

    if (icon == null) {
      return textWidget;
    }

    final iconWidget = Icon(
      icon,
      size: styleProps.iconSize,
      color: styleProps.textColor,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconPosition == IconPosition.leading
          ? [
              iconWidget,
              SizedBox(width: styleProps.iconSpacing),
              textWidget,
            ]
          : [
              textWidget,
              SizedBox(width: styleProps.iconSpacing),
              iconWidget,
            ],
    );
  }

  /// Build filled button
  Widget _buildFilledButton(
    BuildContext context,
    _StyleProperties styleProps,
    Widget content,
    bool isEnabled,
  ) {
    if (gradient != null) {
      // Use Container with gradient
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(styleProps.borderRadius),
        elevation: elevation ?? (isEnabled ? 2 : 0),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(styleProps.borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? gradient
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade300,
                      ],
                    ),
              borderRadius: BorderRadius.circular(styleProps.borderRadius),
            ),
            child: Container(
              padding: styleProps.padding,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      );
    }

    // Use ElevatedButton
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: styleProps.backgroundColor,
        foregroundColor: styleProps.textColor,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        elevation: elevation ?? 2,
        padding: styleProps.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(styleProps.borderRadius),
        ),
      ),
      child: content,
    );
  }

  /// Build outlined button
  Widget _buildOutlinedButton(
    BuildContext context,
    _StyleProperties styleProps,
    Widget content,
    bool isEnabled,
  ) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: styleProps.textColor,
        disabledForegroundColor: Colors.grey.shade600,
        side: BorderSide(
          color: isEnabled
              ? styleProps.borderColor
              : Colors.grey.shade300,
          width: styleProps.borderWidth,
        ),
        padding: styleProps.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(styleProps.borderRadius),
        ),
      ),
      child: content,
    );
  }

  /// Build text button
  Widget _buildTextButton(
    BuildContext context,
    _StyleProperties styleProps,
    Widget content,
    bool isEnabled,
  ) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: styleProps.textColor,
        disabledForegroundColor: Colors.grey.shade600,
        padding: styleProps.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(styleProps.borderRadius),
        ),
      ),
      child: content,
    );
  }

  /// Get size properties based on size enum
  _SizeProperties _getSizeProperties() {
    switch (size) {
      case AppButtonSize.small:
        return _SizeProperties(
          height: 36,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          fontSize: 13,
          iconSize: iconSize ?? 16,
          iconSpacing: iconSpacing ?? 6,
        );
      case AppButtonSize.medium:
        return _SizeProperties(
          height: 48,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          fontSize: 15,
          iconSize: iconSize ?? 18,
          iconSpacing: iconSpacing ?? 8,
        );
      case AppButtonSize.large:
        return _SizeProperties(
          height: 56,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          fontSize: 17,
          iconSize: iconSize ?? 20,
          iconSpacing: iconSpacing ?? 10,
        );
    }
  }

  /// Get style properties based on style enum and theme
  _StyleProperties _getStyleProperties(
    BuildContext context,
    bool isDark,
    bool isEnabled,
  ) {
    final theme = Theme.of(context);
    final sizeProps = _getSizeProperties();

    // Get border radius
    final radius = borderRadius ??
        (shape == AppButtonShape.pill
            ? 999.0
            : shape == AppButtonShape.rounded
                ? 12.0
                : 4.0);

    switch (style) {
      case AppButtonStyle.filled:
        return _StyleProperties(
          backgroundColor: backgroundColor ?? theme.primaryColor,
          textColor: textColor ?? Colors.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
          borderRadius: radius,
          padding: sizeProps.padding,
          fontSize: sizeProps.fontSize,
          fontWeight: FontWeight.w600,
          iconSize: sizeProps.iconSize,
          iconSpacing: sizeProps.iconSpacing,
        );

      case AppButtonStyle.outlined:
        final outlineColor = borderColor ?? theme.primaryColor;
        return _StyleProperties(
          backgroundColor: Colors.transparent,
          textColor: textColor ?? theme.primaryColor,
          borderColor: outlineColor,
          borderWidth: borderWidth ?? 1.5,
          borderRadius: radius,
          padding: sizeProps.padding,
          fontSize: sizeProps.fontSize,
          fontWeight: FontWeight.w600,
          iconSize: sizeProps.iconSize,
          iconSpacing: sizeProps.iconSpacing,
        );

      case AppButtonStyle.text:
        return _StyleProperties(
          backgroundColor: Colors.transparent,
          textColor: textColor ?? theme.primaryColor,
          borderColor: Colors.transparent,
          borderWidth: 0,
          borderRadius: radius,
          padding: sizeProps.padding,
          fontSize: sizeProps.fontSize,
          fontWeight: FontWeight.w600,
          iconSize: sizeProps.iconSize,
          iconSpacing: sizeProps.iconSpacing,
        );
    }
  }
}

/// Button style variants
enum AppButtonStyle {
  /// Filled button with solid background
  filled,

  /// Outlined button with border
  outlined,

  /// Text button with no background or border
  text,
}

/// Button shape variants
enum AppButtonShape {
  /// Rounded corners (12px radius)
  rounded,

  /// Pill shape (999px radius)
  pill,

  /// Square corners (4px radius)
  square,
}

/// Button size variants
enum AppButtonSize {
  /// Small button (36px height)
  small,

  /// Medium button (48px height)
  medium,

  /// Large button (56px height)
  large,
}

/// Icon position in button
enum IconPosition {
  /// Icon before text
  leading,

  /// Icon after text
  trailing,
}

/// Internal class for size properties
class _SizeProperties {
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;

  _SizeProperties({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
  });
}

/// Internal class for style properties
class _StyleProperties {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight fontWeight;
  final double iconSize;
  final double iconSpacing;

  _StyleProperties({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.fontSize,
    required this.fontWeight,
    required this.iconSize,
    required this.iconSpacing,
  });
}
