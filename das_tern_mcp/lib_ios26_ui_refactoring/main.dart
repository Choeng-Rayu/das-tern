// lib_ios26_ui_refactoring/main.dart
//
// DasTern — iOS 26 Liquid Glass UI
// Entry point with full bilingual (EN + KH) support + NotoSansKhmer font.
//
// Wires up: AppTheme (light/dark), LocaleProvider (EN/KH), AppLocalizations,
// and a widget showcase demonstrating all 13 global widgets.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/widgets/widgets.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider()..loadLocalePreference(),
      child: const DasTernApp(),
    ),
  );
}

class DasTernApp extends StatelessWidget {
  const DasTernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        // Apply NotoSansKhmer when locale is Khmer, system default for English
        final fontFamily = AppTextStyles.fontFamilyForLocale(
          localeProvider.locale,
        );

        return MaterialApp(
          title: 'DasTern — iOS 26',
          debugShowCheckedModeBanner: false,

          // ── Theme — bilingual font applied here ────────────────────────────
          theme: AppTheme.light(fontFamily: fontFamily),
          darkTheme: AppTheme.dark(fontFamily: fontFamily),
          themeMode: ThemeMode.system,

          // ── Locale + l10n ──────────────────────────────────────────────────
          locale: localeProvider.locale,
          supportedLocales: LocaleProvider.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const _WidgetShowcase(),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget Showcase — demonstrates all 13 global widgets
// ════════════════════════════════════════════════════════════════════════════

class _WidgetShowcase extends StatefulWidget {
  const _WidgetShowcase();

  @override
  State<_WidgetShowcase> createState() => _WidgetShowcaseState();
}

class _WidgetShowcaseState extends State<_WidgetShowcase> {
  int _navIndex = 0;
  bool _isLoading = false;
  bool _showError = false;
  bool _showEmpty = false;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return AppScaffold(
        title: 'Loading',
        body: AppLoadingView(
          message: l10n?.medications ?? 'Loading medications…',
        ),
      );
    }

    if (_showError) {
      return AppScaffold(
        title: 'Error',
        showBackButton: true,
        body: AppErrorView(
          message: 'Could not load data from server.',
          onRetry: () => setState(() => _showError = false),
        ),
      );
    }

    if (_showEmpty) {
      return AppScaffold(
        title: 'Empty',
        showBackButton: true,
        body: AppEmptyView(
          message: l10n?.noMedications ?? 'No medications added yet.',
          icon: Icons.medication_outlined,
        ),
      );
    }

    return AppScaffold(
      title: l10n?.appTitle ?? 'DasTern',
      subtitle: l10n?.appTagline ?? 'iOS 26 Liquid Glass',
      currentNavIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      headerActions: [
        // Language toggle button — EN ↔ KH
        GestureDetector(
          onTap: localeProvider.toggleLocale,
          child: Text(
            localeProvider.isKhmer ? 'EN' : 'ខ្មែរ',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
      body: _ShowcaseBody(
        onShowLoading: () => setState(() => _isLoading = true),
        onShowError: () => setState(() => _showError = true),
        onShowEmpty: () => setState(() => _showEmpty = true),
        l10n: l10n,
      ),
    );
  }
}

class _ShowcaseBody extends StatefulWidget {
  const _ShowcaseBody({
    required this.onShowLoading,
    required this.onShowError,
    required this.onShowEmpty,
    this.l10n,
  });

  final VoidCallback onShowLoading;
  final VoidCallback onShowError;
  final VoidCallback onShowEmpty;
  final AppLocalizations? l10n;

  @override
  State<_ShowcaseBody> createState() => _ShowcaseBodyState();
}

class _ShowcaseBodyState extends State<_ShowcaseBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kToolbarHeight + 16 + AppSpacing.md,
        bottom: 100 + MediaQuery.paddingOf(context).bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Avatars ─────────────────────────────────────────────
          sectionLabel('Avatars', context),
          Row(
            children: [
              AppAvatar(initials: 'AB', radius: 28, onTap: () {}),
              const SizedBox(width: AppSpacing.md),
              AppAvatar(initials: 'KH', radius: 24),
              const SizedBox(width: AppSpacing.md),
              AppAvatar(
                imageUrl: 'https://i.pravatar.cc/96',
                radius: 32,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Section: Badges ───────────────────────────────────────────────
          sectionLabel('Status Badges', context),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              AppBadge(label: 'Active', variant: AppBadgeVariant.active),
              AppBadge(label: 'Pending', variant: AppBadgeVariant.pending),
              AppBadge(label: 'Completed', variant: AppBadgeVariant.completed),
              AppBadge(label: 'Flagged', variant: AppBadgeVariant.flagged),
              AppBadge(label: 'Info', variant: AppBadgeVariant.info),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Section: Cards ────────────────────────────────────────────────
          sectionLabel('Cards', context),
          AppCard(
            onTap: () {},
            child: Row(
              children: [
                const AppAvatar(initials: 'Rx', radius: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.medicationName ?? 'Medication Name',
                        style: AppTextStyles.headlineMediumResolved(context),
                      ),
                      Text(
                        '500mg • Twice daily',
                        style: AppTextStyles.bodyMediumResolved(context),
                      ),
                    ],
                  ),
                ),
                const AppBadge(
                  label: 'Active',
                  variant: AppBadgeVariant.active,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Text(
              'Static card — no onTap',
              style: AppTextStyles.bodyMediumResolved(context),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Section: Form Fields ──────────────────────────────────────────
          sectionLabel('Form Fields', context),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: l10n?.phoneNumber ?? 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n?.password ?? 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 chars' : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Section: Buttons ──────────────────────────────────────────────
          sectionLabel('Buttons', context),
          AppButton(
            label: l10n?.signIn ?? 'Sign In',
            isFullWidth: true,
            isLoading: _isSubmitting,
            // icon: Icons.login_rounded,
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() => _isSubmitting = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) setState(() => _isSubmitting = false);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n?.createAccount ?? 'Create Account',
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n?.deleteMedication ?? 'Delete',
            variant: AppButtonVariant.destructive,
            isFullWidth: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Ghost Button',
            variant: AppButtonVariant.ghost,
            isFullWidth: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Disabled Button',
            isFullWidth: true,
            onPressed: null, // disabled
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Section: State Views ──────────────────────────────────────────
          sectionLabel('State Views', context),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Loading',
                  variant: AppButtonVariant.secondary,
                  onPressed: widget.onShowLoading,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Error',
                  variant: AppButtonVariant.destructive,
                  onPressed: widget.onShowError,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Empty',
                  variant: AppButtonVariant.ghost,
                  onPressed: widget.onShowEmpty,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ── Section label helper ───────────────────────────────────────────────────

Widget sectionLabel(String label, BuildContext context) => Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
  child: Text(
    label.toUpperCase(),
    style: AppTextStyles.labelSmallResolved(context, color: AppColors.primary),
  ),
);
