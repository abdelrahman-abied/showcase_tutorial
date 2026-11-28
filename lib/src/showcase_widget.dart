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

import 'package:flutter/widgets.dart';

import '../showcase_tutorial.dart';

/// Signature of [ShowCaseWidget.onStart] and [ShowCaseWidget.onComplete], and
/// of the step listeners registered dynamically on the controller with
/// [ShowCaseWidgetState.addOnStartCallback] and
/// [ShowCaseWidgetState.addOnCompleteCallback].
///
/// Receives the zero-based index of the step and the [GlobalKey] of its target.
typedef ShowcaseStepCallback = void Function(int? index, GlobalKey key);

/// Hosts a showcase tour for the [Showcase] widgets in its subtree.
///
/// Wrap your screen (or app) in a [ShowCaseWidget], wrap each target in a
/// [Showcase] with a unique [GlobalKey], then start the tour with
/// `ShowCaseWidget.of(context).startShowCase([...])`. Tour-wide options such as
/// [autoPlay], [barrierInteraction], [style], and the accessibility flags are
/// configured here and shared by every [Showcase] in the tree.
class ShowCaseWidget extends StatefulWidget {
  /// The subtree that contains the [Showcase] widgets — usually your screen,
  /// for example `builder: const HomePage()`.
  ///
  /// Any widget works. Widgets inside it can call `ShowCaseWidget.of(context)`
  /// from their own `build` methods, because their context is below this
  /// [ShowCaseWidget]. The context of the code that *creates* this
  /// [ShowCaseWidget] is not below it, so when the subtree is built inline and
  /// needs `ShowCaseWidget.of(context)` right there, wrap it in a [Builder]:
  ///
  /// ```dart
  /// ShowCaseWidget(
  ///   builder: Builder(
  ///     builder: (context) => Column(
  ///       children: [
  ///         Showcase(key: one, description: 'Menu', child: const Icon(Icons.menu)),
  ///         TextButton(
  ///           onPressed: () => ShowCaseWidget.of(context).startShowCase([one]),
  ///           child: const Text('Start tour'),
  ///         ),
  ///       ],
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// Before 2.0.0 this had to be a [Builder]; existing [Builder] values still
  /// work unchanged.
  final Widget builder;

  /// Triggered when all the showcases are completed.
  ///
  /// To add listeners at runtime, see [ShowCaseWidgetState.addOnFinishCallback].
  final VoidCallback? onFinish;

  /// Triggered every time a step starts, with the step's zero-based index in
  /// the running tour and its target key.
  ///
  /// Also fires for the first step a tour opens on, including one chosen with
  /// `startAt` in [ShowCaseWidgetState.startShowCase]. To add listeners at
  /// runtime, see [ShowCaseWidgetState.addOnStartCallback].
  final ShowcaseStepCallback? onStart;

  /// Triggered every time a step completes (the tour leaves it to go to another
  /// step or to finish), with the step's zero-based index and its target key.
  ///
  /// To add listeners at runtime, see
  /// [ShowCaseWidgetState.addOnCompleteCallback].
  final ShowcaseStepCallback? onComplete;

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
  ///
  /// To add listeners at runtime, see
  /// [ShowCaseWidgetState.addOnDismissCallback].
  final void Function(GlobalKey? dismissedAt)? onDismiss;

  /// Triggered whenever the dimmed background (the barrier) is tapped, in
  /// addition to the configured [barrierInteraction] behaviour.
  ///
  /// Fires even when [barrierInteraction] is [BarrierInteraction.none], so it can
  /// be used purely as a "user tapped outside the highlight" signal — for a hint
  /// nudge, a sound, or analytics — without changing what the tap does. When
  /// [barrierInteraction] is `.next` or `.dismiss` this runs first, then the
  /// configured action follows.
  ///
  /// A step's own [Showcase.onBarrierClick] runs right after this one, for
  /// taps while that step is active.
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

  /// Action buttons shown in **every** step's tooltip — typically a
  /// [ShowCaseDefaultActions] with Previous / Stop / Next.
  ///
  /// Set it once for the tour instead of repeating `actions:` on every
  /// [Showcase]. Built lazily per step, so it can read the current tour state
  /// via `ShowCaseWidget.of(context)`. A per-step [Showcase.actions] overrides
  /// this, and [hideActionsForShowcase] suppresses it on specific steps.
  /// Defaults to `null` (no actions).
  final WidgetBuilder? globalActions;

  /// Container styling for [globalActions]. Overridden by a per-step
  /// [Showcase.actionSettings]. Defaults to `null`.
  final ActionsSettings? globalActionSettings;

  /// Absolute placement for [globalActions] when [actionsPosition] is
  /// [TooltipActionPosition.outside]. Overridden by a per-step
  /// [Showcase.actionButtonsPosition]. Defaults to `null` (auto).
  final ActionButtonsPosition? globalActionButtonsPosition;

  /// Whether action buttons are drawn inside the tooltip box or positioned
  /// outside it, for every step of the tour.
  ///
  /// Overridden per step by [Showcase.actionsPosition]. Defaults to
  /// [TooltipActionPosition.outside], which is how actions have always been
  /// drawn, so existing tours are unaffected.
  final TooltipActionPosition actionsPosition;

  /// The [GlobalKey]s of the steps on which [globalActions] should be hidden —
  /// e.g. a final step that should not offer "Next".
  ///
  /// Ignored by a per-step [Showcase.actions], which always wins.
  /// Defaults to an empty list.
  final List<GlobalKey> hideActionsForShowcase;

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
  /// Deprecated: use `barrierInteraction: BarrierInteraction.none` instead,
  /// which does the same thing. Still honoured until it is removed in 3.0.0:
  /// when `true` it takes precedence and the barrier is inert
  /// ([BarrierInteraction.none]).
  @Deprecated(
    'Use barrierInteraction: BarrierInteraction.none instead. '
    'disableBarrierInteraction will be removed in 3.0.0.',
  )
  final bool disableBarrierInteraction;

  /// What tapping the dimmed background (the barrier) does during a step.
  ///
  /// Defaults to [BarrierInteraction.next] (advance to the next step). Use
  /// [BarrierInteraction.dismiss] to close the whole tour on a background tap,
  /// or [BarrierInteraction.none] to ignore barrier taps.
  ///
  /// Note: the deprecated `disableBarrierInteraction` flag wins when set to
  /// `true`.
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
  ///
  /// Overridden for a single step by [Showcase.enableAutoScroll].
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
  /// `force: true` is passed). With a `delay`, it is called once the delay has
  /// passed, just before the tour would start.
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
  /// to `false`, which makes the tour wait on such a step until its target
  /// mounts (see "Tours across screens" in the README).
  ///
  /// To skip some unmounted steps and wait for others, use
  /// [onShouldSkipUnmountedStep], which takes precedence over this flag.
  final bool autoSkipUnmountedSteps;

  /// Decides, step by step, whether a step whose target widget is not mounted
  /// is skipped (`true`) or waited for (`false`).
  ///
  /// Use it when a tour needs both behaviours: for example a tour that waits
  /// for a step on a page the user opens later, but skips a step whose widget
  /// is only built in some app states.
  ///
  /// ```dart
  /// ShowCaseWidget(
  ///   // Wait for the details page, skip anything else that isn't on screen.
  ///   onShouldSkipUnmountedStep: (index, key) => key != detailsKey,
  ///   builder: const HomePage(),
  /// )
  /// ```
  ///
  /// It is called with the step's `index` in the running tour and its target
  /// `key`, and only for steps whose target is not mounted at that moment;
  /// mounted steps are always shown. It is consulted wherever
  /// [autoSkipUnmountedSteps] would be: when the tour starts (for the first
  /// step and any unmounted steps after it), when it moves forward (the Next
  /// button, a tap on the target or tooltip, the barrier, the keyboard,
  /// auto-play, [ShowCaseWidgetState.next] and [ShowCaseWidgetState.completed])
  /// and when it moves back with [ShowCaseWidgetState.previous]. It runs while
  /// the tour is changing step, so keep it a quick, synchronous check that
  /// does not call `setState` or move the tour itself (`next`, `goTo`,
  /// `startShowCase` and the like).
  ///
  /// When provided, its answer replaces [autoSkipUnmountedSteps] for every
  /// step; the flag only applies while this is `null`. Explicit jumps are not
  /// affected by either: [ShowCaseWidgetState.goTo],
  /// [ShowCaseWidgetState.goToKey] and a step returned by [onResolveNextStep]
  /// always land on the requested step, mounted or not. Steps after a skipped
  /// one are checked in turn, and if every remaining step is skipped the tour
  /// finishes (or, going back, stays where it is).
  ///
  /// Defaults to `null`, which leaves [autoSkipUnmountedSteps] in charge.
  final bool Function(int index, GlobalKey key)? onShouldSkipUnmountedStep;

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

  /// When `true`, the highlight cut-out glides from the previous step's target
  /// to the next one when the tour advances, instead of jumping there — the
  /// "guided tour" feel.
  ///
  /// The cut-out, its optional [Showcase.highlightBorderColor] border, and the
  /// [Showcase.enablePulseAnimation] ring all follow the moving rect; the
  /// tooltip keeps its existing scale transition and appears at the new target.
  /// Only the step being entered animates, so the first step of a tour (and any
  /// step entered while no other was active) simply appears.
  ///
  /// Honors the platform "reduce motion" accessibility setting by jumping
  /// straight to the target. Has no effect on a [Showcase.highlightExactShape]
  /// step, which draws a snapshot of the target rather than a cut-out.
  ///
  /// Defaults to `false`. Tune it with [stepTransitionDuration] and
  /// [stepTransitionCurve].
  final bool enableStepTransition;

  /// How long the [enableStepTransition] glide takes.
  ///
  /// Defaults to `Duration(milliseconds: 300)`. Ignored when
  /// [enableStepTransition] is `false`.
  final Duration stepTransitionDuration;

  /// Curve of the [enableStepTransition] glide.
  ///
  /// Defaults to [Curves.easeInOut]. Ignored when [enableStepTransition] is
  /// `false`.
  final Curve stepTransitionCurve;

  /// When `true`, hovering a part of the showcase that reacts to a click shows
  /// [SystemMouseCursors.click] instead of the default arrow: the highlighted
  /// target (unless [Showcase.disableDefaultTargetGestures] is set), a tooltip
  /// that has [Showcase.onToolTipClick] or `disposeOnTap`, and the built-in
  /// "Skip" button.
  ///
  /// Relevant on web/desktop; harmless on mobile (no pointer). Override the
  /// cursor for a single step with [Showcase.targetMouseCursor] /
  /// [Showcase.tooltipMouseCursor], which win even when this is `false`.
  /// Defaults to `true`.
  ///
  /// Note: the buttons in [ShowCaseDefaultActions] are Material buttons and
  /// already show a click cursor regardless of this flag.
  final bool enablePointerCursor;

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
  /// explicit jump, like [ShowCaseWidgetState.goTo], so neither
  /// [autoSkipUnmountedSteps] nor [onShouldSkipUnmountedStep] is applied to the
  /// target.
  ///
  /// Not consulted by [ShowCaseWidgetState.previous],
  /// [ShowCaseWidgetState.goTo], or [ShowCaseWidgetState.goToKey], which are
  /// explicit navigation. Defaults to `null` (no branching).
  final GlobalKey? Function(int currentIndex, GlobalKey currentKey)? onResolveNextStep;

  /// The text of the tour's built-in buttons: Next, Previous and Stop in every
  /// [ShowCaseDefaultActions], and the Skip button of [showSkip].
  ///
  /// Set it once to translate the tour, e.g.
  /// `labels: const ShowcaseLabels(next: 'التالي', previous: 'السابق')`. A
  /// button's own [ActionButtonConfig.text] still wins for that button.
  /// Defaults to the English labels of `const ShowcaseLabels()`.
  final ShowcaseLabels labels;

  /// Label for the skip button (see [showSkip]).
  ///
  /// When set, it wins over `labels.skip`, so existing apps keep their text.
  /// Defaults to `null`, which uses [labels].
  @Deprecated('Use labels: ShowcaseLabels(skip: ...) instead. Will be removed in 3.0.0.')
  final String? skipButtonText;

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
    this.globalActions,
    this.globalActionSettings,
    this.globalActionButtonsPosition,
    this.actionsPosition = TooltipActionPosition.outside,
    this.hideActionsForShowcase = const [],
    this.autoPlay = false,
    this.autoPlayDelay = const Duration(milliseconds: 2000),
    this.enableAutoPlayLock = false,
    this.blurValue = 0,
    this.scrollDuration = const Duration(milliseconds: 300),
    this.scrollAlignment = 0.5,
    this.disableMovingAnimation = false,
    this.disableScaleAnimation = false,
    this.enableAutoScroll = false,
    @Deprecated(
      'Use barrierInteraction: BarrierInteraction.none instead. '
      'disableBarrierInteraction will be removed in 3.0.0.',
    )
    this.disableBarrierInteraction = false,
    this.barrierInteraction = BarrierInteraction.next,
    this.enableShowcase = true,
    this.style = const ShowcaseStyle(),
    this.showcaseId,
    this.onShouldStartShowcase,
    this.autoSkipUnmountedSteps = false,
    this.onShouldSkipUnmountedStep,
    this.enableKeyboardNavigation = true,
    this.enableStepTransition = false,
    this.stepTransitionDuration = const Duration(milliseconds: 300),
    this.stepTransitionCurve = Curves.easeInOut,
    this.enablePointerCursor = true,
    this.enableAutoAnnouncements = true,
    this.showProgress = false,
    this.progressStyle = ShowcaseProgressStyle.dots,
    this.showSkip = false,
    this.labels = const ShowcaseLabels(),
    @Deprecated('Use labels: ShowcaseLabels(skip: ...) instead. Will be removed in 3.0.0.') this.skipButtonText,
    this.onResolveNextStep,
  });

  /// Returns the [GlobalKey] of the currently active step's target, or `null`
  /// when no tour is running.
  ///
  /// Reads the nearest [_InheritedShowCaseView], so callers rebuild when the
  /// active step changes.
  ///
  /// Pass [aspect] to depend on one step only: the caller is then rebuilt just
  /// for the changes that make that step active or inactive, instead of on
  /// every step change in the tour. [Showcase] passes its own key, which is why
  /// advancing a tour rebuilds the two steps involved rather than all of them.
  /// Omitting [aspect] keeps the original behaviour of rebuilding on any step
  /// change.
  static GlobalKey? activeTargetWidget(BuildContext context, {GlobalKey? aspect}) {
    return InheritedModel.inheritFrom<_InheritedShowCaseView>(context, aspect: aspect)?.activeWidgetIds;
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

  /// Value of the legacy `ShowCaseWidget.disableBarrierInteraction` flag.
  ///
  /// Deprecated with that flag: read [barrierInteraction] instead, which
  /// already accounts for it.
  @Deprecated(
    'Use barrierInteraction instead. '
    'disableBarrierInteraction will be removed in 3.0.0.',
  )
  bool get disableBarrierInteraction => widget.disableBarrierInteraction;

  /// Resolved barrier behaviour. The deprecated
  /// `ShowCaseWidget.disableBarrierInteraction` flag wins when `true`, mapping
  /// to [BarrierInteraction.none].
  BarrierInteraction get barrierInteraction =>
      // The legacy flag is still honoured until it is removed in 3.0.0.
      // ignore: deprecated_member_use_from_same_package
      widget.disableBarrierInteraction ? BarrierInteraction.none : widget.barrierInteraction;

  /// Value of [ShowCaseWidget.onBarrierClick].
  VoidCallback? get onBarrierClick => widget.onBarrierClick;

  /// Value of [ShowCaseWidget.globalFloatingActionWidget].
  WidgetBuilder? get globalFloatingActionWidget => widget.globalFloatingActionWidget;

  /// Value of [ShowCaseWidget.hideFloatingActionWidgetForShowcase].
  List<GlobalKey> get hideFloatingActionWidgetForShowcase => widget.hideFloatingActionWidgetForShowcase;

  /// Value of [ShowCaseWidget.globalActions].
  WidgetBuilder? get globalActions => widget.globalActions;

  /// Value of [ShowCaseWidget.globalActionSettings].
  ActionsSettings? get globalActionSettings => widget.globalActionSettings;

  /// Value of [ShowCaseWidget.globalActionButtonsPosition].
  ActionButtonsPosition? get globalActionButtonsPosition => widget.globalActionButtonsPosition;

  /// Value of [ShowCaseWidget.actionsPosition].
  TooltipActionPosition get actionsPosition => widget.actionsPosition;

  /// Value of [ShowCaseWidget.hideActionsForShowcase].
  List<GlobalKey> get hideActionsForShowcase => widget.hideActionsForShowcase;

  /// Value of [ShowCaseWidget.enableShowcase].
  bool get enableShowcase => widget.enableShowcase;

  /// Value of [ShowCaseWidget.enableKeyboardNavigation].
  bool get enableKeyboardNavigation => widget.enableKeyboardNavigation;

  /// Value of [ShowCaseWidget.enablePointerCursor].
  bool get enablePointerCursor => widget.enablePointerCursor;

  /// Value of [ShowCaseWidget.enableStepTransition].
  bool get enableStepTransition => widget.enableStepTransition;

  /// Value of [ShowCaseWidget.stepTransitionDuration].
  Duration get stepTransitionDuration => widget.stepTransitionDuration;

  /// Value of [ShowCaseWidget.stepTransitionCurve].
  Curve get stepTransitionCurve => widget.stepTransitionCurve;

  /// Global bounds of the target the tour just left, or `null` when the tour is
  /// starting or the previous target could not be measured.
  ///
  /// Captured as the tour leaves a step so the step being entered can glide its
  /// cut-out from here (see [ShowCaseWidget.enableStepTransition]). Only
  /// recorded while transitions are enabled.
  Rect? get previousTargetRect => _previousTargetRect;
  Rect? _previousTargetRect;

  /// Value of [ShowCaseWidget.enableAutoAnnouncements].
  bool get enableAutoAnnouncements => widget.enableAutoAnnouncements;

  /// Value of [ShowCaseWidget.showProgress].
  bool get showProgress => widget.showProgress;

  /// Value of [ShowCaseWidget.progressStyle].
  ShowcaseProgressStyle get progressStyle => widget.progressStyle;

  /// Value of [ShowCaseWidget.showSkip].
  bool get showSkip => widget.showSkip;

  /// The labels the tour's built-in buttons show: [ShowCaseWidget.labels],
  /// with its Skip label replaced by the deprecated
  /// [ShowCaseWidget.skipButtonText] when that is set.
  ShowcaseLabels get labels {
    // ignore: deprecated_member_use_from_same_package
    final legacySkip = widget.skipButtonText;
    return legacySkip == null ? widget.labels : widget.labels.copyWith(skip: legacySkip);
  }

  /// The Skip button's label.
  @Deprecated('Use labels.skip instead. Will be removed in 3.0.0.')
  String get skipButtonText => labels.skip;

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

  /// The focus node of the active step's overlay, shared by every step.
  ///
  /// See [ShowcaseTourFocus.overlayFocusNode].
  final FocusNode _overlayFocusNode = FocusNode(debugLabel: 'Showcase');

  /// Listeners registered with [addOnStartCallback].
  final List<ShowcaseStepCallback> _onStartCallbacks = [];

  /// Listeners registered with [addOnCompleteCallback].
  final List<ShowcaseStepCallback> _onCompleteCallbacks = [];

  /// Listeners registered with [addOnFinishCallback].
  final List<VoidCallback> _onFinishCallbacks = [];

  /// Listeners registered with [addOnDismissCallback].
  final List<void Function(GlobalKey? dismissedAt)> _onDismissCallbacks = [];

  /// The start [startShowCase] scheduled with a `delay`, while it waits.
  Timer? _delayedStart;

  /// Whether a start is waiting on an asynchronous
  /// [ShowCaseWidget.onShouldStartShowcase].
  bool _awaitingGuard = false;

  /// Counts the starts asked for and called off. A guard that answers after
  /// its start was called off, or replaced, finds a newer generation and does
  /// nothing.
  int _startGeneration = 0;

  /// Whether the target widget for [key] is currently laid out on screen.
  ///
  /// Returns `true` only when the target is mounted **and** has been through
  /// layout, so its position and size can be read — replacing manual
  /// `key.currentContext != null` checks, which are `true` for a mounted but
  /// not-yet-laid-out widget.
  ///
  /// Useful before calling [goToKey] (or [startShowCase]) on a step whose target
  /// is rendered conditionally, e.g. an item inside a lazily built list. See also
  /// [ShowCaseWidget.autoSkipUnmountedSteps] and
  /// [ShowCaseWidget.onShouldSkipUnmountedStep], which skip such steps
  /// automatically while navigating.
  bool isTargetRendered(GlobalKey key) => _measureTarget(key) != null;

  /// Global bounds of [key]'s target, or `null` when it is not mounted or has
  /// not been laid out yet.
  Rect? _measureTarget(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null || !targetContext.mounted) return null;
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// Registers [callback] to run whenever a step starts, in addition to
  /// [ShowCaseWidget.onStart].
  ///
  /// Unlike the widget-level callback — which is fixed when the
  /// [ShowCaseWidget] is built — listeners registered here can come and go at
  /// runtime, so a screen, controller, or analytics service deeper in the tree
  /// can observe the tour for as long as it lives. Register in `initState` and
  /// pair with [removeOnStartCallback] in `dispose`.
  ///
  /// Adding the same callback twice invokes it twice. Listeners run after
  /// [ShowCaseWidget.onStart], in registration order; removing one during
  /// dispatch is safe and takes effect from the next step.
  void addOnStartCallback(ShowcaseStepCallback callback) => _onStartCallbacks.add(callback);

  /// Unregisters a listener added with [addOnStartCallback].
  ///
  /// Returns `true` if it was registered. Removes only the first match when the
  /// same callback was added more than once.
  bool removeOnStartCallback(ShowcaseStepCallback callback) => _onStartCallbacks.remove(callback);

  /// Registers [callback] to run whenever a step completes, in addition to
  /// [ShowCaseWidget.onComplete].
  ///
  /// The dynamic counterpart of [ShowCaseWidget.onComplete] — see
  /// [addOnStartCallback] for the registration contract. Pair with
  /// [removeOnCompleteCallback] in `dispose`.
  void addOnCompleteCallback(ShowcaseStepCallback callback) => _onCompleteCallbacks.add(callback);

  /// Unregisters a listener added with [addOnCompleteCallback].
  ///
  /// Returns `true` if it was registered. Removes only the first match when the
  /// same callback was added more than once.
  bool removeOnCompleteCallback(ShowcaseStepCallback callback) => _onCompleteCallbacks.remove(callback);

  /// Registers [callback] to run whenever a tour finishes normally (advances
  /// past its last step), in addition to [ShowCaseWidget.onFinish].
  ///
  /// The dynamic counterpart of [ShowCaseWidget.onFinish], with the same
  /// contract as [addOnStartCallback]: adding the same callback twice invokes
  /// it twice, listeners run after [ShowCaseWidget.onFinish] in registration
  /// order, and removing one during dispatch is safe and takes effect from
  /// the next finish. Like [ShowCaseWidget.onFinish], it is not called when
  /// the tour is dismissed early: see [addOnDismissCallback]. Pair with
  /// [removeOnFinishCallback] in `dispose`.
  void addOnFinishCallback(VoidCallback callback) => _onFinishCallbacks.add(callback);

  /// Unregisters a listener added with [addOnFinishCallback].
  ///
  /// Returns `true` if it was registered. Removes only the first match when the
  /// same callback was added more than once.
  bool removeOnFinishCallback(VoidCallback callback) => _onFinishCallbacks.remove(callback);

  /// Registers [callback] to run whenever the tour is dismissed early, in
  /// addition to [ShowCaseWidget.onDismiss].
  ///
  /// The dynamic counterpart of [ShowCaseWidget.onDismiss]: it runs on every
  /// [dismiss] (a barrier tap with [BarrierInteraction.dismiss], <kbd>Esc</kbd>,
  /// the skip button, `disposeOnTap`, a manual `dismiss()` call, or
  /// [ShowCaseWidget.enableShowcase] turning off mid-tour) and receives the
  /// same [GlobalKey] of the step that was active, or `null` if none was.
  /// It has the same contract as [addOnStartCallback]: adding the same
  /// callback twice invokes it twice, listeners run after
  /// [ShowCaseWidget.onDismiss] in registration order, and removing one during
  /// dispatch is safe and takes effect from the next dismissal. Pair with
  /// [removeOnDismissCallback] in `dispose`.
  void addOnDismissCallback(void Function(GlobalKey? dismissedAt) callback) => _onDismissCallbacks.add(callback);

  /// Unregisters a listener added with [addOnDismissCallback].
  ///
  /// Returns `true` if it was registered. Removes only the first match when the
  /// same callback was added more than once.
  bool removeOnDismissCallback(void Function(GlobalKey? dismissedAt) callback) => _onDismissCallbacks.remove(callback);

  /// Starts the tour over [widgetIds], in that order. If this function is used
  /// when showcase has been disabled then it will throw an exception.
  ///
  /// When [ShowCaseWidget.onShouldStartShowcase] is provided it is consulted
  /// first, and the showcase only starts if it resolves to `true` (useful for
  /// "show the tour only once"). Pass `force: true` to bypass that guard — for
  /// example from a "show tutorial again" button.
  ///
  /// [startAt] is the zero-based index of the step the tour opens on; it
  /// defaults to `0`, the first step. Use it to resume a tour where the user
  /// left off: save the index passed to [ShowCaseWidget.onStart] (or to an
  /// [addOnStartCallback] listener) as the tour runs, clear it in
  /// [ShowCaseWidget.onFinish] and [ShowCaseWidget.onDismiss], and pass the
  /// saved value back here. The package stores nothing itself. A tour started
  /// at [startAt] behaves like a tour started at `0`:
  ///
  /// * the guard above and `force` work the same way,
  /// * [ShowCaseWidget.autoSkipUnmountedSteps] and
  ///   [ShowCaseWidget.onShouldSkipUnmountedStep] are applied from [startAt]
  ///   forward, exactly as they are from the first step, and the tour
  ///   finishes if every step from there on is skipped,
  /// * [currentIndex], the progress indicator and [ShowCaseWidget.onStart]
  ///   report the real step index (a tour started at `2` reports `2`),
  /// * the tour opens directly on that step — with
  ///   [ShowCaseWidget.enableStepTransition] there is no glide from another
  ///   target — and [previous] can still go back to the earlier steps.
  ///
  /// An out-of-range [startAt] is clamped, in every build mode: a negative
  /// value opens the first step and a value past the end opens the last step.
  /// A saved index that no longer fits usually means the tour got shorter in
  /// an app update, so it is treated as data, not a programming error.
  /// Clamping keeps that user in the tour instead of finishing it for them,
  /// which would fire [ShowCaseWidget.onFinish] and could mark a tour they
  /// never saw as done. An empty [widgetIds] list finishes the tour straight
  /// away, whatever [startAt] is.
  ///
  /// [delay] waits that long before starting the tour, for example to let a
  /// screen finish its entrance animation first. It defaults to
  /// [Duration.zero], which starts the tour straight away, within this call,
  /// exactly as without it (a zero or negative [delay] is treated the same).
  /// With a positive [delay]:
  ///
  /// * the call returns at once, and the tour starts once [delay] has passed,
  ///   as if `startShowCase(widgetIds, force: force, startAt: startAt)` were
  ///   called at that moment,
  /// * so [ShowCaseWidget.onShouldStartShowcase] is consulted **after** the
  ///   delay, not before. It sees the app as it is when the tour would start:
  ///   a tour the user completed elsewhere in the meantime does not start.
  ///   An asynchronous guard adds its own wait to the delay,
  /// * a tour already running keeps running until the delayed start replaces
  ///   it.
  ///
  /// The delay's timer belongs to this [ShowCaseWidget], not to the screen
  /// that called [startShowCase]. When a page schedules a delayed start and
  /// the [ShowCaseWidget] sits above the [Navigator], popping the page does
  /// not call the start off: it still fires, and the tour then waits for the
  /// page's steps to mount again (or, with
  /// [ShowCaseWidget.autoSkipUnmountedSteps], skips them and finishes). A
  /// screen that schedules a delayed start should call [cancelDelayedStart] in
  /// its `dispose`, through a [ShowCaseWidgetState] it kept from
  /// `didChangeDependencies` (an ancestor lookup is not allowed in `dispose`).
  /// A start whose steps are not mounted when it fires is not dropped, as a
  /// tour can wait for a page the user has yet to open.
  ///
  /// **Calling a start off.** A start waiting on its [delay], or on an
  /// asynchronous guard, never fires once it is called off. That happens
  /// when [cancelDelayedStart] or [dismiss] is called, when [startShowCase]
  /// is called again (the new call replaces it), when
  /// [ShowCaseWidget.enableShowcase] turns `false`, or when this
  /// [ShowCaseWidget] is disposed. [cancelDelayedStart] does it silently;
  /// [dismiss] also reports a dismissal, as it always does (see [dismiss]).
  ///
  /// The throw for a disabled showcase (see above) happens at the call, not
  /// after the delay.
  void startShowCase(List<GlobalKey> widgetIds, {bool force = false, int startAt = 0, Duration delay = Duration.zero}) {
    if (!enableShowcase) {
      throw Exception(
        "You are trying to start Showcase while it has been disabled with "
        "`enableShowcase` parameter to false from ShowCaseWidget",
      );
    }
    if (!mounted) return;

    // A start still waiting, on its delay or on the guard, is replaced by
    // this one.
    _cancelPendingStart();
    if (delay > Duration.zero) {
      _delayedStart = Timer(delay, () {
        _delayedStart = null;
        if (mounted && enableShowcase) _startShowCaseGuarded(widgetIds, force, startAt);
      });
      return;
    }
    _startShowCaseGuarded(widgetIds, force, startAt);
  }

  /// Whether a start asked for with [startShowCase] has yet to happen: one
  /// waiting on its `delay`, or on an asynchronous
  /// [ShowCaseWidget.onShouldStartShowcase].
  ///
  /// [isShowcaseRunning] stays as it was while a start is pending: a tour
  /// already running keeps running until the start replaces it.
  bool get isStartPending => _delayedStart != null || _awaitingGuard;

  /// Calls off a start that [startShowCase] has yet to make, without firing
  /// any callback, and returns whether one was pending (see [isStartPending]).
  ///
  /// It is the silent way to cancel a start that waits on its `delay` or on an
  /// asynchronous [ShowCaseWidget.onShouldStartShowcase]: unlike [dismiss], it
  /// leaves a running tour alone and calls neither [ShowCaseWidget.onDismiss]
  /// nor the [addOnDismissCallback] listeners.
  ///
  /// Call it from the `dispose` of a screen that scheduled a delayed start,
  /// so the start does not outlive the screen. Keep the [ShowCaseWidgetState]
  /// from `didChangeDependencies`: `dispose` cannot look up ancestors.
  ///
  /// ```dart
  /// late ShowCaseWidgetState _tour;
  ///
  /// @override
  /// void didChangeDependencies() {
  ///   super.didChangeDependencies();
  ///   _tour = ShowCaseWidget.of(context);
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   _tour.cancelDelayedStart();
  ///   super.dispose();
  /// }
  /// ```
  bool cancelDelayedStart() => _cancelPendingStart();

  /// Starts the tour now, unless [ShowCaseWidget.onShouldStartShowcase] says
  /// otherwise (or [force] bypasses it).
  void _startShowCaseGuarded(List<GlobalKey> widgetIds, bool force, int startAt) {
    final guard = widget.onShouldStartShowcase;
    if (force || guard == null) {
      _startShowCaseNow(widgetIds, startAt);
      return;
    }
    // The guard may be synchronous or asynchronous; wrapping in Future.value
    // handles both without forcing callers to await. Its answer only counts
    // while no newer start, dismissal or cancellation came in the meantime,
    // and while the showcase is still enabled.
    final generation = _startGeneration;
    _awaitingGuard = true;
    Future<bool>.value(guard(widget.showcaseId)).then((shouldStart) {
      if (generation != _startGeneration) return;
      _awaitingGuard = false;
      if (shouldStart && mounted && enableShowcase) _startShowCaseNow(widgetIds, startAt);
    });
  }

  /// Calls off a start that waits on its `delay` or on the guard, and returns
  /// whether there was one.
  bool _cancelPendingStart() {
    final wasPending = isStartPending;
    _delayedStart?.cancel();
    _delayedStart = null;
    _awaitingGuard = false;
    _startGeneration++;
    return wasPending;
  }

  void _startShowCaseNow(List<GlobalKey> widgetIds, int startAt) {
    setState(() {
      // A tour always opens on its starting step rather than gliding into it,
      // even when this call restarts a running tour.
      _previousTargetRect = null;
      ids = widgetIds;
      // A stale startAt is clamped into range (see startShowCase). An empty
      // tour stays at 0, which finishes it below as before.
      final start = widgetIds.isEmpty ? 0 : startAt.clamp(0, widgetIds.length - 1);
      activeWidgetId = _nextMountedIndex(start, 1);
      if (activeWidgetId! >= ids!.length) {
        _cleanupAfterSteps();
        _onFinish();
      } else {
        _onStart();
      }
    });
  }

  /// Advances [index] in [direction] (`1` forward / `-1` back) past steps whose
  /// target widget is not currently mounted and that [_shouldSkipUnmounted]
  /// says to skip, returning the first step to show (or an out-of-range index
  /// when none remain). A step that is unmounted but not skipped is returned,
  /// so the tour waits on it until its target mounts.
  int _nextMountedIndex(int index, int direction) {
    final steps = ids;
    if (steps == null) return index;
    if (widget.onShouldSkipUnmountedStep == null && !widget.autoSkipUnmountedSteps) return index;
    while (index >= 0 && index < steps.length && steps[index].currentContext == null) {
      if (!_shouldSkipUnmounted(index, steps[index])) break;
      index += direction;
    }
    return index;
  }

  /// Whether the unmounted step at [index] is skipped: the answer of
  /// [ShowCaseWidget.onShouldSkipUnmountedStep] when set, otherwise
  /// [ShowCaseWidget.autoSkipUnmountedSteps].
  bool _shouldSkipUnmounted(int index, GlobalKey key) {
    final decide = widget.onShouldSkipUnmountedStep;
    return decide == null ? widget.autoSkipUnmountedSteps : decide(index, key);
  }

  /// Resolves the index to advance to when moving forward from [fromIndex].
  ///
  /// Consults [ShowCaseWidget.onResolveNextStep] for conditional / branching
  /// tours: when it returns a [GlobalKey] that is part of the running tour, that
  /// step's index is used as an explicit jump (no [_nextMountedIndex] applied,
  /// mirroring [goTo]). Otherwise the default next index — [fromIndex] + 1,
  /// adjusted for [ShowCaseWidget.onShouldSkipUnmountedStep] /
  /// [ShowCaseWidget.autoSkipUnmountedSteps] — is returned.
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
          _onFinish();
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
          _onFinish();
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
  ///
  /// Calls [ShowCaseWidget.onDismiss] and the [addOnDismissCallback]
  /// listeners with the step that was active, or with `null` when no tour is
  /// running, as it always has. It also calls off a start that [startShowCase]
  /// has yet to make (see [isStartPending]). To call off a pending start
  /// without reporting a dismissal, use [cancelDelayedStart] instead.
  void dismiss() {
    if (!mounted) return;
    _cancelPendingStart();
    // Capture the active step before clearing state so [ShowCaseWidget.onDismiss]
    // can report where the user left off.
    final dismissedAt = activeStepKey;
    setState(_cleanupAfterSteps);
    widget.onDismiss?.call(dismissedAt);
    if (_onDismissCallbacks.isNotEmpty) {
      // A copy, so a listener can unregister itself (or another) while it runs.
      for (final listener in List.of(_onDismissCallbacks)) {
        listener(dismissedAt);
      }
    }
  }

  /// Reports a normal finish to [ShowCaseWidget.onFinish], then to the
  /// listeners registered with [addOnFinishCallback].
  void _onFinish() {
    widget.onFinish?.call();
    if (_onFinishCallbacks.isEmpty) return;
    // A copy, so a listener can unregister itself (or another) while it runs.
    for (final listener in List.of(_onFinishCallbacks)) {
      listener();
    }
  }

  void _onStart() {
    if (activeWidgetId! < ids!.length) {
      final key = ids![activeWidgetId!];
      widget.onStart?.call(activeWidgetId, key);
      _notifyStepListeners(_onStartCallbacks, key);
    }
  }

  void _onComplete() {
    final key = ids![activeWidgetId!];
    // Measure the step we are leaving while it is still laid out, so the step
    // being entered can glide its cut-out from here.
    _previousTargetRect = widget.enableStepTransition ? _measureTarget(key) : null;
    widget.onComplete?.call(activeWidgetId, key);
    _notifyStepListeners(_onCompleteCallbacks, key);
  }

  /// Dispatches a step event to the dynamically registered [listeners].
  ///
  /// Walks a copy of the list so a listener that unregisters itself (or another)
  /// while it runs doesn't mutate the list mid-iteration.
  void _notifyStepListeners(List<ShowcaseStepCallback> listeners, GlobalKey key) {
    if (listeners.isEmpty) return;
    for (final listener in List<ShowcaseStepCallback>.of(listeners)) {
      listener(activeWidgetId, key);
    }
  }

  void _cleanupAfterSteps() {
    ids = null;
    activeWidgetId = null;
    _previousTargetRect = null;
  }

  @override
  void dispose() {
    _cancelPendingStart();
    _onStartCallbacks.clear();
    _onCompleteCallbacks.clear();
    _onFinishCallbacks.clear();
    _onDismissCallbacks.clear();
    _overlayFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShowCaseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A start still waiting on its `delay` is called off too: the tour is not
    // to start while the showcase is disabled.
    if (!widget.enableShowcase) _cancelPendingStart();
    // A running tour cannot survive being disabled: [startShowCase] refuses to
    // run at all while [ShowCaseWidget.enableShowcase] is false, so leaving the
    // tour half-alive would be a state the API cannot otherwise reach. Ending it
    // goes through [dismiss], so [ShowCaseWidget.onDismiss] still reports where
    // the user left off and exactly one of onFinish/onDismiss runs per tour.
    //
    // Deferred to after the frame because [dismiss] invokes that callback, and
    // user callbacks commonly call setState, which is illegal during a build.
    if (oldWidget.enableShowcase && !widget.enableShowcase && ids != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.enableShowcase && ids != null) dismiss();
      });
    }
  }

  /// Exposes the active step's target key to descendants and places the
  /// configured [ShowCaseWidget.builder] subtree below it.
  @override
  Widget build(BuildContext context) {
    return _InheritedShowCaseView(
      activeWidgetIds: ids?.elementAt(activeWidgetId!),
      enableShowcase: widget.enableShowcase,
      child: widget.builder,
    );
  }
}

/// Publishes the active step's key, and whether the tour is enabled at all, to
/// the [Showcase] widgets below.
///
/// This is an [InheritedModel] rather than a plain [InheritedWidget] so a step
/// change does not rebuild every [Showcase] on the screen. Each [Showcase]
/// depends on its own key as an aspect, and a step change only ever alters two
/// of them: the one being left and the one being entered. Dependents that
/// registered without an aspect (an empty dependency set) are still notified on
/// every change, which is what [InheritedModel] does by default.
class _InheritedShowCaseView extends InheritedModel<GlobalKey> {
  final GlobalKey? activeWidgetIds;

  /// Mirrors [ShowCaseWidget.enableShowcase] so a change to it reaches the
  /// [Showcase] widgets below. Without it, flipping the flag published nothing:
  /// [ShowCaseWidget.builder] is one stored widget instance, so the subtree is
  /// never rebuilt on its own.
  final bool enableShowcase;

  const _InheritedShowCaseView({required this.activeWidgetIds, required this.enableShowcase, required super.child});

  @override
  bool updateShouldNotify(_InheritedShowCaseView oldWidget) =>
      oldWidget.activeWidgetIds != activeWidgetIds || oldWidget.enableShowcase != enableShowcase;

  @override
  bool updateShouldNotifyDependent(_InheritedShowCaseView oldWidget, Set<GlobalKey> aspects) {
    // Turning the tour off or back on changes every step's answer, so it has to
    // reach all of them.
    if (oldWidget.enableShowcase != enableShowcase) return true;
    // A step change can only ever alter two: the one that just became active
    // and the one that just stopped being active. Every other step's answer to
    // "am I active?" is still no.
    return aspects.contains(activeWidgetIds) || aspects.contains(oldWidget.activeWidgetIds);
  }
}

/// Gives [Showcase] the parts of [ShowCaseWidgetState] that are not public
/// API. Hidden from the package's public library.
extension ShowcaseTourFocus on ShowCaseWidgetState {
  /// The focus node of the active step's overlay, which a hardware keyboard
  /// drives the tour through.
  ///
  /// It belongs to the tour rather than to each step. When the tour moves on,
  /// the step being entered attaches the node before the step being left lets
  /// go of it, so focus never leaves the overlay. With a node per step, the
  /// one being left gave focus back to the page and the next one took it
  /// again, rebuilding every focus widget on the way in between.
  FocusNode get overlayFocusNode => _overlayFocusNode;

  /// The target key of the step the tour is on right now, or `null` when no
  /// tour is running.
  ///
  /// Read from the tour itself rather than from the inherited value a step
  /// last rebuilt with, so it is current even between frames.
  GlobalKey? get activeStepKey {
    final steps = ids;
    final index = activeWidgetId;
    if (steps == null || index == null || index < 0 || index >= steps.length) return null;
    return steps[index];
  }
}
