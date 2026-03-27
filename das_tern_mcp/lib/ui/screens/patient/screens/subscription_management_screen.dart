import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/subscription_provider.dart';
import '../../../widgets/language_switcher.dart';

/// Subscription Management Screen
/// Shows current plan, trial status, features, and upgrade options
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SubscriptionProvider>().loadSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = context.watch<SubscriptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F7);
    final card = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

    final tier = sub.currentTier;
    final isPlatinum = tier == 'FAMILY_PREMIUM';
    final isPremium = tier == 'PREMIUM';
    final isFreemium = tier == 'FREEMIUM';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.manageSubscriptions),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        actions: const [LanguageSwitcherButton(lightBackground: true)],
      ),
      body: sub.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Plan Card
                  _CurrentPlanCard(tier: tier, isDark: isDark, card: card),
                  const SizedBox(height: 20),

                  // Trial Countdown (if on trial)
                  if (sub.isOnTrial) ...[
                    _TrialCountdownCard(
                      daysRemaining: sub.trialDaysRemaining,
                      expiresAt: sub.trialExpiresAt!,
                      isDark: isDark,
                      card: card,
                      border: border,
                      muted: muted,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Current Features
                  if (isPremium || isPlatinum) ...[
                    Text(
                      l10n.whatYouGet,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CurrentFeaturesCard(
                      tier: tier,
                      isDark: isDark,
                      card: card,
                      border: border,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Upgrade Options
                  Text(
                    isFreemium
                        ? l10n.choosePlan
                        : isPremium
                        ? 'Upgrade to Platinum'
                        : 'Available Plans',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFreemium
                        ? l10n.unlockPremiumFeatures
                        : isPremium
                        ? 'Get unlimited connections and group plan'
                        : 'Manage your subscription',
                    style: TextStyle(color: muted, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Show upgrade options based on current tier
                  if (isFreemium || isPremium) ...[
                    // Show both Premium and Platinum side by side
                    Row(
                      children: [
                        Expanded(
                          child: _PlanCard(
                            title: 'Premium',
                            price: '\$0.50',
                            period: 'month',
                            icon: Icons.workspace_premium,
                            features: const [
                              'Unlimited OCR',
                              'Up to 5 family',
                              '20 GB storage',
                              'Priority support',
                            ],
                            color: const Color(0xFF007AFF),
                            isDark: isDark,
                            card: card,
                            isCurrentPlan: isPremium,
                            onTap: isFreemium
                                ? () => Navigator.pushNamed(
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
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PlanCard(
                            title: 'Platinum',
                            price: '\$1.00',
                            period: 'month',
                            icon: Icons.diamond,
                            features: const [
                              'Everything +',
                              'Unlimited family',
                              '50 GB storage',
                              'Group plan',
                            ],
                            color: const Color(0xFF8B5CF6),
                            isDark: isDark,
                            card: card,
                            badge: 'BEST VALUE',
                            isCurrentPlan: false,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/subscription/payment-method',
                              arguments: {
                                'planType': 'FAMILY_PREMIUM',
                                'plan': {
                                  'id': 'FAMILY_PREMIUM',
                                  'name': 'Platinum',
                                  'price': 1.0,
                                  'currency': 'USD',
                                  'period': 'month',
                                },
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isPlatinum) ...[
                    // Show current plan message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.diamond,
                            color: Color(0xFF8B5CF6),
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'You\'re on the best plan!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enjoy all premium features with unlimited access',
                                  style: TextStyle(color: muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // View Full Comparison
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/subscription/upgrade'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Full Feature Comparison',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
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

// ── Current Plan Card ───────────────────────────────────────────────
class _CurrentPlanCard extends StatelessWidget {
  final String tier;
  final bool isDark;
  final Color card;

  const _CurrentPlanCard({
    required this.tier,
    required this.isDark,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPlatinum = tier == 'FAMILY_PREMIUM';
    final isPremium = tier == 'PREMIUM';

    Color gradStart, gradEnd;
    IconData icon;
    String displayName;

    if (isPlatinum) {
      gradStart = isDark ? const Color(0xFF6B21A8) : const Color(0xFF8B5CF6);
      gradEnd = isDark ? const Color(0xFF581C87) : const Color(0xFF7C3AED);
      icon = Icons.diamond;
      displayName = 'Platinum';
    } else if (isPremium) {
      gradStart = isDark ? const Color(0xFF1E40AF) : const Color(0xFF3B82F6);
      gradEnd = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB);
      icon = Icons.workspace_premium;
      displayName = 'Premium';
    } else {
      gradStart = isDark ? const Color(0xFF374151) : const Color(0xFF9CA3AF);
      gradEnd = isDark ? const Color(0xFF1F2937) : const Color(0xFF6B7280);
      icon = Icons.layers;
      displayName = 'Freemium';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradStart, gradEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: gradStart.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentPlan.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5EE077),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trial Countdown Card ────────────────────────────────────────────
class _TrialCountdownCard extends StatelessWidget {
  final int daysRemaining;
  final DateTime expiresAt;
  final bool isDark;
  final Color card;
  final Color border;
  final Color muted;

  const _TrialCountdownCard({
    required this.daysRemaining,
    required this.expiresAt,
    required this.isDark,
    required this.card,
    required this.border,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = daysRemaining / 30;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.yourTrialPeriod,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.premiumTrialActive,
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$daysRemaining',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                daysRemaining == 1 ? l10n.dayLeft : l10n.daysLeft,
                style: TextStyle(
                  color: muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFE5E5EA),
              color: progress > 0.3
                  ? const Color(0xFF34C759)
                  : const Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${l10n.trialExpiresOn} ${_fmtDate(expiresAt)}',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
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
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Current Features Card ───────────────────────────────────────────
class _CurrentFeaturesCard extends StatelessWidget {
  final String tier;
  final bool isDark;
  final Color card;
  final Color border;

  const _CurrentFeaturesCard({
    required this.tier,
    required this.isDark,
    required this.card,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPlatinum = tier == 'FAMILY_PREMIUM';

    final features = isPlatinum
        ? [
            (Icons.camera_alt_outlined, l10n.unlimitedOcrScanning),
            (Icons.people_outline, 'Unlimited family & doctor connections'),
            (Icons.cloud_outlined, '50 GB storage'),
            (Icons.groups_outlined, 'Group plan support'),
            (Icons.headset_mic_outlined, l10n.prioritySupport),
          ]
        : [
            (Icons.camera_alt_outlined, l10n.unlimitedOcrScanning),
            (Icons.people_outline, l10n.connectFamilyMembers),
            (Icons.cloud_outlined, l10n.twentyGBStorage),
            (Icons.headset_mic_outlined, l10n.prioritySupport),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: features
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      f.$1,
                      size: 20,
                      color: isPlatinum
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Plan Card (Premium & Platinum) ─────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final IconData icon;
  final List<String> features;
  final Color color;
  final bool isDark;
  final Color card;
  final String? badge;
  final bool isCurrentPlan;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.icon,
    required this.features,
    required this.color,
    required this.isDark,
    required this.card,
    this.badge,
    required this.isCurrentPlan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentPlan ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: isCurrentPlan ? 0.5 : 0.3),
            width: isCurrentPlan ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge
            if (badge != null || isCurrentPlan)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  isCurrentPlan ? 'CURRENT' : badge!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/$period',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF8E8E93),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Features
                  ...features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action button
                  if (!isCurrentPlan)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Choose',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Active',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
