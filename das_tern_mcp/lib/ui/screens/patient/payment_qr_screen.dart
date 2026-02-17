import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/subscription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// QR code display screen with live payment status polling.
/// Shows the KHQR code, a countdown timer, and auto-navigates on payment success.
class PaymentQrScreen extends StatefulWidget {
  const PaymentQrScreen({super.key});

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = context.watch<SubscriptionProvider>();
    final status = sub.paymentStatus;

    // Auto-navigate on success
    if (status == 'PAID') {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/subscription/success');
        }
      });
    }

    return PopScope(
      canPop: status != 'PENDING',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showCancelDialog(context, sub);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.scanToPay),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(context, sub),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status indicator
              _StatusBanner(status: status),
              const SizedBox(height: AppSpacing.lg),

              // QR Code
              _QrCodeCard(qrCode: sub.qrCode, status: status),
              const SizedBox(height: AppSpacing.lg),

              // Polling indicator
              if (sub.isPolling)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    return Opacity(
                      opacity: 0.5 + (_pulseController.value * 0.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlue.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.waitingForPaymentEllipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              if (status == 'TIMEOUT' || status == 'FAILED' || status == 'EXPIRED') ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.tryAgain),
                    onPressed: () {
                      Navigator.of(context).popUntil(
                        (route) => route.settings.name == '/subscription/upgrade' || route.isFirst,
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.howToPay,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _instructionStep(l10n.howToPayStep1),
                    _instructionStep(l10n.howToPayStep2),
                    _instructionStep(l10n.howToPayStep3),
                    _instructionStep(l10n.howToPayStep4),
                    _instructionStep(l10n.howToPayStep5),
                  ],
                ),
              ),

              // Supported banks
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.supportedByAllKHQR,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _BankChip(name: 'ABA'),
                  _BankChip(name: 'ACLEDA'),
                  _BankChip(name: 'Wing'),
                  _BankChip(name: 'LOLC'),
                  _BankChip(name: 'Canadia'),
                  _BankChip(name: 'Bakong'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instructionStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, SubscriptionProvider sub) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelPayment),
        content: Text(
          l10n.cancelPaymentMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepWaiting),
          ),
          TextButton(
            onPressed: () {
              sub.resetPayment();
              Navigator.pop(ctx);
              Navigator.of(context).popUntil(
                (route) => route.settings.name == '/subscription/upgrade' || route.isFirst,
              );
            },
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.alertRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Status Banner ───
class _StatusBanner extends StatelessWidget {
  final String status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color color;
    final IconData icon;
    final String text;

    switch (status) {
      case 'PAID':
        color = AppColors.successGreen;
        icon = Icons.check_circle;
        text = l10n.paymentSuccessful;
      case 'FAILED':
        color = AppColors.alertRed;
        icon = Icons.error;
        text = l10n.paymentFailed;
      case 'TIMEOUT':
      case 'EXPIRED':
        color = AppColors.warningOrange;
        icon = Icons.timer_off;
        text = l10n.paymentExpired;
      default:
        color = AppColors.primaryBlue;
        icon = Icons.hourglass_top;
        text = l10n.waitingForPayment;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QR Code Card ───
class _QrCodeCard extends StatelessWidget {
  final String? qrCode;
  final String status;

  const _QrCodeCard({required this.qrCode, required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'PENDING' || status == '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (qrCode != null && isActive) ...[
            // Try to display QR as base64 image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildQrImage(qrCode!),
            ),
          ] else if (!isActive) ...[
            Icon(
              status == 'PAID' ? Icons.check_circle : Icons.cancel,
              size: 100,
              color: status == 'PAID' ? AppColors.successGreen : AppColors.neutralGray,
            ),
          ] else ...[
            const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'KHQR',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0066CC),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrImage(String qrData) {
    // qrData is the KHQR token string - generate QR code from it
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 250.0,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      padding: const EdgeInsets.all(16),
    );
  }
}

// ─── Bank Chip ───
class _BankChip extends StatelessWidget {
  final String name;

  const _BankChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
