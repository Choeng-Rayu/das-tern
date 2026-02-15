import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Scan Prescription tab – captures/picks prescription image and sends to OCR.
/// Matches Figma center tab: ស្កេនវេជ្ជបញ្ជា
class PatientScanTab extends StatefulWidget {
  const PatientScanTab({super.key});

  @override
  State<PatientScanTab> createState() => _PatientScanTabState();
}

class _PatientScanTabState extends State<PatientScanTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  Map<String, dynamic>? _lastResult;
  String? _errorMessage;

  Future<void> _scanImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;

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
        _lastResult = null;
      });

      final bytes = await image.readAsBytes();
      final result = await ApiService.instance.scanPrescription(
        bytes.toList(),
        image.name,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _lastResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scanSuccess),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scanFailed),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanPrescriptionTitle),
        automaticallyImplyLeading: false,
      ),
      body: Center(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl),
                      child: Text(
                        l10n.scanPrescriptionDescription,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
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
                    if (_lastResult != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildResultSummary(),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
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
    );
  }

  Widget _buildResultSummary() {
    final summary = _lastResult?['ocr_summary'] as Map<String, dynamic>?;
    if (summary == null) return const SizedBox.shrink();

    final medCount = summary['total_medications'] ?? 0;
    final confidence = ((summary['confidence_score'] ?? 0) * 100).toInt();
    final needsReview = summary['needs_review'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  needsReview ? Icons.warning_amber : Icons.check_circle,
                  color: needsReview
                      ? AppColors.warningOrange
                      : AppColors.successGreen,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$medCount medications found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Confidence: $confidence%',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
