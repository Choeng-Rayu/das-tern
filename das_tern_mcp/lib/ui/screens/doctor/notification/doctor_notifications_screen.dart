import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/connection_model/connection.dart';
import '../../../../models/notification_model/notification.dart';
import '../../../../providers/connection_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../patient/notification/connection_request_card.dart';
import '../../patient/notification/connection_request_sheet.dart';
import '../../patient/notification/standard_notification_card.dart';

/// Doctor notification screen.
///
/// Uses a single [CustomScrollView] for all states so the viewport never
/// becomes null — same architecture as the patient notification screen.
class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() =>
      _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState
    extends State<DoctorNotificationsScreen> {
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().fetchNotifications();
      context.read<ConnectionProvider>().fetchConnections();
    });
  }

  // ── Helpers ──

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

  void _openConnectionSheet(AppNotification notif) {
    final connectionId = notif.metadata?['connectionId'] as String?;
    if (connectionId == null) return;
    showConnectionRequestSheet(
      context: context,
      notif: notif,
      connectionId: connectionId,
      connection: _findConnection(notif),
      processingIds: _processingIds,
      onApprove: _handleApprove,
      onReject: _handleReject,
    );
  }

  Future<void> _handleApprove(AppNotification notif, String id) async {
    if (!mounted) return;
    setState(() => _processingIds.add(id));

    final connProv = context.read<ConnectionProvider>();
    final notifProv = context.read<NotificationProvider>();

    final success =
        await connProv.acceptConnection(id, {'permissionLevel': 'ALLOWED'});

    if (!notif.isRead) await notifProv.markAsRead(notif.id);
    await notifProv.fetchNotifications();
    if (mounted) await context.read<ConnectionProvider>().fetchConnections();

    if (mounted) {
      setState(() => _processingIds.remove(id));
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? l10n.connectionApproved : (connProv.error ?? 'Error')),
          backgroundColor:
              success ? AppColors.successGreen : AppColors.alertRed,
        ),
      );
    }
  }

  Future<void> _handleReject(AppNotification notif, String id) async {
    if (!mounted) return;
    setState(() => _processingIds.add(id));

    final connProv = context.read<ConnectionProvider>();
    final notifProv = context.read<NotificationProvider>();

    final success = await connProv.revokeConnection(id);

    if (!notif.isRead) await notifProv.markAsRead(notif.id);
    await notifProv.fetchNotifications();
    if (mounted) await context.read<ConnectionProvider>().fetchConnections();

    if (mounted) {
      setState(() => _processingIds.remove(id));
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? l10n.connectionRejected : (connProv.error ?? 'Error')),
          backgroundColor:
              success ? AppColors.textSecondary : AppColors.alertRed,
        ),
      );
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifProv = context.watch<NotificationProvider>();
    context.watch<ConnectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (notifProv.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.alertRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notifProv.unreadCount}',
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
          await notifProv.fetchNotifications();
          if (!context.mounted) return;
          await context.read<ConnectionProvider>().fetchConnections();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: _buildSlivers(notifProv, l10n),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(
      NotificationProvider provider, AppLocalizations l10n) {
    if (provider.isLoading && !provider.hasFetched) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.alertRed),
                const SizedBox(height: AppSpacing.md),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
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
      ];
    }

    if (provider.notifications.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 64, color: AppColors.neutral300),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.noNotifications,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.md),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final notif = provider.notifications[index];
              final child = notif.type == 'CONNECTION_REQUEST'
                  ? _connectionCard(notif)
                  : StandardNotificationCard(notif: notif);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _dismissible(notif, child),
              );
            },
            childCount: provider.notifications.length,
          ),
        ),
      ),
    ];
  }

  Widget _connectionCard(AppNotification notif) {
    final connection = _findConnection(notif);
    final connectionId = notif.metadata?['connectionId'] as String?;
    return ConnectionRequestCard(
      notif: notif,
      connection: connection,
      connectionId: connectionId,
      isProcessing: _processingIds.contains(connectionId),
      onTap: connectionId != null ? () => _openConnectionSheet(notif) : null,
      onApprove: connectionId != null
          ? () => _handleApprove(notif, connectionId)
          : null,
      onReject: connectionId != null
          ? () => _handleReject(notif, connectionId)
          : null,
    );
  }

  Widget _dismissible(AppNotification notif, Widget child) {
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
                child: Text(l10n.remove,
                    style: const TextStyle(color: AppColors.alertRed)),
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
}
