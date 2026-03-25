// lib/core/widgets/app_scaffold.dart
//
// RxCam Global Widget System — Screen Layout Wrapper
// iOS 26 Liquid Glass aesthetic
//
// Requirements: 6.1–6.8

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_header.dart';
import 'app_mesh_background.dart';
import 'app_bottom_nav.dart';

/// Global screen-wrapper widget composing mesh background, glass header,
/// body content, and floating bottom navigation.
///
/// Every screen in RxCam uses [AppScaffold] — no manual [Scaffold] setup needed.
///
/// **Invariant (Req 6.1):** body is ALWAYS wrapped in [AppMeshBackground].
/// **Invariant (Req 6.3/6.4):** bottom nav is present iff [currentNavIndex] ≢ null.
///
/// ```dart
/// AppScaffold(
///   title: 'Home',
///   currentNavIndex: 0,
///   onNavTap: (i) => setState(() => _index = i),
///   body: HomeContent(),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentNavIndex,
    this.onNavTap,
    this.showBackButton = false,
    this.subtitle,
    this.headerActions,
    this.floatingActionButton,
  });

  /// Screen title shown in [AppHeader].
  final String title;

  /// Main content widget — always wrapped in [AppMeshBackground].
  final Widget body;

  /// When non-null, renders [AppBottomNav] at the given selected index. (Req 6.3)
  final int? currentNavIndex;

  /// Callback when a bottom nav tab is tapped.
  final ValueChanged<int>? onNavTap;

  /// Shows a back chevron in [AppHeader] when true.
  final bool showBackButton;

  /// Optional subtitle in [AppHeader].
  final String? subtitle;

  /// Optional trailing action widgets in [AppHeader].
  final List<Widget>? headerActions;

  /// Optional FAB passed to [Scaffold].
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      // Body bleeds under header and bottom nav (Req 6.5)
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: colors.background,

      appBar: AppHeader(
        title: title,
        showBackButton: showBackButton,
        subtitle: subtitle,
        actions: headerActions,
      ),

      // Body ALWAYS wrapped in AppMeshBackground (Req 6.1)
      body: AppMeshBackground(child: body),

      // Bottom nav present iff currentNavIndex != null (Req 6.3, 6.4)
      bottomNavigationBar: currentNavIndex != null
          ? AppBottomNav(
              currentIndex: currentNavIndex!,
              onTap: onNavTap ?? (_) {},
            )
          : null,

      floatingActionButton: floatingActionButton,
    );
  }
}
