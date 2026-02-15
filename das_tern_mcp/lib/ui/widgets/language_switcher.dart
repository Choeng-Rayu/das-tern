import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../theme/app_spacing.dart';

/// Compact pill-shaped language toggle for auth screens.
/// Displays a globe icon + current language code (EN/KM).
/// Taps toggle between English and Khmer locales.
class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isKhmer = localeProvider.locale.languageCode == 'km';

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
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isKhmer ? 'KM' : 'EN',
              style: const TextStyle(
                color: Colors.white,
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
