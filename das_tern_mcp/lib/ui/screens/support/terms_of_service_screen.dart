import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
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
                        const Color(0xFF34C759).withValues(alpha: 0.15),
                        const Color(0xFF30D158).withValues(alpha: 0.08),
                      ]
                    : [
                        const Color(0xFF34C759).withValues(alpha: 0.08),
                        const Color(0xFF30D158).withValues(alpha: 0.04),
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
                    color: const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34C759).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.article_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Terms of Service',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: March 1, 2026',
                  style: TextStyle(color: subtitleColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Sections ──
          ..._sections.map(
            (section) => _SectionCard(
              cardColor: cardColor,
              isDark: isDark,
              bodyColor: bodyColor,
              number: section['number']!,
              title: section['title']!,
              body: section['body']!,
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'If you have questions, contact us at support@dastern.com',
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

const _sections = [
  {
    'number': '1',
    'title': 'Acceptance of Terms',
    'body':
        'By accessing or using DasTern, you agree to be bound by these Terms of Service. If you do not agree, please do not use the application.',
  },
  {
    'number': '2',
    'title': 'Description of Service',
    'body':
        'DasTern provides medication management, health tracking, and telemedicine features. The app is not a substitute for professional medical advice, diagnosis, or treatment.',
  },
  {
    'number': '3',
    'title': 'User Accounts',
    'body':
        'You are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate information and to update it as necessary.',
  },
  {
    'number': '4',
    'title': 'Subscription & Payments',
    'body':
        'Some features require a paid subscription. Prices are displayed before purchase. You may cancel at any time; access continues until the end of the billing period.',
  },
  {
    'number': '5',
    'title': 'Intellectual Property',
    'body':
        'All content, trademarks, and software in DasTern are owned by or licensed to us. You may not copy, modify, or distribute any part without written permission.',
  },
  {
    'number': '6',
    'title': 'Limitation of Liability',
    'body':
        'DasTern is provided "as is". We are not liable for any indirect, incidental, or consequential damages arising from your use of the service.',
  },
  {
    'number': '7',
    'title': 'Changes to Terms',
    'body':
        'We reserve the right to modify these terms at any time. Continued use after changes constitutes acceptance of the new terms.',
  },
];

class _SectionCard extends StatelessWidget {
  final Color cardColor;
  final bool isDark;
  final Color bodyColor;
  final String number;
  final String title;
  final String body;

  const _SectionCard({
    required this.cardColor,
    required this.isDark,
    required this.bodyColor,
    required this.number,
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
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF34C759),
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
