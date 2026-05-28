import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_glass_panel.dart';

/// Configuration for a navigation tab item.
///
/// Each item defines its inactive icon, active icon, label, and whether
/// it should be rendered as a prominent (raised) button.
///
/// ## Example
///
/// ```dart
/// NavItem(
///   icon: CupertinoIcons.house,
///   activeIcon: CupertinoIcons.house_fill,
///   label: AppLocalizations.of(context)!.home,
/// )
/// ```
///
/// ## Prominent Items
///
/// For center action buttons (like Scan), set [isProminent] to `true`:
///
/// ```dart
/// NavItem(
///   icon: CupertinoIcons.camera_fill,
///   activeIcon: CupertinoIcons.camera_fill,
///   label: 'Scan',
///   isProminent: true,
/// )
/// ```
class NavItem {
  /// Creates a navigation item configuration.
  ///
  /// [icon] is displayed when the item is not selected.
  /// [activeIcon] is displayed when the item is selected.
  /// [label] is the text shown when the item is selected (iOS 26 expanding tab).
  /// [isProminent] renders the item as a raised circular button (e.g., Scan).
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isProminent = false,
  });

  /// The icon to display when this item is not selected.
  ///
  /// Use Cupertino icons for iOS 26 aesthetic consistency:
  /// - `CupertinoIcons.house` for home
  /// - `CupertinoIcons.heart` for medications
  /// - `CupertinoIcons.person_2` for connections
  final IconData icon;

  /// The icon to display when this item is selected.
  ///
  /// Typically the filled variant of [icon]:
  /// - `CupertinoIcons.house_fill`
  /// - `CupertinoIcons.heart_fill`
  /// - `CupertinoIcons.person_2_fill`
  final IconData activeIcon;

  /// The text label for this navigation item.
  ///
  /// Shown only when the item is selected (iOS 26 expanding tab behavior).
  /// Should be localized via [AppLocalizations].
  final String label;

  /// Whether this item should be rendered as a prominent raised button.
  ///
  /// When true, the item is displayed as a raised circular button with
  /// [AppColors.primaryBlue] background and white icon, elevated -4dp above
  /// the tab bar baseline. This is typically used for central action buttons
  /// like "Scan" in the patient shell.
  ///
  /// Prominent items maintain their appearance regardless of selection state.
  final bool isProminent;
}

/// iOS 26 Liquid Glass floating bottom navigation bar.
///
/// This widget provides a modern floating pill-shaped navigation bar with:
/// - **Frosted glass effect**: Uses [AppGlassPanel] for the blur effect
/// - **Pill shape**: Full border radius (100dp) for iOS 26 aesthetic
/// - **Animated expanding tabs**: Selected tabs expand to show label
/// - **Prominent center button**: Always raised with primary color
/// - **44dp touch targets**: Minimum size for accessibility
///
/// The navigation bar floats above content with safe area + 12dp gap at bottom.
///
/// ## Basic Usage
///
/// ```dart
/// AppBottomNavigation(
///   currentIndex: _selectedIndex,
///   onTap: (index) => setState(() => _selectedIndex = index),
///   items: [
///     NavItem(
///       icon: CupertinoIcons.house,
///       activeIcon: CupertinoIcons.house_fill,
///       label: AppLocalizations.of(context)!.home,
///     ),
///     NavItem(
///       icon: CupertinoIcons.heart,
///       activeIcon: CupertinoIcons.heart_fill,
///       label: AppLocalizations.of(context)!.medications,
///     ),
///   ],
/// )
/// ```
///
/// ## With Prominent Center Button
///
/// ```dart
/// AppBottomNavigation(
///   currentIndex: _selectedIndex,
///   onTap: (index) => setState(() => _selectedIndex = index),
///   items: [
///     NavItem(
///       icon: CupertinoIcons.house,
///       activeIcon: CupertinoIcons.house_fill,
///       label: 'Home',
///     ),
///     NavItem(
///       icon: CupertinoIcons.heart,
///       activeIcon: CupertinoIcons.heart_fill,
///       label: 'Meds',
///     ),
///     NavItem(
///       icon: CupertinoIcons.camera_fill,
///       activeIcon: CupertinoIcons.camera_fill,
///       label: 'Scan',
///       isProminent: true,
///     ),
///     NavItem(
///       icon: CupertinoIcons.person_2,
///       activeIcon: CupertinoIcons.person_2_fill,
///       label: 'Connect',
///     ),
///     NavItem(
///       icon: CupertinoIcons.settings,
///       activeIcon: CupertinoIcons.settings_solid,
///       label: 'Settings',
///     ),
///   ],
/// )
/// ```
///
/// ## Design Specifications (iOS 26 Liquid Glass)
///
/// - **Panel**: Frosted glass with 100dp border radius (pill shape)
/// - **Position**: Floats above content with safe area + 12dp bottom gap
/// - **Selected tab**: 15% primary background, filled icon, primary color, label visible
/// - **Unselected tab**: Transparent background, outline icon, tertiary color, no label
/// - **Prominent tab**: Always raised -4dp, primary background, white icon
/// - **Animation**: 260ms easeOutCubic for expanding tabs
class AppBottomNavigation extends StatelessWidget {
  /// Creates an iOS 26 Liquid Glass [AppBottomNavigation] widget.
  ///
  /// The [currentIndex] must be a valid index within [items].
  /// The [onTap] callback is invoked when the user taps a navigation item.
  /// The [items] list must contain at least 2 items and at most 5 items.
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedColor,
    this.unselectedColor,
  }) : assert(
         items.length >= 2 && items.length <= 5,
         'Items must be between 2 and 5',
       );

  /// The index of the currently selected navigation item.
  final int currentIndex;

  /// Called when a navigation item is tapped.
  ///
  /// The callback receives the index of the tapped item.
  final ValueChanged<int> onTap;

  /// The list of navigation items to display.
  ///
  /// Must contain between 2 and 5 items.
  final List<NavItem> items;

  /// The color for selected navigation items.
  ///
  /// Defaults to [AppColors.primaryBlue].
  final Color? selectedColor;

  /// The color for unselected navigation items.
  ///
  /// Defaults to [AppColors.neutral400] (tertiary text color).
  final Color? unselectedColor;

  /// Minimum touch target size for accessibility (44dp per iOS HIG).
  static const double _minTouchTarget = 44.0;

  /// Full border radius for pill shape (100dp).
  static const double _radiusFull = 100.0;

  /// Vertical offset for the prominent button (raised above the bar).
  static const double _prominentButtonOffset = -4.0;

  /// Size of the prominent circular button.
  static const double _prominentButtonSize = 48.0;

  /// Icon size for navigation items.
  static const double _iconSize = 22.0;

  /// Animation duration for expanding/collapsing tabs.
  static const Duration _animationDuration = Duration(milliseconds: 260);

  /// Animation curve for smooth iOS-style motion.
  static const Curve _animationCurve = Curves.easeOutCubic;

  /// Upper cap for expanded tab width (with label).
  static const double _maxExpandedWidthCap = 120.0;

  /// Visual height of the pill panel including vertical padding.
  static const double _panelHeight = _prominentButtonSize + (AppSpacing.sm * 2);

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? AppColors.primaryBlue;
    final inactiveColor = unselectedColor ?? AppColors.neutral400;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Available width for tab row after outer and panel padding.
    final availableRowWidth =
        screenWidth - (AppSpacing.md * 2) - (AppSpacing.sm * 2);

    // Width when all items are collapsed (regular: 44dp, prominent: 48dp).
    final baselineRowWidth = items.fold<double>(0, (sum, item) {
      return sum + (item.isProminent ? _prominentButtonSize : _minTouchTarget);
    });

    // Let the selected regular tab consume only remaining horizontal space.
    final maxExpandedWidth =
        (_minTouchTarget + (availableRowWidth - baselineRowWidth))
            .clamp(_minTouchTarget, _maxExpandedWidthCap)
            .toDouble();

    assert(() {
      debugPrint(
        '[AppBottomNavigation] screenWidth=${screenWidth.toStringAsFixed(1)} '
        'availableRowWidth=${availableRowWidth.toStringAsFixed(1)} '
        'baselineRowWidth=${baselineRowWidth.toStringAsFixed(1)} '
        'maxExpandedWidth=${maxExpandedWidth.toStringAsFixed(1)}',
      );
      return true;
    }());

    final bottomInset = MediaQuery.paddingOf(context).bottom + 12.0;

    return SizedBox(
      // Keep bottomNavigationBar compact so page body remains visible.
      height: _panelHeight + bottomInset,
      child: Padding(
        // Float above content with bottom safe area + 12dp gap
        padding: EdgeInsets.only(
          bottom: bottomInset,
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        child: Center(
          child: AppGlassPanel(
            // Pill shape with full border radius
            borderRadius: _radiusFull,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (index) {
                final item = items[index];
                if (item.isProminent) {
                  return _ProminentNavItem(
                    index: index,
                    item: item,
                    activeColor: activeColor,
                    onTap: onTap,
                  );
                }
                return _ExpandingNavItem(
                  index: index,
                  item: item,
                  currentIndex: currentIndex,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  maxExpandedWidth: maxExpandedWidth,
                  onTap: onTap,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// An expanding navigation item that shows label when selected.
///
/// Implements iOS 26 Liquid Glass design:
/// - Selected: Expands to show icon + label, 15% primary background
/// - Unselected: Icon only, 44dp width, transparent background
///
/// Uses [AnimatedContainer] for smooth width transition.
class _ExpandingNavItem extends StatelessWidget {
  const _ExpandingNavItem({
    required this.index,
    required this.item,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.maxExpandedWidth,
    required this.onTap,
  });

  final int index;
  final NavItem item;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double maxExpandedWidth;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: AppBottomNavigation._animationDuration,
        curve: AppBottomNavigation._animationCurve,
        // Minimum 44dp height for touch target
        height: AppBottomNavigation._minTouchTarget,
        // Use constraints instead of fixed width to handle variable text lengths
        constraints: BoxConstraints(
          minWidth: AppBottomNavigation._minTouchTarget,
          maxWidth: isSelected
              ? maxExpandedWidth
              : AppBottomNavigation._minTouchTarget,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppSpacing.sm : 0,
        ),
        decoration: BoxDecoration(
          // 15% primary background when selected
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBottomNavigation._radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animated color/style transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.9,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey<bool>(isSelected),
                // Selected: primary color, unselected: tertiary color
                color: isSelected ? activeColor : inactiveColor,
                size: AppBottomNavigation._iconSize,
              ),
            ),
            // Label with flexible width and ellipsis for overflow handling
            if (isSelected) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An always-prominent navigation item for center action buttons.
///
/// Implements iOS 26 Liquid Glass design:
/// - Circular primary-colored button
/// - Raised -4dp above tab bar baseline
/// - White icon, always prominent regardless of selection state
/// - Glow shadow effect
class _ProminentNavItem extends StatelessWidget {
  const _ProminentNavItem({
    required this.index,
    required this.item,
    required this.activeColor,
    required this.onTap,
  });

  final int index;
  final NavItem item;
  final Color activeColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Transform.translate(
        // Elevated 4dp above tab bar baseline
        offset: const Offset(0, AppBottomNavigation._prominentButtonOffset),
        child: Container(
          width: AppBottomNavigation._prominentButtonSize,
          height: AppBottomNavigation._prominentButtonSize,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            item.activeIcon,
            color: AppColors.white,
            size: AppBottomNavigation._iconSize,
          ),
        ),
      ),
    );
  }
}
