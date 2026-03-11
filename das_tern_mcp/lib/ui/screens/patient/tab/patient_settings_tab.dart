import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../screens/support/contact_support_screen.dart';
import '../../../screens/support/terms_of_service_screen.dart';
import '../../../screens/support/privacy_policy_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/language_switcher.dart';

class PatientSettingsTab extends StatefulWidget {
  const PatientSettingsTab({super.key});

  @override
  State<PatientSettingsTab> createState() => _PatientSettingsTabState();
}

class _PatientSettingsTabState extends State<PatientSettingsTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.settings,
        actions: const [LanguageSwitcherButton(), SizedBox(width: 12)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withValues(
                          alpha: 0.12,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _patientName(auth.user),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.patientRole,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _sectionLabel('REPORTS'),
                _buildGroupCard(isDark, [
                  _buildNavRow(
                    context,
                    icon: Icons.bar_chart_outlined,
                    label: l10n.activityReport,
                    isLast: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ActivityReportScreen(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                _sectionLabel('APPEARANCE'),
                _buildGroupCard(isDark, [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.brightness_6_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              l10n.theme,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _ThemeOptionCard(
                              icon: Icons.phone_android_rounded,
                              label: 'System',
                              isSelected:
                                  themeProvider.themeMode == ThemeMode.system,
                              isDark: isDark,
                              onTap: () =>
                                  themeProvider.setThemeMode(ThemeMode.system),
                            ),
                            const SizedBox(width: 10),
                            _ThemeOptionCard(
                              icon: Icons.light_mode_rounded,
                              label: 'Light',
                              isSelected:
                                  themeProvider.themeMode == ThemeMode.light,
                              isDark: isDark,
                              onTap: () =>
                                  themeProvider.setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 10),
                            _ThemeOptionCard(
                              icon: Icons.dark_mode_rounded,
                              label: 'Dark',
                              isSelected:
                                  themeProvider.themeMode == ThemeMode.dark,
                              isDark: isDark,
                              onTap: () =>
                                  themeProvider.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // APPEARANCE
            _sectionLabel(l10n.appearance.toUpperCase()),
            _buildGroupCard(isDark, [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.brightness_6_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          l10n.theme,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _ThemeOptionCard(
                          icon: Icons.phone_android_rounded,
                          label: l10n.systemTheme,
                          isSelected:
                              themeProvider.themeMode == ThemeMode.system,
                          isDark: isDark,
                          onTap: () =>
                              themeProvider.setThemeMode(ThemeMode.system),
                        ),
                        const SizedBox(width: 10),
                        _ThemeOptionCard(
                          icon: Icons.light_mode_rounded,
                          label: l10n.lightTheme,
                          isSelected:
                              themeProvider.themeMode == ThemeMode.light,
                          isDark: isDark,
                          onTap: () =>
                              themeProvider.setThemeMode(ThemeMode.light),
                        ),
                        const SizedBox(width: 10),
                        _ThemeOptionCard(
                          icon: Icons.dark_mode_rounded,
                          label: l10n.darkTheme,
                          isSelected: themeProvider.themeMode == ThemeMode.dark,
                          isDark: isDark,
                          onTap: () =>
                              themeProvider.setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _divider(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.language,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final isKhmer =
                            localeProvider.locale.languageCode == 'km';
                        localeProvider.changeLocale(
                          isKhmer ? const Locale('en') : const Locale('km'),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.language,
                              color: AppColors.primaryBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localeProvider.locale.languageCode == 'km'
                                  ? 'ខ្មែរ'
                                  : 'English',
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // NOTIFICATION PERMISSION
            _buildGroupCard(isDark, [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.statusSuccess,
                        size: 20,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          l10n.notificationPermission,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.permissionGranted,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.statusSuccess,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // ACCOUNT (Edit Profile + Security/Change Password + Logout)
            _sectionLabel(l10n.account.toUpperCase()),
            _buildGroupCard(isDark, [
              _buildNavRow(
                context,
                icon: Icons.person_outline,
                label: l10n.editProfile,
                onTap: () {
                  Navigator.pushNamed(context, '/patient/edit-profile');
                },
              ),
              _divider(isDark),
              _buildNavRow(
                context,
                icon: Icons.lock_outline,
                label: l10n.changePassword,
                onTap: () {
                  Navigator.pushNamed(context, '/patient/change-password');
                },
              ),
              _divider(isDark),
              InkWell(
                onTap: () => _confirmLogout(context, auth),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                _sectionLabel('ACCOUNT'),
                _buildGroupCard(isDark, [
                  _buildNavRow(
                    context,
                    icon: Icons.person_outline,
                    label: l10n.editProfile,
                    onTap: () {
                      Navigator.pushNamed(context, '/patient/edit-profile');
                    },
                  ),
                  _divider(isDark),
                  _buildNavRow(
                    context,
                    icon: Icons.lock_outline,
                    label: l10n.changePassword,
                    onTap: () {
                      Navigator.pushNamed(context, '/patient/change-password');
                    },
                  ),
                  _divider(isDark),
                  InkWell(
                    onTap: () => _confirmLogout(context, auth),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            color: AppColors.statusError,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.logout,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.statusError,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // SUBSCRIPTION
            _sectionLabel(l10n.subscription.toUpperCase()),
            _buildGroupCard(isDark, [
              _buildNavRow(
                context,
                icon: Icons.workspace_premium_outlined,
                label: l10n.manageSubscriptions,
                isLast: true,
                onTap: () {
                  Navigator.pushNamed(context, '/subscription/upgrade');
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // SUPPORT
            _sectionLabel(l10n.support.toUpperCase()),
            _buildGroupCard(isDark, [
              _buildSupportRow(
                context,
                isDark: isDark,
                icon: Icons.star_rounded,
                iconBg: const Color(0xFFFF9500),
                label: l10n.rateApp,
                subtitle: l10n.rateAppSubtitle,
                onTap: () async {
                  // TODO: Replace with actual app store URL
                  final uri = Uri.parse('https://play.google.com/store');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _divider(isDark),
              _buildSupportRow(
                context,
                isDark: isDark,
                icon: Icons.headset_mic_rounded,
                iconBg: const Color(0xFF007AFF),
                label: l10n.contactSupport,
                subtitle: l10n.contactSupportSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen(),
                    ),
                  );
                },
              ),
              _divider(isDark),
              _buildSupportRow(
                context,
                isDark: isDark,
                icon: Icons.article_rounded,
                iconBg: const Color(0xFF34C759),
                label: l10n.termsOfService,
                subtitle: l10n.termsOfServiceSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
              _divider(isDark),
              _buildSupportRow(
                context,
                isDark: isDark,
                icon: Icons.shield_rounded,
                iconBg: const Color(0xFFAF52DE),
                label: l10n.privacyPolicy,
                subtitle: l10n.privacyPolicySubtitle,
                isLast: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ],
    );
  }

  String _patientName(Map<String, dynamic>? user) {
    if (user == null) return 'Patient';

    final first = user['firstName'] ?? '';
    final last = user['lastName'] ?? '';
    final fullName = '$first $last'.trim();

    return fullName.isEmpty ? 'Patient' : fullName;
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildNavRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            )
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 48,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildSupportRow(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            )
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, AppLocalizations l10n) {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconBg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.62)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 48,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

/// Tappable theme option card with icon, label, and selected state.
class _ThemeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark
        ? AppColors.primaryBlue.withValues(alpha: 0.18)
        : AppColors.primaryBlue.withValues(alpha: 0.1);
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.08);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white60 : Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
