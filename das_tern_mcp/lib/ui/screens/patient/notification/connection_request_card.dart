import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enums_model/enums.dart';
import '../../../../models/notification_model/notification.dart';
import '../../../../models/connection_model/connection.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'notification_utils.dart';

/// Card widget for CONNECTION_REQUEST notifications.
/// Shows inline approve/reject buttons and is tappable to open detail sheet.
class ConnectionRequestCard extends StatelessWidget {
  final AppNotification notif;
  final Connection? connection;
  final String? connectionId;
  final bool isProcessing;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ConnectionRequestCard({
    super.key,
    required this.notif,
    required this.connection,
    required this.connectionId,
    required this.isProcessing,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = connection?.status == ConnectionStatus.pending;
    final isAccepted = connection?.status == ConnectionStatus.accepted;
    final isRevoked = connection?.status == ConnectionStatus.revoked;
    final showActions =
        (isPending || connection == null) && connectionId != null;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: connectionBorderColor(
              isPending: isPending,
              isAccepted: isAccepted,
            ),
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
              // Header row
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
                          timeAgo(notif.createdAt, context),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              // Inline action buttons
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(
                            l10n.rejectConnection,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.alertRed,
                            side: const BorderSide(color: AppColors.alertRed),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            l10n.approveConnection,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ] else if (isAccepted)
                statusBadge(
                  icon: Icons.check_circle,
                  color: AppColors.successGreen,
                  label: l10n.connectionApproved,
                )
              else if (isRevoked)
                statusBadge(
                  icon: Icons.cancel,
                  color: AppColors.alertRed,
                  label: l10n.connectionRejected,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
