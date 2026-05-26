import 'package:flutter/widgets.dart';

/// Shared [ValueKey] instances for [BackdropFilter] coalescing.
///
/// Pass these as the `key` on [BackdropFilter] (via [FrostedSurface.backdropKey])
/// so the Flutter engine can share a single blur pass per scope.
///
/// Spec ref: liquid-glass-flutter SKILL.md §"BackdropFilter coalescing".
abstract class BackdropKeys {
  static const Key shellHeader = ValueKey<String>('bk_shellHeader');
  static const Key contentList = ValueKey<String>('bk_contentList');
  static const Key modal = ValueKey<String>('bk_modal');
  static const Key qrSurface = ValueKey<String>('bk_qrSurface');
}
