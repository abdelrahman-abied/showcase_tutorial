/// Manual placement for the tooltip action buttons (e.g. [ShowCaseDefaultActions]).
///
/// Each value is an offset, in logical pixels, from the matching edge of the
/// tooltip; leave a value `null` to keep the default placement for that edge.
class ActionButtonsPosition {
  /// Offset from the left edge of the tooltip, or `null` for the default.
  final double? left;

  /// Offset from the right edge of the tooltip, or `null` for the default.
  final double? right;

  /// Offset from the top edge of the tooltip, or `null` for the default.
  final double? top;

  /// Offset from the bottom edge of the tooltip, or `null` for the default.
  final double? bottom;

  /// Creates an [ActionButtonsPosition] from optional per-edge offsets.
  const ActionButtonsPosition({
    this.left,
    this.right,
    this.top,
    this.bottom,
  });
}
