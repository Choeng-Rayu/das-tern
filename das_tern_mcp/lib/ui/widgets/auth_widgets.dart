import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_glass_panel.dart';

/// Light background scaffold used across all auth screens.
class AuthGradientScaffold extends StatelessWidget {
  final Widget child;

  const AuthGradientScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF10131A), Color(0xFF171B24), Color(0xFF0F1218)]
                : const [Color(0xFFF2F2F7), Color(0xFFEFF3FB), Color(0xFFF6F8FC)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -120,
                right: -80,
                child: _AuthOrb(
                  size: 300,
                  color: AppColors.primaryBlue,
                  opacity: 0.14,
                ),
              ),
              const Positioned(
                top: 220,
                left: -110,
                child: _AuthOrb(
                  size: 240,
                  color: AppColors.successGreen,
                  opacity: 0.08,
                ),
              ),
              const Positioned(
                bottom: -130,
                right: -100,
                child: _AuthOrb(
                  size: 280,
                  color: AppColors.darkBlue,
                  opacity: 0.1,
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _AuthOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity * 0.8),
              blurRadius: 64,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// App logo + name row used in auth screen headers.
/// [trailing] is reserved for the language switcher.
class AuthHeader extends StatelessWidget {
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    this.trailing,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: AppGlassPanel(
                borderRadius: 14,
                blurRadius: 16,
                child: GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          AppGlassPanel(
            borderRadius: 18,
            blurRadius: 18,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/welcome', (route) => false),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/doctorLogo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context)?.appTitle ?? 'DasTern',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Dark label above form fields.
class AuthFieldLabel extends StatelessWidget {
  final String text;
  final String? suffix;

  const AuthFieldLabel(this.text, {super.key, this.suffix});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: AppGlassPanel(
        borderRadius: 14,
        blurRadius: 10,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 4),
              Text(
                suffix!,
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.neutral400,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Themed text field for auth screens — white fill with light border.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final int? maxLength;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : AppColors.neutral400,
          fontSize: 13,
        ),
        counterText: '',
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : AppColors.neutral300,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : AppColors.neutral300,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: const BorderSide(color: AppColors.alertRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: const BorderSide(color: AppColors.alertRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

/// Primary action button for auth screens — blue gradient pill.
class AuthPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const AuthPrimaryButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDisabled
                ? [
                    AppColors.primaryBlue.withValues(alpha: 0.35),
                    AppColors.primaryBlue.withValues(alpha: 0.25),
                  ]
                : const [AppColors.primaryBlue, Color(0xFF4069DE)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDisabled ? 0.25 : 0.35),
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: isDisabled ? 0.06 : 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

/// "Don't have account? Register" or "Already have account? Sign in" row.
class AuthLinkRow extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback onTap;

  const AuthLinkRow({
    super.key,
    required this.message,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: AppGlassPanel(
        borderRadius: 20,
        blurRadius: 12,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error message banner for auth screens.
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AppGlassPanel(
      borderRadius: 16,
      blurRadius: 14,
      tint: AppColors.alertRed.withValues(alpha: 0.22),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.alertRed, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.alertRed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual step indicator for multi-step forms (e.g., "Step 1 of 2").
class AuthStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepLabel;

  const AuthStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          stepLabel,
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppGlassPanel(
          borderRadius: 18,
          blurRadius: 10,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: List.generate(totalSteps, (i) {
              final isActive = i <= currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryBlue
                        : (isDark
                              ? Colors.white24
                              : AppColors.neutral300),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
