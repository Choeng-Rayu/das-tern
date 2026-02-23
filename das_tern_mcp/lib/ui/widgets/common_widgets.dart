import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Primary action button used throughout the app.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(text),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

/// Reusable card with standard styling.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// Color-coded status badge for displaying statuses throughout the app.
///
/// Used for prescription status, connection status, adherence levels, etc.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double? fontSize;
  final double? borderRadius;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius:
            BorderRadius.circular(borderRadius ?? AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Visual variant for [AppSelectableChip].
enum ChipVariant {
  /// Solid background when selected, grey background when unselected.
  filled,

  /// Border-only when unselected, tinted background + colored border when selected.
  outlined,
}

/// Selectable chip for filters, schedule toggles, and category selections.
class AppSelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final ChipVariant variant;

  const AppSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.variant = ChipVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primaryBlue;

    final Color backgroundColor;
    final Color textColor;
    final Border? border;

    switch (variant) {
      case ChipVariant.filled:
        backgroundColor =
            selected ? color : Colors.grey.shade200;
        textColor = selected ? Colors.white : AppColors.textPrimary;
        border = null;
      case ChipVariant.outlined:
        backgroundColor = selected
            ? color.withValues(alpha: 0.15)
            : Colors.transparent;
        textColor = selected ? color : AppColors.textSecondary;
        border = Border.all(
          color: selected ? color : AppColors.neutral300,
        );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: border,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Metric display card with icon, value, and label.
///
/// Wraps itself in [Expanded] so it works directly inside a [Row].
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Groups a title with a card containing children.
///
/// Used for settings sections, profile sections, and similar grouped content.
class SectionGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionGroup({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Reusable app header used across all pages as a consistent [AppBar].
///
/// Provides standard styling defaults for tabs (no back button) and
/// sub-pages (with back button). Supports optional actions, bottom widgets
/// (e.g. [TabBar]), and custom title widgets.
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: AppHeader(title: 'My Page'),
///   body: ...,
/// )
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = false,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.scrolledUnderElevation,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      automaticallyImplyLeading: showBackButton,
      leading: leading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
    );
  }
}

/// Gradient header widget for home/dashboard screens.
///
/// Displays a gradient background with logo, app name, optional trailing
/// widget (e.g. profile avatar), and a greeting/subtitle area.
///
/// Used by patient home and can be reused by doctor home or other dashboards.
///
/// Usage:
/// ```dart
/// AppGradientHeader(
///   greeting: 'Good morning, John',
///   trailing: CircleAvatar(...),
/// )
/// ```
class AppGradientHeader extends StatelessWidget {
  final String? greeting;
  final String? subtitle;
  final Widget? trailing;
  final String appName;
  final IconData appIcon;
  final List<Color> gradientColors;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final List<Widget>? extraContent;

  const AppGradientHeader({
    super.key,
    this.greeting,
    this.subtitle,
    this.trailing,
    this.appName = 'ដាស់តឿន',
    this.appIcon = Icons.medical_services,
    this.gradientColors = const [Color(0xFF29B6F6), Color(0xFF0288D1)],
    this.borderRadius,
    this.padding,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: borderRadius ??
            const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ??
              const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(appIcon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ?trailing,
                ],
              ),
              if (greeting != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  greeting!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
              if (extraContent != null) ...extraContent!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for a bottom navigation tab item.
class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Reusable bottom navigation bar used by all shell screens.
///
/// Provides consistent styling (colors, font sizes, type) across
/// patient and doctor shells.
///
/// Usage:
/// ```dart
/// Scaffold(
///   bottomNavigationBar: AppBottomNavBar(
///     currentIndex: _currentIndex,
///     onTap: (i) => setState(() => _currentIndex = i),
///     items: [
///       AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
///     ],
///   ),
/// )
/// ```
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double selectedFontSize;
  final double unselectedFontSize;
  final BottomNavigationBarType type;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedColor,
    this.unselectedColor,
    this.selectedFontSize = 11,
    this.unselectedFontSize = 10,
    this.type = BottomNavigationBarType.fixed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: type,
      selectedItemColor: selectedColor ?? AppColors.primaryBlue,
      unselectedItemColor: unselectedColor ?? AppColors.neutral400,
      selectedFontSize: selectedFontSize,
      unselectedFontSize: unselectedFontSize,
      items: items
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
              ))
          .toList(),
    );
  }
}
