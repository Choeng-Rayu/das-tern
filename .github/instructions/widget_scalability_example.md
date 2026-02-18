# Widget Scalability Example: Button System

## Current Implementation (Limited Scalability)

```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  // Limited parameters - hard to extend
  // Fixed width/height - not customizable
  // No theme integration flexibility
}
```

## Improved Scalable Implementation

### 1. Base Button Widget (Maximum Configurability)

```dart
/// Highly configurable base button widget that can be used for ALL button types
class BaseButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final bool expanded;
  final bool disabled;
  final String? semanticLabel;

  const BaseButton({
    super.key,
    this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.textStyle,
    this.expanded = false,
    this.disabled = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonTheme = theme.extension<AppButtonTheme>();
    
    // Use theme values with parameter overrides
    final effectiveVariant = variant;
    final effectiveSize = size;
    
    // Build button based on variant
    return _buildButton(context, theme, buttonTheme);
  }
  
  Widget _buildButton(BuildContext context, ThemeData theme, AppButtonTheme? buttonTheme) {
    // Implementation that handles all variants and sizes
    // Returns appropriate Material button widget
  }
}

enum ButtonVariant {
  primary,
  secondary,
  tertiary,
  danger,
  success,
  warning,
  outlined,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
  xlarge,
}
```

### 2. Specialized Buttons (Extend/Compose Base)

```dart
/// Primary action button - extends base with primary styling
class PrimaryButton extends BaseButton {
  const PrimaryButton({
    super.key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    Widget? icon,
    bool expanded = true,
  }) : super(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          variant: ButtonVariant.primary,
          size: size,
          icon: icon,
          expanded: expanded,
        );
}

/// Secondary action button
class SecondaryButton extends BaseButton {
  const SecondaryButton({
    super.key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    Widget? icon,
    bool expanded = true,
  }) : super(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          variant: ButtonVariant.secondary,
          size: size,
          icon: icon,
          expanded: expanded,
        );
}

/// Icon-only button (composition example)
class IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final ButtonVariant variant;
  final String? tooltip;
  final String semanticLabel;

  const IconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.primary,
    this.tooltip,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BaseButton(
      icon: Icon(icon),
      onPressed: onPressed,
      variant: variant,
      size: size,
      semanticLabel: semanticLabel,
    );
  }
}
```

### 3. Theme Integration

```dart
/// Button theme extension for consistent styling
class AppButtonTheme extends ThemeExtension<AppButtonTheme> {
  final Map<ButtonVariant, ButtonStyle> variantStyles;
  final Map<ButtonSize, EdgeInsetsGeometry> sizePadding;
  final Map<ButtonSize, double> sizeHeight;
  final Map<ButtonSize, TextStyle> sizeTextStyle;

  const AppButtonTheme({
    required this.variantStyles,
    required this.sizePadding,
    required this.sizeHeight,
    required this.sizeTextStyle,
  });

  @override
  ThemeExtension<AppButtonTheme> copyWith({/* ... */}) {
    // Implementation
  }

  @override
  ThemeExtension<AppButtonTheme> lerp(
    ThemeExtension<AppButtonTheme>? other,
    double t,
  ) {
    // Implementation
  }
}
```

## Benefits of Scalable Approach

1. **Single Source of Truth**: All buttons use `BaseButton`
2. **Maximum Configurability**: 20+ parameters for any use case
3. **Theme Consistency**: Uses app theme for colors, spacing, typography
4. **Easy Extension**: New button types just set different parameters
5. **Maintainable**: Changes to base widget affect all buttons
6. **Testable**: Base widget can be thoroughly tested once

## Implementation Workflow

1. **Analyze Requirements**: List all button types needed (primary, secondary, icon, etc.)
2. **Design Base Widget**: Create `BaseButton` with all possible parameters
3. **Create Specialized Widgets**: Make `PrimaryButton`, `SecondaryButton`, etc.
4. **Integrate Theme**: Add `AppButtonTheme` extension
5. **Test All Variations**: Verify all button types and states work
6. **Document Usage**: Show examples of how to use each button type

## Prohibited Patterns

```dart
// ❌ BAD: One-off widget for specific use case
class LoginButton extends StatelessWidget {
  // Hardcoded for login only - not reusable
}

// ❌ BAD: Limited parameters
class SimpleButton extends StatelessWidget {
  // Missing isLoading, disabled state, theme integration
}

// ❌ BAD: Hardcoded values
class SubmitButton extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      width: 100, // Hardcoded - not scalable
      height: 50, // Hardcoded - not scalable
      color: Colors.blue, // Hardcoded - not theme-aware
      // ...
    );
  }
}
```

## Required Checklist for New Widgets

- [ ] Analyzed all potential use cases
- [ ] Checked existing widgets for reuse/extend
- [ ] Designed base widget with maximum parameters
- [ ] Added theme integration
- [ ] Added localization support for text
- [ ] Added accessibility (semantic labels)
- [ ] Created specialized widgets for common use cases
- [ ] Tested all parameter combinations
- [ ] Documented usage examples
