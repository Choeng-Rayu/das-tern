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
                    _CurrentPlanCard(tier: sub.currentTier, isDark: isDark),
                    const SizedBox(height: AppSpacing.md),

                    // Claim Free Trial button (only for Freemium users)
                    if (sub.canClaimTrial)
                      _ClaimFreeTrialButton(isDark: isDark),

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
                          isRecommended: false,
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
// ─── Claim Free Trial Button ────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
class _ClaimFreeTrialButton extends StatelessWidget {
  final bool isDark;

  const _ClaimFreeTrialButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrialConfirmSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
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
                        l10n.claimFreeTrial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.freeTrialOffer,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the trial confirmation as a modal bottom sheet popup.
  void _showTrialConfirmSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = context.read<SubscriptionProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: sub,
        child: _TrialConfirmSheet(isDark: isDark),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Trial Confirm Bottom Sheet ─────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
class _TrialConfirmSheet extends StatelessWidget {
  final bool isDark;

  const _TrialConfirmSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = context.watch<SubscriptionProvider>();
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    // Dark style inspired by the reference design
    const sheetBg = Color(0xFF1A1A2E);
    const dividerColor = Color(0xFF2E2E48);
    final mutedText = Colors.white.withValues(alpha: 0.55);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // ── Scrollable content ──
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Plan name ──
                  Text(
                    l10n.premiumTrial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Top Features label ──
                  Text(
                    l10n.topFeatures,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Feature list ──
                  _featureItem(
                    Icons.check,
                    l10n.cancelAnytime,
                    const Color(0xFF8B8B8B),
                  ),
                  const SizedBox(height: 14),
                  _featureItem(
                    Icons.access_time_rounded,
                    l10n.trialReminderNote,
                    const Color(0xFF9B8AFF),
                  ),
                  const SizedBox(height: 14),
                  _featureItem(
                    Icons.description_outlined,
                    'Unlimited prescriptions & OCR scanning',
                    const Color(0xFF66B2FF),
                  ),
                  const SizedBox(height: 14),
                  _featureItem(
                    Icons.cloud_outlined,
                    '20 GB storage',
                    const Color(0xFF70D4A6),
                  ),
                  const SizedBox(height: 14),
                  _featureItem(
                    Icons.family_restroom_outlined,
                    'Up to 5 family connections',
                    const Color(0xFFE8A0FF),
                  ),

                  const SizedBox(height: 28),

                  // ── Pricing breakdown ──
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: dividerColor, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _priceRow(
                          'Monthly subscription',
                          '\$0.50',
                          mutedText,
                          Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 12),
                        _priceRow(
                          'Promotion',
                          '-\$0.50',
                          mutedText,
                          const Color(0xFF9B8AFF),
                          subtitle: '100% off for a month',
                        ),
                        const SizedBox(height: 12),
                        _priceRow(
                          'VAT (0%)',
                          '\$0.00',
                          mutedText,
                          Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 14),
                        Container(height: 1, color: dividerColor),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Due today',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              '\$0.00',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Subscribe button (pinned at bottom) ──
          Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 14 + bottomPad),
            color: sheetBg,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: sub.isLoading ? null : () => _handleConfirm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: sub.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Subscribe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm(BuildContext context) async {
    final sub = context.read<SubscriptionProvider>();
    final success = await sub.claimFreeTrial();

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (success) {
      Navigator.pop(context); // close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.trialClaimedSuccess),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sub.errorMessage ?? l10n.trialClaimFailed),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  // ── Sheet helper widgets ──

  static Widget _featureItem(IconData icon, String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _priceRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    String? subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: labelColor.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
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
              ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
              : [const Color(0xFF2D5BFF), const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isPremium ? const Color(0xFF764BA2) : const Color(0xFF2D5BFF))
                    .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                // Plan icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isPremium
                        ? Icons.workspace_premium
                        : Icons.star_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.currentPlan,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tier.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (!isPremium) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.upgradeToUnlock,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.verified : Icons.info_outline,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? 'Active' : 'Free',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
              _comparisonRow(context, 'Prescriptions', '1', '\u221e', '\u221e'),
              const Divider(height: 1),
              _comparisonRow(context, 'Medicines', '3', '\u221e', '\u221e'),
              const Divider(height: 1),
              _comparisonRow(context, 'Family Links', '1', '5', '5'),
              const Divider(height: 1),
              _comparisonRow(context, 'Storage', '5 GB', '20 GB', '20 GB'),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: currentTier == 'FREEMIUM'
                    ? FontWeight.bold
                    : FontWeight.normal,
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
                fontWeight: currentTier == 'PREMIUM'
                    ? FontWeight.bold
                    : FontWeight.normal,
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
                fontWeight: currentTier == 'FAMILY_PREMIUM'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: currentTier == 'FAMILY_PREMIUM'
                    ? AppColors.primaryBlue
                    : null,
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.2),
            AppColors.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Premium Trial Active',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have $daysRemaining days remaining',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
