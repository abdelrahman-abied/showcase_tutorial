/*

 * Copyright (c) 2026 Abdulrahman Mohamed
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:flutter/material.dart';

/// Default tooltip styling shared by every `Showcase` under a `ShowCaseWidget`.
///
/// Set this once on `ShowCaseWidget.style` instead of repeating the same
/// styling on every `Showcase`. An individual `Showcase` always wins: each
/// value here is only used when the `Showcase` does not provide its own, and
/// falls back to the built-in default when neither is set.
///
/// ```dart
/// ShowCaseWidget(
///   style: const ShowcaseStyle(
///     tooltipBackgroundColor: Color(0xFF0077B6),
///     textColor: Colors.white,
///     tooltipBorderRadius: BorderRadius.all(Radius.circular(12)),
///   ),
///   builder: ...,
/// );
/// ```
class ShowcaseStyle {
  /// Background color of the default tooltip. Falls back to [Colors.white].
  final Color? tooltipBackgroundColor;

  /// Text color for the default tooltip title and description when no explicit
  /// text style is provided. Falls back to [Colors.black].
  final Color? textColor;

  /// Text style for the default tooltip title.
  final TextStyle? titleTextStyle;

  /// Text style for the default tooltip description.
  final TextStyle? descTextStyle;

  /// Border radius of the default tooltip.
  final BorderRadius? tooltipBorderRadius;

  /// Color of the pulsing highlight ring drawn when a `Showcase` enables
  /// `Showcase.enablePulseAnimation`. Falls back to [Colors.white].
  final Color? pulseColor;

  /// Color of the default tooltip's arrow. Falls back to the tooltip
  /// background color.
  final Color? arrowColor;

  /// Width (base) of the default tooltip's arrow. Falls back to `18`.
  final double? arrowWidth;

  /// Height (depth) of the default tooltip's arrow. Falls back to `9`.
  final double? arrowHeight;

  /// Color of the border drawn around the highlighted target. When `null` no
  /// border is drawn (the default).
  final Color? highlightBorderColor;

  /// Width of the highlight border (see [highlightBorderColor]). Falls back
  /// to `2`.
  final double? highlightBorderWidth;

  /// Creates a [ShowcaseStyle].
  ///
  /// Every parameter is optional; any value left unset falls back to the
  /// per-[Showcase] value first and then to the built-in default.
  const ShowcaseStyle({
    this.tooltipBackgroundColor,
    this.textColor,
    this.titleTextStyle,
    this.descTextStyle,
    this.tooltipBorderRadius,
    this.pulseColor,
    this.arrowColor,
    this.arrowWidth,
    this.arrowHeight,
    this.highlightBorderColor,
    this.highlightBorderWidth,
  });
}
