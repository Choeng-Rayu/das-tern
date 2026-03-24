# RxCam — Flutter Refactor Guide
## iOS 26 Liquid Glass UI · MVVM Clean Architecture · v2.0

> **Primary Brand Colour:** `#009DFF`  
> **Target:** Migrate existing Flutter app to iOS 26 Liquid Glass aesthetic + official MVVM architecture with a fully reusable global widget system.

---

## Table of Contents

1. [Design Token System](#1-design-token-system)
2. [iOS 26 Liquid Glass Principles](#2-ios-26-liquid-glass-principles)
3. [Folder & File Structure](#3-folder--file-structure)
4. [MVVM Layer Rules](#4-mvvm-layer-rules)
5. [Phase 1 — Foundation (Theme + Router + DI)](#5-phase-1--foundation)
6. [Phase 2 — Global Widget System](#6-phase-2--global-widget-system)
7. [Phase 3 — Data Layer](#7-phase-3--data-layer)
8. [Phase 4 — Domain Use Cases](#8-phase-4--domain-use-cases)
9. [Phase 5 — UI Screens (MVVM)](#9-phase-5--ui-screens-mvvm)
10. [Phase 6 — Cleanup & QA](#10-phase-6--cleanup--qa)
11. [Anti-Pattern Reference](#11-anti-pattern-reference)
12. [Acceptance Checklist](#12-acceptance-checklist)

---

## 1. Design Token System

All colours, spacing, typography, and glass values are defined once in `core/theme/` and referenced everywhere. **Never hardcode values in widgets.**

### 1.1 Colour Palette — `app_colors.dart`

```dart
// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ───────────────────────────────────────────────
  static const primary        = Color(0xFF009DFF);   // #009DFF — main brand
  static const primaryLight   = Color(0xFF40BAFF);
  static const primaryDark    = Color(0xFF0070CC);
  static const primaryGlow    = Color(0x33009DFF);   // 20% — glow / tint

  // ── Semantic ─────────────────────────────────────────────
  static const success        = Color(0xFF34D399);
  static const warning        = Color(0xFFFBBF24);
  static const danger         = Color(0xFFF87171);
  static const info           = Color(0xFF009DFF);   // same as primary

  // ── Mesh Background nodes ────────────────────────────────
  static const meshDeep       = Color(0xFF04040D);
  static const meshMid        = Color(0xFF0D0D22);
  static const meshAccent1    = Color(0xFF001E3A);   // deep-blue tinted by brand
  static const meshAccent2    = Color(0xFF001030);

  // ── Liquid Glass surfaces ────────────────────────────────
  static const glassWhite     = Color(0x26FFFFFF);   // 15% white fill
  static const glassBorder    = Color(0x40FFFFFF);   // specular top-edge
  static const glassShadow    = Color(0x33000000);
  static const glassPrimary   = Color(0x1A009DFF);   // brand-tinted glass
  static const glassDanger    = Color(0x1AF87171);
  static const glassSuccess   = Color(0x1A34D399);
  static const glassWarning   = Color(0x1AFBBF24);

  // ── Text ─────────────────────────────────────────────────
  static const textPrimary    = Color(0xFFF0F4FF);
  static const textSecondary  = Color(0x99F0F4FF);   // 60%
  static const textTertiary   = Color(0x55F0F4FF);   // 33%
  static const textOnPrimary  = Color(0xFFFFFFFF);
}
```

### 1.2 Spacing — `app_spacing.dart`

```dart
// lib/core/theme/app_spacing.dart

class AppSpacing {
  AppSpacing._();

  static const double xs  =  4.0;
  static const double sm  =  8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;

  // Radius tokens — iOS 26 uses generous superellipse radii
  static const double radiusSm   = 12.0;
  static const double radiusMd   = 20.0;
  static const double radiusLg   = 28.0;
  static const double radiusXl   = 36.0;
  static const double radiusPill = 100.0;
}
```

### 1.3 Text Styles — `app_text_styles.dart`

```dart
// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // iOS-style display titles
  static const displayLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.1,
  );

  static const displayMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const titleLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  static const titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const labelLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const labelSmall = TextStyle(
    color: AppColors.textTertiary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
  );

  // Tinted variants
  static TextStyle primaryLabel = const TextStyle(
    color: AppColors.primary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}
```

### 1.4 Theme — `app_theme.dart`

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.meshDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.meshMid,
        error: AppColors.danger,
      ),
      // Transparent AppBar — glass handled by AppHeader widget
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
```

---

## 2. iOS 26 Liquid Glass Principles

These 8 principles must be applied consistently across every widget and screen.

| # | Principle | Flutter Implementation |
|---|---|---|
| 1 | **Liquid Glass material** | `BackdropFilter` + `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` + frosted gradient overlay |
| 2 | **Shrinking tab bar** | `AnimationController` + `ScrollController` listener collapses label + height |
| 3 | **Floating layers** | `BoxShadow` soft penumbra + `AppColors.glassBorder` specular 0.8px top edge |
| 4 | **Spring physics** | `SpringSimulation` on press gestures — jelly bounce feel |
| 5 | **Parallax depth** | Scroll offset drives subtle `Transform.translate` on glass layers |
| 6 | **Adaptive tint** | Glass panel receives a `tint` colour param that tints the overlay gradient |
| 7 | **Liquid superellipse** | Use `borderRadius: 28–36` to approximate squircle (iOS continuous curve) |
| 8 | **Dynamic mesh background** | Animated `RadialGradient` orbs (3 nodes, 8–12s loops) behind all glass |

### 2.1 Core Glass Widget — `app_glass_panel.dart`

This is the **foundation widget** that every card, nav bar, button, and sheet is built upon.

```dart
// lib/core/widgets/app_glass_panel.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppGlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? tint;           // Optional brand tint (e.g. AppColors.glassPrimary)
  final double blurRadius;
  final double opacity;
  final EdgeInsetsGeometry? padding;

  const AppGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.tint,
    this.blurRadius = 20,
    this.opacity = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget panel = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        // Principle 1 — Liquid Glass blur
        filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tint ?? Colors.white).withOpacity(0.18),
                (tint ?? Colors.white).withOpacity(0.06),
              ],
            ),
            // Principle 3 — Specular edge (top highlight)
            border: Border.all(
              color: AppColors.glassBorder,
              width: 0.8,
            ),
            // Principle 3 — Floating shadow
            boxShadow: const [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    return Opacity(opacity: opacity, child: panel);
  }
}
```

### 2.2 Animated Mesh Background — `app_mesh_background.dart`

Wrap every screen's root in this widget. The orbs use brand colour `#009DFF`.

```dart
// lib/core/widgets/app_mesh_background.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppMeshBackground extends StatefulWidget {
  final Widget child;
  const AppMeshBackground({super.key, required this.child});

  @override
  State<AppMeshBackground> createState() => _AppMeshBackgroundState();
}

class _AppMeshBackgroundState extends State<AppMeshBackground>
    with TickerProviderStateMixin {
  late AnimationController _c1, _c2;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat(reverse: true);
    _c2 = AnimationController(vsync: this, duration: const Duration(seconds: 13))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c1, _c2]),
      builder: (_, __) => Stack(
        children: [
          // Base
          Container(color: AppColors.meshDeep),
          // Orb 1 — brand blue (primary)
          Positioned(
            left: -80 + _c1.value * 100,
            top: -60 + _c1.value * 80,
            child: _Orb(size: 360, color: AppColors.primary, opacity: 0.30),
          ),
          // Orb 2 — dark blue
          Positioned(
            right: -40 + _c2.value * 70,
            top: 180 + _c2.value * 100,
            child: _Orb(size: 280, color: AppColors.primaryDark, opacity: 0.22),
          ),
          // Orb 3 — lighter brand
          Positioned(
            left: 30 + _c2.value * 50,
            bottom: 80 + _c1.value * 70,
            child: _Orb(size: 240, color: AppColors.primaryLight, opacity: 0.16),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}
```

---

## 3. Folder & File Structure

```
lib/
├── main.dart
├── app.dart                              # MaterialApp root, theme, router
│
├── core/                                 # ── GLOBAL SYSTEM ──────────────────
│   ├── widgets/
│   │   ├── app_glass_panel.dart          # Foundation glass widget
│   │   ├── app_mesh_background.dart      # Animated background
│   │   ├── app_scaffold.dart             # Screen wrapper (glass header + tab bar)
│   │   ├── app_header.dart               # iOS 26 large-title glass header
│   │   ├── app_bottom_nav.dart           # Shrinking glass tab bar
│   │   ├── app_button.dart               # Glass button (all variants)
│   │   ├── app_text_field.dart           # Glass input field
│   │   ├── app_card.dart                 # Glass card container
│   │   ├── app_badge.dart                # Status pill badges
│   │   ├── app_avatar.dart               # Profile avatar with glass ring
│   │   ├── app_loading_view.dart         # Full-screen loading state
│   │   ├── app_error_view.dart           # Full-screen error state
│   │   └── app_empty_view.dart           # Full-screen empty state
│   │
│   ├── theme/
│   │   ├── app_colors.dart               # All colours incl. #009DFF primary
│   │   ├── app_text_styles.dart          # Typography scale
│   │   ├── app_spacing.dart              # Spacing + radius tokens
│   │   └── app_theme.dart               # ThemeData (dark, glass-first)
│   │
│   ├── router/
│   │   └── app_router.dart               # Named routes + navigation helpers
│   │
│   └── utils/
│       ├── extensions.dart               # BuildContext, String, Color helpers
│       └── validators.dart               # Form validation functions
│
├── data/                                 # ── DATA LAYER ─────────────────────
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── medication_service.dart
│   │   ├── prescription_service.dart
│   │   ├── reminder_service.dart
│   │   └── notification_service.dart
│   │
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── medication_repository.dart
│   │   ├── prescription_repository.dart
│   │   └── reminder_repository.dart
│   │
│   └── models/
│       ├── user.dart
│       ├── medication.dart
│       ├── prescription.dart
│       ├── reminder.dart
│       └── schedule_slot.dart
│
├── domain/                               # ── DOMAIN LAYER ────────────────────
│   └── use_cases/
│       ├── generate_schedule_use_case.dart
│       └── process_ocr_result_use_case.dart
│
└── ui/                                   # ── UI LAYER ────────────────────────
    ├── home/
    │   ├── home_view.dart
    │   └── home_viewmodel.dart
    ├── prescription/
    │   ├── prescription_list_view.dart
    │   ├── prescription_list_viewmodel.dart
    │   ├── prescription_detail_view.dart
    │   ├── prescription_detail_viewmodel.dart
    │   ├── create_prescription_view.dart
    │   └── create_prescription_viewmodel.dart
    ├── medication/
    │   ├── medication_list_view.dart
    │   ├── medication_list_viewmodel.dart
    │   ├── add_medication_view.dart
    │   └── add_medication_viewmodel.dart
    ├── scan/
    │   ├── scan_view.dart
    │   ├── scan_viewmodel.dart
    │   ├── ocr_review_view.dart
    │   └── ocr_review_viewmodel.dart
    ├── reminder/
    │   ├── reminder_schedule_view.dart
    │   └── reminder_schedule_viewmodel.dart
    ├── family/
    │   ├── family_view.dart
    │   └── family_viewmodel.dart
    └── settings/
        ├── settings_view.dart
        └── settings_viewmodel.dart
```

---

## 4. MVVM Layer Rules

### Layer 1 — View (`*_view.dart`)

```
✅ Builds UI widgets only — pure Flutter widget tree
✅ Reads state via Consumer<ViewModel> or context.watch<ViewModel>()
✅ Calls ViewModel methods on user interaction
✅ May contain: AnimationController, scroll listeners, conditional rendering
✅ Uses AppGlassPanel, AppButton, AppTextField — never raw Material widgets
❌ NO if/else business logic
❌ NO direct API or database calls
❌ NO data transformation (String → DateTime, etc.)
❌ NO setState() for data — only for local animation state
```

### Layer 2 — ViewModel (`*_viewmodel.dart`)

```
✅ Extends ChangeNotifier
✅ Holds all async state: isLoading, hasError, errorMessage, data
✅ Exposes command methods the View calls (e.g. onScanTapped(), onSaveRx())
✅ Calls Repository methods — never Service directly
✅ Transforms domain models into display-ready strings/enums
✅ Handles navigation via callbacks (avoid BuildContext in ViewModel)
❌ NO Widget or BuildContext imports (except navigation callback)
❌ NO HTTP calls, file I/O
```

### Layer 3 — Repository (`*_repository.dart`)

```
✅ Single source of truth for its data domain
✅ Handles caching (in-memory or local storage)
✅ Handles error catching, retry logic, fallback
✅ Calls Service classes only — never raw http
✅ Returns clean domain models (never raw Map/JSON)
❌ NO ViewModel awareness
❌ NO UI logic
```

### Layer 4 — Service (`*_service.dart`)

```
✅ Wraps exactly one external API endpoint or platform API
✅ Returns Future<T> or Stream<T>
✅ Stateless — holds zero mutable state
✅ Minimal JSON parsing to raw DTO only
❌ NO business logic
❌ NO caching
❌ NO domain model creation
```

### Data Flow Diagram

```
User Tap
   │
   ▼
[View] ──calls──► [ViewModel.onAction()]
                        │
                        ▼ notifyListeners() → View rebuilds
                  [Repository.fetchData()]
                        │
                        ▼
                  [Service.getFromApi()]
                        │
                        ▼
                  Raw JSON / DTO
                        │
                        ▼ (in Repository)
                  Domain Model
                        │
                        ▼ (in ViewModel)
                  Display State
```

---

## 5. Phase 1 — Foundation

### 5.1 Create Theme Files

Create the four files under `lib/core/theme/` using the code from Section 1.

**Checklist:**
- [ ] `app_colors.dart` — primary `#009DFF`, all glass tokens, semantic colours
- [ ] `app_spacing.dart` — spacing scale + radius tokens (iOS 26 values)
- [ ] `app_text_styles.dart` — full typography scale
- [ ] `app_theme.dart` — dark `ThemeData` using above tokens

### 5.2 Router — `app_router.dart`

```dart
// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import '../../ui/home/home_view.dart';
import '../../ui/scan/scan_view.dart';
// ... other imports

class AppRouter {
  static const String home           = '/';
  static const String scan           = '/scan';
  static const String ocrReview      = '/scan/review';
  static const String prescriptions  = '/prescriptions';
  static const String prescDetail    = '/prescriptions/detail';
  static const String createPresc    = '/prescriptions/create';
  static const String medications    = '/medications';
  static const String addMedication  = '/medications/add';
  static const String reminders      = '/reminders';
  static const String family         = '/family';
  static const String settings       = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _slide(const HomeView());
      case scan:
        return _slide(const ScanView());
      // ... all routes
      default:
        return _slide(const HomeView());
    }
  }

  // iOS-style slide transition — complements the glass aesthetic
  static PageRoute _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 340),
    );
  }

  // Call from ViewModel callbacks — no BuildContext needed in ViewModel
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void push(String route, {Object? arguments}) =>
      navigatorKey.currentState?.pushNamed(route, arguments: arguments);

  static void pop() => navigatorKey.currentState?.pop();

  static void pushReplacement(String route) =>
      navigatorKey.currentState?.pushReplacementNamed(route);
}
```

### 5.3 Dependency Injection — `app.dart`

Use `provider` package for DI (add to `pubspec.yaml`):

```yaml
# pubspec.yaml (relevant additions)
dependencies:
  provider: ^6.1.2
  flutter:
    sdk: flutter
```

```dart
// lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'data/services/medication_service.dart';
import 'data/services/prescription_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/medication_repository.dart';
import 'data/repositories/prescription_repository.dart';
import 'ui/home/home_viewmodel.dart';
// ... other viewmodel imports

class RxCamApp extends StatelessWidget {
  const RxCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services (singletons)
    final authService         = AuthService();
    final medicationService   = MedicationService();
    final prescriptionService = PrescriptionService();

    // Repositories (inject services)
    final authRepo   = AuthRepository(authService);
    final medRepo    = MedicationRepository(medicationService);
    final prescRepo  = PrescriptionRepository(prescriptionService);

    return MultiProvider(
      providers: [
        // Repositories
        Provider<AuthRepository>.value(value: authRepo),
        Provider<MedicationRepository>.value(value: medRepo),
        Provider<PrescriptionRepository>.value(value: prescRepo),

        // ViewModels — created lazily, disposed automatically
        ChangeNotifierProvider(create: (_) => HomeViewModel(medRepo, prescRepo)),
        ChangeNotifierProvider(create: (_) => ScanViewModel()),
        // ... all other ViewModels
      ],
      child: MaterialApp(
        title: 'RxCam',
        theme: AppTheme.dark,
        navigatorKey: AppRouter.navigatorKey,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

---

## 6. Phase 2 — Global Widget System

### 6.1 `AppScaffold` — Screen Wrapper

Every screen uses this. Never use raw `Scaffold` in `ui/` layer.

```dart
// lib/core/widgets/app_scaffold.dart

import 'package:flutter/material.dart';
import 'app_mesh_background.dart';
import 'app_header.dart';
import 'app_bottom_nav.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? currentNavIndex;     // null = no bottom nav (detail screens)
  final bool showBackButton;
  final List<Widget>? headerActions;
  final Widget? floatingActionButton;
  final Widget body;
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.currentNavIndex,
    this.showBackButton = false,
    this.headerActions,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      // AppHeader as PreferredSizeWidget
      appBar: AppHeader(
        title: title,
        subtitle: subtitle,
        showBackButton: showBackButton,
        actions: headerActions,
      ),
      // Glass bottom nav — only shown on root tabs
      bottomNavigationBar: currentNavIndex != null
          ? AppBottomNav(currentIndex: currentNavIndex!)
          : null,
      body: AppMeshBackground(child: body),
    );
  }
}
```

### 6.2 `AppHeader` — Glass Navigation Bar

```dart
// lib/core/widgets/app_header.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../router/app_router.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            border: const Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
              child: Row(
                children: [
                  if (showBackButton) ...[
                    GestureDetector(
                      onTap: AppRouter.pop,
                      child: const Icon(
                        CupertinoIcons.chevron_left,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: AppTextStyles.titleMedium),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 6.3 `AppBottomNav` — Shrinking Glass Tab Bar

This implements iOS 26 Principle 2: collapses label on scroll.

```dart
// lib/core/widgets/app_bottom_nav.dart

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../router/app_router.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  static const _tabs = [
    (CupertinoIcons.house_fill,     CupertinoIcons.house,      'Home',       AppRouter.home),
    (CupertinoIcons.pills_fill,     CupertinoIcons.pills,      'Medication', AppRouter.medications),
    (CupertinoIcons.camera_viewfinder, CupertinoIcons.camera_viewfinder, 'Scan', AppRouter.scan),
    (CupertinoIcons.person_2_fill,  CupertinoIcons.person_2,   'Family',     AppRouter.family),
    (CupertinoIcons.gear_alt_fill,  CupertinoIcons.gear_alt,   'Settings',   AppRouter.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.16),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              border: Border.all(color: AppColors.glassBorder, width: 0.8),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.glassShadow,
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final selected = i == currentIndex;
                final tab = _tabs[i];
                return GestureDetector(
                  onTap: () => AppRouter.push(tab.$4),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 14 : 8,
                      vertical: 8,
                    ),
                    decoration: selected
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.glassPrimary,
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? tab.$1 : tab.$2,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            tab.$3,
                            style: AppTextStyles.primaryLabel,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 6.4 `AppButton` — Glass Button (All Variants)

```dart
// lib/core/widgets/app_button.dart

import 'package:flutter/material.dart';
import 'app_glass_panel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Principle 4 — Spring physics on press
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scale = Tween(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _tint {
    switch (widget.variant) {
      case AppButtonVariant.primary:     return AppColors.glassPrimary;
      case AppButtonVariant.secondary:   return AppColors.glassWhite;
      case AppButtonVariant.destructive: return AppColors.glassDanger;
      case AppButtonVariant.ghost:       return Colors.transparent;
    }
  }

  Color get _labelColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:     return AppColors.primary;
      case AppButtonVariant.secondary:   return AppColors.textPrimary;
      case AppButtonVariant.destructive: return AppColors.danger;
      case AppButtonVariant.ghost:       return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _ctrl.forward(),
      onTapUp: disabled
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: AppGlassPanel(
            borderRadius: AppSpacing.radiusPill,
            tint: _tint,
            child: Container(
              width: widget.isFullWidth ? double.infinity : null,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: widget.isFullWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _labelColor,
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: _labelColor, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(widget.label, style: AppTextStyles.labelLarge.copyWith(color: _labelColor)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 6.5 `AppTextField` — Glass Input Field

```dart
// lib/core/widgets/app_text_field.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLines: maxLines,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMedium,
                prefixIcon: prefix,
                suffixIcon: suffix,
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.danger, width: 1.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### 6.6 `AppCard` — Glass Card Container

```dart
// lib/core/widgets/app_card.dart

import 'package:flutter/material.dart';
import 'app_glass_panel.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? tint;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = AppGlassPanel(
      tint: tint,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
```

### 6.7 State Widgets — Loading / Error / Empty

```dart
// lib/core/widgets/app_loading_view.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppLoadingView extends StatelessWidget {
  final String? message;
  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// lib/core/widgets/app_error_view.dart

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            AppButton(label: 'Retry', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

// lib/core/widgets/app_empty_view.dart

class AppEmptyView extends StatelessWidget {
  final String message;
  final IconData? icon;
  const AppEmptyView({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.inbox_outlined, color: AppColors.textTertiary, size: 48),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

### 6.8 `AppBadge` — Status Pills

```dart
// lib/core/widgets/app_badge.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppBadgeVariant { active, pending, completed, flagged, info }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;

  const AppBadge({super.key, required this.label, required this.variant});

  Color get _color {
    switch (variant) {
      case AppBadgeVariant.active:    return AppColors.success;
      case AppBadgeVariant.pending:   return AppColors.warning;
      case AppBadgeVariant.completed: return AppColors.primary;
      case AppBadgeVariant.flagged:   return AppColors.danger;
      case AppBadgeVariant.info:      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: _color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
```

---

## 7. Phase 3 — Data Layer

### 7.1 Domain Models

```dart
// lib/data/models/prescription.dart

class Prescription {
  final String id;
  final String patientName;
  final String doctorName;
  final List<String> medications;
  final DateTime date;
  final String language;       // 'KH' | 'EN' | 'FR'
  final PrescriptionStatus status;
  final double? ocrConfidence;

  const Prescription({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.medications,
    required this.date,
    required this.language,
    required this.status,
    this.ocrConfidence,
  });
}

enum PrescriptionStatus { pending, completed, flagged }

// lib/data/models/medication.dart

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;      // 'morning' | 'afternoon' | 'evening' | 'night'
  final int durationDays;
  final String? notes;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.notes,
  });
}

// lib/data/models/schedule_slot.dart

class ScheduleSlot {
  final String time;           // 'morning' | 'afternoon' | 'evening' | 'night'
  final String displayTime;    // '08:00 AM'
  final List<Medication> medications;

  const ScheduleSlot({
    required this.time,
    required this.displayTime,
    required this.medications,
  });
}
```

### 7.2 Service Example

```dart
// lib/data/services/prescription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class PrescriptionService {
  final String _baseUrl = 'https://api.rxcam.kh/v1';

  // Returns raw decoded JSON — no domain model creation here
  Future<List<Map<String, dynamic>>> fetchPrescriptions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/prescriptions?page=$page&limit=$limit'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prescriptions: ${response.statusCode}');
    }
    final List data = jsonDecode(response.body)['data'];
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/prescriptions/$id'));
    if (response.statusCode != 200) {
      throw Exception('Prescription not found');
    }
    return jsonDecode(response.body)['data'];
  }
}
```

### 7.3 Repository Example

```dart
// lib/data/repositories/prescription_repository.dart

import '../services/prescription_service.dart';
import '../models/prescription.dart';

class PrescriptionRepository {
  final PrescriptionService _service;

  // In-memory cache
  List<Prescription>? _cache;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  PrescriptionRepository(this._service);

  Future<List<Prescription>> getPrescriptions({bool forceRefresh = false}) async {
    final cacheValid = _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration;

    if (cacheValid && !forceRefresh) return _cache!;

    try {
      final raw = await _service.fetchPrescriptions();
      _cache = raw.map(_fromMap).toList();
      _cacheTime = DateTime.now();
      return _cache!;
    } catch (e) {
      // Return stale cache on error if available
      if (_cache != null) return _cache!;
      rethrow;
    }
  }

  Future<Prescription> getById(String id) async {
    // Check cache first
    final cached = _cache?.where((p) => p.id == id).firstOrNull;
    if (cached != null) return cached;

    final raw = await _service.fetchById(id);
    return _fromMap(raw);
  }

  // Private: raw JSON → domain model (never done in Service or ViewModel)
  Prescription _fromMap(Map<String, dynamic> map) {
    return Prescription(
      id:            map['id'] as String,
      patientName:   map['patient_name'] as String,
      doctorName:    map['doctor_name'] as String,
      medications:   List<String>.from(map['medications'] ?? []),
      date:          DateTime.parse(map['date'] as String),
      language:      map['language'] as String? ?? 'EN',
      status:        _parseStatus(map['status'] as String?),
      ocrConfidence: (map['ocr_confidence'] as num?)?.toDouble(),
    );
  }

  PrescriptionStatus _parseStatus(String? s) {
    switch (s) {
      case 'completed': return PrescriptionStatus.completed;
      case 'flagged':   return PrescriptionStatus.flagged;
      default:          return PrescriptionStatus.pending;
    }
  }
}
```

---

## 8. Phase 4 — Domain Use Cases

### 8.1 `GenerateScheduleUseCase`

Groups a list of medications into time-slot buckets for the reminder screen.

```dart
// lib/domain/use_cases/generate_schedule_use_case.dart

import '../../data/models/medication.dart';
import '../../data/models/schedule_slot.dart';

class GenerateScheduleUseCase {
  List<ScheduleSlot> execute(List<Medication> medications) {
    final slots = <String, List<Medication>>{
      'morning':   [],
      'afternoon': [],
      'evening':   [],
      'night':     [],
    };

    for (final med in medications) {
      final bucket = slots[med.frequency];
      if (bucket != null) {
        bucket.add(med);
      } else {
        // Default unmapped to morning
        slots['morning']!.add(med);
      }
    }

    final displayTimes = {
      'morning':   '08:00 AM',
      'afternoon': '12:00 PM',
      'evening':   '06:00 PM',
      'night':     '09:00 PM',
    };

    return slots.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => ScheduleSlot(
              time: e.key,
              displayTime: displayTimes[e.key]!,
              medications: e.value,
            ))
        .toList();
  }
}
```

### 8.2 `ProcessOcrResultUseCase`

Takes raw OCR text from the scanner and extracts structured medications.

```dart
// lib/domain/use_cases/process_ocr_result_use_case.dart

import '../../data/models/medication.dart';

class OcrResult {
  final List<Medication> medications;
  final String? patientName;
  final String? doctorName;
  final String detectedLanguage;
  final double confidence;

  const OcrResult({
    required this.medications,
    required this.detectedLanguage,
    required this.confidence,
    this.patientName,
    this.doctorName,
  });
}

class ProcessOcrResultUseCase {
  // In production: call your OCR AI model/API here
  // For now: regex-based extraction as fallback
  OcrResult execute(String rawText) {
    final language = _detectLanguage(rawText);
    final medications = _extractMedications(rawText);

    return OcrResult(
      medications: medications,
      detectedLanguage: language,
      confidence: medications.isEmpty ? 0.0 : 0.85,
      patientName: _extractPatientName(rawText),
      doctorName: _extractDoctorName(rawText),
    );
  }

  String _detectLanguage(String text) {
    // Khmer Unicode range: \u1780–\u17FF
    if (RegExp(r'[\u1780-\u17FF]').hasMatch(text)) return 'KH';
    if (text.contains(RegExp(r'\b(mg|comprimé|ordonnance|posologie)\b',
        caseSensitive: false))) return 'FR';
    return 'EN';
  }

  List<Medication> _extractMedications(String text) {
    // Pattern: "DrugName Dosage x/day x days"
    final pattern = RegExp(
      r'([A-Za-z\u1780-\u17FF]+(?:\s[A-Za-z]+)?)\s+(\d+mg|\d+ml)\s*(?:×\s*(\d+)\/day)?',
      caseSensitive: false,
    );
    return pattern.allMatches(text).map((m) {
      return Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: m.group(1) ?? '',
        dosage: m.group(2) ?? '',
        frequency: 'morning',
        durationDays: 7,
      );
    }).toList();
  }

  String? _extractPatientName(String text) {
    final match = RegExp(r'(?:patient|អ្នកជំងឺ|patient)\s*[:\s]+([A-Za-z\u1780-\u17FF\s]+)',
        caseSensitive: false)
        .firstMatch(text);
    return match?.group(1)?.trim();
  }

  String? _extractDoctorName(String text) {
    final match = RegExp(r'(?:Dr\.|doctor|វេជ្ជ)\s*([A-Za-z\u1780-\u17FF\s]+)',
        caseSensitive: false)
        .firstMatch(text);
    return match?.group(1)?.trim();
  }
}
```

---

## 9. Phase 5 — UI Screens (MVVM)

### 9.1 ViewModel Pattern (Standard Template)

Use this template for every `*_viewmodel.dart`:

```dart
// Template: lib/ui/[feature]/[feature]_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../data/repositories/[x]_repository.dart';
import '../../data/models/[x].dart';

class FeatureViewModel extends ChangeNotifier {
  final XRepository _repository;

  // ── State ────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  List<X> _items = [];

  // ── Getters (View reads these) ───────────────────────────
  bool get isLoading    => _isLoading;
  bool get hasError     => _errorMessage != null;
  bool get isEmpty      => !_isLoading && _items.isEmpty && !hasError;
  String get errorMessage => _errorMessage ?? 'An error occurred';
  List<X> get items     => List.unmodifiable(_items);

  FeatureViewModel(this._repository);

  // ── Commands (View calls these) ──────────────────────────
  Future<void> load() async {
    _setLoading(true);
    try {
      _items = await _repository.getItems();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => load();

  // ── Private helpers ──────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

### 9.2 View Pattern (Standard Template)

Use this template for every `*_view.dart`:

```dart
// Template: lib/ui/[feature]/[feature]_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_empty_view.dart';
import '[feature]_viewmodel.dart';

class FeatureView extends StatefulWidget {
  const FeatureView({super.key});

  @override
  State<FeatureView> createState() => _FeatureViewState();
}

class _FeatureViewState extends State<FeatureView> {
  @override
  void initState() {
    super.initState();
    // Load on first frame — ViewModel has no BuildContext dependency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeatureViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Feature Title',
      currentNavIndex: 0,      // set correct tab index
      body: Consumer<FeatureViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) return const AppLoadingView();
          if (vm.hasError)  return AppErrorView(message: vm.errorMessage, onRetry: vm.load);
          if (vm.isEmpty)   return const AppEmptyView(message: 'No items yet');

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: vm.items.length,
            itemBuilder: (_, i) => _ItemCard(item: vm.items[i]),
          );
        },
      ),
    );
  }
}

// Private sub-widget — stays in the view file, no logic
class _ItemCard extends StatelessWidget {
  final dynamic item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(item.toString()),
    );
  }
}
```

### 9.3 Scan Screen — MVVM Example

This screen shows the full MVVM split for the most complex feature.

```dart
// lib/ui/scan/scan_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../domain/use_cases/process_ocr_result_use_case.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../data/models/prescription.dart';
import '../../core/router/app_router.dart';

enum ScanState { idle, scanning, processing, success, error }

class ScanViewModel extends ChangeNotifier {
  final ProcessOcrResultUseCase _ocrUseCase;
  final PrescriptionRepository _prescRepo;

  ScanState _state = ScanState.idle;
  double _progress = 0.0;
  String? _errorMessage;
  OcrResult? _lastResult;

  ScanState get state        => _state;
  double get progress        => _progress;
  bool get isScanning        => _state == ScanState.scanning || _state == ScanState.processing;
  String? get errorMessage   => _errorMessage;
  OcrResult? get lastResult  => _lastResult;

  ScanViewModel(this._ocrUseCase, this._prescRepo);

  Future<void> onScanTapped() async {
    _setState(ScanState.scanning);
    _progress = 0.0;

    // Simulate camera capture progress
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      _progress = i / 10;
      notifyListeners();
    }

    _setState(ScanState.processing);
    // In production: call camera plugin + OCR service
    // For now: simulate with mock text
    await Future.delayed(const Duration(milliseconds: 800));
    _lastResult = _ocrUseCase.execute(_mockOcrText);
    _setState(ScanState.success);

    // Navigate to OCR review — no BuildContext in ViewModel
    AppRouter.push(AppRouter.ocrReview);
  }

  void onRetry() {
    _setState(ScanState.idle);
    _errorMessage = null;
  }

  void _setState(ScanState newState) {
    _state = newState;
    notifyListeners();
  }

  static const _mockOcrText =
      'Dr. Sophea Chan\nPatient: ចាន់ ដារា\nAmoxicillin 500mg × 3/day\nParacetamol 500mg PRN';
}
```

```dart
// lib/ui/scan/scan_view.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_glass_panel.dart';
import '../../core/widgets/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'scan_viewmodel.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Scan Prescription',
      showBackButton: true,
      body: Consumer<ScanViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              Expanded(child: _Viewport(vm: vm)),
              _Controls(vm: vm),
            ],
          );
        },
      ),
    );
  }
}

class _Viewport extends StatelessWidget {
  final ScanViewModel vm;
  const _Viewport({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: AppGlassPanel(
        borderRadius: 28,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Camera preview area (replace with real camera plugin in production)
            const _CameraPlaceholder(),
            // Corner scan brackets
            const _ScanBrackets(),
            // Progress overlay while scanning
            if (vm.isScanning)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _ProgressOverlay(progress: vm.progress),
              ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final ScanViewModel vm;
  const _Controls({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppButton(
            label: vm.isScanning ? 'Scanning…' : 'Scan Prescription',
            icon: CupertinoIcons.camera_viewfinder,
            variant: AppButtonVariant.primary,
            isLoading: vm.isScanning,
            onPressed: vm.isScanning ? null : vm.onScanTapped,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  final double progress;
  const _ProgressOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AppGlassPanel(
      borderRadius: 14,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OCR Processing…', style: AppTextStyles.labelLarge),
              Text('${(progress * 100).toInt()}%',
                  style: AppTextStyles.primaryLabel),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.glassBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text('Detecting Khmer + French + English…',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

// Placeholder — replace with camera_preview plugin widget
class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF0D1B2E), Color(0xFF04040D)],
        ),
      ),
      child: const Center(
        child: Icon(
          CupertinoIcons.doc_text_viewfinder,
          color: AppColors.textTertiary,
          size: 64,
        ),
      ),
    );
  }
}

class _ScanBrackets extends StatelessWidget {
  const _ScanBrackets();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BracketPainter()),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 28.0;
    const p = 32.0;
    final corners = [
      [Offset(p, p + l), Offset(p, p), Offset(p + l, p)],
      [Offset(size.width - p - l, p), Offset(size.width - p, p), Offset(size.width - p, p + l)],
      [Offset(p, size.height - p - l), Offset(p, size.height - p), Offset(p + l, size.height - p)],
      [Offset(size.width - p - l, size.height - p), Offset(size.width - p, size.height - p), Offset(size.width - p, size.height - p - l)],
    ];
    for (final c in corners) {
      final path = Path()
        ..moveTo(c[0].dx, c[0].dy)
        ..lineTo(c[1].dx, c[1].dy)
        ..lineTo(c[2].dx, c[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
```

---

## 10. Phase 6 — Cleanup & QA

### 10.1 Remove Old Code

```bash
# Find all raw Scaffold usages remaining in ui/ layer
grep -rn "return Scaffold(" lib/ui/

# Find any direct ElevatedButton usages
grep -rn "ElevatedButton(" lib/ui/

# Find hardcoded colours
grep -rn "Colors\." lib/ui/
grep -rn "Color(0x" lib/ui/  # except in AppColors

# Find direct Navigator.push usage
grep -rn "Navigator.push(" lib/ui/

# Find setState with business logic
grep -rn "setState(" lib/ui/
```

### 10.2 Analyze & Test

```bash
# Must return zero issues
flutter analyze

# Must pass all tests
flutter test

# Check widget test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 10.3 Verify No Regressions

After each phase PR, manually test:

- [ ] Home loads prescription + medication summary
- [ ] Scan → OCR → Review → Save full flow
- [ ] Bottom nav correctly highlights active tab on all 5 tabs
- [ ] Back button works on all detail screens
- [ ] Loading, error, and empty states display correctly on slow/offline connections
- [ ] Reminder auto-generation groups medications correctly into morning/afternoon/evening/night
- [ ] Khmer, French, English text renders correctly in OCR review screen
- [ ] Dark mode glass panels are visible on all backgrounds

---

## 11. Anti-Pattern Reference

| ❌ Anti-Pattern | ✅ Correct Approach |
|---|---|
| `setState()` for fetching data | Move fetch to `ViewModel`, call `notifyListeners()` |
| `http.get()` inside a widget | Create `Service` class, call from `Repository` |
| `Navigator.push(MaterialPageRoute(...))` inline | Use `AppRouter.push('/route')` |
| Copying `BottomNavigationBar` per screen | Use `AppScaffold(currentNavIndex: N)` |
| `ElevatedButton(style: ...)` per screen | Use `AppButton(variant: AppButtonVariant.primary)` |
| `TextField(decoration: ...)` per screen | Use `AppTextField(label: ..., hint: ...)` |
| `Text('Title', style: TextStyle(...))` | Use `Text('Title', style: AppTextStyles.titleLarge)` |
| `Colors.blue` / `Color(0xFF009DFF)` inline | Use `AppColors.primary` |
| `borderRadius: BorderRadius.circular(8)` inline | Use `AppSpacing.radiusSm` |
| `Scaffold(appBar: AppBar(...))` in screens | Use `AppScaffold(title: ...)` |
| Business logic in `build()` method | Extract to `ViewModel` method |
| Raw API objects (`Map<String, dynamic>`) in UI | Transform to domain models in `Repository._fromMap()` |
| `BackdropFilter` applied per-widget manually | Use `AppGlassPanel(tint: ...)` |
| Mesh background `Stack` per screen | Wrap with `AppMeshBackground` inside `AppScaffold` |

---

## 12. Acceptance Checklist

### Architecture

- [ ] `flutter analyze` returns **zero issues**
- [ ] `flutter test` passes with **zero failures**
- [ ] Every screen under `ui/` has exactly one `*_view.dart` + one `*_viewmodel.dart`
- [ ] No business logic exists inside any `*_view.dart` file
- [ ] All API calls route through: `View → ViewModel → Repository → Service`
- [ ] All domain models are created inside `Repository`, never in `Service` or `View`

### Global Widget System

- [ ] `AppScaffold` used on every screen — no raw `Scaffold` in `ui/` layer
- [ ] `AppButton` is the **only** button widget used across the whole app
- [ ] `AppTextField` is the **only** input field used across the whole app
- [ ] `AppGlassPanel` is the **only** glass surface widget — no manual `BackdropFilter` in screens
- [ ] `AppBottomNav` rendered exactly once (inside `AppScaffold`)
- [ ] `AppHeader` rendered exactly once (inside `AppScaffold`)
- [ ] `AppMeshBackground` applied to every screen root via `AppScaffold`

### iOS 26 UI

- [ ] All glass panels use `BackdropFilter` with `sigmaX: 20, sigmaY: 20`
- [ ] All glass panels show specular border `AppColors.glassBorder` at `0.8px`
- [ ] Primary colour `#009DFF` used consistently — no hardcoded blue hex values
- [ ] Tab bar collapses label text on scroll
- [ ] All button presses have spring-physics scale feedback
- [ ] Corner radii use `AppSpacing.radiusLg` (28) or higher — no flat corners on cards
- [ ] Mesh background animates on all main screens

### Features

- [ ] `GenerateScheduleUseCase` correctly groups medications into morning/afternoon/evening/night
- [ ] `ProcessOcrResultUseCase` detects Khmer (`\u1780–\u17FF`), French, and English
- [ ] OCR language badge (KH / FR / EN) shown on prescription cards
- [ ] All screens work identically before and after refactor (no feature regression)

---

> **Milestone:** `v2.0 — iOS 26 Glass + Clean Architecture`  
> **Estimated Effort:** 7–12 days across 6 separate PRs (one per Phase)  
> **Each PR must pass** `flutter analyze` **with zero issues before merge.**