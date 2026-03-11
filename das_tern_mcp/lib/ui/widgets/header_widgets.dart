import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable home header with background image and user greeting.
///
/// Used by both patient and doctor home screens.
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?['firstName'] ?? '') as String;
    final lastName = (user?['lastName'] ?? '') as String;
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
                  // Top row: avatar + name + notification bell
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _PatientAvatar(),
                      const SizedBox(width: AppSpacing.sm),
                      const _PatientName(),
                      const Spacer(),
                      _NotificationBell(
                        unreadCount: unreadCount,
                        onTap: onNotificationTap,
                      ),
                    ],
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.35),
                      thickness: 1,
                    ),
                  ),

                  // ── Greeting message ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _greeting(context),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stay on track with your medicine',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class _PatientAvatar extends StatelessWidget {
  const _PatientAvatar();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?['firstName'] ?? '') as String;
    final lastName = (user?['lastName'] ?? '') as String;
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PatientName extends StatelessWidget {
  const _PatientName();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?['firstName'] ?? '') as String;
    final lastName = (user?['lastName'] ?? '') as String;
    final fullName = '$firstName $lastName'.trim();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fullName.isEmpty ? 'Patient' : fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
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
