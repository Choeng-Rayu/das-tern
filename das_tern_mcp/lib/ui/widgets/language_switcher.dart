import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../theme/app_spacing.dart';

/// Compact pill-shaped language toggle for auth screens.
/// Displays a globe icon + current language code (EN/KM).
/// Taps toggle between English and Khmer locales.
///
/// Set [lightBackground] to `true` when placed on a light/white background
/// (e.g., the login and register screens). Leave `false` for dark/image
/// backgrounds like the welcome screen.
class LanguageSwitcherButton extends StatelessWidget {
  final bool lightBackground;

  const LanguageSwitcherButton({super.key, this.lightBackground = false});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isKhmer = localeProvider.locale.languageCode == 'km';

    final Color fgColor = lightBackground
        ? const Color(0xFF1976D2)
        : Colors.white;
    final Color bgColor = lightBackground
        ? const Color(0xFFE3F2FD)
        : Colors.white.withValues(alpha: 0.15);
    final Color borderColor = lightBackground
        ? const Color(0xFFBBDEFB)
        : Colors.white.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {
        final newLocale = isKhmer ? const Locale('en') : const Locale('km');
        localeProvider.changeLocale(newLocale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, color: fgColor, size: 16),
            const SizedBox(width: 4),
            Text(
              isKhmer ? 'KM' : 'EN',
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
