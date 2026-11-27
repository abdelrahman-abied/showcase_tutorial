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

import 'package:flutter/widgets.dart';

/// Default tooltip styling shared by every `Showcase` under a `ShowCaseWidget`.
///
/// Set this once on `ShowCaseWidget.style` instead of repeating the same
/// styling on every `Showcase`. An individual `Showcase` always wins: each
/// value here is only used when the `Showcase` does not provide its own.
///
/// Every colour of a tour can be set here. A colour left unset everywhere
/// follows the app's `material_ui` theme, so the tour matches the app in light
/// and dark mode without any styling. (An app without a `material_ui` theme
/// gets fixed colours instead: a white tooltip with black text.)
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
  /// Background color of the default tooltip. Falls back to the theme's
  /// `colorScheme.surfaceContainerHigh`, the surface a dialog has.
  final Color? tooltipBackgroundColor;

  /// Text color for the default tooltip title and description when no explicit
  /// text style is provided, and for the progress indicator and Skip label.
  ///
  /// Falls back to the theme's `colorScheme.onSurface`. If you set
  /// [tooltipBackgroundColor] but not this, it is white or black, whichever is
  /// readable on your background.
  final Color? textColor;

  /// Color of the dimmed background drawn behind each step. Its own opacity is
  /// ignored: `Showcase.overlayOpacity` sets how see-through it is.
  ///
  /// Falls back to the theme's `colorScheme.scrim` (black unless the theme
  /// changes it).
  final Color? overlayColor;

  /// Color of the labels of the default action buttons
  /// ([ShowCaseDefaultActions]). A button's own [ActionButtonConfig.textColor]
  /// wins.
  ///
  /// Falls back to the theme's `colorScheme.primary` on the default tooltip,
  /// and to white or black, whichever is readable, on a background you chose.
  final Color? actionTextColor;

  /// Color of the divider between the default action buttons.
  /// [ShowCaseDefaultActions.verticalDividerColor] wins.
  ///
  /// Falls back to the theme's `colorScheme.outlineVariant` on the default
  /// tooltip.
  final Color? actionDividerColor;

  /// Color of the spinner shown while the tour scrolls to a step's target.
  /// Not used by a step with its own `Showcase.scrollLoadingWidget`.
  ///
  /// Falls back to white or black, whichever shows against the dimmed
  /// background.
  final Color? loadingIndicatorColor;

  /// Text style for the default tooltip title.
  ///
  /// When unset, the title uses `titleLarge` from the nearest `material_ui`
  /// `Theme`, coloured with [textColor]. When set, it replaces that style and
  /// [textColor] is not applied.
  ///
  /// Apps still on the legacy `package:flutter/material.dart` `MaterialApp`
  /// can pass their theme's `textTheme.titleLarge` here: the tooltip cannot
  /// read the legacy theme itself.
  final TextStyle? titleTextStyle;

  /// Text style for the default tooltip description.
  ///
  /// When unset, the description uses `titleSmall` from the nearest
  /// `material_ui` `Theme`, coloured with [textColor]. When set, it replaces
  /// that style and [textColor] is not applied. See [titleTextStyle] for apps
  /// still on the legacy `MaterialApp`.
  final TextStyle? descTextStyle;

  /// Border radius of the default tooltip.
  final BorderRadius? tooltipBorderRadius;

  /// Color of the pulsing highlight ring drawn when a `Showcase` enables
  /// `Showcase.enablePulseAnimation`. Falls back to white or black, whichever
  /// shows against the dimmed background.
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
    this.overlayColor,
    this.actionTextColor,
    this.actionDividerColor,
    this.loadingIndicatorColor,
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
