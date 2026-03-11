import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/subscription_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Upgrade plan selection screen.
/// Shows current plan, feature comparison, and upgrade options.
class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _trialClaimed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubscriptionProvider>().loadSubscription();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = context.watch<SubscriptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPlans = sub.plans != null && sub.plans!.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          l10n.upgradePlan,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: Column(
        children: [
          // ── Error banner (non-blocking) ─────────────────────────────────
          if (sub.errorMessage != null && !sub.isLoading)
            Material(
              color: isDark ? const Color(0xFF2A1F1F) : const Color(0xFFFFF3F3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: Color(0xFFE53935),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sub.errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.alertRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context
                          .read<SubscriptionProvider>()
                          .loadSubscription(),
                      icon: sub.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(
                        l10n.retry,
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Loading indicator (thin bar, non-blocking) ──────────────────
          if (sub.isLoading) const LinearProgressIndicator(minHeight: 2),

          // ── Main scrollable content ─────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current plan card
                    _CurrentPlanCard(
                      tier: _trialClaimed ? 'PREMIUM' : sub.currentTier,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Claim Free Trial button (only for Freemium users who haven't claimed)
                    if (!_trialClaimed)
                      _ClaimTrialButton(
                        isDark: isDark,
                        onClaimed: () {
                          setState(() => _trialClaimed = true);
                        },
                      ),

                    // Trial status banner (after claim or actual trial)
                    if (_trialClaimed || sub.isOnTrial) ...[
                      const SizedBox(height: AppSpacing.md),
                      _TrialBanner(
                        daysRemaining: _trialClaimed
                            ? 30
                            : sub.trialDaysRemaining,
                        expiresAt: _trialClaimed
                            ? DateTime.now().add(const Duration(days: 30))
                            : sub.trialExpiresAt!,
                        isDark: isDark,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Section title
                    Text(
                      l10n.choosePlan,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Plan cards – from backend or static fallback
                    if (hasPlans)
                      ...sub.plans!.map(
                        (plan) => _PlanCard(
                          plan: plan,
                          isCurrentPlan: sub.currentTier == plan['id'],
                          isRecommended: plan['isRecommended'] ?? false,
                          isDark: isDark,
                          onUpgrade: () {
                            Navigator.pushNamed(
                              context,
                              '/subscription/payment-method',
                              arguments: {'planType': plan['id'], 'plan': plan},
                            );
                          },
                        ),
                      )
                    else
                      ..._defaultPlanCards(sub.currentTier, isDark),

                    const SizedBox(height: AppSpacing.xl),

                    // Feature comparison
                    _FeatureComparisonSection(
                      currentTier: sub.currentTier,
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _defaultPlanCards(String currentTier, bool isDark) {
    return [
      _PlanCard(
        plan: const {
          'id': 'PREMIUM',
          'name': 'Premium',
          'price': 0.5,
          'currency': 'USD',
          'period': 'month',
          'priceOptions': [
            {'price': 0.5, 'period': 'month', 'display': '\$0.5/month'},
            {'price': 1.0, 'period': '3months', 'display': '\$1/3 months'},
          ],
          'features': [
            'Unlimited manual prescriptions',
            'Unlimited OCR scanning',
            'Connect up to 5 family members',
            '20 GB storage',
            'Priority support',
            '1-month free trial',
          ],
        },
        isCurrentPlan: currentTier == 'PREMIUM',
        isRecommended: true,
        isDark: isDark,
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
                'priceOptions': [
                  {'price': 0.5, 'period': 'month', 'display': '\$0.5/month'},
                  {
                    'price': 1.0,
                    'period': '3months',
                    'display': '\$1/3 months',
                  },
                ],
              },
            },
          );
        },
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Current Plan Card ──────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
class _CurrentPlanCard extends StatelessWidget {
  final String tier;
  final bool isDark;

  const _CurrentPlanCard({required this.tier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = tier == 'PREMIUM' || tier == 'FAMILY_PREMIUM';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFF6B4AA3), const Color(0xFF2D5BFF)]
              : [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withValues(alpha: 0.7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? const Color(0xFF667EEA) : AppColors.primaryBlue)
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
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
                l10n.currentPlan,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
              l10n.upgradeToUnlock,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Plan Card ──────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isCurrentPlan;
  final bool isRecommended;
  final bool isDark;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isRecommended,
    required this.isDark,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.currentLabel,
                      style: const TextStyle(
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
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  child: Text(
                    l10n.upgradeNow,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Feature Comparison Section ────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
class _FeatureComparisonSection extends StatelessWidget {
  final String currentTier;
  final bool isDark;

  const _FeatureComparisonSection({
    required this.currentTier,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.featureComparison,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _comparisonRow(
                context,
                l10n.prescriptionsFeature,
                '1',
                '\u221e',
                '\u221e',
              ),
              const Divider(height: 1),
              _comparisonRow(
                context,
                l10n.medicinesFeature,
                '3',
                '\u221e',
                '\u221e',
              ),
              const Divider(height: 1),
              _comparisonRow(context, l10n.familyLinksFeature, '1', '5', '10'),
              const Divider(height: 1),
              _comparisonRow(
                context,
                l10n.storageFeature,
                '5 GB',
                '20 GB',
                '20 GB',
              ),
              const Divider(height: 1),
              _comparisonRow(
                context,
                l10n.prioritySupportFeature,
                '\u2715',
                '\u2713',
                '\u2713',
              ),
              const Divider(height: 1),
              _comparisonRow(
                context,
                l10n.familyPlanFeature,
                '\u2715',
                '\u2715',
                '\u2713 (3)',
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              family,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for claiming free trial offer
class _ClaimTrialButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onClaimed;

  const _ClaimTrialButton({required this.isDark, this.onClaimed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            l10n.claimYourFreeTrial,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.getOneMonthFreePremiumAccess,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : null,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClaimed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: Text(l10n.claimTrial),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying trial banner
class _TrialBanner extends StatelessWidget {
  final int daysRemaining;
  final DateTime expiresAt;
  final bool isDark;

  const _TrialBanner({
    required this.daysRemaining,
    required this.expiresAt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: isDark ? 0.35 : 0.2),
            AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                l10n.premiumTrialActive,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.trialDaysRemainingBanner(daysRemaining),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : null,
            ),
          ),
        ],
      ),
    );
  }
}
