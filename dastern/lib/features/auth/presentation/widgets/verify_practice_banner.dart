import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/tokens/colors.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_verification_provider.dart';

/// Non-blocking CTA shown on the doctor home until `account_status = 'VERIFIED'`.
/// Dismissible per session (stored in SharedPreferences).
///
/// Spec ref: 02-authentication §8.5.
class VerifyPracticeBanner extends ConsumerWidget {
  const VerifyPracticeBanner({super.key, required this.doctorId});

  final String doctorId;

  static const _dismissedKey = 'verify_practice_banner_dismissed';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = ref.watch(isDoctorVerifiedProvider(doctorId));

    // Hide if verified
    if (isVerified.valueOrNull == true) return const SizedBox.shrink();

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (snap.data?.getBool(_dismissedKey) == true) {
          return const SizedBox.shrink();
        }
        final l = AppLocalizations.of(context)!;
        return Material(
          color: AppColors.info.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.verified_outlined, color: AppColors.info, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l.accountVerificationInfo,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/verify-practice'),
                  child: Text(l.step2AccountInfo),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l.cancel,
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_dismissedKey, true);
                    // Rebuild by invalidating — simplest approach without setState
                    ref.invalidate(isDoctorVerifiedProvider(doctorId));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
