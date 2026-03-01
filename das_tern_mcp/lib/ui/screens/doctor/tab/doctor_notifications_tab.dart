import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/notification_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Doctor notifications tab – reuses notification pattern.
class DoctorNotificationsTab extends StatefulWidget {
  const DoctorNotificationsTab({super.key});

  @override
  State<DoctorNotificationsTab> createState() => _DoctorNotificationsTabState();
}

class _DoctorNotificationsTabState extends State<DoctorNotificationsTab> {
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
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: AppColors.neutral300,
                    ),
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
                        Icons.notifications,
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
}
