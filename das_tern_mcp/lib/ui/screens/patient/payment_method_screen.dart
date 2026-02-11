import 'package:flutter/material.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Payment method selection screen.
/// Shows available payment methods: Bakong (KHQR) and Visa/Mastercard (Coming Soon).
class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final planType = args['planType'] as String? ?? 'PREMIUM';
    final plan = args['plan'] as Map<String, dynamic>? ?? {};
    final planName = plan['name'] ?? planType.replaceAll('_', ' ');
    final price = plan['price'] ?? (planType == 'PREMIUM' ? 0.50 : 1.00);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            _OrderSummaryCard(planName: planName, price: price),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Bakong Payment (Available)
            _PaymentMethodCard(
              icon: Icons.qr_code_2,
              iconColor: const Color(0xFF0066CC),
              title: 'Bakong (KHQR)',
              subtitle: 'Pay with any Cambodian banking app',
              description: 'Scan QR code with ABA, ACLEDA, Wing, or any KHQR-supported bank',
              isAvailable: true,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/subscription/bakong-payment',
                  arguments: {
                    'planType': planType,
                    'plan': plan,
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Visa/Mastercard (Coming Soon)
            _PaymentMethodCard(
              icon: Icons.credit_card,
              iconColor: const Color(0xFF1A1F71),
              title: 'Visa / Mastercard',
              subtitle: 'International credit or debit card',
              description: 'Support for Visa, Mastercard, and other international cards',
              isAvailable: false,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Summary ───
class _OrderSummaryCard extends StatelessWidget {
  final String planName;
  final num price;

  const _OrderSummaryCard({required this.planName, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$planName Plan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '\$$price/month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Payment Method Card ───
class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Card(
        elevation: isAvailable ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isAvailable
              ? BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.2))
              : BorderSide(color: AppColors.neutral300),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAvailable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (!isAvailable) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Coming Soon',
                                    style: TextStyle(
                                      color: AppColors.warningOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isAvailable)
                      const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
