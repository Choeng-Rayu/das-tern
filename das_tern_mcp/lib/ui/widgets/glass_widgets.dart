/// Shared Liquid Glass UI components for Das Tern.
///
/// All glass widgets use [GlassTokens] for blur, tint, border, shadow.
/// BackdropFilter is only used inside these widgets — never compose it manually.
library;

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/glass_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AppGlassPanel — Foundation glass surface
// ═══════════════════════════════════════════════════════════════════════════════

/// The foundation frosted-glass surface. Every glass widget builds on this.
/// Contains exactly one [BackdropFilter] — never nest panels.
class AppGlassPanel extends StatelessWidget {
  const AppGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = GlassTokens.radiusLg,
    this.tint,
    this.padding,
    this.opacity = 1.0,
  });

  final Widget child;
  final double borderRadius;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.resolve(context);
    final resolvedTint = tint ?? Colors.white;
    final isTransparent = resolvedTint == Colors.transparent;

    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: tokens.shadowColor,
              blurRadius: GlassTokens.shadowBlur,
              offset: GlassTokens.shadowOffset,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: tokens.blurRadius,
              sigmaY: tokens.blurRadius,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isTransparent
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          resolvedTint.withValues(alpha: tokens.tintOpacity),
                          resolvedTint.withValues(
                            alpha: tokens.tintOpacitySecondary,
                          ),
                        ],
                      ),
                border: Border(
                  top: BorderSide(
                    color: tokens.borderColor,
                    width: GlassTokens.borderWidth,
                  ),
                ),
              ),
              child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppGlassCard — Tappable glass card with press animation
// ═══════════════════════════════════════════════════════════════════════════════

class AppGlassCard extends StatefulWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius = GlassTokens.radiusLg,
    this.tint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? tint;

  @override
  State<AppGlassCard> createState() => _AppGlassCardState();
}

class _AppGlassCardState extends State<AppGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: GlassTokens.pressDuration,
    );
    _scale = Tween(
      begin: 1.0,
      end: GlassTokens.pressedScale,
    ).animate(CurvedAnimation(parent: _ctrl, curve: GlassTokens.pressCurve));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.resolve(context);
    final panel = AppGlassPanel(
      borderRadius: widget.borderRadius,
      tint: widget.tint,
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
      child: widget.child,
    );

    if (widget.onTap == null) return panel;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => tokens.disableAnimations ? null : _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: panel,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppButton — Glass button with variants
// ═══════════════════════════════════════════════════════════════════════════════

enum AppButtonVariant { primary, secondary, destructive, ghost }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: GlassTokens.pressDuration,
    );
    _scale = Tween(
      begin: 1.0,
      end: GlassTokens.pressedScale,
    ).animate(CurvedAnimation(parent: _ctrl, curve: GlassTokens.pressCurve));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = GlassTokens.resolve(context);

    final (Color tint, Color labelColor) = switch (widget.variant) {
      AppButtonVariant.primary => (
        AppColors.primaryBlue.withValues(alpha: 0.10),
        AppColors.primaryBlue,
      ),
      AppButtonVariant.secondary => (
        (isDark ? Colors.white : Colors.white),
        isDark ? Colors.white : AppColors.textPrimary,
      ),
      AppButtonVariant.destructive => (
        AppColors.alertRed.withValues(alpha: 0.10),
        AppColors.alertRed,
      ),
      AppButtonVariant.ghost => (Colors.transparent, AppColors.textSecondary),
    };

    return Opacity(
      opacity: widget.onPressed == null ? GlassTokens.disabledOpacity : 1.0,
      child: GestureDetector(
        onTapDown: (_) => tokens.disableAnimations ? null : _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: AppGlassPanel(
            tint: tint,
            borderRadius: GlassTokens.radiusFull,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SizedBox(
              width: widget.isFullWidth ? double.infinity : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: labelColor,
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: labelColor, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppTextField — Glass input field
// ═══════════════════════════════════════════════════════════════════════════════

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.resolve(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: tokens.blurRadius * 0.8,
              sigmaY: tokens.blurRadius * 0.8,
            ),
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLines: obscureText ? 1 : maxLines,
              onChanged: onChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: tokens.tintOpacity)
                    : Colors.white.withValues(alpha: tokens.tintOpacity),
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: prefix,
                suffixIcon: suffix,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                  borderSide: BorderSide(
                    color: tokens.borderColor,
                    width: GlassTokens.borderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                  borderSide: const BorderSide(
                    color: AppColors.alertRed,
                    width: 1.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                  borderSide: const BorderSide(
                    color: AppColors.alertRed,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppAvatar — User avatar with glass ring
// ═══════════════════════════════════════════════════════════════════════════════

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 24,
    this.onTap,
  });

  final String? imageUrl;
  final String? initials;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.resolve(context);
    final size = radius * 2;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tokens.borderColor, width: 1.5),
      ),
      child: ClipOval(child: _content(context)),
    );

    if (onTap == null) return avatar;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size.clamp(44.0, double.infinity),
        height: size.clamp(44.0, double.infinity),
        child: Center(child: avatar),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsWidget(context),
      );
    }
    return _initialsWidget(context);
  }

  Widget _initialsWidget(BuildContext context) {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initials ?? '?',
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppScaffold — Screen wrapper (no mesh background, calm system bg)
// ═══════════════════════════════════════════════════════════════════════════════

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF2F2F7),
      appBar: title != null
          ? AppHeader(
              title: title!,
              showBackButton: showBackButton,
              actions: actions,
            )
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppHeader — Glass navigation bar (PreferredSizeWidget)
// ═══════════════════════════════════════════════════════════════════════════════

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
  });

  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.resolve(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurRadius,
          sigmaY: tokens.blurRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: tokens.tintOpacity)
                : Colors.white.withValues(alpha: tokens.tintOpacity),
            border: Border(
              bottom: BorderSide(color: tokens.borderColor, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (showBackButton)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.maybePop(context),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.chevron_left,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!
                          .map(
                            (a) => SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(child: a),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppSettingsSection — Grouped settings section
// ═══════════════════════════════════════════════════════════════════════════════

class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              bottom: AppSpacing.sm,
              top: AppSpacing.lg,
            ),
            child: Text(
              title!.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        AppGlassPanel(
          borderRadius: GlassTokens.radiusMd,
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppSettingsTile — Single settings row
// ═══════════════════════════════════════════════════════════════════════════════

class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          trailing ??
              (onTap != null
                  ? Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: AppColors.textSecondary,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );

    return Column(
      children: [
        onTap != null ? InkWell(onTap: onTap, child: tile) : tile,
        if (showDivider)
          Divider(
            height: 0.5,
            indent: leading != null ? 52 : 16,
            color: AppColors.neutral200.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AppStateView — Loading / Error / Empty state wrapper
// ═══════════════════════════════════════════════════════════════════════════════

enum AppViewState { loading, error, empty, content }

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.state,
    required this.child,
    this.errorMessage,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.onRetry,
  });

  final AppViewState state;
  final Widget child;
  final String? errorMessage;
  final IconData? emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AppViewState.loading => const Center(child: CircularProgressIndicator()),
      AppViewState.error => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.alertRed),
              const SizedBox(height: AppSpacing.md),
              Text(
                errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Retry',
                  onPressed: onRetry,
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
      AppViewState.empty => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emptyIcon ?? Icons.inbox_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              if (emptyTitle != null)
                Text(
                  emptyTitle!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (emptySubtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  emptySubtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
      AppViewState.content => child,
    };
  }
}
