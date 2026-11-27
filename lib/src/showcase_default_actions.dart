import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../showcase_tutorial.dart';
import 'utilities/_showcase_colors.dart';
import 'utilities/_showcase_context_provider.dart';

/// Default action buttons widget for a [Showcase] tooltip.
///
/// Lays out the Previous, Stop and Next buttons in a [Row], each configurable
/// through an [ActionButtonConfig]. Pass it to the `actions` property of a
/// [Showcase] and style its container with [ActionsSettings].
///
/// The buttons' text comes from [ShowCaseWidget.labels] unless a button sets
/// its own [ActionButtonConfig.text]. The row and each button follow the
/// app's text direction, so in a right-to-left app Previous sits on the
/// right. The default tooltip is made wide enough for the buttons' labels. A
/// label that still does not fit its button (for example a long translation
/// on a narrow screen) stays on one line: it is scaled down to no less than
/// 70% of its size, and past that it ends with an ellipsis instead of
/// wrapping.
class ShowCaseDefaultActions extends StatelessWidget {
  /// How the buttons are placed along the main (horizontal) axis of the [Row].
  final MainAxisAlignment mainAxisAlignment;

  /// How much horizontal space the [Row] should occupy.
  final MainAxisSize mainAxisSize;

  /// How the buttons are aligned along the cross (vertical) axis of the [Row].
  final CrossAxisAlignment crossAxisAlignment;

  /// The text direction used to order the buttons, or null to inherit it.
  final TextDirection? textDirection;

  /// The order in which buttons are laid out vertically.
  final VerticalDirection verticalDirection;

  /// The baseline used to align children when [crossAxisAlignment] is baseline.
  final TextBaseline? textBaseline;

  /// Thickness of the vertical divider drawn between buttons.
  ///
  /// Defaults to `1.0`.
  final double? dividerThickness;

  /// Color of the vertical divider drawn between buttons.
  ///
  /// When `null` (the default) it is [ShowcaseStyle.actionDividerColor], or
  /// else follows the app's theme (`colorScheme.outlineVariant` on the
  /// default tooltip).
  final Color? verticalDividerColor;

  /// Configuration for the Next button.
  final ActionButtonConfig next;

  /// Configuration for the Previous button.
  final ActionButtonConfig previous;

  /// Configuration for the Stop button.
  final ActionButtonConfig stop;

  /// Creates the default Previous / Stop / Next action buttons for a tooltip.
  const ShowCaseDefaultActions({
    super.key,
    this.next = const ActionButtonConfig(),
    this.previous = const ActionButtonConfig(),
    this.stop = const ActionButtonConfig(),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.dividerThickness = 1.0,
    this.verticalDividerColor,
  });

  /// Builds the [Row] of Previous, Stop and Next buttons for the tooltip.
  @override
  Widget build(BuildContext context) {
    final provider = ShowcaseContextProvider.of(context);
    final showcaseContext = provider?.context;
    // The tour's labels, published by the overlay the buttons are in. Used
    // outside one, the buttons keep their English text.
    final labels = provider?.labels ?? const ShowcaseLabels();
    // Provided by the tooltip the buttons are in. Used outside one, the
    // buttons keep the colours they had before they followed the theme.
    final defaults = ShowcaseActionColors.maybeOf(context);
    final foreground = defaults?.foreground ?? ShowcaseColors.fallback.accent;
    final divider = verticalDividerColor ?? defaults?.divider ?? ShowcaseColors.fallback.outline;

    return Row(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      verticalDirection: verticalDirection,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: textBaseline,
      textDirection: textDirection,
      children: [
        if (previous.buttonVisible)
          _getButtonWidget(
            previous,
            foreground,
            previous.text ?? labels.previous,
            previous.callback ??
                () {
                  if (showcaseContext != null && ShowCaseWidget.of(showcaseContext).ids != null) {
                    ShowCaseWidget.of(showcaseContext).previous();
                  }
                },
          ),
        if (previous.buttonVisible && stop.buttonVisible || previous.buttonVisible && next.buttonVisible)
          _getVerticalDivider(divider),
        if (stop.buttonVisible)
          _getButtonWidget(
            stop,
            foreground,
            stop.text ?? labels.stop,
            stop.callback ??
                () {
                  if (showcaseContext != null && ShowCaseWidget.of(showcaseContext).ids != null) {
                    ShowCaseWidget.of(showcaseContext).dismiss();
                  }
                },
          ),
        if (stop.buttonVisible && next.buttonVisible) _getVerticalDivider(divider),
        if (next.buttonVisible)
          _getButtonWidget(
            next,
            foreground,
            next.text ?? labels.next,
            next.callback ??
                () {
                  if (showcaseContext != null && ShowCaseWidget.of(showcaseContext).ids != null) {
                    ShowCaseWidget.of(showcaseContext).completed(
                      ShowCaseWidget.of(showcaseContext).ids![ShowCaseWidget.of(showcaseContext).activeWidgetId ?? 0],
                    );
                  }
                },
          ),
      ],
    );
  }

  Widget _getVerticalDivider(Color color) {
    return VerticalDivider(width: 1.0, thickness: dividerThickness, color: color);
  }

  Widget _getButtonWidget(
    ActionButtonConfig actionConfig,
    Color defaultTextColor,
    String buttonText,
    VoidCallback onClick,
  ) {
    final icon = actionConfig.icon;
    final label = actionConfig.buttonTextVisible
        ? Text(
            buttonText,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: actionConfig.textColor ?? defaultTextColor),
          )
        : null;
    // The icon leads, so it follows the text direction: left of the label in
    // a left-to-right app, right of it in a right-to-left one.
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?icon,
        if (icon != null && label != null) const SizedBox(width: 8),
        // Flexible, so that past the smallest scale the label is ellipsized
        // rather than pushing the row out of the button.
        if (label != null) Flexible(child: label),
      ],
    );
    final button = TextButton(
      style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(actionConfig.textButtonBgColor)),
      onPressed: onClick,
      // A label that does not fit (e.g. a long translation on a narrow
      // screen) stays on one line and is scaled down with its icon, instead
      // of breaking mid-word. Only the content scales: the button keeps its
      // size, and so its tap target.
      child: _ScaleDownToWidth(
        // With the text hidden, the label is still what screen readers announce.
        child: label == null ? Semantics(label: buttonText, child: content) : content,
      ),
    );

    final textDirection = actionConfig.textDirection;
    return Expanded(
      child: textDirection == null ? button : Directionality(textDirection: textDirection, child: button),
    );
  }
}

/// Lays [child] out at its natural width, on one line, and scales it down
/// uniformly when that is wider than the space available.
///
/// The scale never goes below [_RenderScaleDownToWidth.minScale], so the text
/// stays readable. Below that the child is laid out narrower than its natural
/// width, and the label (a [Flexible] with [TextOverflow.ellipsis]) is
/// ellipsized.
///
/// Unlike a [FittedBox], the child keeps the incoming height limit, so an
/// icon such as an unsized [Image] is sized the way a button would size it
/// rather than at its full resolution (which would then shrink the label
/// next to it too).
class _ScaleDownToWidth extends SingleChildRenderObjectWidget {
  const _ScaleDownToWidth({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderScaleDownToWidth();
}

class _RenderScaleDownToWidth extends RenderProxyBox {
  /// The smallest scale the content is drawn at.
  static const double minScale = 0.7;

  double _scale = 1.0;

  /// The scale [child] is drawn at under [constraints], and the constraints
  /// it is laid out with.
  ({double scale, BoxConstraints childConstraints}) _fit(BoxConstraints constraints, RenderBox child) {
    final natural = child.getMaxIntrinsicWidth(constraints.maxHeight);
    final available = constraints.hasBoundedWidth ? constraints.maxWidth : natural;
    final scale = natural <= available || natural == 0 ? 1.0 : max(available / natural, minScale);
    // At the smallest scale the child gets only the room that is left, and
    // its label is ellipsized. Otherwise it fits at its natural width; the
    // slack keeps rounding from ellipsizing the last letter.
    final maxWidth = scale == minScale ? available / minScale : natural + 0.5;
    return (scale: scale, childConstraints: BoxConstraints(maxWidth: maxWidth, maxHeight: constraints.maxHeight));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final fit = _fit(constraints, child);
    return constraints.constrain(child.getDryLayout(fit.childConstraints) * fit.scale);
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    final child = this.child;
    if (child == null) return null;
    final fit = _fit(constraints, child);
    final distance = child.getDryBaseline(fit.childConstraints, baseline);
    return distance == null ? null : distance * fit.scale;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      _scale = 1.0;
      size = constraints.smallest;
      return;
    }
    final fit = _fit(constraints, child);
    child.layout(fit.childConstraints, parentUsesSize: true);
    _scale = fit.scale;
    size = constraints.constrain(child.size * _scale);
  }

  // The child is drawn scaled, so its baseline is too.
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final distance = child?.getDistanceToActualBaseline(baseline);
    return distance == null ? null : distance * _scale;
  }

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1.0);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1.0) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_transform);
}

/// Styling and behavior configuration for a single action button rendered by
/// [ShowCaseDefaultActions], such as Next, Previous or Stop.
class ActionButtonConfig {
  /// Button text.
  ///
  /// When `null` (the default) it is the matching [ShowCaseWidget.labels]
  /// entry: `'Next'`, `'Previous'` or `'Stop'` unless the tour translates them.
  /// Also announced by screen readers when [buttonTextVisible] is `false`.
  final String? text;

  /// button icon or image
  final Widget? icon;

  /// Color of button text.
  ///
  /// When `null` (the default) it is [ShowcaseStyle.actionTextColor], or else
  /// follows the app's theme: `colorScheme.primary` on the default tooltip,
  /// and white or black, whichever is readable, on a background you chose.
  final Color? textColor;

  /// Color of button background.
  final Color textButtonBgColor;

  /// Callback on button tap.
  ///
  /// Note: Default callback will be overridden by this one.
  final VoidCallback? callback;

  /// Defines visibility of button.
  final bool buttonVisible;

  /// Whether the button shows its text. When `false` only [icon] is shown,
  /// and the text is still announced by screen readers.
  final bool buttonTextVisible;

  /// The order of [icon] and text inside the button.
  ///
  /// When `null` (the default) the button follows the app's text direction:
  /// the icon comes first, which is on the left in a left-to-right app and on
  /// the right in a right-to-left one. Set [TextDirection.rtl] in a
  /// left-to-right app to put the icon after the text, e.g. a Next arrow.
  final TextDirection? textDirection;

  /// Creates a configuration for a single tooltip action button.
  const ActionButtonConfig({
    this.text,
    this.icon,
    this.textColor,
    this.textButtonBgColor = Colors.transparent,
    this.callback,
    this.buttonVisible = true,
    this.buttonTextVisible = true,
    this.textDirection,
  });
}
