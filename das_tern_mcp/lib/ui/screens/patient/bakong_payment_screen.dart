import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Bakong payment description screen with plan summary and upgrade button.
/// When user taps "Confirm & Get QR Code", creates payment and navigates to QR screen.
class BakongPaymentScreen extends StatelessWidget {
  const BakongPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final planType = args['planType'] as String? ?? 'PREMIUM';
    final plan = args['plan'] as Map<String, dynamic>? ?? {};
    final planName = plan['name'] ?? planType.replaceAll('_', ' ');
    final price = plan['price'] ?? (planType == 'PREMIUM' ? 0.50 : 1.00);
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakong Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bakong header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066CC), Color(0xFF004C99)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Bakong KHQR Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'National Bank of Cambodia',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Plan Summary
            Text(
              'Plan Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _summaryRow(context, 'Plan', planName),
                    const Divider(),
                    _summaryRow(context, 'Price', '\$$price USD'),
                    const Divider(),
                    _summaryRow(context, 'Billing', 'Monthly'),
                    const Divider(),
                    _summaryRow(context, 'Payment', 'Bakong KHQR'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // How it works
            Text(
              'How it Works',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _stepItem(context, '1', 'Click "Confirm & Get QR Code" below'),
            _stepItem(context, '2', 'Open your banking app (ABA, ACLEDA, Wing, etc.)'),
            _stepItem(context, '3', 'Scan the QR code displayed on screen'),
            _stepItem(context, '4', 'Confirm payment in your banking app'),
            _stepItem(context, '5', 'Your plan will be upgraded automatically'),

            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.successGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment is processed securely through the Bakong system by the National Bank of Cambodia.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.successGreen,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Error message
            if (sub.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sub.errorMessage!,
                  style: const TextStyle(color: AppColors.alertRed, fontSize: 13),
                ),
              ),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: sub.isLoading
                    ? null
                    : () async {
                        final success = await sub.createPayment(planType);
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            '/subscription/qr-code',
                            arguments: {'planType': planType, 'plan': plan},
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: sub.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm & Get QR Code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _stepItem(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
