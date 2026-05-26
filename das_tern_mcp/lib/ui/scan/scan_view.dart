import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:das_tern_mcp/core/widgets/app_button.dart';
import 'package:das_tern_mcp/core/widgets/app_error_view.dart';
import 'package:das_tern_mcp/core/widgets/app_loading.dart';
import 'package:das_tern_mcp/core/widgets/app_scaffold.dart';
import 'package:das_tern_mcp/ui/scan/scan_viewmodel.dart';
import 'package:das_tern_mcp/ui/theme/app_colors.dart';
import 'package:das_tern_mcp/ui/theme/app_spacing.dart';

class ScanView extends StatelessWidget {
  const ScanView({
    super.key,
    required this.viewModel,
    this.onResultReady,
  });
  final ScanViewModel viewModel;
  final VoidCallback? onResultReady;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        if (vm.isLoading) {
          return const AppScaffold(
            title: 'Scan Prescription',
            currentIndex: 2,
            showBottomNav: false,
            body: AppLoadingView(),
          );
        }
        if (vm.hasError) {
          return AppScaffold(
            title: 'Scan Prescription',
            currentIndex: 2,
            showBottomNav: false,
            body: AppErrorView(
              message: vm.errorMessage ?? 'Scan failed.',
              onRetry: vm.startScan,
            ),
          );
        }
        return AppScaffold(
          title: 'Scan Prescription',
          currentIndex: 2,
          showBottomNav: false,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImagePreview(imagePath: vm.capturedImagePath),
                const SizedBox(height: AppSpacing.lg),
                if (vm.ocrResult != null) ...[
                  Text(
                    'Detected Text',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.neutral400.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(vm.ocrResult!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Review Results',
                    isFullWidth: true,
                    onPressed: onResultReady,
                  ),
                ] else ...[
                  AppButton(
                    label: 'Take Photo',
                    isFullWidth: true,
                    icon: Icons.camera_alt,
                    onPressed: () => _pickImage(context, ImageSource.camera, vm),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Upload from Gallery',
                    isFullWidth: true,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.photo_library,
                    onPressed: () =>
                        _pickImage(context, ImageSource.gallery, vm),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
      BuildContext context, ImageSource source, ScanViewModel vm) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) {
      await vm.processImage(file.path);
    }
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.imagePath});
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.neutral400.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.neutral400.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner,
                  size: 48, color: AppColors.primaryBlue),
              SizedBox(height: AppSpacing.sm),
              Text('No image selected'),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath!),
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(height: 200),
      ),
    );
  }
}
