import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/subscription_provider.dart';
import '../../../theme/app_colors.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  bool _trialClaimed = false;

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
    final hasPlans = sub.plans != null && sub.plans!.isNotEmpty;

    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F7);
    final card = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.upgradePlan),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (sub.errorMessage != null && !sub.isLoading)
            _ErrorBanner(
              message: sub.errorMessage!,
              isLoading: sub.isLoading,
              onRetry: () =>
                  context.read<SubscriptionProvider>().loadSubscription(),
            ),
          if (sub.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _StatusCard(
                  tier: _trialClaimed ? 'PREMIUM' : sub.currentTier,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                if (!_trialClaimed && !sub.isPremium)
                  _TrialCTA(
                    isDark: isDark,
                    card: card,
                    border: border,
                    onClaimed: () => setState(() => _trialClaimed = true),
                  ),

                if (_trialClaimed || sub.isPremium || sub.isOnTrial) ...[
                  const SizedBox(height: 8),
                  _TrialCountdown(
                    daysRemaining: _trialClaimed ? 30 : sub.trialDaysRemaining,
                    expiresAt: _trialClaimed
                        ? DateTime.now().add(const Duration(days: 30))
                        : sub.trialExpiresAt!,
                    isDark: isDark,
                    card: card,
                    border: border,
                    muted: muted,
                  ),
                ] else ...[
                  const SizedBox(height: 28),
                  Text(
                    l10n.choosePlan,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.unlockPremiumFeatures,
                    style: TextStyle(color: muted, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (hasPlans)
                    ...sub.plans!.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlanTile(
                          plan: plan,
                          isCurrent: sub.currentTier == plan['id'],
                          isDark: isDark,
                          card: card,
                          border: border,
                          muted: muted,
                          onUpgrade: () => Navigator.pushNamed(
                            context,
                            '/subscription/payment-method',
                            arguments: {'planType': plan['id'], 'plan': plan},
                          ),
                        ),
                      ),
                    )
                  else
                    _PlanTile(
                      plan: const {
                        'id': 'PREMIUM',
                        'name': 'Premium',
                        'price': 0.5,
                        'currency': 'USD',
                        'period': 'month',
                        'priceOptions': [
                          {
                            'price': 0.5,
                            'period': 'month',
                            'display': '\$0.5/mo',
                          },
                          {
                            'price': 1.0,
                            'period': '3months',
                            'display': '\$1/3mo',
                          },
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
                      isCurrent: sub.currentTier == 'PREMIUM',
                      isDark: isDark,
                      card: card,
                      border: border,
                      muted: muted,
                      onUpgrade: () => Navigator.pushNamed(
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
                      ),
                    ),
                ],

                const SizedBox(height: 32),
                _ComparisonTable(
                  currentTier: sub.currentTier,
                  isDark: isDark,
                  card: card,
                  border: border,
                  muted: muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Card ─────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final String tier;
  final bool isDark;
  const _StatusCard({required this.tier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = tier == 'PREMIUM' || tier == 'FAMILY_PREMIUM';

    // ── Luxury palette (soft, not bold) ──
    final gradStart = isDark
        ? const Color(0xFF1C2A4A) // soft slate navy
        : const Color(0xFF5B7FFF); // muted periwinkle blue
    final gradEnd = isDark
        ? const Color(0xFF131E35) // subtle dark ink
        : const Color(0xFF3D5EE8); // quiet indigo
    final iconBg = isPremium
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.10);
    final iconColor = isPremium
        ? const Color(0xFFE8C547) // warm gold
        : Colors.white.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradStart, gradEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(
              alpha: isDark ? 0.25 : 0.18,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(
              isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.layers_rounded,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 18),
          // ── Text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentPlan.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayName(tier),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // ── Status badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5EE077), // bright green dot
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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
    );
  }

  String _displayName(String tier) {
    return tier
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

// ── Trial CTA ───────────────────────────────────────────────────────
class _TrialCTA extends StatefulWidget {
  final bool isDark;
  final Color card;
  final Color border;
  final VoidCallback? onClaimed;

  const _TrialCTA({
    required this.isDark,
    required this.card,
    required this.border,
    this.onClaimed,
  });

  @override
  State<_TrialCTA> createState() => _TrialCTAState();
}

class _TrialCTAState extends State<_TrialCTA> {
  bool _busy = false;

  Future<void> _claim() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _TrialConfirmDialog(),
    );
    if (confirmed != true || !mounted) return;

    // Capture context-dependent values before the async gap
    final sub = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _busy = true);
    final success = await sub.claimFreeTrial();
    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      widget.onClaimed?.call();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.trialClaimedSuccess),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(sub.errorMessage ?? l10n.trialClaimFailed),
          backgroundColor: AppColors.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: _busy ? null : _claim,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF34C759),
                size: 22,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.freeTrialOffer,
                    style: TextStyle(
                      color: widget.isDark
                          ? Colors.white54
                          : const Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: widget.isDark ? Colors.white30 : const Color(0xFFC7C7CC),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Trial Countdown ─────────────────────────────────────────────────
class _TrialCountdown extends StatelessWidget {
  final int daysRemaining;
  final DateTime expiresAt;
  final bool isDark;
  final Color card;
  final Color border;
  final Color muted;

  const _TrialCountdown({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Countdown card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.yourTrialPeriod,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$daysRemaining',
                    style: const TextStyle(
                      fontSize: 48,
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
              const SizedBox(height: 16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.trialExpiresOn} ${_fmtDate(expiresAt)}',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // After trial info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5D68A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: isDark
                    ? const Color(0xFFFFD60A)
                    : const Color(0xFFC49000),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.autoRevertToFree,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF6B5900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Included features
        Text(
          l10n.whatYouGet,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _miniFeature(Icons.camera_alt_outlined, l10n.unlimitedOcrScanning),
        _miniFeature(Icons.people_outline, l10n.connectFamilyMembers),
        _miniFeature(Icons.cloud_outlined, l10n.twentyGBStorage),
        _miniFeature(Icons.headset_mic_outlined, l10n.prioritySupport),
        const SizedBox(height: 20),

        // Continue premium
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(
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
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.continuePremium,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniFeature(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF007AFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
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

// ── Plan Tile ───────────────────────────────────────────────────────
class _PlanTile extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isCurrent;
  final bool isDark;
  final Color card;
  final Color border;
  final Color muted;
  final VoidCallback onUpgrade;

  const _PlanTile({
    required this.plan,
    required this.isCurrent,
    required this.isDark,
    required this.card,
    required this.border,
    required this.muted,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final features = (plan['features'] as List?)?.cast<String>() ?? [];
    final name = plan['name'] ?? '';
    final priceOptions = plan['priceOptions'] as List?;
    final price = plan['price'] ?? 0;
    final accent = const Color(0xFF007AFF);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? const Color(0xFF34C759) : border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (priceOptions != null && priceOptions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${_fmtPrice(priceOptions[0]['price'])}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: -1,
                                height: 1,
                              ),
                            ),
                            Text(
                              '/${priceOptions[0]['period'] ?? 'mo'}',
                              style: TextStyle(
                                color: muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (priceOptions.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'or ${priceOptions[1]['display']}',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${_fmtPrice(price)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: -1,
                                height: 1,
                              ),
                            ),
                            Text(
                              '/${plan['period'] ?? 'mo'}',
                              style: TextStyle(
                                color: muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.currentLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF34C759),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Divider(height: 1, color: border),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: features
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF3C3C43),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Button
          if (!isCurrent)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: onUpgrade,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.upgradeNow,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _fmtPrice(dynamic p) {
    final n = (p as num).toDouble();
    return n == n.truncateToDouble()
        ? n.toInt().toString()
        : n.toStringAsFixed(2);
  }
}

// ── Comparison Table ────────────────────────────────────────────────
class _ComparisonTable extends StatelessWidget {
  final String currentTier;
  final bool isDark;
  final Color card;
  final Color border;
  final Color muted;

  const _ComparisonTable({
    required this.currentTier,
    required this.isDark,
    required this.card,
    required this.border,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.featureComparison,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF5F5F7),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'FEATURE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'FREE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: currentTier == 'FREEMIUM'
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: 0.8,
                            color: currentTier == 'FREEMIUM'
                                ? const Color(0xFF007AFF)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: currentTier == 'PREMIUM'
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: 0.8,
                            color: currentTier == 'PREMIUM'
                                ? const Color(0xFF007AFF)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _row(context, 'Manual Input', true, true),
              _div(),
              _row(context, 'OCR Scanning', null, '\u221e'),
              _div(),
              _row(context, 'Reminders', true, true),
              _div(),
              _row(context, l10n.familyLinksFeature, null, '5'),
              _div(),
              _row(context, l10n.storageFeature, '5 GB', '20 GB'),
              _div(),
              _row(context, l10n.prioritySupportFeature, null, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _div() => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: border.withValues(alpha: 0.6),
  );

  Widget _row(BuildContext ctx, String label, dynamic free, dynamic premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 2, child: _val(free)),
          Expanded(flex: 2, child: _val(premium)),
        ],
      ),
    );
  }

  Widget _val(dynamic v) {
    if (v == null || v == false) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: border.withValues(alpha: 0.9),
          ),
        ),
      );
    }
    if (v == true) {
      return Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF34C759),
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return Center(
      child: Text(
        v.toString(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Error Banner ────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isLoading;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: const Color(0xFFFFF3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFFF3B30)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFFF3B30)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.retry, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Trial Confirm Dialog ────────────────────────────────────────────
class _TrialConfirmDialog extends StatelessWidget {
  const _TrialConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Dialog(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.premiumTrial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            _dialogRow(Icons.check_circle_outline, l10n.cancelAnytime),
            _dialogRow(Icons.schedule_outlined, l10n.trialReminderNote),
            _dialogRow(Icons.camera_alt_outlined, l10n.expandedOcrFeature),
            _dialogRow(Icons.people_outline, l10n.familyConnectionsFeature),
            _dialogRow(Icons.cloud_outlined, l10n.expandedStorageFeature),
            const SizedBox(height: 20),
            Divider(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            ),
            const SizedBox(height: 16),
            // Pricing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.trialPeriod,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                Text(
                  l10n.oneMonthFree,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.afterTrial,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                const Text(
                  '\$0.50/mo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.dueToday}: ',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    '\$0.00',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.confirm,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF007AFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
