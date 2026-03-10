import 'package:flutter/material.dart';
import '../../../../models/notification_model/notification.dart';
import '../../../../providers/notification_provider.dart';
import '../../../theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'notification_utils.dart';

/// Standard notification card for non-connection notifications.
class StandardNotificationCard extends StatelessWidget {
  final AppNotification notif;

  const StandardNotificationCard({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral300),
      ),
      color: notif.isRead ? Colors.white : Colors.blue.withValues(alpha: 0.03),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notif.isRead
              ? AppColors.neutral200
              : AppColors.primaryBlue.withValues(alpha: 0.1),
          child: Icon(
            iconForNotificationType(notif.type),
            color: notif.isRead ? AppColors.neutral400 : AppColors.primaryBlue,
            size: 20,
          ),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          notif.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          timeAgo(notif.createdAt, context),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        onTap: () {
          if (!notif.isRead) {
            context.read<NotificationProvider>().markAsRead(notif.id);
          }
        },
      ),
    );
  }
}
