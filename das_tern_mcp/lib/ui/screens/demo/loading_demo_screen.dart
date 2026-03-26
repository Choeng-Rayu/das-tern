import 'package:flutter/material.dart';
import '../../../services/loading_overlay_service.dart';
import '../../widgets/loading/health_loading_indicator.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Demo screen showcasing all variants of the health loading indicators.
///
/// This screen demonstrates:
/// - All four loading animation variants (heartbeat, pills, medical cross, progress ring)
/// - Different sizes (small, medium, large, xlarge)
/// - Fullscreen overlay usage
/// - Loading service integration
/// - Interactive buttons to test each variant
class LoadingDemoScreen extends StatefulWidget {
  const LoadingDemoScreen({super.key});

  @override
  State<LoadingDemoScreen> createState() => _LoadingDemoScreenState();
}

class _LoadingDemoScreenState extends State<LoadingDemoScreen> {
  HealthLoadingVariant _selectedVariant = HealthLoadingVariant.heartbeat;
  HealthLoadingSize _selectedSize = HealthLoadingSize.medium;
  bool _showMessage = true;

  String _getMessage(HealthLoadingVariant variant) {
    switch (variant) {
      case HealthLoadingVariant.heartbeat:
        return 'Monitoring your health...';
      case HealthLoadingVariant.pills:
        return 'Loading medications...';
      case HealthLoadingVariant.medicalCross:
        return 'Processing...';
      case HealthLoadingVariant.progressRing:
        return 'Please wait...';
    }
  }

  void _showOverlay(HealthLoadingVariant variant) {
    LoadingOverlayService.show(
      context,
      variant: variant,
      message: _getMessage(variant),
    );

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      LoadingOverlayService.hide();
    });
  }

  Future<void> _simulateAsyncOperation() async {
    await LoadingOverlayService.showWhile(
      context,
      future: Future.delayed(const Duration(seconds: 2)),
      variant: _selectedVariant,
      message: 'Simulating async operation...',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operation completed!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppHeader(title: 'Loading Indicators Demo', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            Text('Health Loading Indicators', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Interactive demo of all loading animation variants for the DasTern medication management app.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Live preview section
            AppCard(
              child: Column(
                children: [
                  Text('Live Preview', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.neutral200,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: HealthLoadingIndicator(
                        variant: _selectedVariant,
                        size: _selectedSize,
                        message: _showMessage
                            ? _getMessage(_selectedVariant)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Variant selector
            SectionGroup(
              title: 'Animation Variant',
              children: [
                _buildVariantOption(
                  HealthLoadingVariant.heartbeat,
                  'Heartbeat Pulse',
                  'ECG-style heartbeat with pulsing glow',
                  Icons.favorite,
                ),
                const Divider(height: 1),
                _buildVariantOption(
                  HealthLoadingVariant.pills,
                  'Rotating Pills',
                  'Pills orbiting around medical icon',
                  Icons.medication,
                ),
                const Divider(height: 1),
                _buildVariantOption(
                  HealthLoadingVariant.medicalCross,
                  'Medical Cross',
                  'Pulsing cross with shimmer particles',
                  Icons.local_hospital,
                ),
                const Divider(height: 1),
                _buildVariantOption(
                  HealthLoadingVariant.progressRing,
                  'Progress Ring',
                  'Circular progress with medical bag icon',
                  Icons.medical_services,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Size selector
            SectionGroup(
              title: 'Size',
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppSelectableChip(
                        label: 'Small',
                        selected: _selectedSize == HealthLoadingSize.small,
                        onTap: () => setState(
                          () => _selectedSize = HealthLoadingSize.small,
                        ),
                        variant: ChipVariant.outlined,
                      ),
                      AppSelectableChip(
                        label: 'Medium',
                        selected: _selectedSize == HealthLoadingSize.medium,
                        onTap: () => setState(
                          () => _selectedSize = HealthLoadingSize.medium,
                        ),
                        variant: ChipVariant.outlined,
                      ),
                      AppSelectableChip(
                        label: 'Large',
                        selected: _selectedSize == HealthLoadingSize.large,
                        onTap: () => setState(
                          () => _selectedSize = HealthLoadingSize.large,
                        ),
                        variant: ChipVariant.outlined,
                      ),
                      AppSelectableChip(
                        label: 'X-Large',
                        selected: _selectedSize == HealthLoadingSize.xlarge,
                        onTap: () => setState(
                          () => _selectedSize = HealthLoadingSize.xlarge,
                        ),
                        variant: ChipVariant.outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Options
            SectionGroup(
              title: 'Options',
              children: [
                SwitchListTile(
                  title: const Text('Show Message'),
                  subtitle: const Text('Display text below indicator'),
                  value: _showMessage,
                  onChanged: (value) => setState(() => _showMessage = value),
                  activeTrackColor: AppColors.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Fullscreen overlay demos
            SectionGroup(
              title: 'Fullscreen Overlay Examples',
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        text: 'Show Heartbeat Overlay',
                        icon: Icons.favorite,
                        onPressed: () =>
                            _showOverlay(HealthLoadingVariant.heartbeat),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        text: 'Show Pills Overlay',
                        icon: Icons.medication,
                        onPressed: () =>
                            _showOverlay(HealthLoadingVariant.pills),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        text: 'Show Medical Cross Overlay',
                        icon: Icons.local_hospital,
                        onPressed: () =>
                            _showOverlay(HealthLoadingVariant.medicalCross),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        text: 'Show Progress Ring Overlay',
                        icon: Icons.medical_services,
                        onPressed: () =>
                            _showOverlay(HealthLoadingVariant.progressRing),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Service integration demo
            SectionGroup(
              title: 'Loading Service Integration',
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'The LoadingOverlayService allows you to show loading states from anywhere in your app.',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        text: 'Simulate Async Operation',
                        icon: Icons.sync,
                        onPressed: _simulateAsyncOperation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // All variants showcase
            SectionGroup(
              title: 'All Variants (Inline)',
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _buildInlineExample(
                        'Heartbeat',
                        HealthLoadingVariant.heartbeat,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildInlineExample('Pills', HealthLoadingVariant.pills),
                      const SizedBox(height: AppSpacing.md),
                      _buildInlineExample(
                        'Medical Cross',
                        HealthLoadingVariant.medicalCross,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildInlineExample(
                        'Progress Ring',
                        HealthLoadingVariant.progressRing,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Usage example code
            SectionGroup(
              title: 'Usage Example',
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.neutral200,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '''// Simple usage
HealthLoadingIndicator()

// With custom variant
HealthLoadingIndicator(
  variant: HealthLoadingVariant.pills,
  size: HealthLoadingSize.large,
  message: 'Loading...',
)

// Fullscreen overlay
LoadingOverlayService.show(
  context,
  variant: HealthLoadingVariant.heartbeat,
  message: 'Processing...',
);

// Auto-hide after async operation
await LoadingOverlayService.showWhile(
  context,
  future: fetchData(),
  message: 'Loading data...',
);''',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isDarkMode
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantOption(
    HealthLoadingVariant variant,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedVariant == variant;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(description),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
          : null,
      onTap: () => setState(() => _selectedVariant = variant),
      selected: isSelected,
    );
  }

  Widget _buildInlineExample(String label, HealthLoadingVariant variant) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTypography.body)),
        Expanded(
          flex: 1,
          child: HealthLoadingIndicator.inline(
            variant: variant,
            size: HealthLoadingSize.medium,
          ),
        ),
      ],
    );
  }
}
