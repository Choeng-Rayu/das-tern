import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enums_model/enums.dart';
import '../../../../providers/connection_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../models/notification_model/notification.dart';
import '../../../../models/connection_model/connection.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Notifications screen – shows all notifications including
/// doctor connection requests with approve/reject actions.
/// Notifications persist until the user explicitly removes them.
class PatientNotificationsTab extends StatefulWidget {
  const PatientNotificationsTab({super.key});

  @override
  State<PatientNotificationsTab> createState() =>
      _PatientNotificationsTabState();
}

class _PatientNotificationsTabState extends State<PatientNotificationsTab> {
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  /// Fetch notifications and connections fresh every time this screen appears.
  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().fetchNotifications();
      context.read<ConnectionProvider>().fetchConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotificationProvider>();
    // Watch connections so the UI updates after approve/reject
    context.watch<ConnectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
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
        onRefresh: () async {
          await provider.fetchNotifications();
          if (!context.mounted) return;
          await context.read<ConnectionProvider>().fetchConnections();
        },
        child: provider.isLoading && !provider.hasFetched
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : provider.error != null && provider.notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.alertRed,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.alertRed),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () {
                              provider.clearError();
                              provider.fetchNotifications();
                            },
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : provider.notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
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
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: provider.notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final notif = provider.notifications[index];
                  return _buildDismissible(
                    notif,
                    notif.type == 'CONNECTION_REQUEST'
                        ? _buildConnectionRequestCard(notif)
                        : _buildStandardNotification(notif),
                  );
                },
              ),
      ),
    );
  }

  /// Wrap any notification card in a Dismissible for swipe-to-delete.
  Widget _buildDismissible(AppNotification notif, Widget child) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.alertRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.removeNotification),
            content: Text(l10n.removeNotificationConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.remove,
                  style: const TextStyle(color: AppColors.alertRed),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(notif.id);
      },
      child: child,
    );
  }

  /// Get the connection status for a CONNECTION_REQUEST notification.
  Connection? _findConnection(AppNotification notif) {
    final connectionId = notif.metadata?['connectionId'] as String?;
    if (connectionId == null) return null;
    final connections = context.read<ConnectionProvider>().connections;
    try {
      return connections.firstWhere((c) => c.id == connectionId);
    } catch (_) {
      return null;
    }
  }

  /// Show a bottom sheet dialog when patient taps a connection request.
  void _showConnectionRequestSheet(AppNotification notif) {
    final connectionId = notif.metadata?['connectionId'] as String?;
    if (connectionId == null) return;

    final connection = _findConnection(notif);
    final isPending = connection?.status == ConnectionStatus.pending;
    final isAccepted = connection?.status == ConnectionStatus.accepted;
    final isRevoked = connection?.status == ConnectionStatus.revoked;

    // Mark as read when user taps
    if (!notif.isRead) {
      context.read<NotificationProvider>().markAsRead(notif.id);
    }

    final l10n = AppLocalizations.of(context)!;
    final doctorName = connection?.getOtherUserName(notif.userId) ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isProcessing = _processingIds.contains(connectionId);

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Doctor icon
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppColors.primaryBlue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Title
                  Text(
                    notif.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Message
                  Text(
                    notif.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (doctorName.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Status / Action buttons
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(),
                    )
                  else if (isPending) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setSheetState(() {});
                          await _handleApprove(notif, connectionId);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check, size: 20),
                        label: Text(l10n.approveConnection),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          setSheetState(() {});
                          await _handleReject(notif, connectionId);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.close, size: 20),
                        label: Text(l10n.rejectConnection),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alertRed,
                          side: const BorderSide(color: AppColors.alertRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else if (isAccepted) ...[
                    _statusBadge(
                      icon: Icons.check_circle,
                      color: AppColors.successGreen,
                      label: l10n.connectionApproved,
                    ),
                  ] else if (isRevoked) ...[
                    _statusBadge(
                      icon: Icons.cancel,
                      color: AppColors.alertRed,
                      label: l10n.connectionRejected,
                    ),
                  ] else ...[
                    // Connection not yet loaded — show pending actions anyway
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setSheetState(() {});
                          await _handleApprove(notif, connectionId);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check, size: 20),
                        label: Text(l10n.approveConnection),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          setSheetState(() {});
                          await _handleReject(notif, connectionId);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.close, size: 20),
                        label: Text(l10n.rejectConnection),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alertRed,
                          side: const BorderSide(color: AppColors.alertRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBadge({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionRequestCard(AppNotification notif) {
    final l10n = AppLocalizations.of(context)!;
    final connection = _findConnection(notif);
    final connectionId = notif.metadata?['connectionId'] as String?;
    final isProcessing = _processingIds.contains(connectionId);
    final isPending = connection?.status == ConnectionStatus.pending;
    final isAccepted = connection?.status == ConnectionStatus.accepted;
    final isRevoked = connection?.status == ConnectionStatus.revoked;
    // Show approve/reject buttons when pending OR when connection hasn't loaded yet
    final showActions =
        (isPending || connection == null) && connectionId != null;

    return GestureDetector(
      onTap: connectionId != null
          ? () => _showConnectionRequestSheet(notif)
          : null,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isPending
                ? AppColors.primaryBlue.withValues(alpha: 0.3)
                : isAccepted
                ? AppColors.successGreen.withValues(alpha: 0.3)
                : AppColors.neutral300,
          ),
        ),
        color: notif.isRead
            ? Colors.white
            : AppColors.primaryBlue.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeAgo(notif.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron hint for tap
                  if (showActions)
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.primaryBlue.withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(notif.message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: AppSpacing.md),
              // Inline action buttons for pending connections
              if (showActions) ...[
                if (isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleReject(notif, connectionId),
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(l10n.rejectConnection),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.alertRed,
                            side: const BorderSide(color: AppColors.alertRed),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleApprove(notif, connectionId),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n.approveConnection),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ] else if (isAccepted) ...[
                _statusBadge(
                  icon: Icons.check_circle,
                  color: AppColors.successGreen,
                  label: l10n.connectionApproved,
                ),
              ] else if (isRevoked) ...[
                _statusBadge(
                  icon: Icons.cancel,
                  color: AppColors.alertRed,
                  label: l10n.connectionRejected,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardNotification(AppNotification notif) {
    final provider = context.read<NotificationProvider>();

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
            _iconForType(notif.type),
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
          _timeAgo(notif.createdAt),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        onTap: () {
          if (!notif.isRead) {
            provider.markAsRead(notif.id);
          }
        },
      ),
    );
  }

  Future<void> _handleApprove(
    AppNotification notif,
    String connectionId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _processingIds.add(connectionId));

    final connProvider = context.read<ConnectionProvider>();
    final notifProvider = context.read<NotificationProvider>();

    final success = await connProvider.acceptConnection(connectionId, {
      'permissionLevel': 'ALLOWED',
    });

    if (!notif.isRead) {
      await notifProvider.markAsRead(notif.id);
    }
    // Refresh both so the UI updates
    await notifProvider.fetchNotifications();
    if (mounted) {
      await context.read<ConnectionProvider>().fetchConnections();
    }

    if (mounted) {
      setState(() => _processingIds.remove(connectionId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.connectionApproved : (connProvider.error ?? 'Error'),
          ),
          backgroundColor: success
              ? AppColors.successGreen
              : AppColors.alertRed,
        ),
      );
    }
  }

  Future<void> _handleReject(AppNotification notif, String connectionId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _processingIds.add(connectionId));

    final connProvider = context.read<ConnectionProvider>();
    final notifProvider = context.read<NotificationProvider>();

    final success = await connProvider.revokeConnection(connectionId);

    if (!notif.isRead) {
      await notifProvider.markAsRead(notif.id);
    }
    // Refresh both so the UI updates
    await notifProvider.fetchNotifications();
    if (mounted) {
      await context.read<ConnectionProvider>().fetchConnections();
    }

    if (mounted) {
      setState(() => _processingIds.remove(connectionId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.connectionRejected : (connProvider.error ?? 'Error'),
          ),
          backgroundColor: success
              ? AppColors.textSecondary
              : AppColors.alertRed,
        ),
      );
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
      case 'VITAL_ANOMALY':
        return Icons.monitor_heart;
      case 'EMERGENCY_ALERT':
        return Icons.emergency;
      default:
        return Icons.notifications;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
