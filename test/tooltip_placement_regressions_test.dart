import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

// Regressions an independent review found in the placement changes, and the
// guarantees that came with their fixes: a tooltip that fits never moves, a
// custom container with a declared height stays on the side asked for, and a
// tooltip that moves lands with all of its buttons on screen.

const _long =
    'A much longer description that is far too wide for one line, so the tooltip is capped at the screen width';

void _useScreen(WidgetTester tester, Size size, {double keyboard = 0}) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  if (keyboard > 0) tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
  addTearDown(tester.view.reset);
}

Future<void> _showOne(WidgetTester tester, Widget Function(GlobalKey key) step, {bool insideActions = false}) async {
  final key = GlobalKey();
  late BuildContext pageContext;
  await tester.pumpWidget(
    MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        actionsPosition: insideActions ? TooltipActionPosition.inside : TooltipActionPosition.outside,
        globalActions: insideActions ? (_) => const ShowCaseDefaultActions() : null,
        builder: Builder(
          builder: (context) {
            pageContext = context;
            return Scaffold(body: Stack(children: [step(key)]));
          },
        ),
      ),
    ),
  );
  ShowCaseWidget.of(pageContext).startShowCase([key]);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Rect _box(WidgetTester tester, String title) =>
    tester.getRect(find.ancestor(of: find.text(title), matching: find.byType(ClipRRect)).first);

void main() {
  testWidgets('a description that ellipsizes keeps a requested top it fits on', (tester) async {
    // On one line, the tooltip fits above. Laid out wrapped, as the fit check
    // once did, it seemed too tall and moved below.
    _useScreen(tester, const Size(412, 915));
    await _showOne(
      tester,
      (key) => Positioned(
        left: 146,
        top: 110,
        child: Showcase(
          key: key,
          title: 'Title',
          description: _long,
          descTextStyle: const TextStyle(overflow: TextOverflow.ellipsis),
          tooltipPosition: TooltipPosition.top,
          child: const SizedBox(width: 120, height: 48, child: Text('target')),
        ),
      ),
    );
    expect(_box(tester, 'Title').bottom, lessThanOrEqualTo(tester.getRect(find.text('target')).top));
  });

  testWidgets('Showcase.withWidget with a declared height keeps its requested side', (tester) async {
    // Declared 300px tall, it would not fit above, but its real 100px does,
    // and a requested side has always been honoured whatever the height.
    _useScreen(tester, const Size(412, 915));
    await _showOne(
      tester,
      (key) => Positioned(
        left: 146,
        top: 130,
        child: Showcase.withWidget(
          key: key,
          width: 200,
          height: 300,
          tooltipPosition: TooltipPosition.top,
          container: const SizedBox(key: ValueKey('c'), width: 200, height: 100),
          child: const SizedBox(width: 120, height: 48, child: Text('target')),
        ),
      ),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('c'))).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('target')).top),
    );
  });

  testWidgets('a tooltip whose buttons would not fit on the other side stays where it was', (tester) async {
    // Below, the box fits but its button row would not: Next would land at
    // 470..490 on a 480px screen. Above, as before, Next is on screen.
    _useScreen(tester, const Size(320, 480));
    await _showOne(
      tester,
      (key) => Positioned(
        left: 100,
        top: 200,
        child: Showcase(
          key: key,
          title: 'Title',
          description: _long,
          tooltipPosition: TooltipPosition.top,
          child: const SizedBox(width: 120, height: 48, child: Text('target')),
        ),
      ),
      insideActions: true,
    );
    expect(tester.getRect(find.text('Next')).bottom, lessThanOrEqualTo(480));
    expect(tester.getRect(find.text('Next')).bottom, lessThanOrEqualTo(tester.getRect(find.text('target')).top));
  });

  group('a tooltip that moves has all of it on screen, and tappable', () {
    // Each case moves the first step's tooltip to the other side. With the
    // animations on, every part of it stays on the visible screen through a
    // whole bob, and its body and buttons respond.
    final cases = <({String name, Size screen, double textScale, double keyboard, Alignment alignment, bool top})>[
      (
        name: 'small screen, top to bottom',
        screen: const Size(320, 480),
        textScale: 1,
        keyboard: 0,
        alignment: Alignment.topCenter,
        top: true,
      ),
      (
        name: 'small screen, bottom to top',
        screen: const Size(320, 480),
        textScale: 1,
        keyboard: 0,
        alignment: Alignment.bottomCenter,
        top: false,
      ),
      (
        name: 'text scale 2, top to bottom',
        screen: const Size(412, 915),
        textScale: 2,
        keyboard: 0,
        alignment: Alignment.topCenter,
        top: true,
      ),
      (
        name: 'text scale 2, bottom to top',
        screen: const Size(412, 915),
        textScale: 2,
        keyboard: 0,
        alignment: Alignment.bottomCenter,
        top: false,
      ),
      (
        // The target sits just above the keyboard, so below it would be
        // under the keyboard although on the screen.
        name: 'keyboard open, bottom to top',
        screen: const Size(412, 915),
        textScale: 1,
        keyboard: 300,
        alignment: Alignment.bottomCenter,
        top: false,
      ),
    ];
    for (final c in cases) {
      for (final inside in [true, false]) {
        testWidgets('${c.name}, buttons ${inside ? 'inside' : 'outside'}', (tester) async {
          _useScreen(tester, c.screen, keyboard: c.keyboard);
          final previousWarning = WidgetController.hitTestWarningShouldBeFatal;
          WidgetController.hitTestWarningShouldBeFatal = true;
          addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previousWarning);
          final visible = Offset.zero & Size(c.screen.width, c.screen.height - c.keyboard);

          final keys = [GlobalKey(), GlobalKey()];
          var bodyTaps = 0;
          var finished = false;
          late BuildContext pageContext;
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.textScale)),
                child: child!,
              ),
              home: ShowCaseWidget(
                actionsPosition: inside ? TooltipActionPosition.inside : TooltipActionPosition.outside,
                globalActions: (_) => const ShowCaseDefaultActions(),
                onFinish: () => finished = true,
                builder: Builder(
                  builder: (context) {
                    pageContext = context;
                    return Scaffold(
                      body: Stack(
                        children: [
                          Align(
                            alignment: c.alignment,
                            child: Showcase(
                              key: keys[0],
                              title: 'Moved',
                              description: 'Tap here',
                              tooltipPosition: c.top ? TooltipPosition.top : TooltipPosition.bottom,
                              onToolTipClick: () => bodyTaps++,
                              child: const SizedBox(width: 120, height: 48, child: Text('target 0')),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Showcase(
                              key: keys[1],
                              title: 'Second',
                              description: 'The next step',
                              child: const SizedBox(width: 40, height: 40, child: Text('target 1')),
                            ),
                          ),
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

          ShowCaseWidget.of(pageContext).startShowCase(keys);
          await settle();
          final target = tester.getRect(find.text('target 0'));
          final box = _box(tester, 'Moved');
          if (c.top) {
            expect(box.top, greaterThan(target.bottom), reason: 'top gave way to bottom');
          } else {
            expect(box.bottom, lessThan(target.top), reason: 'bottom gave way to top');
          }

          // A whole bob of the moving animation (2s each way).
          for (var i = 0; i < 40; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            for (final part in [
              _box(tester, 'Moved'),
              tester.getRect(find.text('Previous')),
              tester.getRect(find.text('Stop')),
              tester.getRect(find.text('Next')),
            ]) {
              expect(visible, _contains(part), reason: 'frame $i');
            }
          }

          await tester.tap(find.text('Tap here'));
          await settle();
          expect(bodyTaps, 1);
          expect(find.text('Moved'), findsOneWidget, reason: 'a tap on the tooltip does not move the tour');

          await tester.tap(find.text('Next'));
          await settle();
          expect(find.text('Second'), findsOneWidget, reason: 'Next went forward one step');
          await tester.tap(find.text('Previous'));
          await settle();
          expect(find.text('Moved'), findsOneWidget, reason: 'Previous came back');
          expect(finished, isFalse);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

Matcher _contains(Rect inner) => predicate<Rect>(
  (outer) =>
      inner.left >= outer.left - 0.01 &&
      inner.top >= outer.top - 0.01 &&
      inner.right <= outer.right + 0.01 &&
      inner.bottom <= outer.bottom + 0.01,
  'contains $inner',
);
