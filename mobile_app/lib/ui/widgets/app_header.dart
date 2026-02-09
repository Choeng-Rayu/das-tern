import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../../models/user_model/user.dart';

class AppHeader extends StatelessWidget {
  final User user;
  final double progress;
  final int notificationCount;
  final VoidCallback? onLogoTap;
  final VoidCallback? onNotificationTap;

  const AppHeader({
    super.key,
    required this.user,
    this.progress = 0.0,
    this.notificationCount = 0,
    this.onLogoTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.of(context).padding.top + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBlue : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onLogoTap,
                child: Row(
                  children: [
                    Icon(Icons.medication, color: AppColors.primaryBlue, size: 24),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'ដាស់តឿន',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (user.role == UserRole.doctor)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'វេជ្ជបណ្ឌិត',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: isDark ? Colors.white : AppColors.darkBlue,
                      size: 24,
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.alertRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationCount > 9 ? '9+' : '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'សួស្តី ${user.name} !',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.neutralGray.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
        ],
      ),
    );
  }
}
