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

import 'package:flutter/material.dart';

import '../showcase_tutorial.dart';
import 'get_position.dart';
import 'measure_size.dart';

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
  final Color? textColor;
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
  final double? contentHeight;
  final double? contentWidth;
  final VoidCallback? onTooltipTap;
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
    required this.textColor,
    required this.showArrow,
    this.arrowColor,
    this.arrowWidth = 18.0,
    this.arrowHeight = 9.0,
    this.targetTooltipGap = 0.0,
    this.toolTipMargin = const EdgeInsets.all(20),
    required this.contentHeight,
    required this.contentWidth,
    required this.onTooltipTap,
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
    height = widget.contentHeight ?? height;
    final bottomPosition = position.dy + ((widget.position?.getHeight() ?? 0) / 2);
    final topPosition = position.dy - ((widget.position?.getHeight() ?? 0) / 2);
    final hasSpaceInTop = topPosition >= height;
    final EdgeInsets viewInsets = EdgeInsets.fromViewPadding(
      View.of(context).viewInsets,
      View.of(context).devicePixelRatio,
    );
    final double actualVisibleScreenHeight =
        (widget.screenSize?.height ?? MediaQuery.sizeOf(context).height) - viewInsets.bottom;
    final hasSpaceInBottom = (actualVisibleScreenHeight - bottomPosition) >= height;
    return widget.tooltipPosition ??
        (hasSpaceInTop && !hasSpaceInBottom ? TooltipPosition.top : TooltipPosition.bottom);
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
    var maxTextWidth = max(max(titleLength, descriptionLength), _footerWidth);
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
    var maxTextHeight = titleLength + descriptionLength + _footerHeight;
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
            GestureDetector(
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
        ],
      ),
    );
  }

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
    var space = widget.position!.getCenter() - (widget.contentWidth! / 2);
    // Keep the custom container (Showcase.withWidget) within the screen-edge
    // margins, mirroring how the default tooltip clamps to toolTipMargin.
    final maxLeft = max(
      widget.toolTipMargin.left,
      screenWidth - widget.contentWidth! - widget.toolTipMargin.right,
    );
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
    final gap = 6.0 + widget.targetTooltipGap;
    final showArrow = widget.showArrow;

    // Use getRect() for the target's edges: GetPosition.getLeft()/getRight()
    // are unreliable, only getRect() (and getCenter()) are computed correctly.
    final rect = widget.position!.getRect();
    final targetCenterY = rect.center.dy;
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;

    final arrowSpace = showArrow ? arrowShort : 0.0;
    final totalWidth = tooltipWidth + arrowSpace;

    double left = isLeft ? rect.left - gap - totalWidth : rect.right + gap;
    final maxLeft =
        max(widget.toolTipMargin.left, screenW - totalWidth - widget.toolTipMargin.right);
    left = left.clamp(widget.toolTipMargin.left, maxLeft);

    final maxTop =
        max(widget.toolTipMargin.top, screenH - tooltipHeight - widget.toolTipMargin.bottom);
    final top = (targetCenterY - tooltipHeight / 2).clamp(widget.toolTipMargin.top, maxTop);

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
      child: GestureDetector(
        onTap: widget.onTooltipTap,
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
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: Offset(isLeft ? -0.06 : 0.06, 0.0),
              ).animate(_movingAnimation),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    position = widget.offset;

    // Left/right placement uses a dedicated horizontal layout path. (Custom
    // containers and action buttons keep the vertical layout.)
    final tp = widget.tooltipPosition;
    if (widget.container == null &&
        widget.actions == null &&
        widget.position != null &&
        (tp == TooltipPosition.left || tp == TooltipPosition.right)) {
      return _buildHorizontalTooltip(isLeft: tp == TooltipPosition.left);
    }

    final contentOrientation = findPositionForContent(position!);
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

    if (widget.container == null) {
      return Stack(
        children: [
          Positioned(
            top: contentY,
            left: _getLeft(),
            right: _getRight(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: widget.scaleAnimationAlignment ?? Alignment(_getAlignmentX(), _getAlignmentY()),
              child: FractionalTranslation(
                translation: Offset(0.0, contentFractionalOffset as double),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, contentFractionalOffset / 10),
                    end: const Offset(0.0, 0.100),
                  ).animate(_movingAnimation),
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
                              child: GestureDetector(
                                onTap: widget.onTooltipTap,
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
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleLarge!.merge(TextStyle(color: widget.textColor)),
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
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleSmall!.merge(TextStyle(color: widget.textColor)),
                                          ),
                                        ),
                                      if (_hasFooter) _buildProgressFooter()!,
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
          if (widget.actions != null)
            Positioned(
              left: widget.actionButtonsPosition?.left ?? _getLeft(),
              right: widget.actionButtonsPosition?.right ?? _getRight(),
              top: widget.actionButtonsPosition?.top ?? actionTopPos,
              bottom: widget.actionButtonsPosition?.bottom,
              height: min((tooltipHeight - arrowHeight), 40),
              width: tooltipWidth,
              child: Container(color: widget.actionSettings?.containerColor, child: widget.actions),
            ),
        ],
      );
    }
    return Stack(
      children: <Widget>[
        Positioned(
          left: _getSpace(),
          top: contentY - 10,
          child: FractionalTranslation(
            translation: Offset(0.0, contentFractionalOffset as double),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, contentFractionalOffset / 10),
                end: !widget.showArrow && !isArrowUp ? const Offset(0.0, 0.0) : const Offset(0.0, 0.100),
              ).animate(_movingAnimation),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTooltipTap,
                  child: Container(
                    padding: EdgeInsets.only(top: paddingTop),
                    color: Colors.transparent,
                    child: Center(
                      child: MeasureSize(onSizeChange: onSizeChange, child: widget.container),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.actions != null)
          Positioned(
            top: widget.actionButtonsPosition?.top ?? actionTopPosWithContainer,
            left: widget.actionButtonsPosition?.left ?? _getSpace(),
            right: widget.actionButtonsPosition?.right ?? _getRight(),
            bottom: widget.actionButtonsPosition?.bottom,
            child: Padding(
              padding: widget.actionSettings?.containerPadding ?? EdgeInsets.zero,
              child: Container(
                color: widget.actionSettings?.containerColor,
                height: widget.actionSettings?.containerHeight,
                width: widget.actionSettings?.containerWidth,
                child: widget.actions!,
              ),
            ),
          ),
      ],
    );
  }

  void onSizeChange(Size? size) {
    var tempPos = position;
    tempPos = Offset(position!.dx, position!.dy + size!.height);
    setState(() => position = tempPos);
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
    return textPainter.size;
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
