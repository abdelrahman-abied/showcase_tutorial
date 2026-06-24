import 'package:flutter/material.dart';

/// Container styling for the action buttons row in a [Showcase] tooltip.
///
/// Passed to `Showcase.actionSettings` to size, color, and pad the container
/// that holds the action buttons (e.g. [ShowCaseDefaultActions]).
class ActionsSettings {
  /// Width of the action buttons container.
  ///
  /// Defaults to `350`.
  final double? containerWidth;

  /// Height of the action buttons container.
  ///
  /// Defaults to `40`.
  final double? containerHeight;

  /// Background color of the action buttons container.
  ///
  /// Defaults to [Colors.white].
  final Color? containerColor;

  /// Padding around the action buttons inside the container.
  ///
  /// Defaults to `EdgeInsets.only(top: 0.0)`.
  final EdgeInsets? containerPadding;

  /// Creates styling for the action buttons container of a [Showcase] tooltip.
  const ActionsSettings({
    this.containerWidth = 350,
    this.containerHeight = 40,
    this.containerColor = Colors.white,
    this.containerPadding = const EdgeInsets.only(top: 0.0),
  });
}
