import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../models/notification_model/notification.dart';
import '../../../../providers/notification_provider.dart';
import '../../../theme/app_colors.dart';
import 'notification_utils.dart';

/// Standard notification card for non-connection notifications.
/// Uses iOS 26 Liquid Glass styling.
class StandardNotificationCard extends StatelessWidget {
  final AppNotification notif;

  const StandardNotificationCard({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    final typeColor = colorForNotificationType(notif.type);

    // Glass styling colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFillColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.60);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.12);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.10);

    // Blend unread tint with glass fill
    final fillColor = notif.isRead
        ? glassFillColor
        : Color.lerp(glassFillColor, typeColor.withValues(alpha: 0.15), 0.5)!;

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          context.read<NotificationProvider>().markAsRead(notif.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: notif.isRead
                          ? AppColors.neutral200
                          : typeColor.withValues(alpha: 0.1),
                      child: Icon(
                        iconForNotificationType(notif.type),
                        color: notif.isRead ? AppColors.neutral400 : typeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(notif.createdAt, context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
