import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Upgrade plan selection screen.
/// Shows current plan, feature comparison, and upgrade options.
class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<SubscriptionProvider>().loadSubscription(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
        centerTitle: true,
      ),
      body: sub.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current plan card
                  _CurrentPlanCard(tier: sub.currentTier, isDark: isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Section title
                  Text(
                    'Choose a Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Plan cards
                  if (sub.plans != null)
                    ...sub.plans!.map((plan) => _PlanCard(
                          plan: plan,
                          isCurrentPlan: sub.currentTier == plan['id'],
                          onUpgrade: () {
                            Navigator.pushNamed(
                              context,
                              '/subscription/payment-method',
                              arguments: {'planType': plan['id'], 'plan': plan},
                            );
                          },
                        )),

                  if (sub.plans == null || sub.plans!.isEmpty)
                    ..._defaultPlanCards(sub.currentTier),

                  const SizedBox(height: AppSpacing.lg),

                  // Feature comparison
                  _FeatureComparisonTable(currentTier: sub.currentTier),
                ],
              ),
            ),
    );
  }

  List<Widget> _defaultPlanCards(String currentTier) {
    return [
      _PlanCard(
        plan: const {
          'id': 'PREMIUM',
          'name': 'Premium',
          'price': 0.5,
          'currency': 'USD',
          'period': 'month',
          'features': [
            'Unlimited prescriptions',
            'Unlimited medicines',
            'Up to 5 family connections',
            '20 GB storage',
            'Priority support',
          ],
        },
        isCurrentPlan: currentTier == 'PREMIUM',
        onUpgrade: () {
          Navigator.pushNamed(
            context,
            '/subscription/payment-method',
            arguments: {
              'planType': 'PREMIUM',
              'plan': {
                'id': 'PREMIUM',
                'name': 'Premium',
                'price': 0.5,
                'currency': 'USD',
                'period': 'month',
              },
            },
          );
        },
      ),
      const SizedBox(height: AppSpacing.md),
      _PlanCard(
        plan: const {
          'id': 'FAMILY_PREMIUM',
          'name': 'Family Premium',
          'price': 1.0,
          'currency': 'USD',
          'period': 'month',
          'features': [
            'All Premium features',
            'Up to 10 family connections',
            'Family plan (up to 3 members)',
            '20 GB storage per member',
            'Priority family support',
          ],
        },
        isCurrentPlan: currentTier == 'FAMILY_PREMIUM',
        onUpgrade: () {
          Navigator.pushNamed(
            context,
            '/subscription/payment-method',
            arguments: {
              'planType': 'FAMILY_PREMIUM',
              'plan': {
                'id': 'FAMILY_PREMIUM',
                'name': 'Family Premium',
                'price': 1.0,
                'currency': 'USD',
                'period': 'month',
              },
            },
          );
        },
      ),
    ];
  }
}

// ─── Current Plan Card ───
class _CurrentPlanCard extends StatelessWidget {
  final String tier;
  final bool isDark;

  const _CurrentPlanCard({required this.tier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPremium = tier == 'PREMIUM' || tier == 'FAMILY_PREMIUM';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFF6B4AA3), const Color(0xFF2D5BFF)]
              : [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.diamond : Icons.star_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Plan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tier.replaceAll('_', ' '),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 4),
            Text(
              'Upgrade to unlock all features',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Plan Card ───
class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isCurrentPlan;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final features = (plan['features'] as List?)?.cast<String>() ?? [];
    final price = plan['price'] ?? 0;

    return Card(
      elevation: isCurrentPlan ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentPlan
            ? const BorderSide(color: AppColors.successGreen, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '\$$price',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                  ),
                  TextSpan(
                    text: ' /${plan['period'] ?? 'month'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            if (!isCurrentPlan)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Comparison Table ───
class _FeatureComparisonTable extends StatelessWidget {
  final String currentTier;

  const _FeatureComparisonTable({required this.currentTier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _comparisonRow(context, 'Prescriptions', '1', '∞', '∞'),
              const Divider(height: 1),
              _comparisonRow(context, 'Medicines', '3', '∞', '∞'),
              const Divider(height: 1),
              _comparisonRow(context, 'Family Links', '1', '5', '10'),
              const Divider(height: 1),
              _comparisonRow(context, 'Storage', '5 GB', '20 GB', '20 GB'),
              const Divider(height: 1),
              _comparisonRow(context, 'Priority Support', '✕', '✓', '✓'),
              const Divider(height: 1),
              _comparisonRow(context, 'Family Plan', '✕', '✕', '✓ (3)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonRow(
    BuildContext context,
    String feature,
    String free,
    String premium,
    String family,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: currentTier == 'FREEMIUM' ? FontWeight.bold : FontWeight.normal,
                color: currentTier == 'FREEMIUM' ? AppColors.primaryBlue : null,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: currentTier == 'PREMIUM' ? FontWeight.bold : FontWeight.normal,
                color: currentTier == 'PREMIUM' ? AppColors.primaryBlue : null,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              family,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: currentTier == 'FAMILY_PREMIUM' ? FontWeight.bold : FontWeight.normal,
                color: currentTier == 'FAMILY_PREMIUM' ? AppColors.primaryBlue : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
