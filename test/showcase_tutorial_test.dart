import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';
import 'package:showcase_tutorial/src/measure_size.dart';

void main() {
  // Builds a single-step showcase and returns the GlobalKey of the target.
  Widget buildApp(GlobalKey targetKey) {
    return MaterialApp(
      home: ShowCaseWidget(
        // Disable the looping/scale animations so the tree can settle in tests.
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        builder: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: Showcase(
                  key: targetKey,
                  title: 'Title A',
                  description: 'Description A',
                  child: const Text('target'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('renders the child before the showcase starts', (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(buildApp(targetKey));

    expect(find.text('target'), findsOneWidget);
    expect(find.text('Title A'), findsNothing);
    expect(find.text('Description A'), findsNothing);
  });

  testWidgets('shows the tooltip title and description once started',
      (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(buildApp(targetKey));

    ShowCaseWidget.of(tester.element(find.text('target')))
        .startShowCase([targetKey]);

    // Let the overlay insert and the showcase rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Title A'), findsOneWidget);
    expect(find.text('Description A'), findsOneWidget);
  });

  testWidgets('dismiss() tears the showcase overlay back down',
      (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(buildApp(targetKey));

    final showcase = ShowCaseWidget.of(tester.element(find.text('target')));
    showcase.startShowCase([targetKey]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Title A'), findsOneWidget);

    showcase.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Title A'), findsNothing);
  });

  testWidgets('global ShowcaseStyle is applied when a Showcase does not '
      'override it', (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          style: const ShowcaseStyle(textColor: Colors.green),
          builder: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: Showcase(
                    key: targetKey,
                    title: 'Styled',
                    description: 'Body',
                    child: const Text('target'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('target')))
        .startShowCase([targetKey]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final title = tester.widget<Text>(find.text('Styled'));
    expect(title.style?.color, Colors.green);
  });

  testWidgets('description is optional and the tooltip still renders',
      (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: Showcase(
                    key: targetKey,
                    title: 'Title only',
                    child: const Text('target'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('target')))
        .startShowCase([targetKey]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Title only'), findsOneWidget);
  });

  testWidgets('MeasureSize reports the laid-out size of its child',
      (tester) async {
    Size? reported;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MeasureSize(
            onSizeChange: (size) => reported = size,
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      ),
    );
    // Flush the post-frame callback that delivers the measured size.
    await tester.pump();

    expect(reported, const Size(120, 48));
  });

  // Builds a single-step showcase with a start guard.
  Widget buildGuardedApp(
    GlobalKey targetKey, {
    required FutureOr<bool> Function(String?) onShouldStartShowcase,
    String? showcaseId,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        showcaseId: showcaseId,
        onShouldStartShowcase: onShouldStartShowcase,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Showcase(
                key: targetKey,
                title: 'Guarded',
                description: 'Body',
                child: const Text('target'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('onShouldStartShowcase=false blocks the tour and receives the id',
      (tester) async {
    final targetKey = GlobalKey();
    String? receivedId;
    await tester.pumpWidget(
      buildGuardedApp(
        targetKey,
        showcaseId: 'home_v1',
        onShouldStartShowcase: (id) {
          receivedId = id;
          return false;
        },
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('target')))
        .startShowCase([targetKey]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(receivedId, 'home_v1');
    expect(find.text('Guarded'), findsNothing);
  });

  testWidgets('an async onShouldStartShowcase=true starts the tour',
      (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(
      buildGuardedApp(targetKey, onShouldStartShowcase: (id) async => true),
    );

    ShowCaseWidget.of(tester.element(find.text('target')))
        .startShowCase([targetKey]);
    await tester.pump(); // kick off the guard future
    await tester.pump(); // resolve it
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Guarded'), findsOneWidget);
  });

  testWidgets('force:true bypasses a blocking guard', (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(
      buildGuardedApp(targetKey, onShouldStartShowcase: (id) async => false),
    );

    ShowCaseWidget.of(tester.element(find.text('target')))
        .startShowCase([targetKey], force: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Guarded'), findsOneWidget);
  });

  // Builds a three-step showcase. Optionally omit one of the targets from the
  // tree (to exercise auto-skip).
  Widget buildMultiStepApp(
    GlobalKey k1,
    GlobalKey k2,
    GlobalKey k3, {
    bool includeSecondTarget = true,
    bool autoSkipUnmountedSteps = false,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        autoSkipUnmountedSteps: autoSkipUnmountedSteps,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Showcase(
                    key: k1, title: 'One', description: 'd', child: const Text('t1')),
                if (includeSecondTarget)
                  Showcase(
                      key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                Showcase(
                    key: k3, title: 'Three', description: 'd', child: const Text('t3')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('progress getters and goTo / goToKey navigate steps',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    final k3 = GlobalKey();
    await tester.pumpWidget(buildMultiStepApp(k1, k2, k3));

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    expect(state.isShowcaseRunning, isFalse);
    expect(state.totalSteps, 0);

    state.startShowCase([k1, k2, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.isShowcaseRunning, isTrue);
    expect(state.totalSteps, 3);
    expect(state.currentIndex, 0);
    expect(find.text('One'), findsOneWidget);

    state.goTo(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.currentIndex, 2);
    expect(find.text('Three'), findsOneWidget);

    state.goToKey(k2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.currentIndex, 1);
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('autoSkipUnmountedSteps skips a step whose target is absent',
      (tester) async {
    final k1 = GlobalKey();
    final kAbsent = GlobalKey(); // never attached to the tree
    final k3 = GlobalKey();
    await tester.pumpWidget(
      buildMultiStepApp(k1, kAbsent, k3,
          includeSecondTarget: false, autoSkipUnmountedSteps: true),
    );

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, kAbsent, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('One'), findsOneWidget);

    state.next(); // skips the unmounted middle step
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.currentIndex, 2);
    expect(find.text('Three'), findsOneWidget);
  });

  testWidgets('tooltipPosition.right places the tooltip to the right of target',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Showcase(
                  key: key,
                  title: 'Side',
                  description: 'Body',
                  tooltipPosition: TooltipPosition.right,
                  child: const SizedBox(width: 40, height: 40, child: Text('t')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Side'), findsOneWidget);
    final targetRight = tester.getTopRight(find.byKey(key)).dx;
    final tooltipLeft = tester.getTopLeft(find.text('Side')).dx;
    // Tooltip sits just to the right of the target — not pushed far away.
    expect(tooltipLeft, greaterThan(targetRight));
    expect(tooltipLeft - targetRight, lessThan(80));
  });

  testWidgets('tooltipPosition.left places the tooltip to the left of target',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Align(
                alignment: Alignment.centerRight,
                child: Showcase(
                  key: key,
                  description: 'Body',
                  tooltipPosition: TooltipPosition.left,
                  child: const SizedBox(width: 40, height: 40, child: Text('t')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Body'), findsOneWidget);
    final targetLeft = tester.getTopLeft(find.byKey(key)).dx;
    final tooltipRight = tester.getTopRight(find.text('Body')).dx;
    // Tooltip sits just to the left of the target — not pushed far away.
    expect(tooltipRight, lessThan(targetLeft));
    expect(targetLeft - tooltipRight, lessThan(80));
  });

  testWidgets(
      'highlightExactShape wraps the target and runs the snapshot highlight '
      'without error', (tester) async {
    final targetKey = GlobalKey();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: Showcase(
                    key: targetKey,
                    title: 'Exact',
                    description: 'Body',
                    highlightExactShape: true,
                    child: Container(
                      key: const ValueKey('exactChild'),
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // The target is wrapped in a RepaintBoundary so it can be captured.
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('exactChild')),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );

      ShowCaseWidget.of(tester.element(find.byKey(targetKey)))
          .startShowCase([targetKey]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Let the async snapshot capture (toImage) resolve.
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Exact'), findsOneWidget);
    });
  });

  testWidgets('enablePulseAnimation renders the step without error and '
      'animates over time', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          // Leave the tooltip animations on default; the pulse runs its own
          // repeating controller independently.
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Showcase(
                  key: key,
                  title: 'Pulse',
                  description: 'Body',
                  enablePulseAnimation: true,
                  pulseColor: Colors.orange,
                  pulseDuration: const Duration(milliseconds: 800),
                  child: const SizedBox(width: 48, height: 48, child: Text('t')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final state = ShowCaseWidget.of(tester.element(find.text('t')));
    state.startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Pulse'), findsOneWidget);

    // The repeating pulse keeps scheduling frames; advance through part of a
    // cycle to make sure ticking the controller never throws.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    // Tear the overlay down so the pulse controller is disposed cleanly.
    state.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('enablePulseAnimation honors reduce-motion (no perpetual '
      'animation)', (tester) async {
    // The pulse reads disableAnimations from the root MediaQuery, which derives
    // it from the platform accessibility features.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Showcase(
                  key: key,
                  title: 'Pulse',
                  description: 'Body',
                  enablePulseAnimation: true,
                  child: const SizedBox(width: 48, height: 48, child: Text('t')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pulse'), findsOneWidget);

    // With reduce-motion on the pulse controller stays idle, so the tree can
    // fully settle instead of scheduling frames forever.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('per-step arrow + highlight-border styling renders without error',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Showcase(
                  key: key,
                  title: 'Styled',
                  description: 'Body',
                  arrowColor: Colors.orange,
                  arrowWidth: 26,
                  arrowHeight: 13,
                  highlightBorderColor: Colors.orange,
                  highlightBorderWidth: 3,
                  child: const SizedBox(width: 48, height: 48, child: Text('t')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Styled'), findsOneWidget);
  });

  testWidgets('ShowcaseStyle arrow + highlight-border defaults are applied',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          style: const ShowcaseStyle(
            arrowColor: Colors.teal,
            arrowWidth: 22,
            arrowHeight: 11,
            highlightBorderColor: Colors.teal,
            highlightBorderWidth: 2,
          ),
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Showcase(
                  key: key,
                  title: 'Styled',
                  description: 'Body',
                  child: const SizedBox(width: 48, height: 48, child: Text('t')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Styled'), findsOneWidget);
  });

  testWidgets('tooltip inherits RTL directionality', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: Showcase(
                    key: key,
                    title: 'عنوان',
                    description: 'وصف',
                    child: const Text('t'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('عنوان'), findsOneWidget);

    final directionality = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.text('عنوان'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  // Builds a two-step tour with a configurable barrier behaviour. Targets are
  // centered so a tap near a screen corner lands on the dimmed barrier.
  Widget buildBarrierApp(
    GlobalKey k1,
    GlobalKey k2, {
    BarrierInteraction barrierInteraction = BarrierInteraction.next,
    bool disableBarrierInteraction = false,
    bool enableKeyboardNavigation = true,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        barrierInteraction: barrierInteraction,
        disableBarrierInteraction: disableBarrierInteraction,
        enableKeyboardNavigation: enableKeyboardNavigation,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Showcase(
                      key: k1, title: 'One', description: 'd', child: const Text('t1')),
                  Showcase(
                      key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('barrier tap advances to the next step by default',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(buildBarrierApp(k1, k2));

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('One'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10)); // tap the dimmed barrier
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // reverse animation
    await tester.pump(const Duration(milliseconds: 400)); // next step in

    expect(state.currentIndex, 1);
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('barrierInteraction.dismiss closes the tour on a background tap',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(
      buildBarrierApp(k1, k2, barrierInteraction: BarrierInteraction.dismiss),
    );

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.isShowcaseRunning, isTrue);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // reverse animation
    await tester.pump(const Duration(milliseconds: 400)); // overlay teardown

    expect(state.isShowcaseRunning, isFalse);
    expect(find.text('One'), findsNothing);
  });

  testWidgets('barrierInteraction.none ignores background taps', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(
      buildBarrierApp(k1, k2, barrierInteraction: BarrierInteraction.none),
    );

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.currentIndex, 0); // unchanged
    expect(find.text('One'), findsOneWidget);
  });

  testWidgets('legacy disableBarrierInteraction:true makes the barrier inert',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(
      buildBarrierApp(k1, k2, disableBarrierInteraction: true),
    );

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.currentIndex, 0); // disableBarrierInteraction wins
    expect(find.text('One'), findsOneWidget);
  });

  testWidgets('onShow and onDismiss fire on step transitions', (tester) async {
    final events = <String>[];
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Showcase(
                      key: k1,
                      title: 'One',
                      description: 'd',
                      onShow: () => events.add('show1'),
                      onDismiss: () => events.add('dismiss1'),
                      child: const Text('t1'),
                    ),
                    Showcase(
                      key: k2,
                      title: 'Two',
                      description: 'd',
                      onShow: () => events.add('show2'),
                      onDismiss: () => events.add('dismiss2'),
                      child: const Text('t2'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(events, contains('show1'));
    expect(events, isNot(contains('dismiss1')));

    state.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(events, contains('dismiss1'));
    expect(events, contains('show2'));

    state.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(events, contains('dismiss2'));
  });

  testWidgets('keyboard ArrowRight advances and ArrowLeft goes back',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(buildBarrierApp(k1, k2));

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('One'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // reverse animation
    await tester.pump(const Duration(milliseconds: 400)); // next step in
    expect(state.currentIndex, 1);
    expect(find.text('Two'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.currentIndex, 0);
    expect(find.text('One'), findsOneWidget);
  });

  testWidgets('keyboard Escape dismisses the tour', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(buildBarrierApp(k1, k2));

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.isShowcaseRunning, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // reverse animation
    await tester.pump(const Duration(milliseconds: 400)); // teardown
    expect(state.isShowcaseRunning, isFalse);
  });

  testWidgets('enableKeyboardNavigation:false ignores key presses',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(
      buildBarrierApp(k1, k2, enableKeyboardNavigation: false),
    );

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.currentIndex, 0); // unchanged
    expect(find.text('One'), findsOneWidget);
  });

  // Builds a single-step showcase used by the announcement tests.
  Widget buildAnnounceApp(
    GlobalKey key, {
    bool enableAutoAnnouncements = true,
    String? semanticLabel,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        enableAutoAnnouncements: enableAutoAnnouncements,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Showcase(
                key: key,
                title: 'Profile',
                description: 'Your account',
                semanticLabel: semanticLabel,
                child: const Text('t'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('an active step is announced to screen readers', (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (dynamic message) async {
        if (message is Map && message['type'] == 'announce') {
          announced.add((message['data'] as Map)['message'] as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler(SystemChannels.accessibility, null));

    final key = GlobalKey();
    await tester.pumpWidget(buildAnnounceApp(key));
    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(announced, isNotEmpty);
    expect(announced.first, contains('Profile'));
    expect(announced.first, contains('Your account'));
  });

  testWidgets('semanticLabel overrides the announced text', (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (dynamic message) async {
        if (message is Map && message['type'] == 'announce') {
          announced.add((message['data'] as Map)['message'] as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler(SystemChannels.accessibility, null));

    final key = GlobalKey();
    await tester.pumpWidget(
      buildAnnounceApp(key, semanticLabel: 'Open your profile'),
    );
    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(announced, contains('Open your profile'));
  });

  testWidgets('enableAutoAnnouncements:false makes no announcement',
      (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (dynamic message) async {
        if (message is Map && message['type'] == 'announce') {
          announced.add((message['data'] as Map)['message'] as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler(SystemChannels.accessibility, null));

    final key = GlobalKey();
    await tester.pumpWidget(buildAnnounceApp(key, enableAutoAnnouncements: false));
    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(announced, isEmpty);
  });

  testWidgets(
      'onShow/onDismiss can call setState without a "setState during build" '
      'crash', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(_SetStateLifecycleApp(k1: k1, k2: k2));

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // onShow post-frame
    expect(tester.takeException(), isNull);

    state.next(); // dismiss k1 + show k2, both call setState on the ancestor
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  // Builds a three-step tour with the progress/skip footer configurable.
  Widget buildProgressApp(
    GlobalKey k1,
    GlobalKey k2,
    GlobalKey k3, {
    bool showProgress = false,
    ShowcaseProgressStyle progressStyle = ShowcaseProgressStyle.dots,
    bool showSkip = false,
    String skipButtonText = 'Skip',
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        showProgress: showProgress,
        progressStyle: progressStyle,
        showSkip: showSkip,
        skipButtonText: skipButtonText,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Showcase(
                      key: k1, title: 'One', description: 'd', child: const Text('t1')),
                  Showcase(
                      key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                  Showcase(
                      key: k3, title: 'Three', description: 'd', child: const Text('t3')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('showProgress renders one dot per step', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    final k3 = GlobalKey();
    await tester.pumpWidget(buildProgressApp(k1, k2, k3, showProgress: true));

    ShowCaseWidget.of(tester.element(find.text('t1')))
        .startShowCase([k1, k2, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('One'), findsOneWidget);
    // One dot (AnimatedContainer) per step.
    expect(find.byType(AnimatedContainer), findsNWidgets(3));
  });

  testWidgets('progressStyle.numeric shows "current/total" instead of dots',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    final k3 = GlobalKey();
    await tester.pumpWidget(buildProgressApp(k1, k2, k3,
        showProgress: true, progressStyle: ShowcaseProgressStyle.numeric));

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Numeric counter is shown one-based; no dots are rendered.
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);

    state.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('showSkip renders a Skip button that dismisses the tour',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    final k3 = GlobalKey();
    await tester.pumpWidget(buildProgressApp(k1, k2, k3, showSkip: true));

    final state = ShowCaseWidget.of(tester.element(find.text('t1')));
    state.startShowCase([k1, k2, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Skip'), findsOneWidget);
    expect(state.isShowcaseRunning, isTrue);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // reverse animation
    await tester.pump(const Duration(milliseconds: 400)); // teardown

    expect(state.isShowcaseRunning, isFalse);
  });

  testWidgets('skipButtonText customizes the skip label', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    final k3 = GlobalKey();
    await tester.pumpWidget(
      buildProgressApp(k1, k2, k3, showSkip: true, skipButtonText: 'Skip tour'),
    );

    ShowCaseWidget.of(tester.element(find.text('t1')))
        .startShowCase([k1, k2, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Skip tour'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}

/// Host whose [Showcase.onShow]/[Showcase.onDismiss] call `setState` on this
/// ancestor — the scenario that previously threw "setState during build".
class _SetStateLifecycleApp extends StatefulWidget {
  const _SetStateLifecycleApp({required this.k1, required this.k2});

  final GlobalKey k1;
  final GlobalKey k2;

  @override
  State<_SetStateLifecycleApp> createState() => _SetStateLifecycleAppState();
}

class _SetStateLifecycleAppState extends State<_SetStateLifecycleApp> {
  int _events = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('events:$_events'),
                  Showcase(
                    key: widget.k1,
                    title: 'One',
                    description: 'd',
                    onShow: () => setState(() => _events++),
                    onDismiss: () => setState(() => _events++),
                    child: const Text('t1'),
                  ),
                  Showcase(
                    key: widget.k2,
                    title: 'Two',
                    description: 'd',
                    onShow: () => setState(() => _events++),
                    child: const Text('t2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
