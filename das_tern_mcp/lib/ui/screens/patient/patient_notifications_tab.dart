import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/notification_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Notifications/Alerts tab.
class PatientNotificationsTab extends StatefulWidget {
  const PatientNotificationsTab({super.key});

  @override
  State<PatientNotificationsTab> createState() =>
      _PatientNotificationsTabState();
}

class _PatientNotificationsTabState extends State<PatientNotificationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        automaticallyImplyLeading: false,
        actions: [
          if (provider.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.alertRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.unreadCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchNotifications(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: AppColors.neutral300),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.noNotifications,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = provider.notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notif.isRead
                              ? AppColors.neutral200
                              : AppColors.primaryBlue.withValues(alpha: 0.1),
                          child: Icon(
                            _iconForType(notif.type),
                            color: notif.isRead
                                ? AppColors.neutral400
                                : AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          notif.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _timeAgo(notif.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        onTap: () {
                          if (!notif.isRead) {
                            provider.markAsRead(notif.id);
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'CONNECTION_REQUEST':
        return Icons.person_add;
      case 'PRESCRIPTION_UPDATE':
        return Icons.medication;
      case 'MISSED_DOSE_ALERT':
        return Icons.warning_amber;
      case 'URGENT_PRESCRIPTION_CHANGE':
        return Icons.priority_high;
      case 'FAMILY_ALERT':
        return Icons.family_restroom;
      default:
        return Icons.notifications;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
