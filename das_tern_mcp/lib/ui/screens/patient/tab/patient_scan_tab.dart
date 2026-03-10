import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../providers/subscription_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../../utils/app_router.dart';
import '../../../widgets/common_widgets.dart';

/// Scan Prescription tab – captures/picks prescription image, extracts via OCR,
/// then navigates to an editable preview screen before saving.
class PatientScanTab extends StatefulWidget {
  const PatientScanTab({super.key});

  @override
  State<PatientScanTab> createState() => _PatientScanTabState();
}

class _PatientScanTabState extends State<PatientScanTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _scanImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final subscription = context.read<SubscriptionProvider>();

    // Check if user has OCR access (Premium only)
    if (!subscription.hasOcrAccess) {
      _showUpgradeDialog();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final bytes = await image.readAsBytes();

      // Ensure filename has a valid image extension
      String filename = image.name;
      final knownExts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
      final hasValidExt =
          filename.contains('.') &&
          knownExts.contains(filename.toLowerCase().split('.').last);

      if (!hasValidExt) {
        String ext = 'jpg';
        if (bytes.length >= 4) {
          if (bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47) {
            ext = 'png';
          } else if (bytes.length >= 12 &&
              bytes[8] == 0x57 &&
              bytes[9] == 0x45 &&
              bytes[10] == 0x42 &&
              bytes[11] == 0x50) {
            ext = 'webp';
          } else if (bytes[0] == 0x25 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x44 &&
              bytes[3] == 0x46) {
            ext = 'pdf';
          }
        }

        final mime = image.mimeType;
        if (mime != null) {
          if (mime.contains('png')) {
            ext = 'png';
          } else if (mime.contains('webp')) {
            ext = 'webp';
          } else if (mime.contains('pdf')) {
            ext = 'pdf';
          }
        }

        final baseName = filename.replaceAll(RegExp(r'[^\w]'), '_');
        filename = '$baseName.$ext';
      }

      // Use extract (preview only) instead of scan (auto-save)
      final result = await ApiService.instance.extractPrescription(
        bytes.toList(),
        filename,
      );

      if (!mounted) return;

      // Log OCR result metadata for debugging
      debugPrint('[Scan] OCR result keys: ${result.keys.toList()}');
      debugPrint('[Scan] ai_status: ${result['ai_status']}');
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final prescription = data['prescription'] as Map<String, dynamic>? ?? {};
      final medications =
          prescription['medications'] as Map<String, dynamic>? ?? {};
      final items = medications['items'] as List<dynamic>? ?? [];
      debugPrint('[Scan] Medications found: ${items.length}');

      setState(() => _isProcessing = false);

      // Navigate to editable preview screen with extracted data
      Navigator.pushNamed(context, AppRouter.ocrPreview, arguments: result);
    } catch (e) {
      if (!mounted) return;
      final isTimeout =
          e.toString().toLowerCase().contains('timed out') ||
          e.toString().contains('504');
      setState(() {
        _isProcessing = false;
        _errorMessage = isTimeout
            ? 'Scan timed out — the server took too long. Please check your connection and try again.'
            : e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTimeout ? 'Scan timed out. Please try again.' : l10n.scanFailed,
          ),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  void _showSourcePicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.scanFromCamera),
              onTap: () {
                Navigator.pop(ctx);
                _scanImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.scanFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _scanImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.premiumFeature,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ocrPremiumMessage, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.document_scanner_outlined,
              l10n.unlimitedOcrScanning,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.family_restroom_outlined,
              l10n.connectFamilyMembers,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.storage_outlined, l10n.twentyGBStorage),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.support_agent_outlined,
              l10n.prioritySupport,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryBlue,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.freeTrialOffer,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.subscriptionUpgrade);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primaryBlue.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        AppHeader(title: l10n.scanPrescriptionTitle),
        Expanded(
          child: Center(
            child: _isProcessing
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.scanProcessing,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            size: 64,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.scanPrescriptionTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: Text(
                            l10n.scanPrescriptionDescription,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ElevatedButton.icon(
                          onPressed: _showSourcePicker,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(l10n.openScanner),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            child: Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.alertRed),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
