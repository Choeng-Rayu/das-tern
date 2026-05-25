# Design: Design System & Localization

## 1. Module structure

```
lib/core/theme/
├── tokens/
│   ├── colors.dart             # color tokens
│   ├── typography.dart         # type scale + font families
│   ├── spacing.dart            # 4/8/16/24/32/48 grid
│   ├── radii.dart              # 8/12/16/24
│   ├── elevations.dart
│   ├── motion.dart             # durations + curves
│   └── breakpoints.dart
├── light_theme.dart
├── dark_theme.dart
└── theme_controller.dart       # Riverpod provider for selected ThemeMode

lib/core/i18n/
├── l10n.yaml
├── locale_controller.dart      # Riverpod provider for active Locale
└── (generated AppLocalizations)

lib/l10n/
├── app_en.arb
├── app_km.arb
└── app_localizations.dart      # generated

lib/shared/widgets/
├── buttons/
│   └── app_button.dart
├── inputs/
│   └── app_text_field.dart
├── cards/
│   └── app_card.dart
├── chips/
├── dialogs/
├── bottom_sheets/
├── adaptive_scaffold.dart
├── states/
│   ├── empty_state.dart
│   ├── loading_state.dart
│   └── error_state.dart
├── adherence/
│   └── adherence_ring.dart
├── badges/
│   ├── dose_status_badge.dart
│   ├── lifecycle_badge.dart
│   └── permission_chip.dart
└── effects/
    └── frosted_surface.dart
```

## 2. Color tokens

```dart
// lib/core/theme/tokens/colors.dart
class AppColors {
  AppColors._();
  // Brand seed
  static const Color brandSeed = Color(0xFF1A8E5F);

  // Semantic accents (used for status badges)
  static const Color success = Color(0xFF1FAA66);
  static const Color warning = Color(0xFFF1A93A);
  static const Color danger  = Color(0xFFD64545);
  static const Color info    = Color(0xFF3A7BD6);

  // Adherence indicators
  static const Color adherenceGreen  = Color(0xFF1FAA66);
  static const Color adherenceYellow = Color(0xFFF1A93A);
  static const Color adherenceRed    = Color(0xFFD64545);
}

ColorScheme buildLightScheme() => ColorScheme.fromSeed(
  seedColor: AppColors.brandSeed,
  brightness: Brightness.light,
);

ColorScheme buildDarkScheme() => ColorScheme.fromSeed(
  seedColor: AppColors.brandSeed,
  brightness: Brightness.dark,
);
```

## 3. Typography

```dart
// lib/core/theme/tokens/typography.dart
class AppTypography {
  AppTypography._();

  // Khmer-first font stack: Battambang for Khmer; Inter for Latin.
  // Flutter falls through fontFamilyFallback for missing glyphs.
  static const String khmerFamily = 'Battambang';
  static const String latinFamily = 'Inter';
  static const List<String> fallback = ['Battambang', 'Inter', 'NotoSansKhmer'];

  static TextTheme textTheme(ColorScheme cs) => TextTheme(
    displayLarge: TextStyle(fontSize: 36, height: 1.2, fontWeight: FontWeight.w700,
                            color: cs.onSurface, fontFamilyFallback: fallback),
    headlineLarge: TextStyle(fontSize: 28, height: 1.25, fontWeight: FontWeight.w700,
                             color: cs.onSurface, fontFamilyFallback: fallback),
    headlineMedium: TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w600,
                              color: cs.onSurface, fontFamilyFallback: fallback),
    titleLarge: TextStyle(fontSize: 18, height: 1.4, fontWeight: FontWeight.w600,
                          color: cs.onSurface, fontFamilyFallback: fallback),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400,
                         color: cs.onSurface, fontFamilyFallback: fallback),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant, fontFamilyFallback: fallback),
    labelSmall: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant, fontFamilyFallback: fallback),
  );
}
```

```yaml
# pubspec.yaml — fonts
fonts:
  - family: Battambang
    fonts:
      - asset: assets/fonts/Battambang-Regular.ttf
      - asset: assets/fonts/Battambang-Bold.ttf
        weight: 700
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Regular.ttf
      - asset: assets/fonts/Inter-Medium.ttf
        weight: 500
      - asset: assets/fonts/Inter-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Inter-Bold.ttf
        weight: 700
```

## 4. Spacing & radii

```dart
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadii {
  AppRadii._();
  static const Radius small  = Radius.circular(8);
  static const Radius medium = Radius.circular(12);
  static const Radius large  = Radius.circular(16);
  static const Radius xlarge = Radius.circular(24);
}
```

## 5. ThemeData builders

```dart
ThemeData lightTheme() {
  final cs = buildLightScheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    textTheme: AppTypography.textTheme(cs),
    fontFamily: AppTypography.khmerFamily,
    cardTheme: CardTheme(
      elevation: 0,
      color: cs.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadii.medium)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: AppTypography.textTheme(cs).titleLarge,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadii.medium)),
        textStyle: AppTypography.textTheme(cs).bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(AppRadii.medium), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadii.large)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadii.large)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.xlarge),
      ),
    ),
  );
}

ThemeData darkTheme() => /* same as above with buildDarkScheme() */;
```

## 6. AppButton

```dart
enum AppButtonVariant { filled, outlined, text, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPressed == null || loading;
    final child = loading
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label),
          ]);
    final cb = disabled ? null : onPressed;

    return switch (variant) {
      AppButtonVariant.filled => ElevatedButton(onPressed: cb, child: child),
      AppButtonVariant.outlined => OutlinedButton(onPressed: cb, child: child),
      AppButtonVariant.text => TextButton(onPressed: cb, child: child),
      AppButtonVariant.danger => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
        ),
        onPressed: cb,
        child: child,
      ),
    };
  }
}
```

## 7. FrostedSurface (iOS 26 vibe)

```dart
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({super.key, required this.child, this.blur = 24});
  final Widget child;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.all(AppRadii.large),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.7),
            borderRadius: const BorderRadius.all(AppRadii.large),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

## 8. AdaptiveScaffold

```dart
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key, required this.body, required this.destinations,
    required this.selectedIndex, required this.onDestinationSelected,
  });
  final Widget body;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      );
    } else if (width < 840) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            destinations: destinations.map((d) => NavigationRailDestination(
                icon: d.icon, label: Text(d.label))).toList(),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: Row(children: [
        SizedBox(width: 256, child: _Drawer(...)),
        const VerticalDivider(width: 1),
        Expanded(child: body),
      ]),
    );
  }
}
```

## 9. Localization setup

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_km.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
```

```json
// lib/l10n/app_km.arb (excerpt)
{
  "@@locale": "km",
  "appName": "ដាស់តឹង",
  "@appName": { "description": "App name" },

  "auth.signIn.title": "ចូលគណនី",
  "auth.signIn.email.label": "អ៊ីម៉ែល",
  "auth.signIn.email.continue": "បន្ត",
  "auth.signIn.continueWithGoogle": "បន្តជាមួយ Google",
  "auth.signIn.continueWithTelegram": "បន្តជាមួយ Telegram",

  "doses.taken": "បានទទួល",
  "doses.missed": "ខានទទួល",
  "doses.skipped": "បានរំលង",
  "doses.snooze": "ពន្យារ",

  "adherence.greenZone": "≥៩០%",
  "adherence.yellowZone": "៧០–៨៩%",
  "adherence.redZone": "<៧០%",

  "errors.network": "មិនមានបណ្តាញ - សាកល្បងម្តងទៀត",
  "errors.permissionDenied": "អនុញ្ញាតមិនបានគ្រប់គ្រាន់"
}
```

```json
// lib/l10n/app_en.arb (excerpt)
{
  "@@locale": "en",
  "appName": "Das Tern",

  "auth.signIn.title": "Sign in",
  "auth.signIn.email.label": "Email",
  "auth.signIn.email.continue": "Continue",
  "auth.signIn.continueWithGoogle": "Continue with Google",
  "auth.signIn.continueWithTelegram": "Continue with Telegram",

  "doses.taken": "Taken",
  "doses.missed": "Missed",
  "doses.skipped": "Skipped",
  "doses.snooze": "Snooze",

  "adherence.greenZone": "≥90%",
  "adherence.yellowZone": "70–89%",
  "adherence.redZone": "<70%",

  "errors.network": "No connection — please retry",
  "errors.permissionDenied": "Permission denied"
}
```

```dart
// lib/main.dart
MaterialApp.router(
  routerConfig: appRouter,
  theme: lightTheme(),
  darkTheme: darkTheme(),
  themeMode: ref.watch(themeModeControllerProvider),
  locale: ref.watch(localeControllerProvider),
  supportedLocales: const [Locale('km'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
);
```

## 10. Khmer numeral helpers

```dart
class KhmerNumber {
  static const _khmerDigits = ['០','១','២','៣','៤','៥','៦','៧','៨','៩'];
  static String fromInt(int n) => n.toString().split('').map((c) {
    final d = int.tryParse(c);
    return d != null ? _khmerDigits[d] : c;
  }).join();
}
```

Used in Khmer locale where appropriate (e.g., dose counts, adherence percentages). Dosage amounts may stay Arabic numerals for clarity in medical context — flagged for UX review.

## 11. Theme & locale controllers (Riverpod)

```dart
@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    final saved = SharedPrefs.read('theme_mode');
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }
  void setMode(ThemeMode mode) {
    state = mode;
    SharedPrefs.write('theme_mode', mode.name);
  }
}

@riverpod
class LocaleController extends _$LocaleController {
  @override
  Locale build() {
    final saved = SharedPrefs.read('locale');
    return saved == 'en' ? const Locale('en') : const Locale('km');
  }
  void setLocale(Locale loc) {
    state = loc;
    SharedPrefs.write('locale', loc.languageCode);
  }
}
```

## 12. Settings UI

```dart
class AppearanceSettingsPage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    final loc  = ref.watch(localeControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppearance)),
      body: ListView(children: [
        ListTile(title: Text(l10n.themeLight),  trailing: mode == ThemeMode.light  ? const Icon(Icons.check) : null,
                 onTap: () => ref.read(themeModeControllerProvider.notifier).setMode(ThemeMode.light)),
        ListTile(title: Text(l10n.themeDark),   trailing: mode == ThemeMode.dark   ? const Icon(Icons.check) : null,
                 onTap: () => ref.read(themeModeControllerProvider.notifier).setMode(ThemeMode.dark)),
        ListTile(title: Text(l10n.themeSystem), trailing: mode == ThemeMode.system ? const Icon(Icons.check) : null,
                 onTap: () => ref.read(themeModeControllerProvider.notifier).setMode(ThemeMode.system)),
        const Divider(),
        ListTile(title: const Text('ខ្មែរ'),    trailing: loc.languageCode == 'km' ? const Icon(Icons.check) : null,
                 onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('km'))),
        ListTile(title: const Text('English'),  trailing: loc.languageCode == 'en' ? const Icon(Icons.check) : null,
                 onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en'))),
      ]),
    );
  }
}
```

## 13. Testing strategy

- Golden tests for each `lib/shared/widgets/**` widget in light + dark, en + km.
- Contrast tests: `meetsGuideline(textContrastGuideline)`.
- Layout tests at 320, 360, 411, 768, 1280 widths.
- l10n test: every key in `app_en.arb` exists in `app_km.arb` and vice versa (keys equal).

## 14. Storybook (optional but recommended)

`widgetbook` allows browsing every reusable widget at `/dev/widgetbook` (gated by debug flag). Onboarding new contributors to the design system becomes straightforward.
