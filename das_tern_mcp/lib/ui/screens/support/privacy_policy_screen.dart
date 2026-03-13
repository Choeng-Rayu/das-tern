import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_switcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.textPrimary;
    final cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    final sections = [
      {
        'icon': Icons.data_usage_rounded,
        'title': l10n.ppSection1Title,
        'body': l10n.ppSection1Body,
      },
      {
        'icon': Icons.health_and_safety_rounded,
        'title': l10n.ppSection2Title,
        'body': l10n.ppSection2Body,
      },
      {
        'icon': Icons.lock_rounded,
        'title': l10n.ppSection3Title,
        'body': l10n.ppSection3Body,
      },
      {
        'icon': Icons.share_rounded,
        'title': l10n.ppSection4Title,
        'body': l10n.ppSection4Body,
      },
      {
        'icon': Icons.cookie_rounded,
        'title': l10n.ppSection5Title,
        'body': l10n.ppSection5Body,
      },
      {
        'icon': Icons.tune_rounded,
        'title': l10n.ppSection6Title,
        'body': l10n.ppSection6Body,
      },
      {
        'icon': Icons.update_rounded,
        'title': l10n.ppSection7Title,
        'body': l10n.ppSection7Body,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSwitcherButton(lightBackground: true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFFAF52DE).withValues(alpha: 0.15),
                        const Color(0xFF5856D6).withValues(alpha: 0.08),
                      ]
                    : [
                        const Color(0xFFAF52DE).withValues(alpha: 0.08),
                        const Color(0xFF5856D6).withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAF52DE),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFAF52DE).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.privacyPolicy,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.ppLastUpdated,
                  style: TextStyle(color: subtitleColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Highlight banner ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(
                0xFFAF52DE,
              ).withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFAF52DE).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFAF52DE),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.ppHighlightBanner,
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Sections ──
          ...sections.map(
            (section) => _PolicySection(
              cardColor: cardColor,
              isDark: isDark,
              bodyColor: bodyColor,
              icon: section['icon'] as IconData,
              title: section['title'] as String,
              body: section['body'] as String,
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              l10n.ppContactFooter,
              style: TextStyle(color: subtitleColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final Color cardColor;
  final bool isDark;
  final Color bodyColor;
  final IconData icon;
  final String title;
  final String body;

  const _PolicySection({
    required this.cardColor,
    required this.isDark,
    required this.bodyColor,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFAF52DE).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFFAF52DE)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                      height: 1.5,
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
