import 'package:flutter/material.dart';

/// Wraps an extra target widget so it can be highlighted in the same showcase
/// step as the primary [Showcase].
///
/// Each widget whose key is passed to `Showcase.keys` must be wrapped in a
/// [MultiView] (a [RepaintBoundary]) so a snapshot of it can be captured and
/// drawn above the dimmed overlay.
class MultiView extends StatelessWidget {
  /// The extra target widget to wrap and highlight.
  final Widget child;

  /// Creates a [MultiView] that wraps [child] for multi-widget highlighting.
  const MultiView({super.key, required this.child});

  /// Builds a [RepaintBoundary] around [child] so its snapshot can be captured.
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
