import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enums_model/enums.dart';
import '../../../../models/notification_model/notification.dart';
import '../../../../models/connection_model/connection.dart';
import '../../../../providers/notification_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'package:provider/provider.dart';
import 'notification_utils.dart';

/// Bottom sheet that shows connection request details with approve/reject.
void showConnectionRequestSheet({
  required BuildContext context,
  required AppNotification notif,
  required String connectionId,
  required Connection? connection,
  required Set<String> processingIds,
  required Future<void> Function(AppNotification, String) onApprove,
  required Future<void> Function(AppNotification, String) onReject,
}) {
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
          final isProcessing = processingIds.contains(connectionId);

          return SafeArea(
            child: Padding(
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
                  else if (isPending || connection == null)
                    ..._buildActionButtons(
                      l10n: l10n,
                      onApprove: () async {
                        setSheetState(() {});
                        await onApprove(notif, connectionId);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      onReject: () async {
                        setSheetState(() {});
                        await onReject(notif, connectionId);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    )
                  else if (isAccepted)
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
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

List<Widget> _buildActionButtons({
  required AppLocalizations l10n,
  required VoidCallback onApprove,
  required VoidCallback onReject,
}) {
  return [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onApprove,
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
        onPressed: onReject,
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
  ];
}
