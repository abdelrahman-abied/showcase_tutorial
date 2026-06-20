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

import 'package:flutter/material.dart';

import '../showcase_tutorial.dart';

class ShowCaseWidget extends StatefulWidget {
  final Builder builder;

  /// Triggered when all the showcases are completed.
  final VoidCallback? onFinish;

  /// Triggered every time on start of each showcase.
  final Function(int?, GlobalKey)? onStart;

  /// Triggered every time on completion of each showcase
  final Function(int?, GlobalKey)? onComplete;

  /// Whether all showcases will auto sequentially start
  /// having time interval of [autoPlayDelay] .
  ///
  /// Default to `false`
  final bool autoPlay;

  /// Visibility time of current showcase when [autoplay] sets to true.
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
  /// * <kbd>→</kbd> / <kbd>↓</kbd> / <kbd>Enter</kbd> / <kbd>Space</kbd> go to
  ///   the next step,
  /// * <kbd>←</kbd> / <kbd>↑</kbd> go to the previous step.
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

  const ShowCaseWidget({
    super.key,
    required this.builder,
    this.onFinish,
    this.onStart,
    this.onComplete,
    this.autoPlay = false,
    this.autoPlayDelay = const Duration(milliseconds: 2000),
    this.enableAutoPlayLock = false,
    this.blurValue = 0,
    this.scrollDuration = const Duration(milliseconds: 300),
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
  });

  static GlobalKey? activeTargetWidget(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedShowCaseView>()
        ?.activeWidgetIds;
  }

  static ShowCaseWidgetState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ShowCaseWidgetState>();
    if (state != null) {
      return state;
    } else {
      throw Exception('Please provide ShowCaseView context');
    }
  }

  @override
  ShowCaseWidgetState createState() => ShowCaseWidgetState();
}

class ShowCaseWidgetState extends State<ShowCaseWidget> {
  List<GlobalKey>? ids;
  int? activeWidgetId;

  /// These properties are only here so that it can be accessed by
  /// [Showcase]
  bool get autoPlay => widget.autoPlay;

  bool get disableMovingAnimation => widget.disableMovingAnimation;

  bool get disableScaleAnimation => widget.disableScaleAnimation;

  Duration get autoPlayDelay => widget.autoPlayDelay;

  bool get enableAutoPlayLock => widget.enableAutoPlayLock;

  bool get enableAutoScroll => widget.enableAutoScroll;

  bool get disableBarrierInteraction => widget.disableBarrierInteraction;

  /// Resolved barrier behaviour. The legacy [ShowCaseWidget.disableBarrierInteraction]
  /// flag wins when `true`, mapping to [BarrierInteraction.none].
  BarrierInteraction get barrierInteraction => widget.disableBarrierInteraction
      ? BarrierInteraction.none
      : widget.barrierInteraction;

  bool get enableShowcase => widget.enableShowcase;

  bool get enableKeyboardNavigation => widget.enableKeyboardNavigation;

  bool get enableAutoAnnouncements => widget.enableAutoAnnouncements;

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
    while (index >= 0 &&
        index < ids!.length &&
        ids![index].currentContext == null) {
      index += direction;
    }
    return index;
  }

  /// Completes showcase of given key and starts next one
  /// otherwise will finish the entire showcase view
  void completed(GlobalKey? key) {
    if (ids != null && ids![activeWidgetId!] == key && mounted) {
      setState(() {
        _onComplete();
        activeWidgetId = _nextMountedIndex(activeWidgetId! + 1, 1);
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
        activeWidgetId = _nextMountedIndex(activeWidgetId! + 1, 1);
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
    if (mounted) setState(_cleanupAfterSteps);
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

  @override
  Widget build(BuildContext context) {
    return _InheritedShowCaseView(
      activeWidgetIds: ids?.elementAt(activeWidgetId!),
      child: widget.builder,
    );
  }
}

class _InheritedShowCaseView extends InheritedWidget {
  final GlobalKey? activeWidgetIds;

  const _InheritedShowCaseView({
    required this.activeWidgetIds,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedShowCaseView oldWidget) =>
      oldWidget.activeWidgetIds != activeWidgetIds;
}
