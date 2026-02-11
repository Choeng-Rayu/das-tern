import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Displays the generated connection token as a QR code + text code.
/// Patient shows this to caregiver to scan.
class TokenDisplayScreen extends StatefulWidget {
  const TokenDisplayScreen({super.key});

  @override
  State<TokenDisplayScreen> createState() => _TokenDisplayScreenState();
}

class _TokenDisplayScreenState extends State<TokenDisplayScreen> {
  bool _isGenerating = true;
  String? _token;
  DateTime? _expiresAt;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token == null && _error == null) {
      _generateToken();
    }
  }

  Future<void> _generateToken() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final permissionLevel = args?['permissionLevel'] ?? 'REQUEST';

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final provider = context.read<ConnectionProvider>();
      final result = await provider.generateToken(permissionLevel);
      if (result != null && mounted) {
        setState(() {
          _token = result['token'];
          _expiresAt = result['expiresAt'] != null
              ? DateTime.parse(result['expiresAt'])
              : DateTime.now().add(const Duration(hours: 24));
          _isGenerating = false;
        });
      } else if (mounted) {
        setState(() {
          _error = provider.error ?? 'Failed to generate token';
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isGenerating = false;
        });
      }
    }
  }

  String get _timeRemaining {
    if (_expiresAt == null) return '';
    final diff = _expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('កូដតភ្ជាប់'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _isGenerating
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState(context)
                  : _buildTokenDisplay(context),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.alertRed),
          const SizedBox(height: AppSpacing.md),
          Text(
            'មិនអាចបង្កើតកូដ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: 'ព្យាយាមម្តងទៀត',
            onPressed: _generateToken,
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDisplay(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          // QR Code
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
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
                QrImageView(
                  data: _token ?? '',
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.darkBlue,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.neutral300)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'ឬប្រើកូដ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.neutral300)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Text token
                GestureDetector(
                  onTap: () => _copyToken(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _token ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppColors.primaryBlue,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.copy,
                            size: 20, color: AppColors.primaryBlue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _timeRemaining,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Instructions
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ការណែនាំ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStep(context, '1', 'បើកកម្មវិធីនៅលើទូរស័ព្ទគ្រួសារ'),
                _buildStep(context, '2', 'ចុច "ស្កេនកូដ QR" ឬ "បញ្ចូលកូដ"'),
                _buildStep(context, '3', 'ស្កេនកូដ QR នេះ ឬបញ្ចូលកូដ'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Share button
          PrimaryButton(
            text: 'ចែករំលែកកូដ',
            icon: Icons.share,
            onPressed: () {
              Share.share('កូដតភ្ជាប់ DasTern: $_token');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            text: 'បង្កើតកូដថ្មី',
            icon: Icons.refresh,
            isOutlined: true,
            onPressed: _generateToken,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToken() {
    if (_token != null) {
      Clipboard.setData(ClipboardData(text: _token!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('កូដត្រូវបានចម្លង')),
      );
    }
  }
}
