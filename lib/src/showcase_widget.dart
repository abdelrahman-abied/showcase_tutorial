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

import 'package:flutter/material.dart';

import '../showcase_tutorial.dart';

/// Hosts a showcase tour for the [Showcase] widgets in its subtree.
///
/// Wrap your screen (or app) in a [ShowCaseWidget], wrap each target in a
/// [Showcase] with a unique [GlobalKey], then start the tour with
/// `ShowCaseWidget.of(context).startShowCase([...])`. Tour-wide options such as
/// [autoPlay], [barrierInteraction], [style], and the accessibility flags are
/// configured here and shared by every [Showcase] in the tree.
class ShowCaseWidget extends StatefulWidget {
  /// Builds the subtree that contains the [Showcase] widgets.
  final Builder builder;

  /// Triggered when all the showcases are completed.
  final VoidCallback? onFinish;

  /// Triggered every time on start of each showcase.
  final Function(int?, GlobalKey)? onStart;

  /// Triggered every time on completion of each showcase
  final Function(int?, GlobalKey)? onComplete;

  /// Triggered when the tour is dismissed early via [ShowCaseWidgetState.dismiss]
  /// — for example a barrier tap with [BarrierInteraction.dismiss], the
  /// <kbd>Esc</kbd> key, the built-in skip button, a `disposeOnTap` tap, or a
  /// manual `ShowCaseWidget.of(context).dismiss()` call.
  ///
  /// Receives the [GlobalKey] of the step that was active when the tour was
  /// dismissed, or `null` if no step was active. It is **not** called when the
  /// tour finishes normally by advancing past the last step — use [onFinish] for
  /// that. Distinct from the per-step [Showcase.onDismiss], which fires for every
  /// step as the tour leaves it.
  final void Function(GlobalKey? dismissedAt)? onDismiss;

  /// Triggered whenever the dimmed background (the barrier) is tapped, in
  /// addition to the configured [barrierInteraction] behaviour.
  ///
  /// Fires even when [barrierInteraction] is [BarrierInteraction.none], so it can
  /// be used purely as a "user tapped outside the highlight" signal — for a hint
  /// nudge, a sound, or analytics — without changing what the tap does. When
  /// [barrierInteraction] is `.next` or `.dismiss` this runs first, then the
  /// configured action follows.
  final VoidCallback? onBarrierClick;

  /// A screen-anchored widget shown above the overlay for **every** step of the
  /// tour — for example a fixed "Skip" / "Next" button or a progress chip that
  /// stays put instead of moving with each tooltip.
  ///
  /// Built lazily per step, so it can read the current tour state via
  /// `ShowCaseWidget.of(context)`. Position it yourself (e.g. wrap it in an
  /// [Align] or [Positioned]); it is painted on top of the tooltip and receives
  /// taps. A per-step [Showcase.floatingActionWidget] overrides this, and
  /// [hideFloatingActionWidgetForShowcase] suppresses it on specific steps.
  /// Defaults to `null` (no floating widget).
  final WidgetBuilder? globalFloatingActionWidget;

  /// The [GlobalKey]s of the steps on which [globalFloatingActionWidget] should
  /// be hidden — e.g. a step that already shows its own actions, or where the
  /// fixed button would overlap the highlight.
  ///
  /// Ignored by a per-step [Showcase.floatingActionWidget], which always wins.
  /// Defaults to an empty list.
  final List<GlobalKey> hideFloatingActionWidgetForShowcase;

  /// Whether all showcases will auto sequentially start
  /// having time interval of [autoPlayDelay] .
  ///
  /// Default to `false`
  final bool autoPlay;

  /// Visibility time of current showcase when [autoPlay] sets to true.
  ///
  /// Default to [Duration(seconds: 3)]
  final Duration autoPlayDelay;

  /// Whether blocking user interaction while [autoPlay] is enabled.
  ///
  /// Default to `false`
  final bool enableAutoPlayLock;

  /// Whether disabling bouncing/moving animation for all tooltips
  /// while showcasing
  ///
  /// Default to `false`
  final bool disableMovingAnimation;

  /// Whether disabling initial scale animation for all the default tooltips
  /// when showcase is started and completed
  ///
  /// Default to `false`
  final bool disableScaleAnimation;

  /// Whether disabling barrier interaction.
  ///
  /// Superseded by [barrierInteraction]; kept for backward compatibility. When
  /// `true` it takes precedence and the barrier is inert
  /// ([BarrierInteraction.none]).
  final bool disableBarrierInteraction;

  /// What tapping the dimmed background (the barrier) does during a step.
  ///
  /// Defaults to [BarrierInteraction.next] (advance to the next step). Use
  /// [BarrierInteraction.dismiss] to close the whole tour on a background tap,
  /// or [BarrierInteraction.none] to ignore barrier taps.
  ///
  /// Note: [disableBarrierInteraction] wins when set to `true`.
  final BarrierInteraction barrierInteraction;

  /// Provides time duration for auto scrolling when [enableAutoScroll] is true
  final Duration scrollDuration;

  /// Where the target lands within the viewport when [enableAutoScroll] brings
  /// an off-screen target into view, as a fraction of the scroll axis:
  /// `0.0` = leading edge (top / left), `0.5` = centered, `1.0` = trailing edge
  /// (bottom / right). Forwarded to [Scrollable.ensureVisible]'s `alignment`.
  ///
  /// Defaults to `0.5` (centered). Override for a single step with
  /// [Showcase.scrollAlignment].
  final double scrollAlignment;

  /// Default overlay blur used by showcase. if [Showcase.blurValue]
  /// is not provided.
  ///
  /// Default value is 0.
  final double blurValue;

  /// While target widget is out viewport then
  /// whether enabling auto scroll so as to make the target widget visible.
  final bool enableAutoScroll;

  /// Enable/disable showcase globally. Enabled by default.
  final bool enableShowcase;

  /// Default tooltip styling applied to every [Showcase] in this tree.
  ///
  /// Each [Showcase] overrides individual values; anything left unset here
  /// falls back to the built-in defaults.
  final ShowcaseStyle style;

  /// An optional identifier for this showcase, passed to
  /// [onShouldStartShowcase]. Handy when one guard handles several tours.
  final String? showcaseId;

  /// Called when [ShowCaseWidgetState.startShowCase] is invoked (unless
  /// `force: true` is passed).
  ///
  /// Return `false` to skip starting the tour — for example when the user has
  /// already completed it. The result may be a `bool` or a `Future<bool>`.
  ///
  /// The package stores nothing itself: persist completion in [onFinish] (or
  /// [onComplete]) using any storage you like, and read it back here.
  final FutureOr<bool> Function(String? showcaseId)? onShouldStartShowcase;

  /// When `true`, steps whose target widget is not currently mounted are
  /// skipped automatically while starting or navigating the tour, instead of
  /// showing an empty / mis-positioned overlay.
  ///
  /// Useful when some showcased widgets are rendered conditionally. Defaults
  /// to `false`.
  final bool autoSkipUnmountedSteps;

  /// When `true`, the active step can be controlled with a hardware keyboard:
  ///
  /// * <kbd>Esc</kbd> dismisses the tour,
  /// * <kbd>→</kbd> / <kbd>↓</kbd> / <kbd>Enter</kbd> go to the next step,
  /// * <kbd>←</kbd> / <kbd>↑</kbd> go to the previous step.
  ///
  /// Handling is focus-scoped: it only acts while the showcase overlay holds
  /// focus, so it never hijacks keys from the rest of the app.
  ///
  /// Relevant on web/desktop; harmless on mobile (no keyboard). Defaults to
  /// `true`.
  final bool enableKeyboardNavigation;

  /// When `true`, each step's title and description are announced to screen
  /// readers (TalkBack / VoiceOver) as it becomes active, via
  /// [SemanticsService.announce]. A [Showcase.semanticLabel] overrides the
  /// announced text for that step.
  ///
  /// No-op when no screen reader is running. Defaults to `true`.
  final bool enableAutoAnnouncements;

  /// When `true`, the default tooltip shows a built-in step indicator
  /// reflecting the current position in the tour. Its appearance is controlled
  /// by [progressStyle]. Defaults to `false`.
  final bool showProgress;

  /// How the step indicator is rendered when [showProgress] is `true`: as
  /// [ShowcaseProgressStyle.dots] (one dot per step, the default) or as a
  /// [ShowcaseProgressStyle.numeric] "current / total" counter (e.g. `1/6`).
  final ShowcaseProgressStyle progressStyle;

  /// When `true`, the default tooltip shows a "Skip" button that dismisses the
  /// whole tour. Defaults to `false`.
  final bool showSkip;

  /// Resolves the next step at runtime, enabling conditional / branching tours.
  ///
  /// Called whenever the tour advances **forward** from the step at
  /// [currentIndex] (whose target is [currentKey]) — via the Next button, a tap
  /// on the target or tooltip, the barrier, the keyboard, autoplay, or
  /// [ShowCaseWidgetState.next]. Return the [GlobalKey] of the step to jump to,
  /// which must be one of the keys passed to
  /// [ShowCaseWidgetState.startShowCase], to branch or skip ahead; return `null`
  /// to fall through to the normal next step.
  ///
  /// The returned step may be ahead of or behind the current one, so a tour can
  /// skip steps or revisit an earlier one based on app state (e.g. "if the user
  /// already has items, jump to the checkout step"). A branch is treated as an
  /// explicit jump, like [ShowCaseWidgetState.goTo], so
  /// [autoSkipUnmountedSteps] is not applied to the target.
  ///
  /// Not consulted by [ShowCaseWidgetState.previous],
  /// [ShowCaseWidgetState.goTo], or [ShowCaseWidgetState.goToKey], which are
  /// explicit navigation. Defaults to `null` (no branching).
  final GlobalKey? Function(int currentIndex, GlobalKey currentKey)? onResolveNextStep;

  /// Label for the skip button (see [showSkip]). Defaults to `'Skip'`.
  final String skipButtonText;

  /// Creates a [ShowCaseWidget] that hosts the showcase tour for the
  /// [Showcase] widgets built by [builder].
  const ShowCaseWidget({
    super.key,
    required this.builder,
    this.onFinish,
    this.onStart,
    this.onComplete,
    this.onDismiss,
    this.onBarrierClick,
    this.globalFloatingActionWidget,
    this.hideFloatingActionWidgetForShowcase = const [],
    this.autoPlay = false,
    this.autoPlayDelay = const Duration(milliseconds: 2000),
    this.enableAutoPlayLock = false,
    this.blurValue = 0,
    this.scrollDuration = const Duration(milliseconds: 300),
    this.scrollAlignment = 0.5,
    this.disableMovingAnimation = false,
    this.disableScaleAnimation = false,
    this.enableAutoScroll = false,
    this.disableBarrierInteraction = false,
    this.barrierInteraction = BarrierInteraction.next,
    this.enableShowcase = true,
    this.style = const ShowcaseStyle(),
    this.showcaseId,
    this.onShouldStartShowcase,
    this.autoSkipUnmountedSteps = false,
    this.enableKeyboardNavigation = true,
    this.enableAutoAnnouncements = true,
    this.showProgress = false,
    this.progressStyle = ShowcaseProgressStyle.dots,
    this.showSkip = false,
    this.skipButtonText = 'Skip',
    this.onResolveNextStep,
  });

  /// Returns the [GlobalKey] of the currently active step's target, or `null`
  /// when no tour is running.
  ///
  /// Reads the nearest [_InheritedShowCaseView], so callers rebuild when the
  /// active step changes.
  static GlobalKey? activeTargetWidget(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedShowCaseView>()?.activeWidgetIds;
  }

  /// Returns the [ShowCaseWidgetState] of the nearest [ShowCaseWidget] ancestor.
  ///
  /// Use it to drive the tour, e.g.
  /// `ShowCaseWidget.of(context).startShowCase([...])`. Throws if no
  /// [ShowCaseWidget] is found above [context].
  static ShowCaseWidgetState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ShowCaseWidgetState>();
    if (state != null) {
      return state;
    } else {
      throw Exception('Please provide ShowCaseView context');
    }
  }

  /// Creates the mutable state for this widget.
  @override
  ShowCaseWidgetState createState() => ShowCaseWidgetState();
}

/// The state for a [ShowCaseWidget] and the controller for the running tour.
///
/// Obtain it with [ShowCaseWidget.of] to start, navigate, and inspect the
/// showcase: [startShowCase], [next], [previous], [goTo], [dismiss],
/// [currentIndex], [totalSteps], and [isShowcaseRunning].
class ShowCaseWidgetState extends State<ShowCaseWidget> {
  /// The ordered list of target [GlobalKey]s for the running tour, or `null`
  /// when no tour is running.
  List<GlobalKey>? ids;

  /// Zero-based index into [ids] of the active step, or `null` when no tour is
  /// running.
  int? activeWidgetId;

  /// These properties are only here so that it can be accessed by
  /// [Showcase]
  bool get autoPlay => widget.autoPlay;

  /// Value of [ShowCaseWidget.disableMovingAnimation].
  bool get disableMovingAnimation => widget.disableMovingAnimation;

  /// Value of [ShowCaseWidget.disableScaleAnimation].
  bool get disableScaleAnimation => widget.disableScaleAnimation;

  /// Value of [ShowCaseWidget.autoPlayDelay].
  Duration get autoPlayDelay => widget.autoPlayDelay;

  /// Value of [ShowCaseWidget.enableAutoPlayLock].
  bool get enableAutoPlayLock => widget.enableAutoPlayLock;

  /// Value of [ShowCaseWidget.enableAutoScroll].
  bool get enableAutoScroll => widget.enableAutoScroll;

  /// Value of [ShowCaseWidget.scrollAlignment].
  double get scrollAlignment => widget.scrollAlignment;

  /// Value of the legacy [ShowCaseWidget.disableBarrierInteraction] flag.
  ///
  /// Prefer [barrierInteraction] for the resolved barrier behaviour.
  bool get disableBarrierInteraction => widget.disableBarrierInteraction;

  /// Resolved barrier behaviour. The legacy [ShowCaseWidget.disableBarrierInteraction]
  /// flag wins when `true`, mapping to [BarrierInteraction.none].
  BarrierInteraction get barrierInteraction =>
      widget.disableBarrierInteraction ? BarrierInteraction.none : widget.barrierInteraction;

  /// Value of [ShowCaseWidget.onBarrierClick].
  VoidCallback? get onBarrierClick => widget.onBarrierClick;

  /// Value of [ShowCaseWidget.globalFloatingActionWidget].
  WidgetBuilder? get globalFloatingActionWidget => widget.globalFloatingActionWidget;

  /// Value of [ShowCaseWidget.hideFloatingActionWidgetForShowcase].
  List<GlobalKey> get hideFloatingActionWidgetForShowcase =>
      widget.hideFloatingActionWidgetForShowcase;

  /// Value of [ShowCaseWidget.enableShowcase].
  bool get enableShowcase => widget.enableShowcase;

  /// Value of [ShowCaseWidget.enableKeyboardNavigation].
  bool get enableKeyboardNavigation => widget.enableKeyboardNavigation;

  /// Value of [ShowCaseWidget.enableAutoAnnouncements].
  bool get enableAutoAnnouncements => widget.enableAutoAnnouncements;

  /// Value of [ShowCaseWidget.showProgress].
  bool get showProgress => widget.showProgress;

  /// Value of [ShowCaseWidget.progressStyle].
  ShowcaseProgressStyle get progressStyle => widget.progressStyle;

  /// Value of [ShowCaseWidget.showSkip].
  bool get showSkip => widget.showSkip;

  /// Value of [ShowCaseWidget.skipButtonText].
  String get skipButtonText => widget.skipButtonText;

  /// Default tooltip styling for showcases in this tree.
  ShowcaseStyle get style => widget.style;

  /// Returns value of [ShowCaseWidget.blurValue]
  double get blurValue => widget.blurValue;

  /// Whether a showcase tour is currently running.
  bool get isShowcaseRunning => ids != null;

  /// Zero-based index of the active step, or `null` when no tour is running.
  int? get currentIndex => activeWidgetId;

  /// Total number of steps in the running tour (0 when none is running).
  int get totalSteps => ids?.length ?? 0;

  /// Starts Showcase view from the beginning of specified list of widget ids.
  /// If this function is used when showcase has been disabled then it will
  /// throw an exception.
  ///
  /// When [ShowCaseWidget.onShouldStartShowcase] is provided it is consulted
  /// first, and the showcase only starts if it resolves to `true` (useful for
  /// "show the tour only once"). Pass `force: true` to bypass that guard — for
  /// example from a "show tutorial again" button.
  void startShowCase(List<GlobalKey> widgetIds, {bool force = false}) {
    if (!enableShowcase) {
      throw Exception(
        "You are trying to start Showcase while it has been disabled with "
        "`enableShowcase` parameter to false from ShowCaseWidget",
      );
    }
    if (!mounted) return;

    final guard = widget.onShouldStartShowcase;
    if (force || guard == null) {
      _startShowCaseNow(widgetIds);
      return;
    }
    // The guard may be synchronous or asynchronous; wrapping in Future.value
    // handles both without forcing callers to await.
    Future<bool>.value(guard(widget.showcaseId)).then((shouldStart) {
      if (shouldStart && mounted) _startShowCaseNow(widgetIds);
    });
  }

  void _startShowCaseNow(List<GlobalKey> widgetIds) {
    setState(() {
      ids = widgetIds;
      activeWidgetId = _nextMountedIndex(0, 1);
      if (activeWidgetId! >= ids!.length) {
        _cleanupAfterSteps();
        widget.onFinish?.call();
      } else {
        _onStart();
      }
    });
  }

  /// When [ShowCaseWidget.autoSkipUnmountedSteps] is enabled, advances [index]
  /// in [direction] (`1` forward / `-1` back) past steps whose target widget is
  /// not currently mounted, returning the first mounted index (or an
  /// out-of-range index when none remain). Returns [index] unchanged when the
  /// option is disabled.
  int _nextMountedIndex(int index, int direction) {
    if (!widget.autoSkipUnmountedSteps || ids == null) return index;
    while (index >= 0 && index < ids!.length && ids![index].currentContext == null) {
      index += direction;
    }
    return index;
  }

  /// Resolves the index to advance to when moving forward from [fromIndex].
  ///
  /// Consults [ShowCaseWidget.onResolveNextStep] for conditional / branching
  /// tours: when it returns a [GlobalKey] that is part of the running tour, that
  /// step's index is used as an explicit jump (no [_nextMountedIndex] applied,
  /// mirroring [goTo]). Otherwise the default next index — [fromIndex] + 1,
  /// adjusted for [ShowCaseWidget.autoSkipUnmountedSteps] — is returned.
  int _forwardTargetIndex(int fromIndex) {
    final resolver = widget.onResolveNextStep;
    if (resolver != null && ids != null) {
      final target = resolver(fromIndex, ids![fromIndex]);
      if (target != null) {
        final branchIndex = ids!.indexOf(target);
        assert(
          branchIndex != -1,
          'onResolveNextStep returned a GlobalKey that is not part of the '
          'running showcase tour. Return one of the keys passed to '
          'startShowCase, or null to advance to the next step normally.',
        );
        if (branchIndex != -1) return branchIndex;
      }
    }
    return _nextMountedIndex(fromIndex + 1, 1);
  }

  /// Completes showcase of given key and starts next one
  /// otherwise will finish the entire showcase view
  void completed(GlobalKey? key) {
    if (ids != null && ids![activeWidgetId!] == key && mounted) {
      setState(() {
        _onComplete();
        activeWidgetId = _forwardTargetIndex(activeWidgetId!);
        _onStart();

        if (activeWidgetId! >= ids!.length) {
          _cleanupAfterSteps();
          widget.onFinish?.call();
        }
      });
    }
  }

  /// Completes current active showcase and starts next one
  /// otherwise will finish the entire showcase view
  void next() {
    if (ids != null && mounted) {
      setState(() {
        _onComplete();
        activeWidgetId = _forwardTargetIndex(activeWidgetId!);
        _onStart();

        if (activeWidgetId! >= ids!.length) {
          _cleanupAfterSteps();
          widget.onFinish?.call();
        }
      });
    }
  }

  /// Completes current active showcase and starts previous one
  /// otherwise does nothing
  void previous() {
    if (ids == null || !mounted) return;
    final target = _nextMountedIndex((activeWidgetId ?? 0) - 1, -1);
    if (target < 0) return;
    setState(() {
      _onComplete();
      activeWidgetId = target;
      _onStart();
    });
  }

  /// Jumps to the step at [index] (zero-based) of the running tour.
  ///
  /// Does nothing if no tour is running or [index] is out of range. Fires
  /// [ShowCaseWidget.onComplete] for the current step and
  /// [ShowCaseWidget.onStart] for the target step.
  void goTo(int index) {
    if (ids == null || activeWidgetId == null || !mounted) return;
    if (index < 0 || index >= ids!.length) return;
    setState(() {
      _onComplete();
      activeWidgetId = index;
      _onStart();
    });
  }

  /// Jumps to the step whose target is [key].
  ///
  /// Does nothing if [key] is not part of the running tour.
  void goToKey(GlobalKey key) {
    final index = ids?.indexOf(key) ?? -1;
    if (index != -1) goTo(index);
  }

  /// Dismiss entire showcase view
  void dismiss() {
    if (!mounted) return;
    // Capture the active step before clearing state so [ShowCaseWidget.onDismiss]
    // can report where the user left off.
    final dismissedAt = (ids != null &&
            activeWidgetId != null &&
            activeWidgetId! >= 0 &&
            activeWidgetId! < ids!.length)
        ? ids![activeWidgetId!]
        : null;
    setState(_cleanupAfterSteps);
    widget.onDismiss?.call(dismissedAt);
  }

  void _onStart() {
    if (activeWidgetId! < ids!.length) {
      widget.onStart?.call(activeWidgetId, ids![activeWidgetId!]);
    }
  }

  void _onComplete() {
    widget.onComplete?.call(activeWidgetId, ids![activeWidgetId!]);
  }

  void _cleanupAfterSteps() {
    ids = null;
    activeWidgetId = null;
  }

  /// Exposes the active step's target key to descendants and builds the
  /// configured [ShowCaseWidget.builder] subtree.
  @override
  Widget build(BuildContext context) {
    return _InheritedShowCaseView(activeWidgetIds: ids?.elementAt(activeWidgetId!), child: widget.builder);
  }
}

class _InheritedShowCaseView extends InheritedWidget {
  final GlobalKey? activeWidgetIds;

  const _InheritedShowCaseView({required this.activeWidgetIds, required super.child});

  @override
  bool updateShouldNotify(_InheritedShowCaseView oldWidget) => oldWidget.activeWidgetIds != activeWidgetIds;
}
