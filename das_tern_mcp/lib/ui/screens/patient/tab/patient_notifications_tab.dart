import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/connection_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

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
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.alertRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                  final isConnectionRequest = notif.type == 'CONNECTION_REQUEST';
                  final isMissedDose = notif.type == 'MISSED_DOSE_ALERT';
                  final isFamilyAlert = notif.type == 'FAMILY_ALERT';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif.isRead
                          ? AppColors.neutral200
                          : _colorForType(notif.type).withValues(alpha: 0.12),
                      child: Icon(
                        _iconForType(notif.type),
                        color: notif.isRead
                            ? AppColors.neutral400
                            : _colorForType(notif.type),
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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _timeAgo(notif.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isConnectionRequest && !notif.isRead)
                          const Icon(Icons.chevron_right,
                              size: 16, color: AppColors.primaryBlue),
                      ],
                    ),
                    onTap: () {
                      if (!notif.isRead) {
                        provider.markAsRead(notif.id);
                      }
                      if (isConnectionRequest) {
                        _showConnectionApprovalSheet(context, notif.metadata);
                      } else if (isMissedDose || isFamilyAlert) {
                        _handleMissedDoseNotification(context, notif.metadata, notif.type);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  void _showConnectionApprovalSheet(
    BuildContext context,
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) return;
    final connectionId = metadata['connectionId'] as String?;
    if (connectionId == null) return;

    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.person_add, size: 28, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.connectionRequest,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.pendingConnectionRequests,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await context
                            .read<ConnectionProvider>()
                            .revokeConnection(connectionId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? l10n.connectionDenied
                                  : l10n.operationFailed),
                              backgroundColor: success
                                  ? AppColors.alertRed
                                  : AppColors.neutral400,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.alertRed,
                        side: const BorderSide(color: AppColors.alertRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.deny),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await context
                            .read<ConnectionProvider>()
                            .acceptConnection(connectionId, {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? l10n.familyLinked
                                  : l10n.operationFailed),
                              backgroundColor: success
                                  ? AppColors.successGreen
                                  : AppColors.alertRed,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.approve),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _handleMissedDoseNotification(
    BuildContext context,
    Map<String, dynamic>? metadata,
    String type,
  ) {
    if (metadata == null) return;
    final l10n = AppLocalizations.of(context)!;
    final doseId = metadata['doseEventId'] as String?;
    final medName = metadata['medicationName'] as String? ?? '';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final title = type == 'FAMILY_ALERT'
            ? l10n.nudgeTitle
            : l10n.missedDoseAlertTitle;
        final body = type == 'FAMILY_ALERT'
            ? l10n.nudgeMessage
            : l10n.missedDoseBannerMessage(medName);

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.alertRed.withValues(alpha: 0.12),
                child: const Icon(Icons.warning_amber,
                    size: 28, color: AppColors.alertRed),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (doseId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Mark dose as taken via DoseProvider
                      // Navigation to home tab for full context
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/patient',
                        (r) => false,
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.markAsTaken),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.dismiss),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'CONNECTION_REQUEST':
        return AppColors.primaryBlue;
      case 'MISSED_DOSE_ALERT':
        return AppColors.alertRed;
      case 'FAMILY_ALERT':
        return AppColors.warningOrange;
      case 'URGENT_PRESCRIPTION_CHANGE':
        return AppColors.alertRed;
      default:
        return AppColors.primaryBlue;
    }
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
