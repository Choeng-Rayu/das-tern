import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_switcher.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.textPrimary;
    final cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      {
        'number': '1',
        'title': l10n.tosSection1Title,
        'body': l10n.tosSection1Body,
      },
      {
        'number': '2',
        'title': l10n.tosSection2Title,
        'body': l10n.tosSection2Body,
      },
      {
        'number': '3',
        'title': l10n.tosSection3Title,
        'body': l10n.tosSection3Body,
      },
      {
        'number': '4',
        'title': l10n.tosSection4Title,
        'body': l10n.tosSection4Body,
      },
      {
        'number': '5',
        'title': l10n.tosSection5Title,
        'body': l10n.tosSection5Body,
      },
      {
        'number': '6',
        'title': l10n.tosSection6Title,
        'body': l10n.tosSection6Body,
      },
      {
        'number': '7',
        'title': l10n.tosSection7Title,
        'body': l10n.tosSection7Body,
      },
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          l10n.termsOfService,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primaryBlue.withValues(alpha: 0.2),
                        const Color(0xFF667EEA).withValues(alpha: 0.1),
                      ]
                    : [
                        AppColors.primaryBlue.withValues(alpha: 0.08),
                        const Color(0xFF667EEA).withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.primaryBlue.withValues(alpha: 0.2)
                    : AppColors.primaryBlue.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90D9), Color(0xFF667EEA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.termsOfService,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tosLastUpdated,
                  style: TextStyle(color: subtitleColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Sections ──
          ...sections.asMap().entries.map(
            (entry) => _SectionCard(
              cardColor: cardColor,
              isDark: isDark,
              bodyColor: bodyColor,
              number: entry.value['number']!,
              title: entry.value['title']!,
              body: entry.value['body']!,
              isLast: entry.key == sections.length - 1,
            ),
          ),

          const SizedBox(height: 24),
          // ── Footer ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.primaryBlue.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.primaryBlue.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: subtitleColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tosContactFooter,
                    style: TextStyle(color: subtitleColor, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color cardColor;
  final bool isDark;
  final Color bodyColor;
  final String number;
  final String title;
  final String body;
  final bool isLast;

  const _SectionCard({
    required this.cardColor,
    required this.isDark,
    required this.bodyColor,
    required this.number,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8ECF2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.15),
                    const Color(0xFF667EEA).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
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
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13.5,
                      height: 1.6,
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
