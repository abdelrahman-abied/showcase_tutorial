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

import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../showcase_tutorial.dart';
import 'animated_transforms.dart';
import 'get_position.dart';
import 'measure_size.dart';
import 'utilities/_showcase_colors.dart';
import 'utilities/_showcase_context_provider.dart';

class ToolTipWidget extends StatefulWidget {
  final GetPosition? position;
  final Offset? offset;
  final Size? screenSize;
  final String? title;
  final TextAlign? titleAlignment;
  final String? description;
  final TextAlign? descriptionAlignment;
  final TextStyle? titleTextStyle;
  final TextStyle? descTextStyle;
  final Widget? container;
  final Color? tooltipBackgroundColor;

  /// Whether [tooltipBackgroundColor] is the theme's own tooltip colour, as
  /// opposed to one the developer chose.
  final bool isThemeBackground;
  final Color? textColor;

  /// The colours for anything the developer left unset.
  final ShowcaseColors colors;

  /// The dimmed background, which action buttons without a container sit on.
  final Color scrimColor;

  /// Tour-wide colour of the action button labels, if the developer set one.
  final Color? actionTextColor;

  /// Tour-wide colour of the divider between action buttons, if set.
  final Color? actionDividerColor;
  final bool showArrow;

  /// Color of the arrow. Falls back to [tooltipBackgroundColor] when null.
  final Color? arrowColor;

  /// Width (base) of the arrow.
  final double arrowWidth;

  /// Height (depth toward the target) of the arrow.
  final double arrowHeight;

  /// Extra space (logical pixels) between the target and the tooltip, added on
  /// top of the default offset. `0` keeps the original spacing.
  final double targetTooltipGap;

  /// Minimum margin between the tooltip and the screen edges.
  final EdgeInsets toolTipMargin;

  /// The [container]'s height and width as the developer declared them
  /// ([Showcase.height] and [Showcase.width]). When either is `null` the
  /// container is measured, and positioned once its size is known.
  final double? contentHeight;
  final double? contentWidth;
  final VoidCallback? onTooltipTap;

  /// Cursor shown while hovering the tooltip on web/desktop, already resolved by
  /// [Showcase] (see [Showcase.tooltipMouseCursor]).
  final MouseCursor mouseCursor;

  /// Whether the tour opts into pointer cursors, used for the parts of the
  /// tooltip that are always clickable — currently the "Skip" button.
  final bool enablePointerCursor;

  final EdgeInsets? tooltipPadding;
  final Duration movingAnimationDuration;
  final bool disableMovingAnimation;
  final bool disableScaleAnimation;
  final BorderRadius? tooltipBorderRadius;
  final Duration scaleAnimationDuration;
  final Curve scaleAnimationCurve;
  final Alignment? scaleAnimationAlignment;
  final bool isTooltipDismissed;
  final TooltipPosition? tooltipPosition;
  final EdgeInsets? titlePadding;
  final EdgeInsets? descriptionPadding;
  final Widget? actions;
  final ActionsSettings? actionSettings;
  final ActionButtonsPosition? actionButtonsPosition;

  /// Whether [actions] are drawn inside the tooltip box or positioned outside.
  final TooltipActionPosition actionsPosition;

  /// Whether to render a built-in step indicator in the default tooltip.
  final bool showProgress;

  /// How the step indicator is rendered (dots or a numeric counter).
  final ShowcaseProgressStyle progressStyle;

  /// Whether to render a "Skip" button in the default tooltip.
  final bool showSkip;

  /// Label for the skip button.
  final String skipText;

  /// Zero-based index of the active step (for the progress indicator).
  final int currentStep;

  /// Total number of steps in the running tour (for the progress indicator).
  final int totalSteps;

  /// Called when the skip button is tapped.
  final VoidCallback? onSkip;

  //final GlobalKey key;

  const ToolTipWidget({
    super.key,
    required this.position,
    required this.offset,
    required this.screenSize,
    required this.title,
    required this.titleAlignment,
    required this.description,
    required this.titleTextStyle,
    required this.descTextStyle,
    required this.container,
    required this.tooltipBackgroundColor,
    this.isThemeBackground = false,
    required this.textColor,
    this.colors = ShowcaseColors.fallback,
    this.scrimColor = Colors.black45,
    this.actionTextColor,
    this.actionDividerColor,
    required this.showArrow,
    this.arrowColor,
    this.arrowWidth = 18.0,
    this.arrowHeight = 9.0,
    this.targetTooltipGap = 0.0,
    this.toolTipMargin = const EdgeInsets.all(20),
    required this.contentHeight,
    required this.contentWidth,
    required this.onTooltipTap,
    this.mouseCursor = MouseCursor.defer,
    this.enablePointerCursor = true,
    required this.movingAnimationDuration,
    required this.descriptionAlignment,
    this.tooltipPadding = const EdgeInsets.symmetric(vertical: 8),
    required this.disableMovingAnimation,
    required this.disableScaleAnimation,
    required this.tooltipBorderRadius,
    required this.scaleAnimationDuration,
    required this.scaleAnimationCurve,
    this.scaleAnimationAlignment,
    this.isTooltipDismissed = false,
    this.tooltipPosition,
    this.titlePadding,
    this.descriptionPadding,
    this.actions,
    this.actionSettings,
    this.actionButtonsPosition,
    this.actionsPosition = TooltipActionPosition.outside,
    this.showProgress = false,
    this.progressStyle = ShowcaseProgressStyle.dots,
    this.showSkip = false,
    this.skipText = 'Skip',
    this.currentStep = 0,
    this.totalSteps = 0,
    this.onSkip,
  });

  @override
  State<ToolTipWidget> createState() => _ToolTipWidgetState();
}

class _ToolTipWidgetState extends State<ToolTipWidget> with TickerProviderStateMixin {
  Offset? position;

  bool isArrowUp = false;

  late final AnimationController _movingAnimationController;
  late final Animation<double> _movingAnimation;
  late final AnimationController _scaleAnimationController;
  late final Animation<double> _scaleAnimation;

  double tooltipWidth = 0;
  double tooltipHeight = 0;
  double actionWidgetHeight = 0;
  double tooltipTextPadding = 15;

  TooltipPosition findPositionForContent(Offset position) {
    var height = 120.0;
    height = _containerHeight ?? height;
    final bottomPosition = position.dy + ((widget.position?.getHeight() ?? 0) / 2);
    final topPosition = position.dy - ((widget.position?.getHeight() ?? 0) / 2);
    final hasSpaceInTop = topPosition >= height;
    final hasSpaceInBottom = (_visibleScreenHeight - bottomPosition) >= height;
    return widget.tooltipPosition ??
        (hasSpaceInTop && !hasSpaceInBottom ? TooltipPosition.top : TooltipPosition.bottom);
  }

  /// The height of the screen above the keyboard, if one is open.
  double get _visibleScreenHeight {
    final view = View.of(context);
    final viewInsets = EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio);
    return (widget.screenSize?.height ?? MediaQuery.sizeOf(context).height) - viewInsets.bottom;
  }

  /// Leeway for the fit checks below, so rounding never moves a tooltip.
  static const _fitTolerance = 0.5;

  /// Whether the tooltip can take the left/right layout. A custom container
  /// and *outside* actions keep the vertical one (see [build]).
  bool get _canGoBeside =>
      widget.container == null &&
      (widget.actions == null || widget.actionsPosition.isInside) &&
      widget.position != null;

  /// The side of the target the tooltip goes on.
  ///
  /// A tooltip that fits where it has always gone stays there. Only one that
  /// does not moves, and only to a side where it does fit:
  ///
  /// * a requested side it does not fit on gives way to the opposite side
  ///   (top and bottom, left and right);
  /// * with no side requested, a tooltip that fits neither above nor below
  ///   the target goes beside it, on whichever of left and right it fits.
  ///
  /// Where nothing fits, the tooltip is placed as it always was.
  TooltipPosition _resolvePosition() {
    final requested = widget.tooltipPosition;
    if (widget.position == null) return findPositionForContent(position!);
    switch (requested) {
      case null:
        final usual = findPositionForContent(position!);
        if (!_canGoBeside) return usual;
        // Judged first by the estimate the tooltip is sized with, which is
        // cheap and rarely short of its real height; only a tooltip that
        // misses on both sides by it is measured.
        if (_fitsVertically(above: true, estimate: true) || _fitsVertically(above: false, estimate: true)) {
          return usual;
        }
        if (_fitsVertically(above: true) || _fitsVertically(above: false)) return usual;
        final fitsLeft = _fitsBeside(isLeft: true);
        final fitsRight = _fitsBeside(isLeft: false);
        if (fitsLeft && fitsRight) {
          // Physical sides: the one with more room, whatever the direction.
          final rect = widget.position!.getRect();
          final roomLeft = rect.left;
          final roomRight = MediaQuery.sizeOf(context).width - rect.right;
          return roomLeft > roomRight ? TooltipPosition.left : TooltipPosition.right;
        }
        if (fitsLeft) return TooltipPosition.left;
        if (fitsRight) return TooltipPosition.right;
        return usual;
      case TooltipPosition.top || TooltipPosition.bottom:
        final above = requested == TooltipPosition.top;
        if (!_fitsVertically(above: above) && _fitsVertically(above: !above)) {
          return above ? TooltipPosition.bottom : TooltipPosition.top;
        }
        return requested;
      case TooltipPosition.left || TooltipPosition.right:
        // Without the left/right layout it is placed above, as it always was.
        if (!_canGoBeside) return requested;
        final isLeft = requested == TooltipPosition.left;
        if (!_fitsBeside(isLeft: isLeft) && _fitsBeside(isLeft: !isLeft)) {
          return isLeft ? TooltipPosition.right : TooltipPosition.left;
        }
        return requested;
    }
  }

  /// Whether the tooltip, placed [above] or below the target by the vertical
  /// layout in [build], lies within the visible screen.
  ///
  /// It is judged where it rests before it starts to bob (where it stays
  /// when the moving animation is off), and by a height it is at least as
  /// tall as, so one judged not to fit really does not. With [estimate], the
  /// default tooltip is judged by [tooltipHeight] instead, which is no such
  /// promise.
  bool _fitsVertically({required bool above, bool estimate = false}) {
    final custom = widget.container != null;
    // A container that is not measured yet is not shown either; it is judged
    // once it is.
    final height = custom
        ? _containerHeight
        : _verticalHeight(above: above, boxHeight: estimate ? tooltipHeight : _minBoxHeight);
    if (height == null) return true;
    final targetOffset = 3 + widget.targetTooltipGap;
    if (above) {
      final contentY = widget.position!.getTop() - targetOffset;
      // Translated up by its own height, then a tenth more by the moving
      // animation's starting point. A container sits in a 10px padding and
      // is placed 10px higher.
      final top = custom ? contentY - 11 - 1.1 * height : contentY - 1.1 * height;
      return top >= -_fitTolerance;
    }
    final contentY = widget.position!.getBottom() + targetOffset;
    return contentY + height <= _visibleScreenHeight + _fitTolerance;
  }

  /// The height the default tooltip takes in the vertical layout, placed
  /// [above] or below the target, around a box [boxHeight] tall.
  double _verticalHeight({required bool above, required double boxHeight}) {
    // The arrow's room, kept even without the arrow, and the margin around it.
    var height = max(0.0, widget.arrowHeight - 1) + boxHeight;
    if (widget.showArrow) height += above ? 18 : 13;
    return height;
  }

  /// The least height of the default tooltip's box: its text wrapped to the
  /// box's width, the footer and inside actions. Inside actions count only
  /// the height the caller declared, as nothing more is known about them.
  ///
  /// Text is laid out as the [Text] widgets in the box are, under the
  /// [Material] that sets their default style. Measured when first needed,
  /// which a tooltip that fits where it always went seldom does.
  double get _minBoxHeight => _minBoxHeightCache ??= _measureMinBoxHeight();
  double? _minBoxHeightCache;

  double _measureMinBoxHeight() {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final padding = widget.tooltipPadding ?? EdgeInsets.zero;
    final contentWidth = max(0.0, tooltipWidth - padding.horizontal);
    double textHeight(String text, TextStyle style, EdgeInsets? textPadding) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      )..layout(maxWidth: max(0.0, contentWidth - (textPadding?.horizontal ?? 0)));
      final height = painter.height;
      painter.dispose();
      return height + (textPadding?.vertical ?? 0);
    }

    var height = padding.vertical;
    if (widget.title != null) {
      final style = widget.titleTextStyle ?? theme.textTheme.titleLarge!.merge(TextStyle(color: widget.textColor));
      height += textHeight(widget.title!, style, widget.titlePadding);
    }
    if (widget.description != null) {
      final style = widget.descTextStyle ?? theme.textTheme.titleSmall!.merge(TextStyle(color: widget.textColor));
      height += textHeight(widget.description!, style, widget.descriptionPadding);
    }
    // The footer's top padding; its row is at least as tall as nothing.
    if (_hasFooter) height += 8;
    if (_hasInsideActions) {
      height +=
          (widget.actionSettings?.containerPadding ?? const EdgeInsets.only(top: 8)).vertical +
          (widget.actionSettings?.containerHeight ?? 0);
    }
    return height;
  }

  /// The left edge of the tooltip in the left/right layout, [isLeft] or right
  /// of the target: beside it, then held within [ToolTipWidget.toolTipMargin].
  double _besideLeft({required bool isLeft}) {
    final gap = 6.0 + widget.targetTooltipGap;
    // Use getRect() for the target's edges: GetPosition.getLeft()/getRight()
    // are unreliable, only getRect() (and getCenter()) are computed correctly.
    final rect = widget.position!.getRect();
    final screenW = MediaQuery.sizeOf(context).width;
    final totalWidth = _besideWidth;
    final left = isLeft ? rect.left - gap - totalWidth : rect.right + gap;
    final maxLeft = max(widget.toolTipMargin.left, screenW - totalWidth - widget.toolTipMargin.right);
    return left.clamp(widget.toolTipMargin.left, maxLeft);
  }

  /// The width of the tooltip in the left/right layout, arrow included.
  double get _besideWidth => tooltipWidth + (widget.showArrow ? widget.arrowHeight : 0.0);

  /// The top edge of the tooltip in the left/right layout: centred on the
  /// target, then held within [ToolTipWidget.toolTipMargin].
  double get _besideTop {
    final targetCenterY = widget.position!.getRect().center.dy;
    final screenH = MediaQuery.sizeOf(context).height;
    final maxTop = max(widget.toolTipMargin.top, screenH - tooltipHeight - widget.toolTipMargin.bottom);
    return (targetCenterY - tooltipHeight / 2).clamp(widget.toolTipMargin.top, maxTop);
  }

  /// Whether the tooltip's box, placed [isLeft] or right of the target, lies
  /// on screen without covering the target. Held within the margins, it would
  /// cover a target too near that edge.
  ///
  /// The box is taken at the least height it can have, and without the
  /// arrow, so one judged not to fit really does not.
  bool _fitsBeside({required bool isLeft}) {
    final target = widget.position!.getRect();
    final screen = MediaQuery.sizeOf(context);
    final arrow = widget.showArrow && !isLeft ? widget.arrowHeight : 0.0;
    final box = Rect.fromLTWH(_besideLeft(isLeft: isLeft) + arrow, _besideTop, tooltipWidth, _minBoxHeight);
    final onScreen =
        box.left >= -_fitTolerance &&
        box.top >= -_fitTolerance &&
        box.right <= screen.width + _fitTolerance &&
        box.bottom <= screen.height + _fitTolerance;
    final overlap = box.intersect(target);
    final clear = overlap.width <= _fitTolerance || overlap.height <= _fitTolerance;
    return onScreen && clear;
  }

  void _getTooltipWidth() {
    final titleStyle =
        widget.titleTextStyle ?? Theme.of(context).textTheme.titleLarge!.merge(TextStyle(color: widget.textColor));
    final descriptionStyle =
        widget.descTextStyle ?? Theme.of(context).textTheme.titleSmall!.merge(TextStyle(color: widget.textColor));
    final titleLength = widget.title == null
        ? 0
        : _textSize(widget.title!, titleStyle).width +
              widget.tooltipPadding!.right +
              widget.tooltipPadding!.left +
              (widget.titlePadding?.right ?? 0) +
              (widget.titlePadding?.left ?? 0);
    final descriptionLength = widget.description == null
        ? 0
        : (_textSize(widget.description!, descriptionStyle).width +
              widget.tooltipPadding!.right +
              widget.tooltipPadding!.left +
              (widget.descriptionPadding?.right ?? 0) +
              (widget.descriptionPadding?.left ?? 0));
    var maxTextWidth = max(
      max(max(titleLength, descriptionLength), max(_footerWidth, _insideActionsWidth)),
      _defaultActionsWidth,
    );
    if (maxTextWidth > widget.screenSize!.width - widget.toolTipMargin.horizontal) {
      tooltipWidth = widget.screenSize!.width - widget.toolTipMargin.horizontal;
    } else {
      tooltipWidth = maxTextWidth + tooltipTextPadding;
    }
  }

  void _getTooltipHeight() {
    final titleStyle =
        widget.titleTextStyle ?? Theme.of(context).textTheme.titleLarge!.merge(TextStyle(color: widget.textColor));
    final descriptionStyle =
        widget.descTextStyle ?? Theme.of(context).textTheme.titleSmall!.merge(TextStyle(color: widget.textColor));
    final titleLength = widget.title == null
        ? 0
        : _textSize(widget.title!, titleStyle).height + widget.tooltipPadding!.bottom + widget.tooltipPadding!.top;
    final descriptionLength = widget.description == null
        ? 0
        : (_textSize(widget.description!, descriptionStyle).height +
              widget.tooltipPadding!.bottom +
              widget.tooltipPadding!.top);
    var maxTextHeight = titleLength + descriptionLength + _footerHeight + _insideActionsHeight;
    if (maxTextHeight > widget.screenSize!.height - widget.toolTipMargin.vertical) {
      tooltipHeight = widget.screenSize!.height - widget.toolTipMargin.vertical;
    } else {
      tooltipHeight = maxTextHeight + tooltipTextPadding;
    }
  }

  /// Whether the built-in progress/skip footer is shown in the default tooltip.
  bool get _hasFooter => (widget.showProgress || widget.showSkip) && widget.totalSteps > 0;

  /// Reserved vertical space for the progress/skip footer.
  double get _footerHeight => _hasFooter ? 28.0 : 0.0;

  /// Whether the action buttons flow inside the tooltip box rather than being
  /// positioned outside it.
  bool get _hasInsideActions => widget.actions != null && widget.actionsPosition.isInside;

  /// Vertical space the tooltip reserves for inside actions.
  ///
  /// The widget belongs to the caller, so its height cannot be measured the way
  /// the title and description are. [ActionsSettings.containerHeight] is how to
  /// say how much room it needs; 40 matches the height the outside placement
  /// has always given it.
  double get _insideActionsHeight => _hasInsideActions ? (widget.actionSettings?.containerHeight ?? 40.0) : 0.0;

  /// Width the tooltip reserves for inside actions, when the caller declared
  /// one. Without it the actions take whatever width the text sets.
  double get _insideActionsWidth {
    if (!_hasInsideActions) return 0;
    final declared = widget.actionSettings?.containerWidth;
    if (declared == null) return 0;
    return declared + widget.tooltipPadding!.left + widget.tooltipPadding!.right;
  }

  /// Width the tooltip needs so the labels of [ShowCaseDefaultActions] fit
  /// their buttons at full size, or 0 for other actions.
  ///
  /// The buttons share the row equally, so every button needs the room of
  /// the widest one. The estimate follows [TextButton]'s defaults: its label
  /// style, padding and minimum width. A declared
  /// [ActionsSettings.containerWidth] for inside actions sets their width
  /// instead (see [_insideActionsWidth]).
  double get _defaultActionsWidth {
    final actions = widget.actions;
    if (actions is! ShowCaseDefaultActions) return 0;
    if (_hasInsideActions && widget.actionSettings?.containerWidth != null) return 0;
    final theme = Theme.of(context);
    final labels = ShowcaseContextProvider.of(context)?.labels ?? const ShowcaseLabels();
    final labelStyle = theme.textTheme.labelLarge ?? const TextStyle(fontSize: 14);
    final padding = theme.useMaterial3 ? 24.0 : 16.0;
    double buttonWidth(ActionButtonConfig config, String label) {
      final icon = config.icon;
      final iconWidth = icon == null
          ? 0.0
          : icon is Icon
          ? icon.size ?? (theme.useMaterial3 ? 18.0 : 24.0)
          : 24.0;
      final textWidth = config.buttonTextVisible ? _textSize(config.text ?? label, labelStyle).width : 0.0;
      final gap = icon != null && config.buttonTextVisible ? 8.0 : 0.0;
      return max(64.0, iconWidth + gap + textWidth + padding);
    }

    final widths = [
      if (actions.previous.buttonVisible) buttonWidth(actions.previous, labels.previous),
      if (actions.stop.buttonVisible) buttonWidth(actions.stop, labels.stop),
      if (actions.next.buttonVisible) buttonWidth(actions.next, labels.next),
    ];
    if (widths.isEmpty) return 0;
    // One-pixel dividers sit between the buttons.
    final row = widths.reduce(max) * widths.length + (widths.length - 1);
    // Outside actions are as wide as the tooltip; inside ones sit within its
    // padding.
    return _hasInsideActions ? row + widget.tooltipPadding!.left + widget.tooltipPadding!.right : row;
  }

  /// Builds the action row that flows inside the tooltip box, or `null` when
  /// the actions are positioned outside it (or absent).
  Widget? _buildInsideActions() {
    if (!_hasInsideActions) return null;
    // With no container colour the buttons sit on the tooltip itself.
    final containerColor = widget.actionSettings?.containerColor;
    return Padding(
      padding: widget.actionSettings?.containerPadding ?? const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: widget.actionSettings?.containerHeight,
        width: widget.actionSettings?.containerWidth,
        child: ColoredBox(
          color: containerColor ?? Colors.transparent,
          child: _withActionColors(
            widget.actions!,
            background: containerColor ?? widget.tooltipBackgroundColor!,
            isThemeBackground: containerColor == null && widget.isThemeBackground,
          ),
        ),
      ),
    );
  }

  /// The colour of the box drawn behind actions placed outside the tooltip.
  ///
  /// Without [ActionsSettings] there is no box and the buttons sit on the
  /// dimmed background (`null`). With settings, the box takes
  /// [ActionsSettings.containerColor], or the tooltip's colour when that is
  /// unset, so the two match.
  Color? get _outsideActionsColor {
    final settings = widget.actionSettings;
    if (settings == null) return null;
    return settings.containerColor ?? widget.tooltipBackgroundColor;
  }

  /// Wraps the outside [ToolTipWidget.actions] with their default colours.
  Widget _outsideActions() {
    final boxColor = _outsideActionsColor;
    return _withActionColors(
      widget.actions!,
      background: boxColor ?? widget.scrimColor,
      isThemeBackground: boxColor != null && widget.actionSettings?.containerColor == null && widget.isThemeBackground,
    );
  }

  /// Gives the action buttons in [actions] the default colours for the
  /// [background] they are drawn on. A colour set on a button itself, or
  /// tour-wide in [ShowcaseStyle], still wins.
  Widget _withActionColors(Widget actions, {required Color background, required bool isThemeBackground}) {
    return ShowcaseActionColors(
      foreground:
          widget.actionTextColor ?? widget.colors.actionForegroundOn(background, isThemeBackground: isThemeBackground),
      divider:
          widget.actionDividerColor ?? widget.colors.actionDividerOn(background, isThemeBackground: isThemeBackground),
      child: actions,
    );
  }

  /// The "current / total" label for the numeric progress style, e.g. `1/6`.
  /// [ToolTipWidget.currentStep] is zero-based, so it is shown one-based.
  String get _progressLabel => '${widget.currentStep + 1}/${widget.totalSteps}';

  /// Text style shared by the numeric progress label (measurement + render).
  static const _progressTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

  /// Estimated horizontal space the footer needs, so the tooltip is measured
  /// wide enough to fit the indicator and the skip button.
  double get _footerWidth {
    if (!_hasFooter) return 0;
    var w = 0.0;
    if (widget.showProgress) {
      w += switch (widget.progressStyle) {
        ShowcaseProgressStyle.numeric => _textSize(_progressLabel, _progressTextStyle).width + 16,
        ShowcaseProgressStyle.dots => widget.totalSteps * 10.0 + 16,
      };
    }
    if (widget.showSkip) {
      w += _textSize(widget.skipText, const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)).width + 16;
    }
    if (widget.showProgress && widget.showSkip) w += 16; // gap
    return w + widget.tooltipPadding!.left + widget.tooltipPadding!.right;
  }

  /// Builds the dots + skip footer row, or `null` when neither is enabled.
  Widget? _buildProgressFooter() {
    if (!_hasFooter) return null;
    final color = widget.textColor ?? Colors.black;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showProgress)
            switch (widget.progressStyle) {
              ShowcaseProgressStyle.numeric => Text(_progressLabel, style: _progressTextStyle.copyWith(color: color)),
              ShowcaseProgressStyle.dots => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.totalSteps, (i) {
                  final isActive = i == widget.currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? color : color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            }
          else
            const SizedBox.shrink(),
          if (widget.showSkip)
            MouseRegion(
              // Always a real button, so it opts in with the tour rather than
              // with the tooltip body's resolved cursor.
              cursor: widget.enablePointerCursor ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSkip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    widget.skipText,
                    style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Makes [child] the tooltip's tap surface, and — on web/desktop — shows the
  /// cursor [Showcase] resolved for it while the pointer is over it.
  Widget _tappable({required Widget child}) => MouseRegion(
    cursor: widget.mouseCursor,
    child: GestureDetector(onTap: widget.onTooltipTap, child: child),
  );

  double? _getLeft() {
    if (widget.position != null) {
      final width = widget.container != null ? _customContainerWidth.value : tooltipWidth;
      double leftPositionValue = widget.position!.getCenter() - (width * 0.5);
      if ((leftPositionValue + width) > MediaQuery.sizeOf(context).width) {
        return null;
      } else if ((leftPositionValue) < widget.toolTipMargin.left) {
        return widget.toolTipMargin.left;
      } else {
        return leftPositionValue;
      }
    }
    return null;
  }

  double? _getRight() {
    if (widget.position != null) {
      final width = widget.container != null ? _customContainerWidth.value : tooltipWidth;

      final left = _getLeft();
      if (left == null || (left + width) > MediaQuery.sizeOf(context).width) {
        final rightPosition = widget.position!.getCenter() + (width * 0.5);

        return (rightPosition + width) > MediaQuery.sizeOf(context).width ? widget.toolTipMargin.right : null;
      } else {
        return null;
      }
    }
    return null;
  }

  double _getSpace() {
    final screenWidth = widget.screenSize!.width;
    // Only null while the container is hidden, waiting to be measured.
    final contentWidth = _containerWidth ?? 0;
    var space = widget.position!.getCenter() - (contentWidth / 2);
    // Keep the custom container (Showcase.withWidget) within the screen-edge
    // margins, mirroring how the default tooltip clamps to toolTipMargin.
    final maxLeft = max(widget.toolTipMargin.left, screenWidth - contentWidth - widget.toolTipMargin.right);
    space = space.clamp(widget.toolTipMargin.left, maxLeft);
    return space;
  }

  double _getAlignmentX() {
    final calculatedLeft = _getLeft();
    var left = calculatedLeft == null ? 0 : (widget.position!.getCenter() - calculatedLeft);
    var right = _getLeft() == null
        ? (MediaQuery.sizeOf(context).width - widget.position!.getCenter()) - (_getRight() ?? 0)
        : 0;
    final containerWidth = widget.container != null ? _customContainerWidth.value : tooltipWidth;

    if (left != 0) {
      return (-1 + (2 * (left / containerWidth)));
    } else {
      return (1 - (2 * (right / containerWidth)));
    }
  }

  double _getAlignmentY() {
    var dy = isArrowUp
        ? -1.0
        : (MediaQuery.sizeOf(context).height / 2) < widget.position!.getTop()
        ? -1.0
        : 1.0;
    return dy;
  }

  final GlobalKey _customContainerKey = GlobalKey();
  final ValueNotifier<double> _customContainerWidth = ValueNotifier<double>(1);

  /// The custom container's laid-out size, as [MeasureSize] last reported it.
  Size? _measuredContainerSize;

  /// Whether the container's size is measured rather than declared: one of
  /// [ToolTipWidget.contentHeight] and [ToolTipWidget.contentWidth] is `null`.
  bool get _measuresContainer =>
      widget.container != null && (widget.contentHeight == null || widget.contentWidth == null);

  /// The container's height for placement: declared, or else measured.
  double? get _containerHeight => widget.contentHeight ?? _measuredContainerSize?.height;

  /// The container's width for placement: declared, or else measured.
  double? get _containerWidth => widget.contentWidth ?? _measuredContainerSize?.width;

  /// Whether the container is laid out but not yet measured. Its position
  /// depends on its size, so until then it is kept off stage: neither painted
  /// nor tappable, rather than drawn for a frame in the wrong place.
  bool get _awaitsContainerSize => _measuresContainer && _measuredContainerSize == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.container != null &&
          _customContainerKey.currentContext != null &&
          _customContainerKey.currentContext?.size != null) {
        setState(() {
          _customContainerWidth.value = _customContainerKey.currentContext!.size!.width;
        });
      }
    });
    _movingAnimationController = AnimationController(duration: widget.movingAnimationDuration, vsync: this);
    _movingAnimation = CurvedAnimation(parent: _movingAnimationController, curve: Curves.easeInOut);
    _scaleAnimationController = AnimationController(
      duration: widget.scaleAnimationDuration,
      vsync: this,
      lowerBound: widget.disableScaleAnimation ? 1 : 0,
    );
    _scaleAnimation = CurvedAnimation(parent: _scaleAnimationController, curve: widget.scaleAnimationCurve);
    if (widget.disableScaleAnimation) {
      movingAnimationListener();
    } else {
      _scaleAnimationController
        ..addStatusListener((scaleAnimationStatus) {
          if (scaleAnimationStatus == AnimationStatus.completed) {
            movingAnimationListener();
          }
        })
        ..forward();
    }
    if (!widget.disableMovingAnimation) {
      _movingAnimationController.forward();
    }
  }

  void movingAnimationListener() {
    _movingAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _movingAnimationController.reverse();
      }
      if (_movingAnimationController.isDismissed) {
        if (!widget.disableMovingAnimation) {
          _movingAnimationController.forward();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    _getTooltipWidth();
    _getTooltipHeight();
    _minBoxHeightCache = null;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _movingAnimationController.dispose();
    _scaleAnimationController.dispose();

    super.dispose();
  }

  /// Builds the tooltip to the left or right of the target, with the arrow
  /// pointing horizontally at it and the tooltip vertically centred on it.
  Widget _buildHorizontalTooltip({required bool isLeft}) {
    final arrowShort = widget.arrowHeight; // arrow depth toward the target
    final arrowLong = widget.arrowWidth; // arrow span along the tooltip edge
    final showArrow = widget.showArrow;

    final left = _besideLeft(isLeft: isLeft);
    final top = _besideTop;

    if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
      _scaleAnimationController.reverse();
    }

    final arrow = SizedBox(
      width: arrowShort,
      height: arrowLong,
      child: CustomPaint(
        painter: _Arrow(
          strokeColor: widget.arrowColor ?? widget.tooltipBackgroundColor!,
          strokeWidth: 10,
          paintingStyle: PaintingStyle.fill,
          direction: isLeft ? _ArrowDirection.right : _ArrowDirection.left,
        ),
      ),
    );

    final box = ClipRRect(
      borderRadius: widget.tooltipBorderRadius ?? BorderRadius.circular(8.0),
      child: _tappable(
        child: Container(
          width: tooltipWidth,
          padding: widget.tooltipPadding,
          color: widget.tooltipBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: widget.title != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.title != null)
                Padding(
                  padding: widget.titlePadding ?? EdgeInsets.zero,
                  child: Text(
                    widget.title!,
                    textAlign: widget.titleAlignment,
                    style:
                        widget.titleTextStyle ??
                        Theme.of(context).textTheme.titleLarge!.merge(TextStyle(color: widget.textColor)),
                  ),
                ),
              if (widget.description != null)
                Padding(
                  padding: widget.descriptionPadding ?? EdgeInsets.zero,
                  child: Text(
                    widget.description!,
                    textAlign: widget.descriptionAlignment,
                    style:
                        widget.descTextStyle ??
                        Theme.of(context).textTheme.titleSmall!.merge(TextStyle(color: widget.textColor)),
                  ),
                ),
              if (_hasFooter) _buildProgressFooter()!,
              if (_hasInsideActions) _buildInsideActions()!,
            ],
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned(
          top: top,
          left: left,
          // The animations repaint this subtree every frame; on its own layer
          // that leaves the scrim and the cut-out alone.
          child: OverflowRepaintBoundary(
            child: ScaleTransitionBox(
              scale: _scaleAnimation,
              alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              child: SlideTransitionBox(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: Offset(isLeft ? -0.06 : 0.06, 0.0),
                ).animate(_movingAnimation),
                // As in the vertical layout: the slide moves this layer rather
                // than re-recording the text, arrow and clipped background.
                child: RepaintBoundary(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Row(
                      // left/right are physical positions, so keep the
                      // arrow/box order fixed regardless of the app text direction.
                      // (Tooltip text inside `box` still renders RTL.)
                      textDirection: TextDirection.ltr,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [if (showArrow && !isLeft) arrow, box, if (showArrow && isLeft) arrow],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // The target's geometry is measured once and shared by every read below;
    // drop the previous build's reading so this one measures afresh.
    widget.position?.invalidate();
    position = widget.offset;

    // Left/right placement uses a dedicated horizontal layout path. A custom
    // container keeps the vertical layout, and so do *outside* actions, which
    // need the absolute Positioned that only the vertical path emits.
    //
    // Inside actions are part of the tooltip box, which the horizontal path
    // already builds, so they must not force the fallback: doing so put a
    // left/right step back on the vertical path, where the tooltip is placed
    // from the target with no top clamp and lands off screen for a target near
    // the top edge. Reachable on every step once `globalActions` is set.
    //
    // A tooltip that does not fit on its side may change sides first; see
    // _resolvePosition.
    final contentOrientation = _resolvePosition();
    if (_canGoBeside && contentOrientation.isHorizontal) {
      return _buildHorizontalTooltip(isLeft: contentOrientation == TooltipPosition.left);
    }

    final contentOffsetMultiplier = contentOrientation == TooltipPosition.bottom ? 1.0 : -1.0;
    isArrowUp = contentOffsetMultiplier == 1.0;

    // The base 3px offset plus any caller-requested gap, pushed away from the
    // target in whichever direction the tooltip sits (multiplier is +1 below the
    // target, -1 above it).
    final targetOffset = 3 + widget.targetTooltipGap;
    final contentY = isArrowUp
        ? widget.position!.getBottom() + (contentOffsetMultiplier * targetOffset)
        : widget.position!.getTop() + (contentOffsetMultiplier * targetOffset);

    final num contentFractionalOffset = contentOffsetMultiplier.clamp(-1.0, 0.0);

    final arrowWidth = widget.arrowWidth;
    final arrowHeight = widget.arrowHeight;

    // Reserve room for the arrow plus the original fixed margin (13/18 at the
    // default 9px arrow height), so a custom arrow height stays clear of the
    // tooltip body.
    var paddingTop = isArrowUp ? arrowHeight + 13.0 : 0.0;
    var paddingBottom = isArrowUp ? 0.0 : arrowHeight + 18.0;

    if (!widget.showArrow) {
      paddingTop = 10;
      paddingBottom = 10;
    }

    if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
      _scaleAnimationController.reverse();
    }

    var actionTopPos = isArrowUp
        ? (contentY + tooltipHeight + widget.position!.getHeightContainer())
        : contentY - (tooltipHeight + widget.position!.getHeightContainer());
    var actionTopPosWithContainer = isArrowUp
        ? (contentY + arrowHeight + tooltipHeight + widget.position!.getHeightContainer())
        : contentY - (arrowHeight + tooltipHeight + widget.position!.getHeightContainer());

    // Hold the outside action row inside toolTipMargin, as the tooltip already
    // is. The row sits on the far side of the tooltip from the target, which
    // has no room when the tooltip is against a screen edge: the buttons drew
    // over the status bar, clipped. An explicit ActionButtonsPosition is
    // honoured exactly and never clamped.
    final screenH = widget.screenSize!.height;
    double clampActionTop(double top, double height) {
      final maxTop = max(widget.toolTipMargin.top, screenH - height - widget.toolTipMargin.bottom);
      return top.clamp(widget.toolTipMargin.top, maxTop);
    }

    actionTopPos = clampActionTop(actionTopPos, min(tooltipHeight - arrowHeight, 40.0));
    actionTopPosWithContainer = clampActionTop(
      actionTopPosWithContainer,
      widget.actionSettings?.containerHeight ?? 40.0,
    );

    if (widget.container == null) {
      return Stack(
        children: [
          Positioned(
            top: contentY,
            left: _getLeft(),
            right: _getRight(),
            // The animations repaint this subtree every frame; on its own layer
            // that leaves the scrim and the cut-out alone.
            child: OverflowRepaintBoundary(
              child: ScaleTransitionBox(
                scale: _scaleAnimation,
                alignment: widget.scaleAnimationAlignment ?? Alignment(_getAlignmentX(), _getAlignmentY()),
                child: FractionalTranslation(
                  translation: Offset(0.0, contentFractionalOffset as double),
                  child: SlideTransitionBox(
                    position: Tween<Offset>(
                      begin: Offset(0.0, contentFractionalOffset / 10),
                      end: const Offset(0.0, 0.100),
                    ).animate(_movingAnimation),
                    // The moving animation ping-pongs forever, so the tooltip is
                    // translated every frame. Behind a RepaintBoundary that becomes a
                    // layer offset instead of a re-raster of the text, the arrow and
                    // the clipped background.
                    child: RepaintBoundary(
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          padding: widget.showArrow
                              ? EdgeInsets.only(
                                  top: paddingTop - (isArrowUp ? arrowHeight : 0),
                                  bottom: paddingBottom - (isArrowUp ? 0 : arrowHeight),
                                )
                              : null,
                          child: Stack(
                            alignment: isArrowUp
                                ? Alignment.topLeft
                                : _getLeft() == null
                                ? Alignment.bottomRight
                                : Alignment.bottomLeft,
                            children: [
                              if (widget.showArrow)
                                Positioned(
                                  left: _getArrowLeft(arrowWidth),
                                  right: _getArrowRight(arrowWidth),
                                  child: CustomPaint(
                                    painter: _Arrow(
                                      strokeColor: widget.arrowColor ?? widget.tooltipBackgroundColor!,
                                      strokeWidth: 10,
                                      paintingStyle: PaintingStyle.fill,
                                      direction: isArrowUp ? _ArrowDirection.up : _ArrowDirection.down,
                                    ),
                                    child: SizedBox(height: arrowHeight, width: arrowWidth),
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: isArrowUp ? arrowHeight - 1 : 0,
                                  bottom: isArrowUp ? 0 : arrowHeight - 1,
                                ),
                                child: ClipRRect(
                                  borderRadius: widget.tooltipBorderRadius ?? BorderRadius.circular(8.0),
                                  child: _tappable(
                                    child: Container(
                                      width: tooltipWidth,
                                      padding: widget.tooltipPadding,
                                      color: widget.tooltipBackgroundColor,
                                      child: Column(
                                        crossAxisAlignment: widget.title != null
                                            ? CrossAxisAlignment.start
                                            : CrossAxisAlignment.center,
                                        children: <Widget>[
                                          if (widget.title != null)
                                            Padding(
                                              padding: widget.titlePadding ?? EdgeInsets.zero,
                                              child: Text(
                                                widget.title!,
                                                textAlign: widget.titleAlignment,
                                                style:
                                                    widget.titleTextStyle ??
                                                    Theme.of(context).textTheme.titleLarge!
                                                        .merge(TextStyle(color: widget.textColor)),
                                              ),
                                            ),
                                          if (widget.description != null)
                                            Padding(
                                              padding: widget.descriptionPadding ?? EdgeInsets.zero,
                                              child: Text(
                                                widget.description!,
                                                textAlign: widget.descriptionAlignment,
                                                style:
                                                    widget.descTextStyle ??
                                                    Theme.of(context).textTheme.titleSmall!
                                                        .merge(TextStyle(color: widget.textColor)),
                                              ),
                                            ),
                                          if (_hasFooter) _buildProgressFooter()!,
                                          if (_hasInsideActions) _buildInsideActions()!,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.actions != null && !widget.actionsPosition.isInside)
            Positioned(
              left: widget.actionButtonsPosition?.left ?? _getLeft(),
              right: widget.actionButtonsPosition?.right ?? _getRight(),
              top: widget.actionButtonsPosition?.top ?? actionTopPos,
              bottom: widget.actionButtonsPosition?.bottom,
              height: min((tooltipHeight - arrowHeight), 40),
              width: tooltipWidth,
              child: Container(color: _outsideActionsColor, child: _outsideActions()),
            ),
        ],
      );
    }
    // Same reason as the default tooltip: the custom container slides every
    // frame, so keep it on its own layer.
    Widget container = RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: _tappable(
          child: Container(
            padding: EdgeInsets.only(top: paddingTop),
            color: Colors.transparent,
            child: Center(
              child: MeasureSize(onSizeChange: onSizeChange, child: widget.container),
            ),
          ),
        ),
      ),
    );
    if (_measuresContainer) {
      // Below the translations, which hit-test outside their box: Offstage
      // only hit-tests inside its own, as a RepaintBoundary does.
      container = Offstage(offstage: _awaitsContainerSize, child: container);
    }
    return Stack(
      children: <Widget>[
        Positioned(
          left: _getSpace(),
          top: contentY - 10,
          // Keeps the per-frame slide off the scrim's layer, as above.
          child: OverflowRepaintBoundary(
            child: FractionalTranslation(
              translation: Offset(0.0, contentFractionalOffset as double),
              child: SlideTransitionBox(
                position: Tween<Offset>(
                  begin: Offset(0.0, contentFractionalOffset / 10),
                  end: !widget.showArrow && !isArrowUp ? const Offset(0.0, 0.0) : const Offset(0.0, 0.100),
                ).animate(_movingAnimation),
                child: container,
              ),
            ),
          ),
        ),
        // Placed from the container's position, so held back with it.
        if (widget.actions != null && !widget.actionsPosition.isInside && !_awaitsContainerSize)
          Positioned(
            top: widget.actionButtonsPosition?.top ?? actionTopPosWithContainer,
            left: widget.actionButtonsPosition?.left ?? _getSpace(),
            right: widget.actionButtonsPosition?.right ?? _getRight(),
            bottom: widget.actionButtonsPosition?.bottom,
            child: Padding(
              padding: widget.actionSettings?.containerPadding ?? EdgeInsets.zero,
              child: Container(
                color: _outsideActionsColor,
                height: widget.actionSettings?.containerHeight,
                width: widget.actionSettings?.containerWidth,
                child: _outsideActions(),
              ),
            ),
          ),
      ],
    );
  }

  void onSizeChange(Size? size) {
    // Reported after the frame, by which time the step may have closed.
    if (!mounted) return;
    var tempPos = position;
    tempPos = Offset(position!.dx, position!.dy + size!.height);
    setState(() {
      position = tempPos;
      _measuredContainerSize = size;
    });
  }

  Size _textSize(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
      // Measure with the ambient text direction so RTL (e.g. Arabic) text is
      // sized correctly.
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    )..layout();
    final size = textPainter.size;
    // Frees the native paragraph that `layout()` allocated.
    textPainter.dispose();
    return size;
  }

  double? _getArrowLeft(double arrowWidth) {
    final left = _getLeft();
    if (left == null) return null;
    return (widget.position!.getCenter() - (arrowWidth / 2) - left);
  }

  double? _getArrowRight(double arrowWidth) {
    if (_getLeft() != null) return null;
    return (MediaQuery.sizeOf(context).width - widget.position!.getCenter()) - (_getRight() ?? 0) - (arrowWidth / 2);
  }
}

enum _ArrowDirection { up, down, left, right }

class _Arrow extends CustomPainter {
  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final _ArrowDirection direction;
  final Paint _paint;

  _Arrow({
    this.strokeColor = Colors.black,
    this.strokeWidth = 3,
    this.paintingStyle = PaintingStyle.stroke,
    this.direction = _ArrowDirection.up,
  }) : _paint = Paint()
         ..color = strokeColor
         ..strokeWidth = strokeWidth
         ..style = paintingStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(getTrianglePath(size.width, size.height), _paint);
  }

  Path getTrianglePath(double x, double y) {
    switch (direction) {
      case _ArrowDirection.up:
        return Path()
          ..moveTo(0, y)
          ..lineTo(x / 2, 0)
          ..lineTo(x, y)
          ..close();
      case _ArrowDirection.down:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(x, 0)
          ..lineTo(x / 2, y)
          ..close();
      case _ArrowDirection.left:
        return Path()
          ..moveTo(x, 0)
          ..lineTo(x, y)
          ..lineTo(0, y / 2)
          ..close();
      case _ArrowDirection.right:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(0, y)
          ..lineTo(x, y / 2)
          ..close();
    }
  }

  @override
  bool shouldRepaint(covariant _Arrow oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.direction != direction;
  }
}
