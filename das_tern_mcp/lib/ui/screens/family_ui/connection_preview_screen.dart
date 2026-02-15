import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/connection_model/connection.dart';
import '../../../models/enums_model/enums.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Preview modal shown after scanning / entering a connection token.
/// Shows patient info and permission level before confirming.
class ConnectionPreviewScreen extends StatefulWidget {
  const ConnectionPreviewScreen({super.key});

  @override
  State<ConnectionPreviewScreen> createState() =>
      _ConnectionPreviewScreenState();
}

class _ConnectionPreviewScreenState extends State<ConnectionPreviewScreen> {
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
            _error = result?['message'] ?? l10n.tokenInvalidOrExpired;
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

  Future<void> _consumeToken() async {
    final l10n = AppLocalizations.of(context)!;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final token = args?['token'] as String?;
    if (token == null) return;

    setState(() => _isConsuming = true);

    try {
      final provider = context.read<ConnectionProvider>();
      final success = await provider.consumeToken(token);
      if (mounted) {
        if (success) {
          // Show success and go to family access list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.connectionSuccess),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/patient',
            (route) => false,
          );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connectionTitle),
        centerTitle: true,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                backgroundColor:
                    AppColors.primaryBlue.withValues(alpha: 0.1),
                child: const Icon(Icons.person,
                    size: 32, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                patientName.isEmpty ? l10n.patient : patientName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoRow(
                context,
                Icons.shield_outlined,
                l10n.accessLevelTitle,
                Connection.permissionLevelToDisplay(
                  _permFromString(permLevel),
                ),
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

        // Warning
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warningOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.warningOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 20, color: AppColors.warningOrange),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.connectionRequiresApproval,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warningOrange,
                      ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
