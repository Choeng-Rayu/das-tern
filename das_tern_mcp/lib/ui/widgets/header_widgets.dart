import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PatientHeader extends StatelessWidget {
  const PatientHeader({
    super.key,
    this.onNotificationTap,
    this.unreadCount = 0,
    this.title,

    /// Override back-button visibility.
    /// - `null` (default): show back button only if [Navigator.canPop] is true.
    /// - `false`: never show a back button (use on main tab screens).
    /// - `true`: always show a back button.
    this.showBackButton,
  });

  final VoidCallback? onNotificationTap;
  final int unreadCount;

  /// If provided, replaces the greeting text with this title
  /// while keeping the avatar row and background image.
  final String? title;

  /// Controls back-button visibility. `null` defers to [Navigator.canPop].
  final bool? showBackButton;

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

    // The text shown below the divider: either the custom title or the greeting
    final headerText = title ?? '${_greeting(context)} $fullName!';

    // Collapsed height = avatar row + padding
    const collapsedContentHeight = 60.0;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      leading: (showBackButton ?? Navigator.canPop(context))
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      pinned: true,
      expandedHeight: 180,
      collapsedHeight: collapsedContentHeight,
      toolbarHeight: collapsedContentHeight,
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      // ── Always visible: avatar row ──
      title: Row(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRouter.patientEditProfile),
            child: const _PatientAvatar(),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _PatientName(),
          const Spacer(),
          _NotificationBell(unreadCount: unreadCount, onTap: onNotificationTap),
        ],
      ),
      // ── Expanded area: background image + greeting (below the avatar row) ──
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/backgroundHeader.png',
                  fit: BoxFit.cover,
                ),
              ),

              // Greeting text – positioned below the toolbar area
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(
                      color: Colors.white.withValues(alpha: 0.35),
                      thickness: 1,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      headerText,
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
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
    );
  }
}

/// Avatar
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Name + role badge
class _PatientName extends StatelessWidget {
  const _PatientName();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final l10n = AppLocalizations.of(context)!;
    final firstName = (user?['firstName'] ?? '') as String;
    final lastName = (user?['lastName'] ?? '') as String;
    final fullName = '$firstName $lastName'.trim();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fullName.isEmpty ? l10n.patient : fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.patientRole,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification Bell
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount, required this.onTap});

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
            width: 40,
            height: 40,
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
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const BoxDecoration(
                  color: AppColors.alertRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
