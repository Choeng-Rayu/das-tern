import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

              // ── Pay with Banking App button ──
              if (status == 'PENDING' && sub.deepLink != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.account_balance, size: 22),
                    label: Text(
                      l10n.payWithBankingApp,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003D99),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _BankChooserSheet(
                          deepLink: sub.deepLink!,
                        ),
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

// ─── Known Cambodian Banking App Data ───
/// Each entry maps a bank name to its Android package ID for installation
/// detection and deep-link routing.
class _KhBankInfo {
  final String name;
  final String packageAndroid;
  final Color color;
  final String initial;

  const _KhBankInfo({
    required this.name,
    required this.packageAndroid,
    required this.color,
    required this.initial,
  });
}

const List<_KhBankInfo> _khBanks = [
  _KhBankInfo(
    name: 'ABA Bank',
    packageAndroid: 'com.ababank.abaapp',
    color: Color(0xFF003D99),
    initial: 'A',
  ),
  _KhBankInfo(
    name: 'ACLEDA Bank',
    packageAndroid: 'com.aceleda.mobilebanking',
    color: Color(0xFF006B3F),
    initial: 'AC',
  ),
  _KhBankInfo(
    name: 'Wing Money',
    packageAndroid: 'com.wingmoney.wingapp',
    color: Color(0xFFE5242B),
    initial: 'W',
  ),
  _KhBankInfo(
    name: 'NBC Bakong',
    packageAndroid: 'kh.gov.nbc.bakong',
    color: Color(0xFF003087),
    initial: 'BK',
  ),
  _KhBankInfo(
    name: 'LOLC Cambodia',
    packageAndroid: 'com.lolc.lolcdigital',
    color: Color(0xFFE31837),
    initial: 'L',
  ),
  _KhBankInfo(
    name: 'Canadia Bank',
    packageAndroid: 'com.canadiabank.mobilebank',
    color: Color(0xFF006233),
    initial: 'CB',
  ),
  _KhBankInfo(
    name: 'Chip Mong Bank',
    packageAndroid: 'com.chipmongbank.mobileapp',
    color: Color(0xFF0070C0),
    initial: 'CM',
  ),
];

// ─── Bank Chooser Bottom Sheet ───
/// Bottom sheet that detects which KHQR-compatible banking apps are installed
/// on the device and lists only those.
///
/// Detection uses a MAIN+LAUNCHER intent URI — the most reliable way to test
/// for a specific Android package when the package is declared in the app's
/// <queries> manifest block.
///
/// When the user taps a bank, the Bakong payment deep-link is routed directly
/// into that bank's package via an Android intent URI:
///   intent://HOST/PATH#Intent;scheme=https;package=PKG;action=VIEW;end
///
/// This bypasses Android's default App-Link resolution (which would always
/// pick NBC Bakong as the verified handler) and sends the payment context to
/// the user-chosen bank. The bank app opens with the amount pre-loaded and
/// the user only needs to enter their PIN.
class _BankChooserSheet extends StatefulWidget {
  final String deepLink;

  const _BankChooserSheet({required this.deepLink});

  @override
  State<_BankChooserSheet> createState() => _BankChooserSheetState();
}

class _BankChooserSheetState extends State<_BankChooserSheet> {
  String? _loadingBank;
  List<_KhBankInfo> _installedBanks = [];
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkInstalledBanks();
  }

  /// Uses MAIN+LAUNCHER intent — the most reliable way to detect whether
  /// an Android package is installed (requires <queries> in AndroidManifest).
  Future<void> _checkInstalledBanks() async {
    final installed = <_KhBankInfo>[];
    for (final bank in _khBanks) {
      try {
        final uri = Uri.parse(
          'intent:#Intent;'
          'action=android.intent.action.MAIN;'
          'category=android.intent.category.LAUNCHER;'
          'package=${bank.packageAndroid};'
          'end',
        );
        if (await canLaunchUrl(uri)) {
          installed.add(bank);
        }
      } catch (_) {
        // skip
      }
    }
    if (mounted) {
      setState(() {
        _installedBanks = installed;
        _checking = false;
      });
    }
  }

  /// Opens the selected bank with the payment pre-loaded.
  ///
  /// For every bank we build an Android intent URI that routes the Bakong
  /// deep-link URL directly into that bank's package:
  ///   intent://HOST/PATH#Intent;scheme=https;package=PKG;action=VIEW;end
  ///
  /// Major Cambodian banks (ABA, ACLEDA, Wing, Bakong…) register as App-Link
  /// handlers for the `bakong-deeplink.nbc.gov.kh` domain, so the bank app
  /// receives the full payment context and the user only needs to enter their
  /// PIN. By passing the package explicitly we bypass Android's default
  /// single-app-link resolution and let the user's chosen bank handle it.
  Future<void> _openBank(_KhBankInfo bank) async {
    if (_loadingBank != null) return;
    setState(() => _loadingBank = bank.name);
    try {
      final deepLinkUri = Uri.parse(widget.deepLink);

      // Reconstruct host+path+query from the short link so we can embed them
      // in the intent URI.
      final pathAndQuery = deepLinkUri.hasQuery
          ? '${deepLinkUri.path}?${deepLinkUri.query}'
          : deepLinkUri.path;

      final intentUri = Uri.parse(
        'intent://${deepLinkUri.host}$pathAndQuery'
        '#Intent;'
        'scheme=https;'
        'action=android.intent.action.VIEW;'
        'package=${bank.packageAndroid};'
        'end',
      );

      final launched = await launchUrl(
        intentUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showError();
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _loadingBank = null);
    }
  }

  void _showError() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.bankNotInstalled),
        backgroundColor: AppColors.alertRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            l10n.selectYourBank,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.openInBankingApp,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),

          // Bank list
          if (_checking) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
          ] else if (_installedBanks.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No compatible banking apps found.\nInstall ABA, ACLEDA, Wing, or Bakong.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ] else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _installedBanks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final bank = _installedBanks[i];
                return _BankTile(
                  bank: bank,
                  isLoading: _loadingBank == bank.name,
                  disabled: _loadingBank != null && _loadingBank != bank.name,
                  onTap: () => _openBank(bank),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── Bank Tile ───
class _BankTile extends StatelessWidget {
  final _KhBankInfo bank;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _BankTile({
    required this.bank,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: disabled ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bank.color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          bank.initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        bank.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: disabled ? AppColors.neutralGray : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
              'Open and pay',
              style: TextStyle(
                fontSize: 11,
                color: disabled
                    ? AppColors.neutral300
                    : AppColors.textSecondary,
              ),
            ),
      trailing: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: disabled
                  ? AppColors.neutral300
                  : AppColors.textSecondary,
            ),
    );
  }
}
