/*
 * Copyright (c) 2021 Simform Solutions
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

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../showcase_tutorial.dart';
import 'get_position.dart';
import 'layout_overlays.dart';
import 'shape_clipper.dart';
import 'tooltip_widget.dart';
import 'utilities/_showcase_context_provider.dart';

class Showcase extends StatefulWidget {
  /// A key that is unique across the entire app.
  ///
  /// This Key will be used to control state of individual showcase and also
  /// used in [ShowCaseWidgetState.startShowCase] to define position of current
  /// target widget while showcasing.
  @override
  final GlobalKey key;

  /// Additional widgets to highlight together in the **same** showcase step.
  ///
  /// Each [GlobalKey] must point to a widget wrapped in a [MultiView] (a
  /// [RepaintBoundary]). A snapshot of every such widget is painted above the
  /// overlay so multiple, non-adjacent widgets — for example several items in
  /// a `ListView` or a multi-select control — appear highlighted at once while
  /// a single tooltip is shown.
  ///
  /// A key whose widget is not currently mounted is skipped; the remaining
  /// widgets are still highlighted.
  final List<GlobalKey>? keys;

  /// Target widget that will be showcased or highlighted
  final Widget child;

  /// Represents subject line of target widget
  final String? title;

  /// Title alignment with in tooltip widget
  ///
  /// Defaults to [TextAlign.start]
  final TextAlign titleAlignment;

  /// Represents summary description of target widget
  final String? description;

  /// ShapeBorder of the highlighted box when target widget will be showcased.
  ///
  /// Note: If [targetBorderRadius] is specified, this parameter will be ignored.
  ///
  /// Default value is:
  /// ```dart
  /// RoundedRectangleBorder(
  ///   borderRadius: BorderRadius.all(Radius.circular(8)),
  /// ),
  /// ```
  final ShapeBorder targetShapeBorder;

  /// When `true`, the highlight conforms to the target widget's **actual
  /// painted shape** instead of a geometric [targetShapeBorder].
  ///
  /// The target is captured as a snapshot and drawn above the dimmed overlay,
  /// so any shape — a circle, a pill, a star, an irregular icon or logo — is
  /// highlighted exactly, without having to set [targetShapeBorder] or
  /// [targetBorderRadius] to match it manually.
  ///
  /// Notes:
  /// * While the step is showing, the target is rendered as a **static image**,
  ///   so it will not animate or update until the showcase moves on. For
  ///   typical static UI this is invisible to the user.
  /// * To be captured, the child is wrapped in a [RepaintBoundary].
  /// * [targetShapeBorder]/[targetBorderRadius] are ignored for the highlight
  ///   when this is enabled.
  ///
  /// Defaults to `false`.
  final bool highlightExactShape;

  /// Radius of rectangle box while target widget is being showcased.
  final BorderRadius? targetBorderRadius;

  /// TextStyle for default tooltip title
  final TextStyle? titleTextStyle;

  /// TextStyle for default tooltip description
  final TextStyle? descTextStyle;

  /// Empty space around tooltip content.
  ///
  /// Default Value for [Showcase] widget is:
  /// ```dart
  /// EdgeInsets.symmetric(vertical: 8, horizontal: 8)
  /// ```
  final EdgeInsets tooltipPadding;

  /// Background color of overlay during showcase.
  ///
  /// Default value is [Colors.black45]
  final Color overlayColor;

  /// Opacity apply on [overlayColor] (which ranges from 0.0 to 1.0)
  ///
  /// Default to 0.75
  final double overlayOpacity;

  /// Custom tooltip widget when [Showcase.withWidget] is used.
  final Widget? container;

  /// Defines background color for tooltip widget.
  ///
  /// Falls back to [ShowCaseWidget.style], then to [Colors.white].
  final Color? tooltipBackgroundColor;

  /// Defines text color of default tooltip when [titleTextStyle] and
  /// [descTextStyle] is not provided.
  ///
  /// Falls back to [ShowCaseWidget.style], then to [Colors.black].
  final Color? textColor;

  /// If [enableAutoScroll] is sets to `true`, this widget will be shown above
  /// the overlay until the target widget is visible in the viewport.
  final Widget scrollLoadingWidget;

  /// Whether the default tooltip will have arrow to point out the target widget.
  ///
  /// Default to `true`
  final bool showArrow;

  /// Height of [container]
  final double? height;

  /// Width of [container]
  final double? width;

  /// The duration of time the bouncing animation of tooltip should last.
  ///
  /// Default to [Duration(milliseconds: 2000)]
  final Duration movingAnimationDuration;

  /// Triggered when default tooltip is tapped
  final VoidCallback? onToolTipClick;

  /// Called when this step becomes the active showcase — i.e. its tooltip
  /// appears on screen.
  ///
  /// Handy for analytics ("user reached step 3") or to trigger a side effect
  /// when a particular step is reached.
  final VoidCallback? onShow;

  /// Called when this step stops being the active showcase — when the tour
  /// advances past it, navigates away from it, or the whole showcase is
  /// dismissed.
  ///
  /// Handy for analytics or per-step cleanup.
  final VoidCallback? onDismiss;

  /// Text announced to screen readers when this step becomes active, when
  /// [ShowCaseWidget.enableAutoAnnouncements] is on.
  ///
  /// Defaults to the step's title and description joined together. Provide this
  /// to customise the spoken text — useful for a custom [container] tooltip
  /// that has no [title]/[description].
  final String? semanticLabel;

  /// Triggered when showcased target widget is tapped
  ///
  /// Note: [disposeOnTap] is required if you're using [onTargetClick]
  /// otherwise throws error
  final VoidCallback? onTargetClick;

  /// Will dispose all showcases if tapped on target widget or tooltip
  ///
  /// Note: [onTargetClick] is required if you're using [disposeOnTap]
  /// otherwise throws error
  final bool? disposeOnTap;

  /// Whether tooltip should have bouncing animation while showcasing
  ///
  /// If null value is provided,
  /// [ShowCaseWidget.disableAnimation] will be considered.
  final bool? disableMovingAnimation;

  /// Whether disabling initial scale animation for default tooltip when
  /// showcase is started and completed
  ///
  /// Default to `false`
  final bool? disableScaleAnimation;

  /// Padding around target widget
  ///
  /// Default to [EdgeInsets.zero]
  final EdgeInsets targetPadding;

  /// Triggered when target has been double tapped
  final VoidCallback? onTargetDoubleTap;

  /// Triggered when target has been long pressed.
  ///
  /// Detected when a pointer has remained in contact with the screen at the same location for a long period of time.
  final VoidCallback? onTargetLongPress;

  /// Border Radius of default tooltip
  ///
  /// Default to [BorderRadius.circular(8)]
  final BorderRadius? tooltipBorderRadius;

  /// Description alignment with in tooltip widget
  ///
  /// Defaults to [TextAlign.start]
  final TextAlign descriptionAlignment;

  /// if `disableDefaultTargetGestures` parameter is true
  /// onTargetClick, onTargetDoubleTap, onTargetLongPress and
  /// disposeOnTap parameter will not work
  ///
  /// Note: If `disableDefaultTargetGestures` is true then make sure to
  /// dismiss current showcase with `ShowCaseWidget.of(context).dismiss()`
  /// if you are navigating to other screen. This will be handled by default
  /// if `disableDefaultTargetGestures` is set to false.
  final bool disableDefaultTargetGestures;

  /// Defines blur value.
  /// This will blur the background while displaying showcase.
  ///
  /// If null value is provided,
  /// [ShowCaseWidget.blurValue] will be considered.
  ///
  final double? blurValue;

  /// A duration for animation which is going to played when
  /// tooltip comes first time in the view.
  ///
  /// Defaults to 300 ms.
  final Duration scaleAnimationDuration;

  /// The curve to be used for initial animation of tooltip.
  ///
  /// Defaults to Curves.easeIn
  final Curve scaleAnimationCurve;

  /// An alignment to origin of initial tooltip animation.
  ///
  /// Alignment will be pre-calculated but if pre-calculated
  /// alignment doesn't work then this parameter can be
  /// used to customise the direction of the tooltip animation.
  ///
  /// eg.
  /// ```dart
  ///     Alignment(-0.2,0.3) or Alignment.centerLeft
  /// ```
  final Alignment? scaleAnimationAlignment;

  /// Tooltip action button widget
  final Widget? actions;
  final ActionsSettings? actionSettings;
  final ActionButtonsPosition? actionButtonsPosition;

  /// Defines vertical position of tooltip respective to Target widget
  ///
  /// Defaults to adaptive into available space.
  final TooltipPosition? tooltipPosition;

  /// Provides padding around the title. Default padding is zero.
  final EdgeInsets? titlePadding;

  /// Provides padding around the description. Default padding is zero.
  final EdgeInsets? descriptionPadding;

  const Showcase({
    required this.key,
    this.keys,
    required this.child,
    this.title,
    this.titleAlignment = TextAlign.start,
    this.description,
    this.descriptionAlignment = TextAlign.start,
    this.targetShapeBorder = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    this.highlightExactShape = false,
    this.overlayColor = Colors.black45,
    this.overlayOpacity = 0.75,
    this.titleTextStyle,
    this.descTextStyle,
    this.tooltipBackgroundColor,
    this.textColor,
    this.scrollLoadingWidget = const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
    this.showArrow = true,
    this.onTargetClick,
    this.disposeOnTap,
    this.movingAnimationDuration = const Duration(milliseconds: 2000),
    this.disableMovingAnimation,
    this.disableScaleAnimation,
    this.tooltipPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    this.onToolTipClick,
    this.onShow,
    this.onDismiss,
    this.semanticLabel,
    this.targetPadding = EdgeInsets.zero,
    this.blurValue,
    this.targetBorderRadius,
    this.onTargetLongPress,
    this.onTargetDoubleTap,
    this.tooltipBorderRadius,
    this.disableDefaultTargetGestures = false,
    this.scaleAnimationDuration = const Duration(milliseconds: 300),
    this.scaleAnimationCurve = Curves.easeIn,
    this.scaleAnimationAlignment,
    this.tooltipPosition,
    this.titlePadding,
    this.descriptionPadding,
    this.actions,
    this.actionSettings = const ActionsSettings(),
    this.actionButtonsPosition,
  }) : height = null,
       width = null,
       container = null,
       assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0, "overlay opacity must be between 0 and 1."),
       assert(onTargetClick == null || disposeOnTap != null, "disposeOnTap is required if you're using onTargetClick"),
       assert(
         disposeOnTap == null ? true : (onTargetClick == null ? false : true),
         "onTargetClick is required if you're using disposeOnTap",
       ),
       super(key: key);

  const Showcase.withWidget({
    required this.key,
    this.keys,
    required this.child,
    required this.container,
    required this.height,
    required this.width,
    this.targetShapeBorder = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    this.highlightExactShape = false,
    this.overlayColor = Colors.black45,
    this.targetBorderRadius,
    this.overlayOpacity = 0.75,
    this.scrollLoadingWidget = const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
    this.onTargetClick,
    this.disposeOnTap,
    this.movingAnimationDuration = const Duration(milliseconds: 2000),
    this.disableMovingAnimation,
    this.targetPadding = EdgeInsets.zero,
    this.blurValue,
    this.onTargetLongPress,
    this.onTargetDoubleTap,
    this.onShow,
    this.onDismiss,
    this.semanticLabel,
    this.disableDefaultTargetGestures = false,
    this.tooltipPosition,
    this.actions,
    this.actionSettings = const ActionsSettings(),
    this.actionButtonsPosition,
  }) : showArrow = false,
       onToolTipClick = null,
       scaleAnimationDuration = const Duration(milliseconds: 300),
       scaleAnimationCurve = Curves.decelerate,
       scaleAnimationAlignment = null,
       disableScaleAnimation = null,
       title = null,
       description = null,
       titleAlignment = TextAlign.start,
       descriptionAlignment = TextAlign.start,
       titleTextStyle = null,
       descTextStyle = null,
       tooltipBackgroundColor = null,
       textColor = null,
       tooltipBorderRadius = null,
       tooltipPadding = const EdgeInsets.symmetric(vertical: 8),
       titlePadding = null,
       descriptionPadding = null,
       assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0, "overlay opacity must be between 0 and 1.");

  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> {
  bool _showShowCase = false;
  bool _isScrollRunning = false;
  bool _isTooltipDismissed = false;
  bool _enableShowcase = true;
  Timer? timer;
  GetPosition? position;

  /// Focus node for the active overlay so a hardware keyboard can drive the
  /// tour **only while the showcase holds focus** (never app-wide).
  final FocusNode _focusNode = FocusNode(debugLabel: 'Showcase');

  /// Wraps the child when [Showcase.highlightExactShape] is enabled so it can
  /// be captured with [RenderRepaintBoundary.toImage].
  final GlobalKey _childBoundaryKey = GlobalKey();

  ShowCaseWidgetState get showCaseWidgetState => ShowCaseWidget.of(context);

  @override
  void dispose() {
    _focusNode.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enableShowcase = showCaseWidgetState.enableShowcase;
    if (_enableShowcase) {
      position ??= GetPosition(
        key: widget.key,
        padding: widget.targetPadding,
        screenWidth: MediaQuery.sizeOf(context).width,
        screenHeight: MediaQuery.sizeOf(context).height,
      );
      showOverlay();
    }
  }

  /// show overlay if there is any target widget
  void showOverlay() {
    final activeStep = ShowCaseWidget.activeTargetWidget(context);
    final isActiveNow = activeStep == widget.key;
    final wasActive = _showShowCase;

    setState(() {
      _showShowCase = isActiveNow;
    });

    // Fire the per-step lifecycle callbacks on actual transitions only, so a
    // rebuild for an unrelated dependency change (e.g. a rotation) doesn't
    // re-trigger them.
    if (isActiveNow && !wasActive) {
      _announceForAccessibility();
      _notifyLifecycle(widget.onShow);
      // Take focus so keyboard navigation works without the user tapping first.
      if (showCaseWidgetState.enableKeyboardNavigation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    } else if (!isActiveNow && wasActive) {
      _notifyLifecycle(widget.onDismiss);
    }

    if (isActiveNow) {
      if (showCaseWidgetState.enableAutoScroll) {
        _scrollIntoView();
      }

      if (showCaseWidgetState.autoPlay) {
        timer = Timer(Duration(seconds: showCaseWidgetState.autoPlayDelay.inSeconds), _nextIfAny);
      }
    }
  }

  /// Invokes a per-step lifecycle [callback] ([Showcase.onShow] /
  /// [Showcase.onDismiss]) after the current frame.
  ///
  /// [showOverlay] runs during [didChangeDependencies], i.e. in the build
  /// phase. These callbacks commonly call `setState` on an ancestor (e.g. to
  /// update a "Step x of y" indicator), which is illegal during build — so we
  /// defer them to a post-frame callback.
  void _notifyLifecycle(VoidCallback? callback) {
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  /// Announces this step's title and description (or [Showcase.semanticLabel])
  /// to screen readers. A no-op when no screen reader is active.
  void _announceForAccessibility() {
    if (!showCaseWidgetState.enableAutoAnnouncements) return;
    final label = widget.semanticLabel ??
        [widget.title, widget.description]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .join('. ');
    if (label.isEmpty) return;
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    // `announce` is kept for compatibility with the package's Flutter floor
    // (>=3.27.0); its replacement `sendAnnouncement` doesn't exist there yet.
    // ignore: deprecated_member_use
    SemanticsService.announce(label, textDirection);
  }

  /// Handles hardware-keyboard navigation for the active step. Only called
  /// while the overlay's [Focus] holds focus, so it never hijacks keys from the
  /// rest of the app. Returns [KeyEventResult.handled] when the key is consumed.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _dismissShowcaseTour();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.enter) {
      _nextIfAny();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      showCaseWidgetState.previous();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scrollIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      // The Showcase may be disposed before this post-frame callback fires
      // (e.g. the screen redirects within a frame of its first build).
      // Guard against operating on an unmounted State, otherwise both the
      // setState calls and the `currentContext!` null-check operator throw.
      if (!mounted) return;
      setState(() => _isScrollRunning = true);
      final targetContext = widget.key.currentContext; // ?? widget.keys![0].currentContext;
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: showCaseWidgetState.widget.scrollDuration,
          alignment: 0.5,
        );
      }
      if (!mounted) return;
      setState(() => _isScrollRunning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_enableShowcase) {
      return AnchoredOverlay(
        overlayBuilder: (context, rectBound, offset) {
          final size = MediaQuery.sizeOf(context);
          position = GetPosition(
            key: widget.key,
            padding: widget.targetPadding,
            screenWidth: size.width,
            screenHeight: size.height,
          );

          return buildOverlayOnTarget(offset, rectBound.size, rectBound, size);
        },
        showOverlay: true,
        // Wrap in a RepaintBoundary so the target can be captured as a snapshot
        // and highlighted in its exact painted shape.
        child: widget.highlightExactShape
            ? RepaintBoundary(key: _childBoundaryKey, child: widget.child)
            : widget.child,
      );
    }
    return widget.child;
  }

  Future<void> _nextIfAny() async {
    if (timer != null && timer!.isActive) {
      if (showCaseWidgetState.enableAutoPlayLock) {
        return;
      }
      timer!.cancel();
    } else if (timer != null && !timer!.isActive) {
      timer = null;
    }
    await _reverseAnimateTooltip();
    showCaseWidgetState.completed(widget.key);
  }

  Future<void> _getOnTargetTap() async {
    if (widget.disposeOnTap == true) {
      await _reverseAnimateTooltip();
      showCaseWidgetState.dismiss();
      widget.onTargetClick!();
    } else {
      (widget.onTargetClick ?? _nextIfAny).call();
    }
  }

  Future<List<Widget>> _buildCopys(BuildContext context) async {
    final list = <Widget>[];
    final keys = widget.keys;
    if (keys == null || keys.isEmpty) return list;

    // Build an overlay copy for every key. Each one is handled independently
    // so a single missing or unmounted widget is simply skipped instead of
    // dropping the highlights for the whole multi-widget step.
    for (final element in keys) {
      try {
        final keyContext = element.currentContext;
        if (keyContext == null || !keyContext.mounted) continue;

        final boundary = keyContext.findRenderObject();
        if (boundary is! RenderRepaintBoundary || !boundary.hasSize) continue;

        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) continue;

        final offset = boundary.localToGlobal(Offset.zero);
        list.add(
          Positioned(
            left: offset.dx,
            top: offset.dy,
            child: Container(
              width: boundary.size.width,
              height: boundary.size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: MemoryImage(byteData.buffer.asUint8List()),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      } catch (_) {
        // Ignore this widget and keep building the remaining copies.
        continue;
      }
    }
    return list;
  }

  /// Captures the target widget and returns it as a [Positioned] image so the
  /// highlight matches the widget's exact painted shape. Used when
  /// [Showcase.highlightExactShape] is enabled. Returns `null` if the target
  /// cannot be captured (e.g. not yet laid out), in which case the plain
  /// dimmed overlay is shown.
  Future<Widget?> _buildExactShapeCopy(BuildContext context) async {
    try {
      final keyContext = _childBoundaryKey.currentContext;
      if (keyContext == null || !keyContext.mounted) return null;

      final boundary = keyContext.findRenderObject();
      if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return null;

      final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final offset = boundary.localToGlobal(Offset.zero);
      return Positioned(
        left: offset.dx,
        top: offset.dy,
        // The snapshot is purely visual; taps fall through to [_TargetWidget].
        child: IgnorePointer(
          child: Image.memory(
            byteData.buffer.asUint8List(),
            width: boundary.size.width,
            height: boundary.size.height,
            fit: BoxFit.fill,
          ),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _getOnTooltipTap() async {
    if (widget.disposeOnTap == true) {
      await _reverseAnimateTooltip();
      showCaseWidgetState.dismiss();
    }
    widget.onToolTipClick?.call();
  }

  /// Reverse-animates the tooltip and then dismisses the whole tour. Used when
  /// [ShowCaseWidget.barrierInteraction] is [BarrierInteraction.dismiss].
  Future<void> _dismissShowcaseTour() async {
    await _reverseAnimateTooltip();
    if (!mounted) return;
    showCaseWidgetState.dismiss();
  }

  /// Reverse animates the provided tooltip or
  /// the custom container widget.
  Future<void> _reverseAnimateTooltip() async {
    setState(() => _isTooltipDismissed = true);
    await Future<dynamic>.delayed(widget.scaleAnimationDuration);
    _isTooltipDismissed = false;
  }

  Widget buildOverlayOnTarget(
    Offset offset,
    Size size,
    Rect rectBound,
    Size screenSize, {
    Offset? offsetChild,
    Size? sizeChild,
  }) {
    var blur = 0.0;
    if (_showShowCase) {
      blur = widget.blurValue ?? showCaseWidgetState.blurValue;
    }

    // Set blur to 0 if application is running on web and
    // provided blur is less than 0.
    blur = kIsWeb && blur < 0 ? 0 : blur;

    if (!_showShowCase) return const SizedBox.shrink();

    final Widget overlay = Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: ShowcaseContextProvider(
            context: context,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    switch (showCaseWidgetState.barrierInteraction) {
                      case BarrierInteraction.next:
                        _nextIfAny();
                        break;
                      case BarrierInteraction.dismiss:
                        _dismissShowcaseTour();
                        break;
                      case BarrierInteraction.none:
                        break;
                    }
                  },
                  child: ClipPath(
                    clipper: RRectClipper(
                      // With an exact-shape highlight the snapshot provides the
                      // cut-out, so the overlay dims the whole screen (no hole).
                      area: (_isScrollRunning || widget.highlightExactShape) ? Rect.zero : rectBound,
                      isCircle: widget.targetShapeBorder is CircleBorder,
                      radius: _isScrollRunning ? BorderRadius.zero : widget.targetBorderRadius,
                      overlayPadding: _isScrollRunning ? EdgeInsets.zero : widget.targetPadding,
                    ),
                    child: blur != 0
                        ? BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                            child: Container(
                              width: MediaQuery.sizeOf(context).width,
                              height: MediaQuery.sizeOf(context).height,
                              decoration: BoxDecoration(
                                color: widget.overlayColor.withValues(alpha: widget.overlayOpacity),
                              ),
                            ),
                          )
                        : Container(
                            width: MediaQuery.sizeOf(context).width,
                            height: MediaQuery.sizeOf(context).height,
                            decoration: BoxDecoration(
                              color: widget.overlayColor.withValues(alpha: widget.overlayOpacity),
                            ),
                          ),
                  ),
                ),
                if (_isScrollRunning) Center(child: widget.scrollLoadingWidget),
                if (!_isScrollRunning) ...[
                  _TargetWidget(
                    offset: offset,
                    size: size,
                    onTap: _getOnTargetTap,
                    radius: widget.targetBorderRadius,
                    onDoubleTap: widget.onTargetDoubleTap,
                    onLongPress: widget.onTargetLongPress,
                    shapeBorder: widget.targetShapeBorder,
                    disableDefaultChildGestures: widget.disableDefaultTargetGestures,
                  ),
                  if (widget.keys != null && widget.keys!.isNotEmpty) ...[
                    FutureBuilder<List<Widget>>(
                      future: _buildCopys(context),
                      builder: (context, AsyncSnapshot<List<Widget>> snapshot) {
                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                          return Stack(children: snapshot.data!);
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                  if (widget.highlightExactShape)
                    FutureBuilder<Widget?>(
                      future: _buildExactShapeCopy(context),
                      builder: (context, AsyncSnapshot<Widget?> snapshot) {
                        return snapshot.data ?? const SizedBox.shrink();
                      },
                    ),
                  ToolTipWidget(
                    position: position,
                    offset: offset,
                    screenSize: screenSize,
                    title: widget.title,
                    titleAlignment: widget.titleAlignment,
                    description: widget.description,
                    descriptionAlignment: widget.descriptionAlignment,
                    titleTextStyle: widget.titleTextStyle ?? showCaseWidgetState.style.titleTextStyle,
                    descTextStyle: widget.descTextStyle ?? showCaseWidgetState.style.descTextStyle,
                    container: widget.container,
                    tooltipBackgroundColor: widget.tooltipBackgroundColor ??
                        showCaseWidgetState.style.tooltipBackgroundColor ??
                        Colors.white,
                    textColor: widget.textColor ?? showCaseWidgetState.style.textColor ?? Colors.black,
                    showArrow: widget.showArrow,
                    contentHeight: widget.height,
                    contentWidth: widget.width,
                    onTooltipTap: _getOnTooltipTap,
                    tooltipPadding: widget.tooltipPadding,
                    disableMovingAnimation: widget.disableMovingAnimation ?? showCaseWidgetState.disableMovingAnimation,
                    disableScaleAnimation: widget.disableScaleAnimation ?? showCaseWidgetState.disableScaleAnimation,
                    movingAnimationDuration: widget.movingAnimationDuration,
                    tooltipBorderRadius: widget.tooltipBorderRadius ?? showCaseWidgetState.style.tooltipBorderRadius,
                    scaleAnimationDuration: widget.scaleAnimationDuration,
                    scaleAnimationCurve: widget.scaleAnimationCurve,
                    scaleAnimationAlignment: widget.scaleAnimationAlignment,
                    isTooltipDismissed: _isTooltipDismissed,
                    tooltipPosition: widget.tooltipPosition,
                    titlePadding: widget.titlePadding,
                    descriptionPadding: widget.descriptionPadding,
                    actions: widget.actions,
                    actionSettings: widget.actionSettings,
                    actionButtonsPosition: widget.actionButtonsPosition,
                    showProgress: showCaseWidgetState.showProgress,
                    showSkip: showCaseWidgetState.showSkip,
                    skipText: showCaseWidgetState.skipButtonText,
                    currentStep: showCaseWidgetState.currentIndex ?? 0,
                    totalSteps: showCaseWidgetState.totalSteps,
                    onSkip: _dismissShowcaseTour,
                  ),
                ],
              ],
            ),
          ),
    );

    if (!showCaseWidgetState.enableKeyboardNavigation) return overlay;
    // Focus-scoped: keys are handled only while this overlay holds focus, so
    // navigation never hijacks keys from the rest of the app.
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: overlay,
    );
  }
}

class _TargetWidget extends StatelessWidget {
  final Offset offset;
  final Size? size;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final ShapeBorder? shapeBorder;
  final BorderRadius? radius;
  final bool disableDefaultChildGestures;

  const _TargetWidget({
    required this.offset,
    this.size,
    this.onTap,
    this.shapeBorder,
    this.radius,
    this.onDoubleTap,
    this.onLongPress,
    this.disableDefaultChildGestures = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: IgnorePointer(
        ignoring: disableDefaultChildGestures,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap,
            child: Container(
              height: size!.height + 16,
              width: size!.width + 16,
              decoration: ShapeDecoration(
                shape: radius != null
                    ? RoundedRectangleBorder(borderRadius: radius!)
                    : shapeBorder ?? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
