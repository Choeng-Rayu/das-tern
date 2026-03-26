// lib/core/widgets/app_bottom_nav.dart
//
// DasTern Global Widget System — Floating Glass Tab Bar
// iOS 26 Liquid Glass aesthetic — five tabs, pill shape
//
// Requirements: 8.1–8.14

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_glass_panel.dart';

/// Navigation tab enum — indices 0–4. (Req 8.1)
///
/// Note: [tabIndex] is used instead of [index] because `index` is a reserved
/// property on all Dart enums (returns the enum's ordinal position).
enum NavTab {
  home(0),
  medication(1),
  scan(2),
  connection(3),
  settings(4);

  const NavTab(this.tabIndex);
  final int tabIndex;
}

/// Floating glass pill tab bar with five navigation tabs.
///
/// The Scan tab (index 2) is always visually prominent with a circular
/// [AppColors.primary] background, regardless of selection state (Req 8.3).
///
/// **Invariant (Req 8.13):** exactly one tab is selected at any time.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Currently selected tab index (0–4). (Req 8.13)
  final int currentIndex;

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Float above content with bottom safe area + 12 dp gap (Req 8.9)
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 12,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Center(
        child: AppGlassPanel(
          // Pill shape (Req 8.10)
          borderRadius: AppSpacing.radiusFull,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavItem(
                index: 0,
                outlineIcon: CupertinoIcons.house,
                filledIcon: CupertinoIcons.house_fill,
                label: 'Home',
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                // Use heart icons for Medication — valid in cupertino_icons 1.0.x
                outlineIcon: CupertinoIcons.heart,
                filledIcon: CupertinoIcons.heart_fill,
                label: 'Medication',
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              // Always-prominent Scan tab
              _ScanTab(onTap: () => onTap(2)),
              _NavItem(
                index: 3,
                outlineIcon: CupertinoIcons.person_2,
                filledIcon: CupertinoIcons.person_2_fill,
                label: 'Connection',
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 4,
                outlineIcon: CupertinoIcons.settings,
                filledIcon: CupertinoIcons.settings_solid,
                label: 'Settings',
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _NavItem — regular tab (indices 0, 1, 3, 4) ───────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    required this.currentIndex,
    required this.onTap,
  });

  final int index;
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isSelected = currentIndex == index;

    // Estimate expanded width: icon (22) + gap (6) + ~7.5 px/char + padding
    final labelWidth = label.length * 7.5 + 22.0 + 14.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        // Minimum 44 dp height for touch target (Req 8.14)
        height: 44,
        width: isSelected ? labelWidth : 44,
        decoration: BoxDecoration(
          // 15% primary background when selected (Req 8.4)
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              // Selected: primary, unselected: textTertiary (Req 8.4, 8.5)
              color: isSelected ? AppColors.primary : colors.textTertiary,
              size: 22,
            ),
            // Animate label in/out (Req 8.6)
            if (isSelected)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 160),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _ScanTab — always-prominent centre tab (index 2) ─────────────────────────

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.translate(
        // Elevated 4 dp above tab bar baseline (Req 8.3)
        offset: const Offset(0, -4),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.camera_fill,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
