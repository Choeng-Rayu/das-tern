import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable patient home header with background image and user greeting.
///
/// Usage:
/// ```dart
/// PatientHeader(onNotificationTap: () { ... })
/// ```
class PatientHeader extends StatelessWidget {
  const PatientHeader({
    super.key,
    this.onNotificationTap,
    this.unreadCount = 0,
  });

  final VoidCallback? onNotificationTap;
  final int unreadCount;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/backgroundHeader.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top row: avatar + doctor name + notification bell ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _DoctorAvatar(),
                      const SizedBox(width: AppSpacing.sm),
                      const _DoctorName(),
                      const Spacer(),
                      _NotificationBell(
                        unreadCount: unreadCount,
                        onTap: onNotificationTap,
                      ),
                    ],
                  ),

                  // ── Divider ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.35),
                      thickness: 1,
                    ),
                  ),

                  // ── Bottom: large greeting + user name ────────────────
                  Text(
                    '${_greeting(context)} $fullName !',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: Image.asset('assets/doctorLogo.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _DoctorName extends StatelessWidget {
  const _DoctorName();

  @override
  Widget build(BuildContext context) {
    // Replace with a dynamic value from your provider if needed
    return const Text(
      'Dastern',
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount, this.onTap});

  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (unreadCount > 0) _UnreadBadge(count: unreadCount),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -2,
      right: -2,
      child: Container(
        width: 17,
        height: 17,
        decoration: const BoxDecoration(
          color: AppColors.alertRed,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
