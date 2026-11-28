import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

/// Where the sweep below reads, and with `--dart-define=RECORD_PLACEMENT=true`
/// writes, the tooltip rects recorded before the placement changes.
const _baselinePath = 'test/fixtures/tooltip_placement_baseline.json';
const _record = bool.fromEnvironment('RECORD_PLACEMENT');

/// The phone-sized screen every test here runs on, in logical pixels.
const _screen = Size(412, 915);

void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = _screen * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

const _shortText = 'Tap here';
const _longText =
    'A much longer description that is far too wide for one line, so the tooltip is capped at the screen width';

/// One configuration of the placement sweep.
class _Case {
  const _Case({
    required this.custom,
    required this.position,
    required this.alignment,
    required this.target,
    required this.rtl,
    this.longText = false,
    this.showArrow = true,
    this.actions,
    this.declared,
    this.actual,
  });

  /// `Showcase.withWidget` rather than the default tooltip.
  final bool custom;
  final TooltipPosition? position;
  final Alignment alignment;
  final Size target;
  final bool rtl;
  final bool longText;
  final bool showArrow;

  /// Built-in actions inside or outside the default tooltip, or none.
  final TooltipActionPosition? actions;

  /// `Showcase.withWidget`'s `width`/`height`, and the container's real size.
  final Size? declared;
  final Size? actual;

  String get id => [
    custom ? 'custom' : 'default',
    position?.name ?? 'auto',
    '${alignment.x},${alignment.y}',
    '${target.width}x${target.height}',
    rtl ? 'rtl' : 'ltr',
    if (!custom) longText ? 'long' : 'short',
    if (!custom) showArrow ? 'arrow' : 'noarrow',
    if (!custom) actions?.name ?? 'noactions',
    if (custom) 'declared${declared!.width}x${declared!.height}',
    if (custom) 'actual${actual!.width}x${actual!.height}',
  ].join('|');
}

List<_Case> _sweep() {
  final alignments = [
    for (final y in [-1.0, -0.75, 0.0, 0.75, 1.0])
      for (final x in [-1.0, 0.0, 1.0]) Alignment(x, y),
  ];
  const targets = [Size(40, 40), Size(160, 56), Size(100, 600)];
  final cases = <_Case>[];
  for (final position in <TooltipPosition?>[null, ...TooltipPosition.values]) {
    for (final alignment in alignments) {
      for (final target in targets) {
        for (final rtl in [false, true]) {
          for (final (longText, showArrow) in [(false, true), (true, true), (false, false)]) {
            for (final actions in <TooltipActionPosition?>[null, ...TooltipActionPosition.values]) {
              cases.add(
                _Case(
                  custom: false,
                  position: position,
                  alignment: alignment,
                  target: target,
                  rtl: rtl,
                  longText: longText,
                  showArrow: showArrow,
                  actions: actions,
                ),
              );
            }
          }
          for (final (declared, actual) in [
            (const Size(140, 80), const Size(140, 80)),
            (const Size(300, 300), const Size(300, 300)),
            // Declared sizes are trusted even when they are wrong.
            (const Size(140, 80), const Size(200, 50)),
          ]) {
            cases.add(
              _Case(
                custom: true,
                position: position,
                alignment: alignment,
                target: target,
                rtl: rtl,
                declared: declared,
                actual: actual,
              ),
            );
          }
        }
      }
    }
  }
  return cases;
}

const _containerKey = ValueKey('container');

/// Shows [c] and returns the tooltip's rect (the default tooltip's box, or the
/// custom container), the target's rect, and the "Next" button's rect when
/// the step has actions.
Future<({Rect tooltip, Rect target, Rect? next})> _probe(WidgetTester tester, _Case c) async {
  final key = GlobalKey();
  late BuildContext pageContext;
  final actions = c.actions == null ? null : const ShowCaseDefaultActions();
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      builder: (context, child) =>
          Directionality(textDirection: c.rtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        builder: Builder(
          builder: (context) {
            pageContext = context;
            final target = SizedBox.fromSize(size: c.target, child: const Text('target'));
            return Scaffold(
              body: Align(
                alignment: c.alignment,
                child: c.custom
                    ? Showcase.withWidget(
                        key: key,
                        width: c.declared!.width,
                        height: c.declared!.height,
                        tooltipPosition: c.position,
                        container: SizedBox.fromSize(key: _containerKey, size: c.actual),
                        child: target,
                      )
                    : Showcase(
                        key: key,
                        title: 'Title',
                        description: c.longText ? _longText : _shortText,
                        showArrow: c.showArrow,
                        tooltipPosition: c.position,
                        actions: actions,
                        actionsPosition: c.actions,
                        child: target,
                      ),
              ),
            );
          },
        ),
      ),
    ),
  );
  ShowCaseWidget.of(pageContext).startShowCase([key]);
  await tester.pump();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final tooltip = c.custom
      ? tester.getRect(find.byKey(_containerKey))
      : tester.getRect(find.ancestor(of: find.text('Title'), matching: find.byType(ClipRRect)).first);
  final next = c.actions == null ? null : tester.getRect(find.text('Next'));
  return (tooltip: tooltip, target: tester.getRect(find.text('target')), next: next);
}

List<double> _ltrb(Rect r) => [r.left, r.top, r.right, r.bottom];

/// Whether [tooltip] is wholly on screen and clear of [target].
bool _fits(Rect tooltip, Rect target) {
  const eps = 0.01;
  final onScreen =
      tooltip.left >= -eps &&
      tooltip.top >= -eps &&
      tooltip.right <= _screen.width + eps &&
      tooltip.bottom <= _screen.height + eps;
  final overlap = tooltip.intersect(target);
  final clear = overlap.width <= eps || overlap.height <= eps;
  return onScreen && clear;
}

/// The rects worth recording: the tooltip's, then the "Next" button's when
/// the step has actions.
List<double> _rects(({Rect tooltip, Rect target, Rect? next}) r) => [
  ..._ltrb(r.tooltip),
  if (r.next != null) ..._ltrb(r.next!),
];

void main() {
  testWidgets('a tooltip that fits keeps the rect it had before the placement changes', (tester) async {
    _usePhoneScreen(tester);
    final cases = _sweep();
    if (_record) {
      final recorded = <String, List<double>?>{};
      for (final c in cases) {
        final r = await _probe(tester, c);
        recorded[c.id] = _fits(r.tooltip, r.target) ? _rects(r) : null;
      }
      File(_baselinePath)
        ..createSync(recursive: true)
        // In sweep order, so the ids need not be stored.
        ..writeAsStringSync('${jsonEncode(recorded.values.toList())}\n');
      return;
    }

    final ids = [for (final c in cases) c.id];
    final stored = (jsonDecode(File(_baselinePath).readAsStringSync()) as List).cast<List<Object?>?>();
    expect(stored, hasLength(ids.length), reason: 'the sweep matches the recording');
    final baseline = {
      for (var i = 0; i < ids.length; i++) ids[i]: stored[i]?.cast<num>().map((n) => n.toDouble()).toList(),
    };
    var compared = 0;
    final moved = <String>[];
    for (final c in cases) {
      final before = baseline[c.id];
      if (before == null) continue;
      compared++;
      final after = _rects(await _probe(tester, c));
      if (!listEquals(after, before)) moved.add('${c.id}: $before -> $after');
    }
    expect(moved, isEmpty);
    // Most of the sweep fits; the rest is what the placement changes are for.
    expect(compared, greaterThan(cases.length ~/ 2));
  });

  group('a tooltip that does not fit moves to a side where it does', () {
    // Each case is the middle step of a three-step tour, with the tooltip
    // animations on. Its buttons and body are tapped where it moved to: a tap
    // that missed would fall through to the dimmed background, whose default
    // is to move the tour on.
    for (final c in _moveCases) {
      for (final rtl in [false, true]) {
        testWidgets('${c.name} (${rtl ? 'RTL' : 'LTR'})', (tester) async {
          _usePhoneScreen(tester);
          final previousWarning = WidgetController.hitTestWarningShouldBeFatal;
          WidgetController.hitTestWarningShouldBeFatal = true;
          addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previousWarning);

          final keys = [GlobalKey(), GlobalKey(), GlobalKey()];
          var bodyTaps = 0;
          var dismissed = false;
          var finished = false;
          late BuildContext pageContext;
          Widget step(int i, Alignment alignment, Size size, {TooltipPosition? position}) => Align(
            alignment: alignment,
            child: Showcase(
              key: keys[i],
              title: 'Step $i',
              description: _shortText,
              tooltipPosition: position,
              onToolTipClick: () => bodyTaps++,
              child: SizedBox.fromSize(size: size, child: Text('target $i')),
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) =>
                  Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
              home: ShowCaseWidget(
                actionsPosition: c.outside ? TooltipActionPosition.outside : TooltipActionPosition.inside,
                // Short labels keep the tooltip narrow enough to go beside a
                // target: the test font draws every letter a square.
                globalActions: (_) => const ShowCaseDefaultActions(previous: ActionButtonConfig(text: 'Prev')),
                onDismiss: (_) => dismissed = true,
                onFinish: () => finished = true,
                builder: Builder(
                  builder: (context) {
                    pageContext = context;
                    return Scaffold(
                      body: Stack(
                        children: [
                          step(0, c.others, const Size(40, 40)),
                          step(1, c.alignment, c.target, position: c.position),
                          step(2, Alignment(c.others.x, -c.others.y), const Size(40, 40)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );

          Future<void> settle() async {
            for (var i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }

          Rect tooltip() =>
              tester.getRect(find.ancestor(of: find.text('Step 1'), matching: find.byType(ClipRRect)).first);

          ShowCaseWidget.of(pageContext).startShowCase(keys);
          await settle();
          ShowCaseWidget.of(pageContext).next();
          await settle();
          expect(find.text('Step 1'), findsOneWidget);
          final target = tester.getRect(find.text('target 1'));
          final box = tooltip();
          expect(Offset.zero & _screen, _contains(box), reason: 'on screen: $box');
          expect(box.overlaps(target), isFalse, reason: 'clear of the target: $box, $target');
          switch (c.expected) {
            case TooltipPosition.top:
              expect(box.bottom, lessThanOrEqualTo(target.top));
            case TooltipPosition.bottom:
              expect(box.top, greaterThanOrEqualTo(target.bottom));
            case TooltipPosition.left:
              expect(box.right, lessThanOrEqualTo(target.left));
              expect(target.center.dy, inInclusiveRange(box.top, box.bottom), reason: 'beside the target');
            case TooltipPosition.right:
              expect(box.left, greaterThanOrEqualTo(target.right));
              expect(target.center.dy, inInclusiveRange(box.top, box.bottom), reason: 'beside the target');
          }

          await tester.tap(find.text(_shortText));
          await settle();
          expect(bodyTaps, 1);
          expect(find.text('Step 1'), findsOneWidget, reason: 'a tap on the tooltip does not move the tour');

          await tester.tap(find.text('Prev'));
          await settle();
          expect(find.text('Step 0'), findsOneWidget, reason: 'Previous went back');

          await tester.tap(find.text('Next'));
          await settle();
          expect(find.text('Step 1'), findsOneWidget);
          expect(tooltip(), box, reason: 'back where it was');

          await tester.tap(find.text('Next'));
          await settle();
          expect(find.text('Step 2'), findsOneWidget, reason: 'Next went forward one step');
          ShowCaseWidget.of(pageContext).previous();
          await settle();

          await tester.tap(find.text('Stop'));
          await settle();
          expect(dismissed, isTrue);
          expect(finished, isFalse);
          expect(find.text('Step 1'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('with no side set and room on both, it goes beside the target on the roomier side', (tester) async {
    _usePhoneScreen(tester);
    Future<Rect> show(Alignment alignment) async {
      final key = GlobalKey();
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) {
                pageContext = context;
                return Scaffold(
                  body: Align(
                    alignment: alignment,
                    child: Showcase(
                      key: key,
                      title: 'Title',
                      child: const SizedBox(width: 20, height: 860, child: Text('target')),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      ShowCaseWidget.of(pageContext).startShowCase([key]);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return tester.getRect(find.ancestor(of: find.text('Title'), matching: find.byType(ClipRRect)).first);
    }

    Rect target() => tester.getRect(find.text('target'));
    expect((await show(const Alignment(-0.2, 0))).left, greaterThan(target().right), reason: 'more room right');
    expect((await show(const Alignment(0.2, 0))).right, lessThan(target().left), reason: 'more room left');
  });

  testWidgets('a tooltip that fits on neither side is placed as before', (tester) async {
    _usePhoneScreen(tester);
    // A full-width tooltip next to a target as tall as the screen: no side
    // fits, so it goes below as it always did, and so does a requested top.
    for (final position in [null, TooltipPosition.top, TooltipPosition.bottom]) {
      final key = GlobalKey();
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) {
                pageContext = context;
                return Scaffold(
                  body: Center(
                    child: Showcase(
                      key: key,
                      title: 'Title',
                      description: _longText,
                      tooltipPosition: position,
                      child: const SizedBox(width: 100, height: 860, child: Text('target')),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      ShowCaseWidget.of(pageContext).startShowCase([key]);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final box = tester.getRect(find.ancestor(of: find.text('Title'), matching: find.byType(ClipRRect)).first);
      final target = tester.getRect(find.text('target'));
      if (position == TooltipPosition.top) {
        expect(box.bottom, lessThan(target.top), reason: 'top, as requested');
      } else {
        expect(box.top, greaterThan(target.bottom), reason: '${position?.name ?? 'auto'} goes below');
      }
    }
  });

  testWidgets('a measured custom container that does not fit on its side moves, and its button works', (tester) async {
    // Only a measured container moves: one with a declared height stays on
    // the side asked for, as it always did (see the regression tests).
    _usePhoneScreen(tester);
    final previousWarning = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previousWarning);
    for (final (position, alignment) in [
      (TooltipPosition.top, Alignment.topCenter),
      (TooltipPosition.bottom, Alignment.bottomCenter),
    ]) {
      final key = GlobalKey();
      var taps = 0;
      var finished = false;
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: ShowCaseWidget(
            onFinish: () => finished = true,
            builder: Builder(
              builder: (context) {
                pageContext = context;
                return Scaffold(
                  body: Align(
                    alignment: alignment,
                    child: Showcase.withWidget(
                      key: key,
                      tooltipPosition: position,
                      container: SizedBox(
                        width: 200,
                        height: 120,
                        child: Center(
                          child: FilledButton(onPressed: () => taps++, child: const Text('Got it')),
                        ),
                      ),
                      child: const SizedBox(width: 80, height: 56, child: Text('target')),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      ShowCaseWidget.of(pageContext).startShowCase([key]);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final button = tester.getRect(find.text('Got it'));
      final target = tester.getRect(find.text('target'));
      if (position == TooltipPosition.top) {
        expect(button.top, greaterThan(target.bottom), reason: 'top gave way to bottom');
      } else {
        expect(button.bottom, lessThan(target.top), reason: 'bottom gave way to top');
      }
      await tester.tap(find.text('Got it'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(taps, 1);
      expect(finished, isFalse, reason: 'the tap did not fall through to the dimmed background');
    }
  });
}

/// A step whose tooltip has to move: where its target is, what was asked
/// for, and where the tooltip should end up.
typedef _MoveCase = ({
  String name,
  Alignment alignment,
  Size target,
  TooltipPosition? position,
  TooltipPosition expected,

  /// Where the other two steps' targets go, mirrored vertically for the third.
  Alignment others,

  /// Whether the buttons are outside the tooltip rather than inside it.
  bool outside,
});

const List<_MoveCase> _moveCases = [
  (
    name: 'top at the top edge goes below',
    alignment: Alignment.topCenter,
    target: Size(120, 48),
    position: TooltipPosition.top,
    expected: TooltipPosition.bottom,
    others: Alignment(0, 0.5),
    outside: false,
  ),
  (
    name: 'bottom at the bottom edge goes above',
    alignment: Alignment.bottomCenter,
    target: Size(120, 48),
    position: TooltipPosition.bottom,
    expected: TooltipPosition.top,
    others: Alignment(0, -0.5),
    outside: false,
  ),
  (
    name: 'left at the left edge goes right',
    alignment: Alignment.centerLeft,
    target: Size(40, 48),
    position: TooltipPosition.left,
    expected: TooltipPosition.right,
    others: Alignment(0.8, 0.6),
    outside: false,
  ),
  (
    name: 'right at the right edge goes left',
    alignment: Alignment.centerRight,
    target: Size(40, 48),
    position: TooltipPosition.right,
    expected: TooltipPosition.left,
    others: Alignment(-0.8, 0.6),
    outside: false,
  ),
  (
    name: 'unset beside a target too tall for above or below goes right',
    alignment: Alignment.centerLeft,
    target: Size(40, 860),
    position: null,
    expected: TooltipPosition.right,
    others: Alignment(0.8, 0.9),
    outside: false,
  ),
  (
    name: 'unset beside a target too tall for above or below goes left',
    alignment: Alignment.centerRight,
    target: Size(40, 860),
    position: null,
    expected: TooltipPosition.left,
    others: Alignment(-0.8, 0.9),
    outside: false,
  ),
  // Outside buttons keep the tooltip above or below, and follow it there.
  (
    name: 'top at the top edge goes below, with the buttons outside',
    alignment: Alignment.topCenter,
    target: Size(120, 48),
    position: TooltipPosition.top,
    expected: TooltipPosition.bottom,
    others: Alignment(0, 0.5),
    outside: true,
  ),
  (
    name: 'bottom at the bottom edge goes above, with the buttons outside',
    alignment: Alignment.bottomCenter,
    target: Size(120, 48),
    position: TooltipPosition.bottom,
    expected: TooltipPosition.top,
    others: Alignment(0, -0.5),
    outside: true,
  ),
];

Matcher _contains(Rect inner) => predicate<Rect>(
  (outer) =>
      inner.left >= outer.left - 0.01 &&
      inner.top >= outer.top - 0.01 &&
      inner.right <= outer.right + 0.01 &&
      inner.bottom <= outer.bottom + 0.01,
  'contains $inner',
);
