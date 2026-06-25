import 'package:flutter/material.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

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
  bool _branchSkipAhead = false; // on => branch from P straight to the last step
  int _step = 0;
  int _total = 0;
  BarrierInteraction _barrier = BarrierInteraction.next;
  String _lastEvent = '—'; // last onShow/onDismiss fired (lifecycle demo)

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ShowCaseWidget(
        autoSkipUnmountedSteps: true,
        barrierInteraction: _barrier,
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
                title: Text(show.isShowcaseRunning
                    ? 'Step $_step of $_total  ·  $_lastEvent'
                    : 'Feature demos (1.5.0)'),
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
                      description: 'tooltipPosition.right',
                      tooltipPosition: TooltipPosition.right,
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
                        title: 'Exact shape',
                        description: 'Highlight hugs the star, not a box.',
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
                      description: 'An animated ring pulses around the target.',
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
                      description: 'Custom arrow + highlight border.',
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
                      description: 'Action buttons with custom text.',
                      actions: ShowCaseDefaultActions(
                        previous: const ActionButtonConfig(text: 'Back'),
                        stop: const ActionButtonConfig(text: 'Skip'),
                        next: const ActionButtonConfig(text: 'Continue'),
                      ),
                      child: const _Dot('C'),
                    ),
                  ),
                  // Conditional step — included only when the checkbox is on.
                  if (_includeConditional)
                    Positioned(
                      bottom: 220,
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
                  // Controls.
                  Positioned(
                    bottom: 110,
                    left: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _includeConditional,
                          onChanged: (v) =>
                              setState(() => _includeConditional = v ?? false),
                          title: const Text(
                              'Include conditional step (off → auto-skipped)'),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _branchSkipAhead,
                          onChanged: (v) =>
                              setState(() => _branchSkipAhead = v ?? false),
                          title: const Text(
                              'Branch: skip from P straight to the last step'),
                        ),
                        // Barrier-tap behavior: tap the dimmed background to see it.
                        SegmentedButton<BarrierInteraction>(
                          segments: const [
                            ButtonSegment(
                                value: BarrierInteraction.next,
                                label: Text('next')),
                            ButtonSegment(
                                value: BarrierInteraction.dismiss,
                                label: Text('dismiss')),
                            ButtonSegment(
                                value: BarrierInteraction.none,
                                label: Text('none')),
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
                      ],
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
