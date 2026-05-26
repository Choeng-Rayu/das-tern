import 'package:flutter/material.dart';

/// Full-screen centered loading indicator.
///
/// Use as the [body] of a [Scaffold] (or inside [AppScaffold]) while an
/// async operation is in progress.
///
/// Usage:
/// ```dart
/// if (viewModel.isLoading) const AppLoadingView()
/// ```
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.color});

  /// Optional override for the indicator colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
