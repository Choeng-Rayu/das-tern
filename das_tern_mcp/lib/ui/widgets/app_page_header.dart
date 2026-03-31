import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A configurable gradient header widget for use across different screens.
///
/// This widget provides a consistent header experience with support for:
/// - Gradient background (blue theme)
/// - Custom title text
/// - Optional back button with configurable callback
/// - Optional trailing action widgets
/// - Optional extra content area (e.g., search bars, tab bars)
/// - Optional logo and app name display
/// - Safe area handling
/// - Rounded bottom corners
///
/// ## Usage Examples
///
/// ### Simple title header (sub-page)
/// ```dart
/// AppPageHeader(
///   title: 'Settings',
///   showBackButton: true,
/// )
/// ```
///
/// ### Main page with logo and actions
/// ```dart
/// AppPageHeader(
///   title: 'Dashboard',
///   showLogo: true,
///   actions: [
///     IconButton(
///       icon: Icon(Icons.notifications, color: Colors.white),
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
///
/// ### Header with extra content (search bar)
/// ```dart
/// AppPageHeader(
///   title: 'Medications',
///   showBackButton: true,
///   extraContent: [
///     Padding(
///       padding: EdgeInsets.symmetric(horizontal: 16),
///       child: SearchBar(),
///     ),
///   ],
/// )
/// ```
class AppPageHeader extends StatelessWidget {
  /// Creates an [AppPageHeader] widget.
  ///
  /// The [title] parameter is required and will be displayed as the header text.
  const AppPageHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showLogo = true,
    this.actions,
    this.extraContent,
    this.onBackPressed,
  });

  /// The title text displayed in the header.
  final String title;

  /// Whether to show a back button on the leading side.
  ///
  /// Defaults to `false`. When `true`, displays a back arrow icon button.
  /// If [onBackPressed] is provided, it will be called when tapped;
  /// otherwise, [Navigator.pop] will be invoked.
  final bool showBackButton;

  /// Whether to show the app logo and name row.
  ///
  /// Defaults to `true`. Set to `false` for sub-pages where only
  /// the title should be displayed (e.g., detail screens, settings).
  final bool showLogo;

  /// Optional list of action widgets displayed on the trailing side.
  ///
  /// These are typically [IconButton] widgets for actions like
  /// notifications, settings, or profile access.
  final List<Widget>? actions;

  /// Optional list of widgets rendered below the title row.
  ///
  /// Use this for additional content like search bars, tab bars,
  /// filters, or any other header-related UI elements.
  final List<Widget>? extraContent;

  /// Custom callback invoked when the back button is pressed.
  ///
  /// If `null` and [showBackButton] is `true`, the default behavior
  /// is to call [Navigator.pop].
  final VoidCallback? onBackPressed;

  /// The gradient colors used for the header background.
  static const List<Color> _gradientColors = [
    Color(0xFF29B6F6), // Light blue
    Color(0xFF0288D1), // Dark blue
  ];

  /// The border radius for the bottom corners.
  static const double _bottomBorderRadius = 20.0;

  /// Minimum touch target size for interactive elements (Material guidelines).
  static const double _minTouchTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_bottomBorderRadius),
          bottomRight: Radius.circular(_bottomBorderRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo row (optional)
              if (showLogo) ...[
                _buildLogoRow(),
                const SizedBox(height: AppSpacing.md),
              ],
              // Title row with back button and actions
              _buildTitleRow(context),
              // Extra content area (optional)
              if (extraContent != null && extraContent!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ...extraContent!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the logo and app name row.
  Widget _buildLogoRow() {
    return Row(
      children: [
        // App logo placeholder - uses a simple icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            color: AppColors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          'Das Tern',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Builds the main title row with optional back button and actions.
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button (optional)
        if (showBackButton) ...[
          _buildBackButton(context),
          const SizedBox(width: AppSpacing.sm),
        ],
        // Title text
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Action buttons (optional)
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          ...actions!,
        ],
      ],
    );
  }

  /// Builds the back button with minimum touch target size.
  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: _minTouchTarget,
      height: _minTouchTarget,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBackPressed ?? () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(_minTouchTarget / 2),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// A sliver version of [AppPageHeader] for use with [CustomScrollView].
///
/// This widget provides the same functionality as [AppPageHeader] but
/// is designed to work within a sliver-based scrollable layout.
///
/// ## Usage Example
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAppPageHeader(
///       title: 'My Medications',
///       showBackButton: true,
///     ),
///     SliverList(...),
///   ],
/// )
/// ```
class SliverAppPageHeader extends StatelessWidget {
  /// Creates a [SliverAppPageHeader] widget.
  const SliverAppPageHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showLogo = true,
    this.actions,
    this.extraContent,
    this.onBackPressed,
  });

  /// The title text displayed in the header.
  final String title;

  /// Whether to show a back button on the leading side.
  final bool showBackButton;

  /// Whether to show the app logo and name row.
  final bool showLogo;

  /// Optional list of action widgets displayed on the trailing side.
  final List<Widget>? actions;

  /// Optional list of widgets rendered below the title row.
  final List<Widget>? extraContent;

  /// Custom callback invoked when the back button is pressed.
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AppPageHeader(
        title: title,
        showBackButton: showBackButton,
        showLogo: showLogo,
        actions: actions,
        extraContent: extraContent,
        onBackPressed: onBackPressed,
      ),
    );
  }
}
