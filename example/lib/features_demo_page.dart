import 'package:flutter/material.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

import 'scroll_alignment_demo_page.dart';

/// A scratch page to manually exercise the package features:
/// left/right tooltip positions, the progress API, auto-skip of unmounted
/// steps, RTL, custom action-button text, and conditional / branching tours
/// (`onResolveNextStep`).
class FeaturesDemoPage extends StatefulWidget {
  const FeaturesDemoPage({super.key});

  @override
  State<FeaturesDemoPage> createState() => _FeaturesDemoPageState();
}

class _FeaturesDemoPageState extends State<FeaturesDemoPage> {
  final _topLeft = GlobalKey();
  final _topRight = GlobalKey();
  final _center = GlobalKey();
  final _multiPrimary = GlobalKey();
  final _multiA = GlobalKey();
  final _multiB = GlobalKey();
  final _exact = GlobalKey();
  final _pulse = GlobalKey();
  final _styled = GlobalKey();
  final _conditional = GlobalKey();
  final _bottom = GlobalKey();

  bool _rtl = false;
  bool _numericProgress = false; // dots vs "1/6" progress indicator
  bool _includeConditional = false; // off => that step is auto-skipped
  bool _branchSkipAhead =
      false; // on => branch from P straight to the last step
  bool _autoPlay = false; // on => the tour auto-advances (1.5s/step)
  bool _wideGap = false; // on => the "C" step's tooltip sits further from it
  bool _wideMargin =
      false; // on => the "R" step's tooltip is held further from the edges
  bool _glideSteps = false; // on => the highlight glides between targets
  // Starts on: `outside` places the buttons absolutely, so on a step whose
  // target sits near a screen edge they crowd the tooltip. Uncheck to compare.
  bool _actionsInside = true;
  int _step = 0;
  int _total = 0;
  BarrierInteraction _barrier = BarrierInteraction.next;
  String _lastEvent = '—'; // last onShow/onDismiss fired (lifecycle demo)
  Rect? _centerRect; // live bounds of the "C" target (onTargetRectUpdate)

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ShowCaseWidget(
        autoSkipUnmountedSteps: true,
        barrierInteraction: _barrier,
        // Glide the cut-out between targets instead of cutting. The steps here
        // are spread across the screen, so the travel is easy to see.
        enableStepTransition: _glideSteps,
        stepTransitionDuration: const Duration(milliseconds: 400),
        // Auto-play: 1.5s per step tour-wide; the "Exact shape" step overrides
        // this with a longer per-step Showcase.autoPlayDelay (it has more to read).
        autoPlay: _autoPlay,
        autoPlayDelay: const Duration(milliseconds: 1500),
        // A screen-anchored button pinned for the whole tour, hidden on the last
        // "B" step via hideFloatingActionWidgetForShowcase.
        globalFloatingActionWidget: (context) => Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton.tonalIcon(
              onPressed: ShowCaseWidget.of(context).dismiss,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('End tour'),
            ),
          ),
        ),
        hideFloatingActionWidgetForShowcase: [_bottom],
        // Previous/Next declared once for the whole tour instead of on every
        // Showcase. The "C" step sets its own `actions:`, which wins, and the
        // first step is listed below because "Previous" has nowhere to go.
        globalActions: (context) => ShowCaseDefaultActions(
          previous: const ActionButtonConfig(text: 'Back'),
          stop: const ActionButtonConfig(text: 'Skip'),
          next: const ActionButtonConfig(text: 'Next'),
        ),
        hideActionsForShowcase: [_topLeft],
        // Outside the tooltip box (the default) or flowing inside it.
        actionsPosition: _actionsInside
            ? TooltipActionPosition.inside
            : TooltipActionPosition.outside,
        showProgress: true,
        progressStyle: _numericProgress
            ? ShowcaseProgressStyle.numeric
            : ShowcaseProgressStyle.dots,
        showSkip: true,
        // Conditional / branching tour: when the toggle is on, advancing past
        // the pulsing "P" step jumps straight to the last "B" step, skipping
        // the styled / custom-buttons / conditional steps in between.
        onResolveNextStep: (index, key) {
          if (_branchSkipAhead && key == _pulse) return _bottom;
          return null; // fall through to the normal next step
        },
        onStart: (index, key) => setState(() => _step = (index ?? 0) + 1),
        builder: Builder(
          builder: (context) {
            final show = ShowCaseWidget.of(context);
            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xff0077b6),
                foregroundColor: Colors.white,
                title: Text(
                  show.isShowcaseRunning
                      ? 'Step $_step of $_total  ·  $_lastEvent'
                      : 'Feature demos (1.14.0)',
                ),
                actions: [
                  const Center(child: Text('1/6')),
                  Switch(
                    value: _numericProgress,
                    onChanged: (v) => setState(() => _numericProgress = v),
                  ),
                  const Center(child: Text('RTL')),
                  Switch(
                    value: _rtl,
                    onChanged: (v) => setState(() => _rtl = v),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  // Tooltip on the RIGHT of a left-edge target.
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Showcase(
                      key: _topLeft,
                      targetShapeBorder: const CircleBorder(),
                      description: _wideMargin
                          ? 'toolTipMargin: held 96px from the edges'
                          : 'tooltipPosition.right',
                      tooltipPosition: TooltipPosition.right,
                      // toolTipMargin: minimum gap kept from every screen edge.
                      // This edge-hugging target makes the clamp visible — a wide
                      // margin pushes the tooltip down/in from the top-left corner.
                      // (Also applies to Showcase.withWidget containers.)
                      toolTipMargin: _wideMargin
                          ? const EdgeInsets.all(96)
                          : const EdgeInsets.all(20),
                      onShow: () => setState(() => _lastEvent = 'onShow: R'),
                      onDismiss: () =>
                          setState(() => _lastEvent = 'onDismiss: R'),
                      child: const _Dot('R'),
                    ),
                  ),
                  // Tooltip on the LEFT of a right-edge target.
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Showcase(
                      key: _topRight,
                      targetShapeBorder: const CircleBorder(),
                      description: 'tooltipPosition.left',
                      tooltipPosition: TooltipPosition.left,
                      child: const _Dot('L'),
                    ),
                  ),
                  // Multi-widget step: the primary (M) highlights two extra
                  // widgets (1 and 2) in the same step. Extras are wrapped in
                  // MultiView so a snapshot can be drawn over the overlay.
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MultiView(key: _multiA, child: const _Dot('1')),
                        const SizedBox(width: 24),
                        Showcase(
                          key: _multiPrimary,
                          targetShapeBorder: const CircleBorder(),
                          keys: [_multiA, _multiB],
                          description: 'Highlights 3 widgets at once',
                          child: const _Dot('M'),
                        ),
                        const SizedBox(width: 24),
                        MultiView(key: _multiB, child: const _Dot('2')),
                      ],
                    ),
                  ),
                  // Exact-shape step: an irregular widget (a star) highlighted
                  // by its actual painted shape — no targetShapeBorder needed.
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Showcase(
                        key: _exact,
                        highlightExactShape: true,
                        // Per-step autoPlayDelay: lingers longer than the
                        // tour-wide 1.5s when auto-play is on.
                        autoPlayDelay: const Duration(seconds: 4),
                        title: 'Exact shape',
                        description:
                            'Highlight hugs the star. Lingers 4s in auto-play.',
                        child: const Icon(
                          Icons.star,
                          size: 72,
                          color: Color(0xfff4a261),
                        ),
                      ),
                    ),
                  ),
                  // Pulsing highlight ring — an animated ring pings outward
                  // around the target to draw the eye.
                  Positioned(
                    top: 200,
                    left: 16,
                    child: Showcase(
                      key: _pulse,
                      targetShapeBorder: const CircleBorder(),
                      title: 'Pulsing ring',
                      description:
                          'An animated ring pulses around the target. Hover it '
                          'on web/desktop: this step forces a "forbidden" cursor.',
                      // Per-step cursor override: wins over the tour-wide
                      // enablePointerCursor resolution (which would show a
                      // click cursor here).
                      targetMouseCursor: SystemMouseCursors.forbidden,
                      enablePulseAnimation: true,
                      pulseColor: const Color(0xfff4a261),
                      child: const _Dot('P'),
                    ),
                  ),
                  // Tooltip & highlight styling: custom arrow color/size and a
                  // colored border around the highlighted target.
                  Positioned(
                    top: 200,
                    right: 16,
                    child: Showcase(
                      key: _styled,
                      targetShapeBorder: const CircleBorder(),
                      title: 'Styled',
                      description:
                          'Custom arrow + highlight border. This tooltip is '
                          'tappable, so it gets a click cursor.',
                      // A tooltip only gets the click cursor when tapping it
                      // actually does something — like this.
                      onToolTipClick: () =>
                          setState(() => _lastEvent = 'tooltip tapped: S'),
                      tooltipBackgroundColor: const Color(0xff023047),
                      textColor: Colors.white,
                      arrowColor: const Color(0xfff4a261),
                      arrowWidth: 26,
                      arrowHeight: 13,
                      highlightBorderColor: const Color(0xfff4a261),
                      highlightBorderWidth: 3,
                      child: const _Dot('S'),
                    ),
                  ),
                  // Center step with custom action-button text.
                  Align(
                    child: Showcase(
                      key: _center,
                      targetShapeBorder: const CircleBorder(),
                      title: 'Custom buttons',
                      description:
                          'Custom buttons. Background taps do nothing here.',
                      // Extra space between the target and the tooltip.
                      targetTooltipGap: _wideGap ? 28 : 0,
                      // Per-step barrier override: whatever the tour-wide
                      // SegmentedButton selects, this one step ignores
                      // background taps.
                      barrierInteraction: BarrierInteraction.none,
                      // Live bounds of this target: fires when the step opens
                      // and again whenever they change (resize, rotation, …).
                      onTargetRectUpdate: (rect) =>
                          setState(() => _centerRect = rect),
                      actions: ShowCaseDefaultActions(
                        previous: const ActionButtonConfig(text: 'Back'),
                        stop: const ActionButtonConfig(text: 'Skip'),
                        next: const ActionButtonConfig(text: 'Continue'),
                      ),
                      child: const _Dot('C'),
                    ),
                  ),
                  // Conditional step — included only when the checkbox is on.
                  // Sits in the target row rather than down among the controls,
                  // which are painted over it.
                  if (_includeConditional)
                    Positioned(
                      top: 200,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Showcase(
                          key: _conditional,
                          targetShapeBorder: const CircleBorder(),
                          description: 'Conditional step',
                          child: const _Dot('?'),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Showcase(
                        key: _bottom,
                        targetShapeBorder: const CircleBorder(),
                        title: 'Done',
                        description: 'Last step.',
                        child: const _Dot('B'),
                      ),
                    ),
                  ),
                  // Controls. Bounded top *and* bottom and scrollable: with only
                  // `bottom` set, a Positioned child gets unbounded height, so a
                  // tall column silently renders off the top of the screen
                  // instead of reporting an overflow.
                  Positioned(
                    top: 270,
                    bottom: 88,
                    left: 16,
                    right: 16,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Registers its own step listener on the controller —
                          // no wiring needed from this page.
                          const _StepListenerLabel(),
                          Text(
                            _centerRect == null
                                ? 'onTargetRectUpdate ("C"): —'
                                : 'onTargetRectUpdate ("C"): '
                                      '${_centerRect!.left.toStringAsFixed(0)},'
                                      '${_centerRect!.top.toStringAsFixed(0)} '
                                      '${_centerRect!.width.toStringAsFixed(0)}×'
                                      '${_centerRect!.height.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _includeConditional,
                            onChanged: (v) => setState(
                              () => _includeConditional = v ?? false,
                            ),
                            title: const Text(
                              'Include conditional step (off → auto-skipped)',
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _branchSkipAhead,
                            onChanged: (v) =>
                                setState(() => _branchSkipAhead = v ?? false),
                            title: const Text(
                              'Branch: skip from P straight to the last step',
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _glideSteps,
                            onChanged: (v) =>
                                setState(() => _glideSteps = v ?? false),
                            title: const Text(
                              'Glide the highlight between steps (400ms)',
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _actionsInside,
                            onChanged: (v) =>
                                setState(() => _actionsInside = v ?? false),
                            title: const Text(
                              'Draw the tour buttons inside the tooltip',
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _autoPlay,
                            onChanged: (v) =>
                                setState(() => _autoPlay = v ?? false),
                            title: const Text(
                              'Auto-play (1.5s/step; the star step lingers 4s)',
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _wideGap,
                            onChanged: (v) =>
                                setState(() => _wideGap = v ?? false),
                            title: const Text(
                              'Wide tooltip gap (the "C" step sits further away)',
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _wideMargin,
                            onChanged: (v) =>
                                setState(() => _wideMargin = v ?? false),
                            title: const Text(
                              'Wide tooltip margin (the "R" step held in from the edges)',
                            ),
                          ),
                          // Barrier-tap behavior: tap the dimmed background to see it.
                          SegmentedButton<BarrierInteraction>(
                            segments: const [
                              ButtonSegment(
                                value: BarrierInteraction.next,
                                label: Text('next'),
                              ),
                              ButtonSegment(
                                value: BarrierInteraction.dismiss,
                                label: Text('dismiss'),
                              ),
                              ButtonSegment(
                                value: BarrierInteraction.none,
                                label: Text('none'),
                              ),
                            ],
                            selected: {_barrier},
                            onSelectionChanged: (s) =>
                                setState(() => _barrier = s.first),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              final ids = [
                                _topLeft,
                                _topRight,
                                _multiPrimary,
                                _exact,
                                _pulse,
                                _styled,
                                _center,
                                _conditional,
                                _bottom,
                              ];
                              setState(() => _total = ids.length);
                              show.startShowCase(ids);
                            },
                            child: const Text('Start tour'),
                          ),
                          OutlinedButton(
                            // isTargetRendered: only jump to the conditional step
                            // when its target is actually laid out on screen.
                            onPressed: () {
                              if (!show.isTargetRendered(_conditional)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'The "?" target is not on screen — tick the '
                                      'checkbox above first.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              show.goToKey(_conditional);
                            },
                            child: const Text('Go to the conditional step'),
                          ),
                          OutlinedButton(
                            // Auto-scroll alignment lives on its own scrollable
                            // page (this demo page is a non-scrolling Stack).
                            onPressed: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ScrollAlignmentDemoPage(),
                              ),
                            ),
                            child: const Text('Auto-scroll alignment demo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reports the tour's step events without the host page wiring anything up.
///
/// It registers its own listeners on the controller at runtime
/// ([ShowCaseWidgetState.addOnStartCallback] /
/// [ShowCaseWidgetState.addOnCompleteCallback]) and removes them again on
/// dispose — the dynamic counterpart of `ShowCaseWidget.onStart` / `onComplete`,
/// which are fixed when the `ShowCaseWidget` is built.
class _StepListenerLabel extends StatefulWidget {
  const _StepListenerLabel();

  @override
  State<_StepListenerLabel> createState() => _StepListenerLabelState();
}

class _StepListenerLabelState extends State<_StepListenerLabel> {
  ShowCaseWidgetState? _controller;
  String _label = 'registered listener: idle';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ShowCaseWidget.of(context);
    if (identical(controller, _controller)) return;
    _unregister();
    _controller = controller
      ..addOnStartCallback(_onStepStart)
      ..addOnCompleteCallback(_onStepComplete);
  }

  void _onStepStart(int? index, GlobalKey key) => setState(
    () => _label = 'registered listener: step ${(index ?? 0) + 1} started',
  );

  void _onStepComplete(int? index, GlobalKey key) => setState(
    () => _label = 'registered listener: step ${(index ?? 0) + 1} completed',
  );

  void _unregister() {
    _controller?.removeOnStartCallback(_onStepStart);
    _controller?.removeOnCompleteCallback(_onStepComplete);
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(_label, style: const TextStyle(fontSize: 12));
}

class _Dot extends StatelessWidget {
  final String label;
  const _Dot(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xff0077b6),
        shape: BoxShape.circle,
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
