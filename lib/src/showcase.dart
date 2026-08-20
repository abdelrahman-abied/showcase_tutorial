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

/// Highlights its [child] as a single step of a showcase tour.
///
/// Wrap each target widget in a [Showcase] with a unique [GlobalKey], place
/// them under a [ShowCaseWidget], then start the tour with
/// `ShowCaseWidget.of(context).startShowCase([...])`. While the step is active a
/// dimmed overlay cuts out the target and shows a tooltip built from [title]
/// and [description].
///
/// Use the default constructor for the built-in title/description tooltip, or
/// [Showcase.withWidget] to supply a fully custom [container] tooltip. Styling
/// values left unset fall back to [ShowCaseWidget.style] ([ShowcaseStyle]) and
/// then to the built-in default.
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

  /// When `true`, an animated ring gently pulses outward around the highlighted
  /// target — like a sonar ping — to draw the eye to it, in addition to the
  /// static cut-out.
  ///
  /// The ring follows the highlight's shape ([targetShapeBorder] /
  /// [targetBorderRadius]); with [highlightExactShape] it pulses around the
  /// target's bounding box. Honors the platform "reduce motion" accessibility
  /// setting by falling back to a single static ring.
  ///
  /// Defaults to `false`.
  final bool enablePulseAnimation;

  /// Color of the pulsing ring (see [enablePulseAnimation]).
  ///
  /// Falls back to [ShowCaseWidget.style] ([ShowcaseStyle.pulseColor]), then to
  /// [Colors.white].
  final Color? pulseColor;

  /// Duration of one full pulse cycle (see [enablePulseAnimation]). A smaller
  /// value pulses faster.
  ///
  /// Defaults to [Duration(milliseconds: 1500)].
  final Duration pulseDuration;

  /// Color of a border drawn around the highlighted target.
  ///
  /// When `null` (and [ShowcaseStyle.highlightBorderColor] is also unset) no
  /// border is drawn. The border follows the highlight's shape
  /// ([targetShapeBorder] / [targetBorderRadius]); with [highlightExactShape]
  /// it outlines the target's bounding box.
  final Color? highlightBorderColor;

  /// Width of the highlight border (see [highlightBorderColor]).
  ///
  /// Falls back to [ShowCaseWidget.style] ([ShowcaseStyle.highlightBorderWidth]),
  /// then to `2`.
  final double? highlightBorderWidth;

  /// Color of the default tooltip's arrow.
  ///
  /// Falls back to [ShowCaseWidget.style] ([ShowcaseStyle.arrowColor]), then to
  /// the resolved tooltip background color so the arrow matches the tooltip.
  /// Ignored when [showArrow] is `false`.
  final Color? arrowColor;

  /// Width (base) of the default tooltip's arrow.
  ///
  /// Falls back to [ShowCaseWidget.style] ([ShowcaseStyle.arrowWidth]), then to
  /// `18`. Ignored when [showArrow] is `false`.
  final double? arrowWidth;

  /// Height (depth toward the target) of the default tooltip's arrow.
  ///
  /// Falls back to [ShowCaseWidget.style] ([ShowcaseStyle.arrowHeight]), then to
  /// `9`. Ignored when [showArrow] is `false`.
  final double? arrowHeight;

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

  /// If [ShowCaseWidget.enableAutoScroll] is sets to `true`, this widget will be shown above
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
  /// [ShowCaseWidget.disableMovingAnimation] will be considered.
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

  /// Container styling for the action buttons.
  ///
  /// Defaults to `const ActionsSettings()`.
  final ActionsSettings? actionSettings;

  /// Manual placement of the action buttons within the tooltip.
  ///
  /// When `null` the buttons are positioned automatically.
  final ActionButtonsPosition? actionButtonsPosition;

  /// Defines vertical position of tooltip respective to Target widget
  ///
  /// Defaults to adaptive into available space.
  final TooltipPosition? tooltipPosition;

  /// Provides padding around the title. Default padding is zero.
  final EdgeInsets? titlePadding;

  /// Provides padding around the description. Default padding is zero.
  final EdgeInsets? descriptionPadding;

  /// A screen-anchored widget shown above the overlay while **this** step is
  /// active — for example a fixed "Skip" / "Next" button that stays put instead
  /// of moving with the tooltip.
  ///
  /// Position it yourself (e.g. wrap it in an [Align] or [Positioned]); it is
  /// painted on top of the tooltip and receives taps. Overrides
  /// [ShowCaseWidget.globalFloatingActionWidget] for this step. Defaults to
  /// `null` (falls back to the global one, if any).
  final Widget? floatingActionWidget;

  /// Visibility time of **this** step when [ShowCaseWidget.autoPlay] is on,
  /// overriding the tour-wide [ShowCaseWidget.autoPlayDelay].
  ///
  /// Lets a single step linger longer (or advance quicker) than the rest — handy
  /// when one step has more to read. When `null` the tour-wide delay is used. Has
  /// no effect unless `autoPlay` is enabled.
  final Duration? autoPlayDelay;

  /// Extra space, in logical pixels, between the target and the tooltip — added
  /// on top of the default offset.
  ///
  /// Applies to all tooltip positions (top / bottom / left / right). Defaults to
  /// `0`, which keeps the original spacing.
  final double targetTooltipGap;

  /// Minimum margin kept between the tooltip and the screen edges.
  ///
  /// The tooltip is clamped to stay at least this far from each edge, and its
  /// width/height are capped to fit within these margins. Defaults to
  /// `EdgeInsets.all(20)`.
  final EdgeInsets toolTipMargin;

  /// Overrides [ShowCaseWidget.scrollAlignment] for this step.
  ///
  /// Controls where the target lands in the viewport when
  /// [ShowCaseWidget.enableAutoScroll] scrolls it into view: `0.0` = leading
  /// edge (top / left), `0.5` = centered, `1.0` = trailing edge (bottom /
  /// right). Defaults to `null`, which uses the tour-wide
  /// [ShowCaseWidget.scrollAlignment].
  final double? scrollAlignment;

  /// Called while this step is active whenever the highlighted target's bounds
  /// change — for example after a scroll, a rotation, the keyboard opening, or
  /// the target itself resizing.
  ///
  /// Fires once with the initial bounds when the step becomes active, then again
  /// on every change, and is delivered after the frame is laid out (so it is safe
  /// to `setState` from it). The [Rect] is in global coordinates and describes the
  /// target widget itself — [targetPadding], which the cut-out adds around it, is
  /// not included.
  ///
  /// Handy for anchoring your own UI to the highlight, such as a
  /// [floatingActionWidget] that should sit just below the target. Defaults to
  /// `null`.
  final void Function(Rect targetRect)? onTargetRectUpdate;

  /// Overrides [ShowCaseWidget.barrierInteraction] for **this** step.
  ///
  /// Lets one step behave differently from the rest of the tour — e.g. a tour
  /// that advances on a background tap but has a single step where the barrier
  /// is inert ([BarrierInteraction.none]) because the user must interact with
  /// the target.
  ///
  /// Takes precedence over the tour-wide setting, including the legacy
  /// [ShowCaseWidget.disableBarrierInteraction] flag. Does not suppress
  /// [ShowCaseWidget.onBarrierClick], which still fires on every barrier tap.
  /// Defaults to `null`, which uses the tour-wide behaviour.
  final BarrierInteraction? barrierInteraction;

  /// Mouse cursor shown while hovering this step's highlighted target on
  /// web/desktop.
  ///
  /// When `null` the cursor is resolved from
  /// [ShowCaseWidget.enablePointerCursor]: [SystemMouseCursors.click] for a
  /// target that reacts to a click, and [MouseCursor.defer] when
  /// [disableDefaultTargetGestures] makes it inert. Set it explicitly to force a
  /// cursor — e.g. [SystemMouseCursors.forbidden] on a "look, don't touch" step,
  /// or [MouseCursor.defer] to keep whatever the target itself uses. An explicit
  /// value wins even when [ShowCaseWidget.enablePointerCursor] is `false`.
  final MouseCursor? targetMouseCursor;

  /// Mouse cursor shown while hovering this step's tooltip on web/desktop.
  ///
  /// When `null` the cursor is resolved from
  /// [ShowCaseWidget.enablePointerCursor]: [SystemMouseCursors.click] only when
  /// the tooltip actually reacts to a tap ([onToolTipClick] or [disposeOnTap]),
  /// otherwise [MouseCursor.defer]. An explicit value wins even when
  /// [ShowCaseWidget.enablePointerCursor] is `false`.
  final MouseCursor? tooltipMouseCursor;

  /// Creates a showcase step with the built-in title/description tooltip.
  ///
  /// [key] and [child] are required. Styling values left unset fall back to
  /// [ShowCaseWidget.style] and then to the built-in default. Use
  /// [Showcase.withWidget] instead to supply a custom [container] tooltip.
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
    this.enablePulseAnimation = false,
    this.pulseColor,
    this.pulseDuration = const Duration(milliseconds: 1500),
    this.highlightBorderColor,
    this.highlightBorderWidth,
    this.arrowColor,
    this.arrowWidth,
    this.arrowHeight,
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
    this.floatingActionWidget,
    this.autoPlayDelay,
    this.targetTooltipGap = 0.0,
    this.toolTipMargin = const EdgeInsets.all(20),
    this.scrollAlignment,
    this.onTargetRectUpdate,
    this.barrierInteraction,
    this.targetMouseCursor,
    this.tooltipMouseCursor,
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

  /// Creates a showcase step with a fully custom tooltip widget.
  ///
  /// Unlike the default [Showcase] constructor, the tooltip is the supplied
  /// [container] sized by [height] and [width]; [title]/[description] and the
  /// default tooltip styling do not apply.
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
    this.enablePulseAnimation = false,
    this.pulseColor,
    this.pulseDuration = const Duration(milliseconds: 1500),
    this.highlightBorderColor,
    this.highlightBorderWidth,
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
    this.floatingActionWidget,
    this.autoPlayDelay,
    this.targetTooltipGap = 0.0,
    this.toolTipMargin = const EdgeInsets.all(20),
    this.scrollAlignment,
    this.onTargetRectUpdate,
    this.barrierInteraction,
    this.targetMouseCursor,
    this.tooltipMouseCursor,
  }) : showArrow = false,
       arrowColor = null,
       arrowWidth = null,
       arrowHeight = null,
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

  /// Creates the mutable state for this widget.
  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> with SingleTickerProviderStateMixin {
  bool _showShowCase = false;
  bool _isScrollRunning = false;
  bool _isTooltipDismissed = false;
  bool _enableShowcase = true;
  Timer? timer;
  GetPosition? position;

  /// The target bounds last reported to [Showcase.onTargetRectUpdate], used to
  /// fire only on actual changes. Reset when the step stops being active so a
  /// revisit reports its bounds afresh.
  Rect? _lastNotifiedRect;

  /// Drives the cut-out glide when this step is entered
  /// (see [ShowCaseWidget.enableStepTransition]).
  AnimationController? _transitionController;

  /// Bounds the glide starts from — the previous step's target — or `null` when
  /// this step should simply appear.
  Rect? _transitionFrom;

  /// Focus node for the active overlay so a hardware keyboard can drive the
  /// tour **only while the showcase holds focus** (never app-wide).
  final FocusNode _focusNode = FocusNode(debugLabel: 'Showcase');

  /// Wraps the child when [Showcase.highlightExactShape] is enabled so it can
  /// be captured with [RenderRepaintBoundary.toImage].
  final GlobalKey _childBoundaryKey = GlobalKey();

  /// The [Showcase.highlightExactShape] snapshot for the active step, captured
  /// once when the step opens.
  _TargetSnapshot? _exactShapeSnapshot;

  /// The [Showcase.keys] snapshots for the active step, captured once when the
  /// step opens.
  List<_TargetSnapshot> _multiSnapshots = const [];

  /// Identifies the in-flight capture, so a capture started for a step that has
  /// since closed (or restarted) discards its images instead of showing them.
  Object? _snapshotToken;

  ShowCaseWidgetState get showCaseWidgetState => ShowCaseWidget.of(context);

  @override
  void dispose() {
    _releaseSnapshots();
    _focusNode.dispose();
    _transitionController?.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(Showcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The snapshots are captured once per activation, so a step whose snapshot
    // inputs change while it is showing has to capture again.
    if (_showShowCase &&
        (oldWidget.highlightExactShape != widget.highlightExactShape ||
            !listEquals(oldWidget.keys, widget.keys))) {
      _releaseSnapshots();
      _scheduleSnapshotCapture();
    }
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
    final showcaseState = showCaseWidgetState;
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
      _scheduleSnapshotCapture();
      _startStepTransition();
      _announceForAccessibility();
      _notifyLifecycle(widget.onShow);
      // Take focus so keyboard navigation works without the user tapping first.
      if (showcaseState.enableKeyboardNavigation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    } else if (!isActiveNow && wasActive) {
      _releaseSnapshots();
      _transitionFrom = null;
      _transitionController?.stop();
      _notifyLifecycle(widget.onDismiss);
    }

    if (isActiveNow) {
      if (showcaseState.enableAutoScroll) {
        _scrollIntoView();
      }

      if (showcaseState.autoPlay) {
        // Per-step [Showcase.autoPlayDelay] overrides the tour-wide delay; the
        // full Duration is used (no longer truncated to whole seconds).
        final autoPlayDelay = widget.autoPlayDelay ?? showcaseState.autoPlayDelay;
        timer = Timer(autoPlayDelay, _nextIfAny);
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

  /// Begins the cut-out glide into this step, if the tour asked for one.
  ///
  /// Every step paints its own full-screen scrim, so the scrim itself is
  /// continuous across a step change and only the cut-out jumps. That lets the
  /// step being entered produce the whole transition on its own, by animating
  /// its cut-out from where the previous target was; the step being left simply
  /// stops painting.
  ///
  /// Skipped — leaving the cut-out to appear in place — when the tour has no
  /// previous target (the first step), when "reduce motion" is on, or when
  /// [Showcase.highlightExactShape] replaces the cut-out with a snapshot.
  void _startStepTransition() {
    _transitionFrom = null;
    if (!showCaseWidgetState.enableStepTransition || widget.highlightExactShape) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;

    final from = showCaseWidgetState.previousTargetRect;
    if (from == null) return;

    _transitionFrom = from;
    (_transitionController ??= AnimationController(vsync: this))
      ..duration = showCaseWidgetState.stepTransitionDuration
      ..forward(from: 0);
  }

  /// The cut-out bounds for this frame: [rectBound] normally, or a point along
  /// the glide from the previous target while a step transition is running.
  Rect _transitionRect(Rect rectBound) {
    final from = _transitionFrom;
    final controller = _transitionController;
    if (from == null || controller == null || controller.isCompleted) return rectBound;
    final t = showCaseWidgetState.stepTransitionCurve.transform(controller.value);
    return Rect.lerp(from, rectBound, t) ?? rectBound;
  }

  /// Builds a piece of the highlight from the cut-out bounds, re-running
  /// [builder] each frame while a step transition glides those bounds.
  Widget _withCutOut(Rect rectBound, Widget Function(Rect cutOut) builder) {
    final controller = _transitionController;
    if (_transitionFrom == null || controller == null) return builder(rectBound);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => builder(_transitionRect(rectBound)),
    );
  }

  /// [rect] expanded by [Showcase.targetPadding] — the region the cut-out
  /// actually covers, which the border and pulse ring have to match.
  Rect _paddedRect(Rect rect) => Rect.fromLTRB(
    rect.left - widget.targetPadding.left,
    rect.top - widget.targetPadding.top,
    rect.right + widget.targetPadding.right,
    rect.bottom + widget.targetPadding.bottom,
  );

  /// Cursor shown while hovering the highlighted target on web/desktop.
  ///
  /// An explicit [Showcase.targetMouseCursor] always wins; otherwise a click
  /// cursor is used when the tour opts in and the target still reacts to a tap.
  MouseCursor get _targetCursor {
    final cursor = widget.targetMouseCursor;
    if (cursor != null) return cursor;
    if (!showCaseWidgetState.enablePointerCursor || widget.disableDefaultTargetGestures) {
      return MouseCursor.defer;
    }
    return SystemMouseCursors.click;
  }

  /// Cursor shown while hovering the tooltip on web/desktop.
  ///
  /// An explicit [Showcase.tooltipMouseCursor] always wins; otherwise a click
  /// cursor is used only when tapping the tooltip actually does something, since
  /// the tap handler is always wired up but is a no-op without one of these.
  MouseCursor get _tooltipCursor {
    final cursor = widget.tooltipMouseCursor;
    if (cursor != null) return cursor;
    final tappable = widget.onToolTipClick != null || widget.disposeOnTap == true;
    if (!showCaseWidgetState.enablePointerCursor || !tappable) return MouseCursor.defer;
    return SystemMouseCursors.click;
  }

  /// Reports the highlighted target's bounds to [Showcase.onTargetRectUpdate]
  /// when they differ from the last reported value.
  ///
  /// Called while the overlay builds, so — like [_notifyLifecycle] — the callback
  /// is deferred to a post-frame callback: listeners typically `setState` on an
  /// ancestor to reposition their own UI, which is illegal during build.
  void _notifyTargetRectUpdate(Rect rect) {
    final callback = widget.onTargetRectUpdate;
    if (callback == null || _lastNotifiedRect == rect) return;
    _lastNotifiedRect = rect;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(rect);
    });
  }

  /// Announces this step's title and description (or [Showcase.semanticLabel])
  /// to screen readers. A no-op when no screen reader is active.
  void _announceForAccessibility() {
    if (!showCaseWidgetState.enableAutoAnnouncements) return;
    final label =
        widget.semanticLabel ??
        [
          widget.title,
          widget.description,
        ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join('. ');
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
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowUp) {
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
          // Per-step [Showcase.scrollAlignment] overrides the tour-wide value.
          alignment: widget.scrollAlignment ?? showCaseWidgetState.scrollAlignment,
        );
      }
      if (!mounted) return;
      setState(() => _isScrollRunning = false);
      // A target that was off-screen when the step opened could not be captured
      // then; now that it has been scrolled into view, try once more.
      if (_showShowCase && _exactShapeSnapshot == null && _multiSnapshots.isEmpty) {
        _scheduleSnapshotCapture();
      }
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
        // Only the active step mounts an OverlayEntry. Otherwise every Showcase
        // on the screen keeps one inserted for the whole life of the route, and
        // each is rebuilt on every ancestor rebuild just to return an empty box.
        showOverlay: _showShowCase,
        // Wrap in a RepaintBoundary so the target can be captured as a snapshot
        // and highlighted in its exact painted shape.
        child: widget.highlightExactShape ? RepaintBoundary(key: _childBoundaryKey, child: widget.child) : widget.child,
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

  /// Captures the widget behind [key] as a [ui.Image].
  ///
  /// Returns `null` when the widget is not mounted, is not a
  /// [RepaintBoundary], or has not been laid out yet.
  Future<_TargetSnapshot?> _capture(GlobalKey key, double pixelRatio) async {
    try {
      final keyContext = key.currentContext;
      if (keyContext == null || !keyContext.mounted) return null;

      final boundary = keyContext.findRenderObject();
      if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return null;

      final size = boundary.size;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      return _TargetSnapshot(key: key, image: image, size: size);
    } catch (_) {
      // A widget that cannot be captured is simply not highlighted.
      return null;
    }
  }

  /// Captures the snapshots this step paints above the overlay — the
  /// [Showcase.highlightExactShape] copy of the target and one copy per
  /// [Showcase.keys] entry — once, when the step opens.
  ///
  /// The capture is deliberately *not* redone per build. Encoding a widget to an
  /// image is expensive, and re-running it on every rebuild (as a `FutureBuilder`
  /// with an inline future does) re-encodes the target several times a second
  /// and leaks every [ui.Image] it produces. The step shows a static snapshot by
  /// design, so one capture per activation is all it needs; only the snapshot's
  /// *position* is re-read per build, so it still tracks a target that scrolls.
  void _scheduleSnapshotCapture() {
    final keys = widget.keys;
    final wantsMulti = keys != null && keys.isNotEmpty;
    if (!widget.highlightExactShape && !wantsMulti) return;

    final token = Object();
    _snapshotToken = token;
    // Capture after the frame: the boundary needs a painted layer, and the
    // step has only just been made active.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _snapshotToken != token) return;
      final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

      final exact = widget.highlightExactShape ? await _capture(_childBoundaryKey, pixelRatio) : null;
      final multi = <_TargetSnapshot>[];
      if (wantsMulti) {
        for (final key in keys) {
          final snapshot = await _capture(key, 2.0);
          if (snapshot != null) multi.add(snapshot);
        }
      }

      // The step may have closed while the capture ran.
      if (!mounted || _snapshotToken != token) {
        exact?.dispose();
        for (final snapshot in multi) {
          snapshot.dispose();
        }
        return;
      }

      setState(() {
        // Never overwrite a live snapshot without freeing it first.
        _exactShapeSnapshot?.dispose();
        for (final snapshot in _multiSnapshots) {
          snapshot.dispose();
        }
        _exactShapeSnapshot = exact;
        _multiSnapshots = multi;
      });
    });
  }

  /// Frees the captured images when the step closes or the widget is disposed.
  void _releaseSnapshots() {
    _snapshotToken = null;
    _exactShapeSnapshot?.dispose();
    _exactShapeSnapshot = null;
    for (final snapshot in _multiSnapshots) {
      snapshot.dispose();
    }
    _multiSnapshots = const [];
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
    if (!_showShowCase) {
      // Forget the last reported bounds so returning to this step reports its
      // rect again from scratch.
      _lastNotifiedRect = null;
      return const SizedBox.shrink();
    }

    // Resolved once, and only for the step that is actually showing:
    // `showCaseWidgetState` is a `findAncestorStateOfType` walk up the whole
    // element tree, and this method reads ~20 values off it.
    final showcaseState = showCaseWidgetState;

    var blur = widget.blurValue ?? showcaseState.blurValue;

    // Set blur to 0 if application is running on web and
    // provided blur is less than 0.
    blur = kIsWeb && blur < 0 ? 0 : blur;

    _notifyTargetRectUpdate(rectBound);

    // Resolve the optional highlight border (per-Showcase wins, then the global
    // ShowcaseStyle). A null color means no border is drawn.
    final style = showcaseState.style;
    final highlightBorderColor = widget.highlightBorderColor ?? style.highlightBorderColor;
    final highlightBorderWidth = widget.highlightBorderWidth ?? style.highlightBorderWidth ?? 2.0;

    // Resolve what a barrier tap does: an explicit per-step
    // [Showcase.barrierInteraction] wins over the tour-wide value (which already
    // accounts for the legacy `disableBarrierInteraction` flag).
    final barrierInteraction = widget.barrierInteraction ?? showcaseState.barrierInteraction;

    // Resolve the screen-anchored floating widget: a per-step
    // [Showcase.floatingActionWidget] wins; otherwise fall back to the tour-wide
    // [ShowCaseWidget.globalFloatingActionWidget] unless this step is in
    // [hideFloatingActionWidgetForShowcase].
    final floatingSuppressed =
        showcaseState.hideFloatingActionWidgetForShowcase.contains(widget.key);
    final Widget? floatingActionWidget = widget.floatingActionWidget ??
        (floatingSuppressed ? null : showcaseState.globalFloatingActionWidget?.call(context));

    // Hoisted so the (potentially full-screen, blurred) scrim is built once: a
    // plain color needs a ColoredBox, not the BoxDecoration/BoxPainter
    // machinery a decorated Container sets up.
    final screen = MediaQuery.sizeOf(context);
    final scrim = SizedBox(
      width: screen.width,
      height: screen.height,
      child: ColoredBox(color: widget.overlayColor.withValues(alpha: widget.overlayOpacity)),
    );

    final Widget overlay = Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: ShowcaseContextProvider(
        context: context,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                // Notify the barrier-tap listener first, regardless of what the
                // tap is configured to do (it fires even for `.none`).
                showcaseState.onBarrierClick?.call();
                switch (barrierInteraction) {
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
              child: _withCutOut(
                rectBound,
                (cutOut) => ClipPath(
                  clipper: RRectClipper(
                    // With an exact-shape highlight the snapshot provides the
                    // cut-out, so the overlay dims the whole screen (no hole).
                    area: (_isScrollRunning || widget.highlightExactShape) ? Rect.zero : cutOut,
                    isCircle: widget.targetShapeBorder is CircleBorder,
                    radius: _isScrollRunning ? BorderRadius.zero : widget.targetBorderRadius,
                    overlayPadding: _isScrollRunning ? EdgeInsets.zero : widget.targetPadding,
                  ),
                  child: blur != 0
                      ? BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                          child: scrim,
                        )
                      : scrim,
                ),
              ),
            ),
            if (_isScrollRunning) Center(child: widget.scrollLoadingWidget),
            if (!_isScrollRunning) ...[
              if (widget.enablePulseAnimation)
                _withCutOut(
                  rectBound,
                  // Match the cut-out, including while it glides between steps.
                  (cutOut) => _PulsingOverlay(
                    targetRect: _paddedRect(cutOut),
                    isCircle: widget.targetShapeBorder is CircleBorder,
                    borderRadius: widget.targetBorderRadius,
                    color: widget.pulseColor ?? showcaseState.style.pulseColor ?? Colors.white,
                    duration: widget.pulseDuration,
                  ),
                ),
              _TargetWidget(
                offset: offset,
                size: size,
                onTap: _getOnTargetTap,
                radius: widget.targetBorderRadius,
                onDoubleTap: widget.onTargetDoubleTap,
                onLongPress: widget.onTargetLongPress,
                shapeBorder: widget.targetShapeBorder,
                disableDefaultChildGestures: widget.disableDefaultTargetGestures,
                cursor: _targetCursor,
              ),
              for (final snapshot in _multiSnapshots) ?snapshot.build(),
              // The snapshot is purely visual; taps fall through to
              // [_TargetWidget].
              ?_exactShapeSnapshot?.build(),
              if (highlightBorderColor != null)
                _withCutOut(
                  rectBound,
                  (cutOut) => _HighlightBorder(
                    targetRect: _paddedRect(cutOut),
                    isCircle: widget.targetShapeBorder is CircleBorder,
                    borderRadius: widget.targetBorderRadius,
                    color: highlightBorderColor,
                    strokeWidth: highlightBorderWidth,
                  ),
                ),
              ToolTipWidget(
                position: position,
                offset: offset,
                screenSize: screenSize,
                title: widget.title,
                titleAlignment: widget.titleAlignment,
                description: widget.description,
                descriptionAlignment: widget.descriptionAlignment,
                titleTextStyle: widget.titleTextStyle ?? showcaseState.style.titleTextStyle,
                descTextStyle: widget.descTextStyle ?? showcaseState.style.descTextStyle,
                container: widget.container,
                tooltipBackgroundColor:
                    widget.tooltipBackgroundColor ?? showcaseState.style.tooltipBackgroundColor ?? Colors.white,
                textColor: widget.textColor ?? showcaseState.style.textColor ?? Colors.black,
                showArrow: widget.showArrow,
                arrowColor: widget.arrowColor ?? style.arrowColor,
                arrowWidth: widget.arrowWidth ?? style.arrowWidth ?? 18.0,
                arrowHeight: widget.arrowHeight ?? style.arrowHeight ?? 9.0,
                targetTooltipGap: widget.targetTooltipGap,
                toolTipMargin: widget.toolTipMargin,
                contentHeight: widget.height,
                contentWidth: widget.width,
                onTooltipTap: _getOnTooltipTap,
                mouseCursor: _tooltipCursor,
                enablePointerCursor: showcaseState.enablePointerCursor,
                tooltipPadding: widget.tooltipPadding,
                disableMovingAnimation: widget.disableMovingAnimation ?? showcaseState.disableMovingAnimation,
                disableScaleAnimation: widget.disableScaleAnimation ?? showcaseState.disableScaleAnimation,
                movingAnimationDuration: widget.movingAnimationDuration,
                tooltipBorderRadius: widget.tooltipBorderRadius ?? showcaseState.style.tooltipBorderRadius,
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
                showProgress: showcaseState.showProgress,
                progressStyle: showcaseState.progressStyle,
                showSkip: showcaseState.showSkip,
                skipText: showcaseState.skipButtonText,
                currentStep: showcaseState.currentIndex ?? 0,
                totalSteps: showcaseState.totalSteps,
                onSkip: _dismissShowcaseTour,
              ),
              // Screen-anchored floating widget, painted above the tooltip and
              // tappable (the caller positions it with Align/Positioned).
              ?floatingActionWidget,
            ],
          ],
        ),
      ),
    );

    if (!showcaseState.enableKeyboardNavigation) return overlay;
    // Focus-scoped: keys are handled only while this overlay holds focus, so
    // navigation never hijacks keys from the rest of the app.
    return Focus(focusNode: _focusNode, autofocus: true, onKeyEvent: _handleKeyEvent, child: overlay);
  }
}

/// A captured image of a highlighted widget, painted above the dimmed overlay.
///
/// Holds the [ui.Image] for as long as the step is showing so it is encoded
/// once rather than on every rebuild, and re-reads the source widget's position
/// per build so the snapshot still follows a target that scrolls.
class _TargetSnapshot {
  _TargetSnapshot({required this.key, required this.image, required this.size});

  /// The [RepaintBoundary] the image was captured from, used to re-read the
  /// live position.
  final GlobalKey key;

  final ui.Image image;

  /// The boundary's logical size, which the image is drawn at.
  final Size size;

  /// The source widget's current top-left in global coordinates, or `null` if
  /// it is no longer laid out.
  Offset? get _offset {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero);
  }

  /// The positioned image, or `null` while the source widget is not laid out.
  Widget? build() {
    final offset = _offset;
    if (offset == null) return null;
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: IgnorePointer(
        // Passed uncloned on purpose: [RawImage] clones the image itself and
        // hands the clone to its [RenderImage], which disposes it. Cloning here
        // as well would create a handle nobody owns, leaking one per build.
        // This class stays the owner of [image] and disposes it in [dispose].
        child: RawImage(image: image, width: size.width, height: size.height, fit: BoxFit.fill),
      ),
    );
  }

  void dispose() => image.dispose();
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

  /// Cursor shown while hovering the target on web/desktop
  /// (see [Showcase.targetMouseCursor]).
  final MouseCursor cursor;

  const _TargetWidget({
    required this.offset,
    this.size,
    this.onTap,
    this.shapeBorder,
    this.radius,
    this.onDoubleTap,
    this.onLongPress,
    this.disableDefaultChildGestures = false,
    this.cursor = MouseCursor.defer,
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
          // Not opaque, so the real widget underneath still receives hover
          // events (and keeps its own hover states) while the cursor here wins.
          child: MouseRegion(
            cursor: cursor,
            opaque: false,
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
                      : shapeBorder ??
                            const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints an animated ring that pulses outward around the highlighted target
/// (see [Showcase.enablePulseAnimation]).
///
/// The pulse never covers the target itself — the rings expand from the
/// highlight's edge into the dimmed area — and is purely decorative, so it is
/// wrapped in an [IgnorePointer] and lets taps fall through to the barrier and
/// the target. When the platform "reduce motion" accessibility setting is on it
/// draws a single static ring instead of animating.
class _PulsingOverlay extends StatefulWidget {
  /// The highlighted region, in overlay (global) coordinates.
  final Rect targetRect;

  /// Whether the highlight is a circle ([CircleBorder]); affects ring corners.
  final bool isCircle;

  /// Corner radius of the rectangular highlight, when set.
  final BorderRadius? borderRadius;

  /// Ring color (alpha is modulated as each ring fades out).
  final Color color;

  /// Duration of one full pulse cycle.
  final Duration duration;

  const _PulsingOverlay({
    required this.targetRect,
    required this.isCircle,
    required this.borderRadius,
    required this.color,
    required this.duration,
  });

  @override
  State<_PulsingOverlay> createState() => _PulsingOverlayState();
}

class _PulsingOverlayState extends State<_PulsingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  /// Whether the platform "reduce motion" accessibility setting is on. When it
  /// is, the controller stays idle and a single static ring is drawn.
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(_PulsingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!_reduceMotion) {
        _controller
          ..reset()
          ..repeat();
      }
    }
  }

  /// Runs the controller only when motion is allowed, so a "reduce motion" user
  /// never pays for an idle 60 fps animation.
  void _syncTicker() {
    if (_reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Size the layer to the ring's reach instead of the whole screen, so the
    // RepaintBoundary doesn't allocate a full-screen layer (and a smaller layer
    // is cheaper to re-raster each frame) for a couple of thin rings.
    const margin = _PulsingRingPainter._maxExtent + _PulsingRingPainter._strokeWidth;
    final bounds = widget.targetRect.inflate(margin);
    final localTarget = Rect.fromLTWH(margin, margin, widget.targetRect.width, widget.targetRect.height);

    CustomPaint paintRing(double? progress) => CustomPaint(
      size: bounds.size,
      painter: _PulsingRingPainter(
        targetRect: localTarget,
        isCircle: widget.isCircle,
        borderRadius: widget.borderRadius,
        color: widget.color,
        progress: progress,
      ),
    );

    return Positioned.fromRect(
      rect: bounds,
      child: IgnorePointer(
        child: RepaintBoundary(
          // Under reduced motion the controller is idle, so skip the per-frame
          // AnimatedBuilder rebuild entirely and draw a single static ring.
          child: _reduceMotion
              ? paintRing(null)
              : AnimatedBuilder(animation: _controller, builder: (context, _) => paintRing(_controller.value)),
        ),
      ),
    );
  }
}

/// Draws the expanding, fading rings for [_PulsingOverlay].
class _PulsingRingPainter extends CustomPainter {
  final Rect targetRect;
  final bool isCircle;
  final BorderRadius? borderRadius;
  final Color color;

  /// Animation value in `[0, 1)`, or `null` to draw a single static ring
  /// (reduced motion).
  final double? progress;

  /// Number of concurrent rings, phased evenly to read as a continuous wave.
  static const _ringCount = 2;

  /// How far (logical pixels) a ring travels outward over one cycle.
  static const _maxExtent = 14.0;

  static const _strokeWidth = 2.5;

  _PulsingRingPainter({
    required this.targetRect,
    required this.isCircle,
    required this.borderRadius,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect.isEmpty) return;

    // One reusable Paint for the frame; only its color changes per ring.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final localProgress = progress;
    if (localProgress == null) {
      // Reduced motion: one steady ring hugging the target.
      _drawRing(canvas, paint, expansion: 2.0, alpha: 0.9);
      return;
    }

    for (var i = 0; i < _ringCount; i++) {
      final t = (localProgress + i / _ringCount) % 1.0;
      _drawRing(canvas, paint, expansion: _maxExtent * t, alpha: 1.0 - t);
    }
  }

  void _drawRing(Canvas canvas, Paint paint, {required double expansion, required double alpha}) {
    if (alpha <= 0.0) return;
    final rect = targetRect.inflate(expansion);
    paint.color = color.withValues(alpha: color.a * alpha.clamp(0.0, 1.0));

    final Radius radius;
    if (isCircle) {
      radius = Radius.circular(rect.height);
    } else {
      // Keep the corners rounded as the ring grows, matching the cut-out's
      // default 3px corner when no explicit radius is given.
      final base = borderRadius?.topLeft.x ?? 3.0;
      radius = Radius.circular(base + expansion);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
  }

  @override
  bool shouldRepaint(_PulsingRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.targetRect != targetRect ||
      oldDelegate.color != color ||
      oldDelegate.isCircle != isCircle ||
      oldDelegate.borderRadius != borderRadius;
}

/// A static border drawn around the highlighted target
/// (see [Showcase.highlightBorderColor]).
///
/// The stroke is centred on the cut-out's edge and follows its shape. It is
/// purely decorative, so it is wrapped in an [IgnorePointer] and lets taps fall
/// through to the barrier and the target.
class _HighlightBorder extends StatelessWidget {
  /// The cut-out region, in overlay (global) coordinates.
  final Rect targetRect;

  /// Whether the highlight is a circle ([CircleBorder]); affects corners.
  final bool isCircle;

  /// Corner radius of the rectangular highlight, when set.
  final BorderRadius? borderRadius;

  /// Border color.
  final Color color;

  /// Border thickness.
  final double strokeWidth;

  const _HighlightBorder({
    required this.targetRect,
    required this.isCircle,
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Size the layer to the stroke's reach (a centred stroke extends half its
    // width beyond the edge) rather than the whole screen.
    final margin = strokeWidth;
    final bounds = targetRect.inflate(margin);
    final localTarget = Rect.fromLTWH(margin, margin, targetRect.width, targetRect.height);

    return Positioned.fromRect(
      rect: bounds,
      child: IgnorePointer(
        child: CustomPaint(
          size: bounds.size,
          painter: _HighlightBorderPainter(
            targetRect: localTarget,
            isCircle: isCircle,
            borderRadius: borderRadius,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

/// Strokes the highlight outline for [_HighlightBorder], mirroring the cut-out's
/// shape ([RRectClipper]).
class _HighlightBorderPainter extends CustomPainter {
  final Rect targetRect;
  final bool isCircle;
  final BorderRadius? borderRadius;
  final Color color;
  final double strokeWidth;

  _HighlightBorderPainter({
    required this.targetRect,
    required this.isCircle,
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final Radius radius;
    if (isCircle) {
      radius = Radius.circular(targetRect.height);
    } else {
      // Match the cut-out's corners (default 3px when no explicit radius).
      radius = Radius.circular(borderRadius?.topLeft.x ?? 3.0);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(targetRect, radius), paint);
  }

  @override
  bool shouldRepaint(_HighlightBorderPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.isCircle != isCircle ||
      oldDelegate.borderRadius != borderRadius;
}
