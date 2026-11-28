import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';
import 'package:showcase_tutorial/src/shape_clipper.dart';

void main() {
  late List<GlobalKey> keys;
  late BuildContext tourContext;
  late List<String> log;
  late Map<int, Completer<void>> waits;
  late int pageTaps;

  setUp(() {
    keys = List.generate(3, (_) => GlobalKey());
    log = [];
    waits = {};
    pageTaps = 0;
  });

  // Sizes the test screen like a phone.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  // Makes a tap that would fall through to something else fail the test.
  void failOnMissedTaps() {
    final previousWarning = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previousWarning);
  }

  // The tooltip animates forever, so frames are pumped instead of settling.
  Future<void> pumpFrames(WidgetTester tester, [int count = 6]) async {
    await tester.pump();
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // The active step's dimmed background.
  final barrier = find.byWidgetPredicate((w) => w is ClipPath && w.clipper is RRectClipper);

  // Which step's tooltip is on screen, or -1 for none.
  int shownStep() {
    for (var i = 0; i < keys.length; i++) {
      if (find.text('Step $i').evaluate().isNotEmpty) return i;
    }
    return -1;
  }

  // A hook that logs its calls and waits on a completer per step.
  Future<void> waitingHook(int index, GlobalKey key) {
    log.add('before $index');
    return (waits[index] = Completer<void>()).future;
  }

  ShowCaseWidgetState controller() => ShowCaseWidget.of(tourContext);

  Widget page() {
    return Scaffold(
      body: Builder(
        builder: (context) {
          tourContext = context;
          return Column(
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                Showcase(key: keys[i], title: 'Step $i', description: 'd', child: Text('target $i')),
                const SizedBox(height: 120),
              ],
              // Something to tap that is not part of the tour.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => pageTaps++,
                child: const SizedBox(width: 400, height: 300, child: Text('page area')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget app({
    ShowcaseBeforeStepCallback? onBeforeStep,
    bool autoPlay = false,
    bool autoSkipUnmountedSteps = false,
    bool enableStepTransition = false,
    bool enableShowcase = true,
    BarrierInteraction barrierInteraction = BarrierInteraction.next,
    GlobalKey? Function(int, GlobalKey)? onResolveNextStep,
    FutureOr<bool> Function(String?)? onShouldStartShowcase,
    Widget? child,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        onBeforeStep: onBeforeStep,
        autoPlay: autoPlay,
        autoPlayDelay: const Duration(seconds: 1),
        autoSkipUnmountedSteps: autoSkipUnmountedSteps,
        enableStepTransition: enableStepTransition,
        enableShowcase: enableShowcase,
        barrierInteraction: barrierInteraction,
        onResolveNextStep: onResolveNextStep,
        onShouldStartShowcase: onShouldStartShowcase,
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        onStart: (index, key) => log.add('start $index'),
        onComplete: (index, key) => log.add('complete $index'),
        onFinish: () => log.add('finish'),
        onDismiss: (key) => log.add('dismiss ${key == null ? null : keys.indexOf(key)}'),
        builder: child ?? page(),
      ),
    );
  }

  group('onBeforeStep: when it runs', () {
    testWidgets('before onStart of every step, after onComplete of the step left', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      expect(log, ['before 0']);
      expect(shownStep(), -1, reason: 'the first step waits for its callback');

      waits[0]!.complete();
      await pumpFrames(tester);
      expect(log, ['before 0', 'start 0']);
      expect(shownStep(), 0);

      controller().next();
      await pumpFrames(tester);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1']);
      waits[1]!.complete();
      await pumpFrames(tester);
      expect(log.last, 'start 1');
      expect(shownStep(), 1);

      controller().previous();
      await pumpFrames(tester);
      expect(log.sublist(log.length - 2), ['complete 1', 'before 0']);
      waits[0]!.complete();
      await pumpFrames(tester);
      expect(log.last, 'start 0');

      controller().goTo(2);
      await pumpFrames(tester);
      expect(log.sublist(log.length - 2), ['complete 0', 'before 2']);
      waits[2]!.complete();
      await pumpFrames(tester);
      expect(log.last, 'start 2');

      // Moving past the last step finishes the tour without a callback.
      log.clear();
      controller().next();
      await pumpFrames(tester);
      expect(log, ['complete 2', 'finish']);
    });

    testWidgets('after the start guard and its delay; not at all when the guard says no', (tester) async {
      usePhone(tester);
      var allow = false;
      await tester.pumpWidget(
        app(
          onBeforeStep: waitingHook,
          onShouldStartShowcase: (_) {
            log.add('guard');
            return allow;
          },
        ),
      );
      controller().startShowCase(keys, delay: const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(log, isEmpty, reason: 'nothing before the delay ends');
      await tester.pump(const Duration(milliseconds: 600));
      expect(log, ['guard'], reason: 'a tour the guard turns down never asks');

      allow = true;
      controller().startShowCase(keys, delay: const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(log, ['guard', 'guard', 'before 0']);
    });

    testWidgets('gets the startAt step, the branch target and the step after skipped ones', (tester) async {
      usePhone(tester);
      final missing = GlobalKey();
      final calls = <int>[];
      await tester.pumpWidget(
        app(
          onBeforeStep: (index, key) => calls.add(index),
          autoSkipUnmountedSteps: true,
          onResolveNextStep: (index, key) => index == 1 ? keys[0] : null,
        ),
      );
      // [missing] is skipped before the callback is asked about anything.
      controller().startShowCase([missing, keys[0], keys[1]], startAt: 0);
      await pumpFrames(tester);
      expect(calls, [1]);

      controller().startShowCase([keys[0], keys[1], keys[2]], startAt: 1);
      await pumpFrames(tester);
      expect(calls, [1, 1]);
      expect(shownStep(), 1);

      // onResolveNextStep branches from step 1 back to step 0.
      controller().next();
      await pumpFrames(tester);
      expect(calls, [1, 1, 0]);
      expect(shownStep(), 0);
    });

    testWidgets('can open the page of a step that is not on screen yet', (tester) async {
      usePhone(tester);
      final navigator = GlobalKey<NavigatorState>();
      final home = GlobalKey();
      final details = GlobalKey();
      late BuildContext homeContext;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            onStart: (index, key) => log.add('start $index'),
            onBeforeStep: (index, key) async {
              if (key != details) return;
              unawaited(
                navigator.currentState!.push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: Showcase(key: details, title: 'Details', description: 'd', child: const Text('details')),
                    ),
                  ),
                ),
              );
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            builder: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                homeContext = context;
                return Showcase(key: home, title: 'Home', description: 'd', child: const Text('home'));
              },
            ),
          ),
        ),
      );
      ShowCaseWidget.of(homeContext).startShowCase([home, details]);
      await pumpFrames(tester);
      expect(find.text('Home'), findsOneWidget);

      ShowCaseWidget.of(homeContext).next();
      await pumpFrames(tester, 10);
      expect(find.text('Details'), findsOneWidget);
      expect(log, ['start 0', 'start 1']);
    });
  });

  group('onBeforeStep: while the tour waits', () {
    testWidgets('nothing is shown, and the app takes taps', (tester) async {
      usePhone(tester);
      failOnMissedTaps();
      await tester.pumpWidget(app(onBeforeStep: (index, key) => index == 1 ? waitingHook(index, key) : null));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      expect(shownStep(), 0);

      controller().next();
      await pumpFrames(tester);
      expect(shownStep(), -1);
      expect(barrier, findsNothing, reason: 'no dimmed background while waiting');
      expect(controller().isShowcaseRunning, isTrue);
      expect(controller().isPreparingStep, isTrue);
      expect(controller().currentIndex, 1);
      expect(ShowCaseWidget.activeTargetWidget(tourContext), isNull);

      await tester.tap(find.text('page area'));
      await pumpFrames(tester);
      expect(pageTaps, 1);
      expect(controller().currentIndex, 1);

      waits[1]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 1);
      expect(controller().isPreparingStep, isFalse);
    });

    testWidgets('a second tap on the background does not advance the tour twice', (tester) async {
      usePhone(tester);
      failOnMissedTaps();
      await tester.pumpWidget(app(onBeforeStep: (index, key) => index == 0 ? null : waitingHook(index, key)));
      controller().startShowCase(keys);
      await pumpFrames(tester);

      // Both taps land while the step's tooltip closes.
      await tester.tapAt(const Offset(20, 850));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(20, 850));
      await pumpFrames(tester, 10);
      expect(log, ['start 0', 'complete 0', 'before 1']);

      waits[1]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 1);
      expect(log, ['start 0', 'complete 0', 'before 1', 'start 1']);
    });

    testWidgets('the back button is the app\'s while the tour waits', (tester) async {
      usePhone(tester);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => ShowCaseWidget(
            backButtonInteraction: BackButtonInteraction.block,
            onBeforeStep: (index, key) => index == 1 ? waitingHook(index, key) : null,
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: child!,
          ),
          home: const Scaffold(body: Text('home')),
        ),
      );
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => page()));
      await pumpFrames(tester);
      controller().startShowCase(keys);
      await pumpFrames(tester);
      await tester.binding.handlePopRoute();
      await pumpFrames(tester);
      expect(navigator.currentState!.canPop(), isTrue, reason: 'a showing step blocks back');

      controller().next();
      await pumpFrames(tester);
      await tester.binding.handlePopRoute();
      await pumpFrames(tester);
      expect(navigator.currentState!.canPop(), isFalse, reason: 'with no step showing, back closes the page');
    });
  });

  group('onBeforeStep: the tour moves while it waits', () {
    testWidgets('next() moves on from the step being prepared, which never starts', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      waits[0]!.complete();
      await pumpFrames(tester);

      controller().next();
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'before 2']);
      expect(controller().currentIndex, 2);

      // The late completion shows nothing.
      waits[1]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), -1);
      expect(log.last, 'before 2');

      waits[2]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 2);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'before 2', 'start 2']);
    });

    testWidgets('completed() with the key of the step left is ignored', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: (index, key) => index == 0 ? null : waitingHook(index, key)));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().completed(keys[0]);
      controller().completed(keys[0]);
      await pumpFrames(tester);
      expect(log, ['start 0', 'complete 0', 'before 1']);

      // With the key of the step being prepared it moves on, like next().
      controller().completed(keys[1]);
      await pumpFrames(tester);
      expect(log, ['start 0', 'complete 0', 'before 1', 'before 2']);
    });

    testWidgets('previous() goes back from the step being prepared', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);

      // On the first step there is nowhere to go back to: the wait goes on.
      controller().previous();
      await pumpFrames(tester);
      expect(log, ['before 0']);
      waits[0]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 0);

      controller().next();
      await pumpFrames(tester);
      controller().previous();
      await pumpFrames(tester);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'before 0']);

      waits[1]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), -1, reason: 'the step given up does not show');
      waits[0]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 0);
      expect(log.where((e) => e == 'start 1'), isEmpty);
    });

    testWidgets('goTo() and goToKey() jump from the step being prepared', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().goTo(2);
      await pumpFrames(tester);
      controller().goToKey(keys[1]);
      await pumpFrames(tester);
      expect(log, ['before 0', 'before 2', 'before 1']);

      waits[0]!.complete();
      waits[2]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), -1);
      waits[1]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 1);
      expect(log, ['before 0', 'before 2', 'before 1', 'start 1']);
    });

    testWidgets('dismiss() ends the tour, with no step to report', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().dismiss();
      await pumpFrames(tester);
      expect(log, ['before 0', 'dismiss null']);
      expect(controller().isShowcaseRunning, isFalse);
      expect(controller().isPreparingStep, isFalse);

      waits[0]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), -1);
      expect(log, ['before 0', 'dismiss null']);
    });

    testWidgets('startShowCase() replaces the tour; the old step never shows', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      waits[0]!.complete();
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      final firstWait = waits[1]!;

      controller().startShowCase([keys[2], keys[1]]);
      await pumpFrames(tester);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'before 0']);
      expect(controller().totalSteps, 2);

      firstWait.complete();
      await pumpFrames(tester);
      expect(shownStep(), -1);
      waits[0]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 2, reason: "the new tour's first step");
      expect(log.where((e) => e.startsWith('start')), ['start 0', 'start 0']);
    });

    testWidgets('a delayed startShowCase() lets the waiting step show first', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: (index, key) => index == 1 ? waitingHook(index, key) : null));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await tester.pump();
      controller().startShowCase([keys[2]], delay: const Duration(seconds: 2));
      waits[1]!.complete();
      await pumpFrames(tester);
      expect(shownStep(), 1);

      await tester.pump(const Duration(seconds: 2));
      await pumpFrames(tester);
      expect(shownStep(), 2);
    });

    testWidgets('turning enableShowcase off ends the tour; the step never shows', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);

      await tester.pumpWidget(app(onBeforeStep: waitingHook, enableShowcase: false));
      waits[0]!.complete();
      await pumpFrames(tester);
      expect(log, ['before 0', 'dismiss null']);
      expect(controller().isShowcaseRunning, isFalse);

      // Turned back on, nothing comes back.
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      await pumpFrames(tester);
      expect(shownStep(), -1);
    });

    testWidgets('disposing the ShowCaseWidget drops the step', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: waitingHook));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      await tester.pumpWidget(const MaterialApp(home: Text('gone')));
      waits[0]!.complete();
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
      expect(log, ['before 0']);
    });

    testWidgets('the callback itself can skip its step with next()', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        app(
          onBeforeStep: (index, key) {
            log.add('before $index');
            if (index == 1) controller().next();
          },
        ),
      );
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(shownStep(), 2);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'before 2', 'start 2']);
    });

    testWidgets('an asynchronous callback can skip its step with next()', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        app(
          onBeforeStep: (index, key) async {
            log.add('before $index');
            await Future<void>.delayed(const Duration(milliseconds: 100));
            if (index == 1) controller().next();
          },
        ),
      );
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(shownStep(), 2);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'before 2', 'start 2']);
    });

    testWidgets('the callback can end the tour with dismiss()', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        app(
          onBeforeStep: (index, key) {
            log.add('before $index');
            if (index == 1) controller().dismiss();
          },
        ),
      );
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(shownStep(), -1);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'dismiss null']);
    });

    testWidgets('the callback can start another tour', (tester) async {
      usePhone(tester);
      var restarted = false;
      await tester.pumpWidget(
        app(
          onBeforeStep: (index, key) {
            log.add('before $index');
            if (index == 1 && !restarted) {
              restarted = true;
              controller().startShowCase([keys[2]]);
            }
          },
        ),
      );
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(shownStep(), 2);
      expect(controller().totalSteps, 1);
      expect(log, ['before 0', 'start 0', 'complete 0', 'before 1', 'before 0', 'start 0']);
    });

    testWidgets('an onComplete that ends the tour leaves nothing to prepare', (tester) async {
      usePhone(tester);
      final calls = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            onBeforeStep: (index, key) => calls.add(index),
            onComplete: (index, key) => controller().dismiss(),
            builder: page(),
          ),
        ),
      );
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
      expect(calls, [0]);
      expect(controller().isShowcaseRunning, isFalse);
      expect(shownStep(), -1);
    });
  });

  group('onBeforeStep: errors', () {
    testWidgets('a synchronous throw is reported and the step shows', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app(onBeforeStep: (index, key) => throw StateError('no data')));
      controller().startShowCase(keys);
      final error = tester.takeException();
      expect(error, isA<StateError>());
      await pumpFrames(tester);
      expect(shownStep(), 0);
      expect(log, ['start 0']);
    });

    testWidgets('a failed future is reported and the step shows', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        app(
          onBeforeStep: (index, key) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            throw StateError('no data');
          },
        ),
      );
      controller().startShowCase(keys);
      await pumpFrames(tester);
      expect(tester.takeException(), isA<StateError>());
      expect(shownStep(), 0);
      expect(log, ['start 0']);
    });
  });

  group('onBeforeStep: timing', () {
    // Frames from next() until the next step's tooltip is on screen.
    Future<int> framesToNextStep(WidgetTester tester) async {
      final target = shownStep() + 1;
      controller().next();
      for (var frame = 1; frame <= 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (shownStep() == target) return frame;
      }
      return -1;
    }

    testWidgets('a synchronous callback shows the step on the same frame as no callback', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app());
      controller().startShowCase(keys);
      await pumpFrames(tester);
      final without = await framesToNextStep(tester);

      final preparing = <bool>[];
      await tester.pumpWidget(app(onBeforeStep: (index, key) => preparing.add(controller().isPreparingStep)));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      final withSync = await framesToNextStep(tester);

      expect(without, 2);
      expect(withSync, without);
      expect(preparing, [true, true], reason: 'preparing while the callback runs');
      expect(controller().isPreparingStep, isFalse);
    });

    testWidgets('without a callback the tour is never preparing a step', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(app());
      controller().startShowCase(keys);
      expect(controller().isPreparingStep, isFalse);
      expect(controller().currentIndex, 0);
      expect(log, ['start 0'], reason: 'onStart runs within startShowCase, as before');
      controller().next();
      expect(controller().isPreparingStep, isFalse);
      expect(log, ['start 0', 'complete 0', 'start 1']);
    });

    testWidgets('auto-play counts from when the step shows, not while it waits', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        app(autoPlay: true, onBeforeStep: (index, key) => index == 1 ? waitingHook(index, key) : null),
      );
      controller().startShowCase(keys);
      await pumpFrames(tester);
      // Step 0 plays for its second, then the tour waits on step 1.
      await tester.pump(const Duration(seconds: 1));
      await pumpFrames(tester);
      expect(controller().currentIndex, 1);
      expect(shownStep(), -1);

      // However long the wait, nothing advances.
      await tester.pump(const Duration(seconds: 5));
      expect(controller().currentIndex, 1);

      waits[1]!.complete();
      await pumpFrames(tester, 3);
      expect(shownStep(), 1);
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller().currentIndex, 1, reason: 'its second has only just started');
      await tester.pump(const Duration(milliseconds: 600));
      await pumpFrames(tester, 3);
      expect(controller().currentIndex, 2);
    });

    testWidgets('with enableStepTransition, only a synchronous callback keeps the glide', (tester) async {
      usePhone(tester);
      final glideFrom = <Rect?>[];
      Widget transitionApp(ShowcaseBeforeStepCallback hook) => MaterialApp(
        home: ShowCaseWidget(
          enableStepTransition: true,
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          onBeforeStep: hook,
          onStart: (index, key) => glideFrom.add(controller().previousTargetRect),
          builder: page(),
        ),
      );

      await tester.pumpWidget(transitionApp((index, key) {}));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(glideFrom, [isNull, isNotNull], reason: 'glides from step 0 after a synchronous callback');

      glideFrom.clear();
      await tester.pumpWidget(transitionApp((index, key) => Future<void>.delayed(const Duration(milliseconds: 100))));
      controller().startShowCase(keys);
      await pumpFrames(tester);
      controller().next();
      await pumpFrames(tester);
      expect(glideFrom, [isNull, isNull], reason: 'appears without a glide after waiting');
    });
  });
}
