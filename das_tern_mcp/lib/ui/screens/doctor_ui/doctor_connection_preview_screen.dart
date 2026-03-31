import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/connection_model/connection.dart';
import '../../../models/enums_model/enums.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Preview screen shown to doctors after scanning a patient's QR code.
/// Displays patient info and permission level before confirming connection.
class DoctorConnectionPreviewScreen extends StatefulWidget {
  const DoctorConnectionPreviewScreen({super.key});

  @override
  State<DoctorConnectionPreviewScreen> createState() =>
      _DoctorConnectionPreviewScreenState();
}

class _DoctorConnectionPreviewScreenState
    extends State<DoctorConnectionPreviewScreen> {
  bool _isLoading = true;
  bool _isConsuming = false;
  Map<String, dynamic>? _tokenData;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tokenData == null && _error == null && _isLoading) {
      _validateToken();
    }
  }

  Future<void> _validateToken() async {
    final l10n = AppLocalizations.of(context)!;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final token = args?['token'] as String?;

    if (token == null || token.isEmpty) {
      setState(() {
        _error = l10n.invalidToken;
        _isLoading = false;
      });
      return;
    }

    try {
      final provider = context.read<ConnectionProvider>();
      final result = await provider.validateToken(token);
      if (mounted) {
        if (result != null && result['valid'] == true) {
          setState(() {
            _tokenData = result;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = _getErrorMessage(result, l10n);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(Map<String, dynamic>? result, AppLocalizations l10n) {
    if (result == null) {
      return l10n.networkError;
    }
    final message = result['message'] as String?;
    final errorCode = result['errorCode'] as String?;

    // Handle specific error codes
    if (errorCode == 'TOKEN_EXPIRED') {
      return l10n.tokenExpiredMessage;
    } else if (errorCode == 'TOKEN_USED') {
      return l10n.tokenAlreadyUsed;
    } else if (errorCode == 'INVALID_TOKEN') {
      return l10n.invalidToken;
    }

    return message ?? l10n.tokenInvalidOrExpired;
  }

  Future<void> _consumeToken() async {
    final l10n = AppLocalizations.of(context)!;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final token = args?['token'] as String?;
    if (token == null) return;

    setState(() => _isConsuming = true);

    try {
      final provider = context.read<ConnectionProvider>();
      // Use generic consumeToken - backend determines connection type based on user's role
      final success = await provider.consumeToken(token);
      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          setState(() {
            _error = provider.error ?? l10n.failedToConnect;
            _isConsuming = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isConsuming = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.connectionRequestSent,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.patientNeedsToApprove,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: l10n.ok,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/doctor',
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connectionTitle),
        centerTitle: true,
        actions: const [LanguageSwitcherButton(lightBackground: true)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState(context)
              : _buildPreview(context),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.alertRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.alertRed,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.codeInvalid,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: l10n.retry,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final patientData = _tokenData?['patient'] ?? {};
    final patientName =
        '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
            .trim();
    final permLevel = _tokenData?['permissionLevel'] ?? 'REQUEST';
    final expiresAt = _tokenData?['expiresAt'] != null
        ? DateTime.parse(_tokenData!['expiresAt'])
        : null;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),

        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          l10n.codeValidTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Patient info card
        AppCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                patientName.isEmpty ? l10n.patient : patientName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoRow(
                context,
                Icons.shield_outlined,
                l10n.accessLevelTitle,
                Connection.permissionLevelToDisplay(_permFromString(permLevel)),
              ),
              if (expiresAt != null)
                _buildInfoRow(
                  context,
                  Icons.timer_outlined,
                  l10n.expiresLabel,
                  _formatExpiry(expiresAt),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Info notice about patient approval
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.connectionRequiresApproval,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Action buttons
        PrimaryButton(
          text: l10n.connectNow,
          isLoading: _isConsuming,
          onPressed: _consumeToken,
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          text: l10n.cancel,
          isOutlined: true,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(DateTime expiry) {
    final l10n = AppLocalizations.of(context)!;
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return l10n.tokenExpired;
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '$hours ${l10n.hoursUnit} $minutes ${l10n.minutesUnit}';
  }

  PermissionLevel _permFromString(String v) {
    switch (v) {
      case 'REQUEST':
        return PermissionLevel.request;
      case 'SELECTED':
        return PermissionLevel.selected;
      case 'ALLOWED':
        return PermissionLevel.allowed;
      default:
        return PermissionLevel.notAllowed;
    }
  }
}
