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
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: AppColors.alertRed,
                    ),
                    const SizedBox(width: 12),
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
                        foregroundColor: AppColors.alertRed,
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

                    // Show trial period info if claimed/on trial, otherwise show plan selection
                    if (_trialClaimed || sub.isOnTrial)
                      _TrialPeriodInfo(
                        daysRemaining: _trialClaimed
                            ? 30
                            : sub.trialDaysRemaining,
                        expiresAt: _trialClaimed
                            ? DateTime.now().add(const Duration(days: 30))
                            : sub.trialExpiresAt!,
                        isDark: isDark,
                      )
                    else ...[
                      // Section header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.choosePlan,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.unlockPremiumFeatures,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Plan cards – from backend or static fallback
                      if (hasPlans)
                        ...sub.plans!.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key < sub.plans!.length - 1
                                  ? AppSpacing.md
                                  : 0,
                            ),
                            child: _PlanCard(
                              plan: entry.value,
                              isCurrentPlan:
                                  sub.currentTier == entry.value['id'],
                              isRecommended: entry.value['id'] == 'PREMIUM',
                              isDark: isDark,
                              onUpgrade: () {
                                Navigator.pushNamed(
                                  context,
                                  '/subscription/payment-method',
                                  arguments: {
                                    'planType': entry.value['id'],
                                    'plan': entry.value,
                                  },
                                );
                              },
                            ),
                          ),
                        )
                      else
                        ..._defaultPlanCards(sub.currentTier, isDark),
                    ],

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
              ? [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                  const Color(0xFFF093FB),
                ]
              : [AppColors.primaryBlue, const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? const Color(0xFF667EEA) : AppColors.primaryBlue)
                .withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPremium
                            ? Icons.workspace_premium
                            : Icons.star_border_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.currentPlan.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTierName(tier),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                if (!isPremium) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.upgradeToUnlock,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTierName(String tier) {
    return tier
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Trial Banner ────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A5F7A), const Color(0xFF2E8B57)]
              : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.premiumTrialActive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysRemaining > 0
                      ? '$daysRemaining ${daysRemaining == 1 ? l10n.dayRemaining : l10n.daysRemaining}'
                      : l10n.expiresToday,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.enjoyUnlimitedFeatures,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Claim Trial Button ─────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
class _ClaimTrialButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onClaimed;

  const _ClaimTrialButton({required this.isDark, this.onClaimed});

  @override
  State<_ClaimTrialButton> createState() => _ClaimTrialButtonState();
}

class _ClaimTrialButtonState extends State<_ClaimTrialButton> {
  bool _isClaiming = false;

  Future<void> _handleClaimTrial() async {
    if (_isClaiming) return;

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _PremiumTrialDialog(),
    );

    if (confirmed != true || !mounted) return;

    final l10n = AppLocalizations.of(context)!;

    // Claim success – update UI immediately
    widget.onClaimed?.call();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.trialClaimedSuccess),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isClaiming ? null : _handleClaimTrial,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.claimFreeTrial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.freeTrialOffer,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isClaiming)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
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
    final planName = plan['name'] ?? '';
    final isFamilyPlan = (plan['id'] as String).contains('FAMILY');
    final priceOptions = plan['priceOptions'] as List?;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.successGreen
              : (isRecommended
                    ? AppColors.primaryBlue.withOpacity(0.5)
                    : (isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE5E5E5))),
          width: isCurrentPlan ? 2.5 : (isRecommended ? 2 : 1),
        ),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          if (isRecommended && !isCurrentPlan)
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Recommended badge
          if (isRecommended && !isCurrentPlan)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, Color(0xFF5C7CFF)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Current plan badge
          if (isCurrentPlan)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.currentLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and plan name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isFamilyPlan
                              ? [
                                  const Color(0xFF667EEA),
                                  const Color(0xFF764BA2),
                                ]
                              : [
                                  AppColors.primaryBlue,
                                  const Color(0xFF5C7CFF),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isFamilyPlan
                                        ? const Color(0xFF667EEA)
                                        : AppColors.primaryBlue)
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFamilyPlan ? Icons.family_restroom : Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isFamilyPlan
                                ? 'Perfect for families'
                                : 'For individuals',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Price
                if (priceOptions != null && priceOptions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${(priceOptions[0]['price'] as num).toStringAsFixed((priceOptions[0]['price'] as num).truncateToDouble() == priceOptions[0]['price'] ? 1 : 2)}',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryBlue,
                                  height: 1,
                                  letterSpacing: -1,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '/${priceOptions[0]['period'] ?? 'month'}',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (priceOptions.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'or ${priceOptions[1]['display']}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryBlue,
                              height: 1,
                              letterSpacing: -1,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '/${plan['period'] ?? 'month'}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                        (isDark ? Colors.white : Colors.black).withOpacity(
                          0.05,
                        ),
                        (isDark ? Colors.white : Colors.black).withOpacity(0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Features
                ...features.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < features.length - 1 ? 14 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.successGreen,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Upgrade button
                if (!isCurrentPlan)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onUpgrade,
                      style:
                          ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                          ).copyWith(
                            elevation:
                                MaterialStateProperty.resolveWith<double>((
                                  states,
                                ) {
                                  if (states.contains(MaterialState.pressed))
                                    return 0;
                                  return 4;
                                }),
                          ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.upgradeNow,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.featureComparison,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Compare all features across tiers',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Comparison table
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252525)
                      : const Color(0xFFF8F9FD),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'FEATURES',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _tierHeaderBadge(
                        context,
                        'FREE',
                        currentTier == 'FREEMIUM',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _tierHeaderBadge(
                        context,
                        'PREMIUM',
                        currentTier == 'PREMIUM',
                      ),
                    ),
                  ],
                ),
              ),

              // Feature rows
              _comparisonRow(
                context,
                Icons.edit_outlined,
                'Manual Input',
                true,
                true,
              ),
              _divider(),
              _comparisonRow(
                context,
                Icons.document_scanner_outlined,
                'OCR Scanning',
                null,
                '\u221e',
              ),
              _divider(),
              _comparisonRow(
                context,
                Icons.notifications_outlined,
                'Reminders',
                true,
                true,
              ),
              _divider(),
              _comparisonRow(
                context,
                Icons.family_restroom_outlined,
                l10n.familyLinksFeature,
                null,
                '5',
              ),
              _divider(),
              _comparisonRow(
                context,
                Icons.storage_outlined,
                l10n.storageFeature,
                '5 GB',
                '20 GB',
              ),
              _divider(),
              _comparisonRow(
                context,
                Icons.support_agent_outlined,
                l10n.prioritySupportFeature,
                null,
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tierHeaderBadge(BuildContext context, String text, bool isActive) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: AppColors.primaryBlue, width: 1.5)
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.8,
            color: isActive ? AppColors.primaryBlue : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? Colors.white : Colors.black).withOpacity(0),
            (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            (isDark ? Colors.white : Colors.black).withOpacity(0),
          ],
        ),
      ),
    );
  }

  Widget _comparisonRow(
    BuildContext context,
    IconData icon,
    String feature,
    dynamic free,
    dynamic premium,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: AppColors.primaryBlue.withOpacity(0.7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _featureValue(context, free, currentTier == 'FREEMIUM'),
          ),
          Expanded(
            flex: 2,
            child: _featureValue(context, premium, currentTier == 'PREMIUM'),
          ),
        ],
      ),
    );
  }

  Widget _featureValue(BuildContext context, dynamic value, bool isActive) {
    if (value == null || value == false) {
      return Center(
        child: Icon(
          Icons.remove,
          size: 18,
          color: AppColors.textSecondary.withOpacity(0.3),
        ),
      );
    }

    if (value == true) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 14,
            color: AppColors.successGreen,
          ),
        ),
      );
    }

    return Center(
      child: Text(
        value.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Premium Trial Confirmation Dialog ──────────────────────────────
// ═══════════════════════════════════════════════════════════════════
class _PremiumTrialDialog extends StatelessWidget {
  const _PremiumTrialDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.premiumTrial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.topFeatures,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feature list
                  _FeatureItem(
                    icon: Icons.check_circle_outline,
                    text: l10n.cancelAnytime,
                    color: Colors.white,
                  ),
                  _FeatureItem(
                    icon: Icons.info_outline,
                    text: l10n.trialReminderNote,
                    color: const Color(0xFF8B9DC3),
                  ),
                  _FeatureItem(
                    icon: Icons.camera_alt_outlined,
                    text: l10n.expandedOcrFeature,
                    color: const Color(0xFF8B9DC3),
                  ),
                  _FeatureItem(
                    icon: Icons.people_outline,
                    text: l10n.familyConnectionsFeature,
                    color: const Color(0xFF8B9DC3),
                  ),
                  _FeatureItem(
                    icon: Icons.cloud_outlined,
                    text: l10n.expandedStorageFeature,
                    color: const Color(0xFF8B9DC3),
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(color: Color(0xFF3D3D3D), height: 1),

            // Pricing details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _PriceRow(
                    label: l10n.trialPeriod,
                    value: l10n.oneMonthFree,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: l10n.promotion,
                    value: '-\$0.50',
                    sublabel: l10n.hundredPercentOff,
                    valueColor: const Color(0xFF4A9EFF),
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: l10n.afterTrial,
                    value: '\$0.50/month',
                    valueColor: Colors.white70,
                  ),
                  const SizedBox(height: 16),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.dueToday,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$0.00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.confirm,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final Color valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.sublabel,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Trial Period Information (Senior-Friendly) ─────────────────────
// ═══════════════════════════════════════════════════════════════════
class _TrialPeriodInfo extends StatelessWidget {
  final int daysRemaining;
  final DateTime expiresAt;
  final bool isDark;

  const _TrialPeriodInfo({
    required this.daysRemaining,
    required this.expiresAt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.yourTrialPeriod,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Big countdown card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A5F7A), const Color(0xFF2E8B57)]
                  : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Days remaining - BIG NUMBER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$daysRemaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    daysRemaining == 1 ? l10n.dayLeft : l10n.daysLeft,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Expiration date
              Text(
                '${l10n.trialExpiresOn} ${_formatDate(expiresAt)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                l10n.enjoyingPremium,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // What happens after trial
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFFFD54F),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? Colors.amber : const Color(0xFFF57C00),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.afterTrialEnds,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  l10n.autoRevertToFree,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // What you're enjoying now
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.whatYouGet,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // Features list
        _LargeFeatureItem(
          icon: Icons.camera_alt_outlined,
          title: l10n.unlimitedOcrScanning,
          isDark: isDark,
        ),
        _LargeFeatureItem(
          icon: Icons.people_outline,
          title: l10n.connectFamilyMembers,
          isDark: isDark,
        ),
        _LargeFeatureItem(
          icon: Icons.cloud_outlined,
          title: l10n.twentyGBStorage,
          isDark: isDark,
        ),
        _LargeFeatureItem(
          icon: Icons.support_agent_outlined,
          title: l10n.prioritySupport,
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        // Keep premium section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.keepPremiumFeatures,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onlyPerMonth,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    l10n.continuePremium,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _LargeFeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _LargeFeatureItem({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Icon(Icons.check_circle, color: AppColors.successGreen, size: 24),
        ],
      ),
    );
  }
}
