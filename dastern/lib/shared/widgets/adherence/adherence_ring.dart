import 'package:flutter/material.dart';

import '../../../core/theme/tokens/colors.dart';

/// Compact circular adherence indicator.
///
/// Displays a percentage as both a ring and a numeric label, colour-coded
/// against the green/yellow/red adherence zones defined in [AppColors].
/// The whole widget is announced as a single semantic node so screen
/// readers don't have to parse the ring + label separately.
///
/// Spec ref: 09-design-system-localization §Requirement 3 (`AdherenceRing`).
class AdherenceRing extends StatelessWidget {
  const AdherenceRing({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 6,
    this.label,
  }) : assert(value >= 0 && value <= 1, 'value must be 0..1');

  /// Adherence ratio in `0.0 – 1.0`.
  final double value;
  final double size;
  final double strokeWidth;

  /// Optional override label; defaults to a percentage rendering of [value].
  final String? label;

  Color _zoneColor() {
    if (value >= 0.9) return AppColors.adherenceGreen;
    if (value >= 0.7) return AppColors.adherenceYellow;
    return AppColors.adherenceRed;
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _zoneColor();
    final ThemeData theme = Theme.of(context);
    final String pct = '${(value * 100).round()}%';

    return Semantics(
      label: 'Adherence $pct',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Center(
              child: Text(
                label ?? pct,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
