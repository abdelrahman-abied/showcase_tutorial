import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

// Where the tour's ShowCaseWidget sits.
enum _Placement {
  // On the page itself, below the Navigator: the usual place.
  onPage,
  // Above the Navigator, in MaterialApp.builder: a tour across screens.
  aboveNavigator,
}

void main() {
  late GlobalKey<NavigatorState> navigator;
  late GlobalKey first;
  late GlobalKey second;
  late BuildContext tourContext;
  late List<GlobalKey?> dismissedAt;
  late int finished;

  setUp(() {
    navigator = GlobalKey<NavigatorState>();
    first = GlobalKey();
    second = GlobalKey();
    dismissedAt = [];
    finished = 0;
  });

  // Sizes the test screen like a phone.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  // The tooltip animates forever, so frames are pumped instead of settling.
  // Long enough for a page transition and a tooltip's closing animation.
  Future<void> pumpFrames(WidgetTester tester, [int count = 8]) async {
    await tester.pump();
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  ShowCaseWidget tour(BackButtonInteraction? interaction, Widget child) {
    return ShowCaseWidget(
      backButtonInteraction: interaction ?? BackButtonInteraction.passThrough,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      onDismiss: dismissedAt.add,
      onFinish: () => finished++,
      builder: child,
    );
  }

  // The page with the tour's two steps.
  Widget stepsPage() {
    return Scaffold(
      body: Builder(
        builder: (context) {
          tourContext = context;
          return Column(
            children: [
              Showcase(key: first, title: 'First step', description: 'd', child: const Text('first target')),
              const SizedBox(height: 200),
              Showcase(key: second, title: 'Second step', description: 'd', child: const Text('second target')),
            ],
          );
        },
      ),
    );
  }

  // A home page, with the steps page pushed on top of it, so back has a page
  // to close. Pass `null` to leave backButtonInteraction at its default.
  Future<void> openStepsPage(
    WidgetTester tester,
    _Placement placement,
    BackButtonInteraction? interaction, {
    ThemeData? theme,
  }) async {
    usePhone(tester);
    final above = placement == _Placement.aboveNavigator;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: theme,
        builder: above ? (context, child) => tour(interaction, child!) : null,
        home: const Scaffold(body: Text('home page')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => above ? stepsPage() : tour(interaction, stepsPage())),
    );
    await pumpFrames(tester);
    expect(find.text('first target'), findsOneWidget);
  }

  ShowCaseWidgetState controller() => ShowCaseWidget.of(tourContext);

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await pumpFrames(tester);
  }

  bool stepsPageOpen() => navigator.currentState!.canPop();

  for (final placement in _Placement.values) {
    group('backButtonInteraction, ShowCaseWidget ${placement.name}', () {
      testWidgets('by default back closes the page, as without the option', (tester) async {
        await openStepsPage(tester, placement, null);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);
        expect(find.text('First step'), findsOneWidget);

        await pressBack(tester);
        expect(stepsPageOpen(), isFalse, reason: 'back closed the steps page');
        expect(find.text('First step'), findsNothing);
        expect(dismissedAt, isEmpty, reason: 'back is not a dismissal by default');
      });

      testWidgets('passThrough is the default', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.passThrough);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);

        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
        expect(dismissedAt, isEmpty);
      });

      testWidgets('dismiss: back ends the tour and the page stays; back again closes it', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.dismiss);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);
        expect(find.text('First step'), findsOneWidget);

        await pressBack(tester);
        expect(stepsPageOpen(), isTrue, reason: 'the page stays open');
        expect(find.text('First step'), findsNothing);
        expect(controller().isShowcaseRunning, isFalse);
        expect(dismissedAt, [first]);
        expect(finished, 0);

        // With the tour gone, back is the app's again.
        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
        expect(dismissedAt, [first], reason: 'no second dismissal');
      });

      testWidgets('dismiss: two quick presses report one dismissal', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.dismiss);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);

        // The second press lands while the tooltip is still animating out.
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.binding.handlePopRoute();
        await pumpFrames(tester);
        expect(stepsPageOpen(), isTrue);
        expect(dismissedAt, [first]);
      });

      testWidgets('previous: back steps back, and on the first step ends the tour', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.previous);
        controller().startShowCase([first, second], startAt: 1);
        await pumpFrames(tester);
        expect(find.text('Second step'), findsOneWidget);

        await pressBack(tester);
        expect(stepsPageOpen(), isTrue);
        expect(controller().currentIndex, 0);
        expect(find.text('First step'), findsOneWidget);
        expect(dismissedAt, isEmpty);

        // Nowhere further back to go: back leaves the tour, not the page.
        await pressBack(tester);
        expect(stepsPageOpen(), isTrue);
        expect(controller().isShowcaseRunning, isFalse);
        expect(dismissedAt, [first]);

        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
      });

      testWidgets('previous: a step that would be skipped going back counts as no earlier step', (tester) async {
        // The tour's first key is not on screen, and the tour skips such steps.
        final missing = GlobalKey();
        usePhone(tester);
        final above = placement == _Placement.aboveNavigator;
        ShowCaseWidget skippingTour(Widget child) => ShowCaseWidget(
          backButtonInteraction: BackButtonInteraction.previous,
          autoSkipUnmountedSteps: true,
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          onDismiss: dismissedAt.add,
          builder: child,
        );
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            builder: above ? (context, child) => skippingTour(child!) : null,
            home: const Scaffold(body: Text('home page')),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => above ? stepsPage() : skippingTour(stepsPage())),
        );
        await pumpFrames(tester);
        controller().startShowCase([missing, first, second]);
        await pumpFrames(tester);
        expect(controller().currentIndex, 1);

        await pressBack(tester);
        expect(stepsPageOpen(), isTrue);
        expect(controller().isShowcaseRunning, isFalse);
        expect(dismissedAt, [first]);
      });

      testWidgets('block: back does nothing while a step shows', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.block);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);

        await pressBack(tester);
        await pressBack(tester);
        expect(stepsPageOpen(), isTrue);
        expect(find.text('First step'), findsOneWidget);
        expect(controller().currentIndex, 0);
        expect(dismissedAt, isEmpty);

        // Once the tour is over, back closes the page again.
        controller().dismiss();
        await pumpFrames(tester);
        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
      });

      testWidgets('block also holds after the tour moves to another step', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.block);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);
        controller().next();
        await pumpFrames(tester);
        expect(find.text('Second step'), findsOneWidget);

        await pressBack(tester);
        expect(stepsPageOpen(), isTrue);
        expect(find.text('Second step'), findsOneWidget);

        // Finishing the tour gives back to the app.
        controller().next();
        await pumpFrames(tester);
        expect(finished, 1);
        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
      });

      testWidgets('back is left alone before the tour starts', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.block);
        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
      });

      testWidgets('back is left alone while the tour waits on a step that is not on screen', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.block);
        final elsewhere = GlobalKey();
        controller().startShowCase([elsewhere]);
        await pumpFrames(tester);
        expect(controller().isShowcaseRunning, isTrue);

        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
      });

      testWidgets('a dialog over the step closes on back; the tour stays', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.block);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);

        showDialog<void>(context: tourContext, builder: (_) => const Text('a dialog'));
        await pumpFrames(tester);
        expect(find.text('a dialog'), findsOneWidget);
        expect(find.text('First step'), findsNothing, reason: 'the step hides under the dialog');

        await pressBack(tester);
        expect(find.text('a dialog'), findsNothing);
        expect(stepsPageOpen(), isTrue);
        expect(find.text('First step'), findsOneWidget, reason: 'the step is back');

        // And back is the tour's again.
        await pressBack(tester);
        expect(stepsPageOpen(), isTrue);
        expect(find.text('First step'), findsOneWidget);
      });

      testWidgets('switching the option while a step shows takes effect at once', (tester) async {
        usePhone(tester);
        var interaction = BackButtonInteraction.passThrough;
        late StateSetter setOuter;
        final above = placement == _Placement.aboveNavigator;
        Widget switchable(Widget child) => StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return tour(interaction, child);
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            builder: above ? (context, child) => switchable(child!) : null,
            home: const Scaffold(body: Text('home page')),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => above ? stepsPage() : switchable(stepsPage())),
        );
        await pumpFrames(tester);
        controller().startShowCase([first, second]);
        await pumpFrames(tester);

        setOuter(() => interaction = BackButtonInteraction.block);
        await pumpFrames(tester);
        await pressBack(tester);
        expect(stepsPageOpen(), isTrue);
        expect(find.text('First step'), findsOneWidget);

        setOuter(() => interaction = BackButtonInteraction.passThrough);
        await pumpFrames(tester);
        await pressBack(tester);
        expect(stepsPageOpen(), isFalse);
      });
    });
  }

  group('backButtonInteraction across screens', () {
    late BuildContext homeContext;

    Future<void> openHome(WidgetTester tester, BackButtonInteraction interaction) async {
      usePhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => tour(interaction, child!),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                homeContext = context;
                return Showcase(key: first, title: 'Home step', description: 'd', child: const Text('home target'));
              },
            ),
          ),
        ),
      );
    }

    Route<void> plainPage() => MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('plain page')));

    testWidgets('a page pushed over the step closes on back; the step comes back', (tester) async {
      await openHome(tester, BackButtonInteraction.block);
      ShowCaseWidget.of(homeContext).startShowCase([first]);
      await pumpFrames(tester);
      expect(find.text('Home step'), findsOneWidget);

      navigator.currentState!.push(plainPage());
      await pumpFrames(tester);
      expect(find.text('Home step'), findsNothing);

      await pressBack(tester);
      expect(find.text('plain page'), findsNothing, reason: 'back closed the covering page');
      expect(find.text('Home step'), findsOneWidget);
    });

    testWidgets('back on a page with no step closes it while the tour waits for another page', (tester) async {
      await openHome(tester, BackButtonInteraction.block);
      final later = GlobalKey();
      ShowCaseWidget.of(homeContext).startShowCase([first, later]);
      await pumpFrames(tester);
      ShowCaseWidget.of(homeContext).next();
      await pumpFrames(tester);
      expect(ShowCaseWidget.of(homeContext).currentIndex, 1);

      navigator.currentState!.push(plainPage());
      await pumpFrames(tester);
      await pressBack(tester);
      expect(find.text('plain page'), findsNothing);
      expect(ShowCaseWidget.of(homeContext).isShowcaseRunning, isTrue);
    });

    testWidgets('previous into a step on the page below leaves back to the app', (tester) async {
      await openHome(tester, BackButtonInteraction.previous);
      final detailsStep = GlobalKey();
      ShowCaseWidget.of(homeContext).startShowCase([first, detailsStep]);
      await pumpFrames(tester);
      ShowCaseWidget.of(homeContext).next();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Showcase(key: detailsStep, title: 'Details step', description: 'd', child: const Text('details')),
          ),
        ),
      );
      await pumpFrames(tester);
      expect(find.text('Details step'), findsOneWidget);

      // Back goes to the home step, which is under this page: it waits there,
      // and nothing on this page is a step any more.
      await pressBack(tester);
      expect(ShowCaseWidget.of(homeContext).currentIndex, 0);
      expect(find.text('details'), findsOneWidget, reason: 'the details page stays');

      // So the next back closes the page, and the home step shows.
      await pressBack(tester);
      expect(find.text('details'), findsNothing);
      expect(find.text('Home step'), findsOneWidget);
    });

    testWidgets('on the first page, back with a step showing does not leave the app', (tester) async {
      await openHome(tester, BackButtonInteraction.dismiss);
      ShowCaseWidget.of(homeContext).startShowCase([first]);
      await pumpFrames(tester);

      final handled = await tester.binding.handlePopRoute();
      await pumpFrames(tester);
      expect(handled, isTrue, reason: 'the app handled back instead of the system');
      expect(dismissedAt, [first]);

      // With no step showing, the first page hands back to the system again.
      expect(await tester.binding.handlePopRoute(), isFalse);
    });
  });

  group('backButtonInteraction and predictive back', () {
    testWidgets('the page reports that it handles back while a step shows', (tester) async {
      usePhone(tester);
      final canHandlePop = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          onNavigationNotification: (notification) {
            canHandlePop.add(notification.canHandlePop);
            return true;
          },
          builder: (context, child) => tour(BackButtonInteraction.dismiss, child!),
          home: stepsPage(),
        ),
      );
      await pumpFrames(tester);
      canHandlePop.clear();

      controller().startShowCase([first]);
      await pumpFrames(tester);
      expect(canHandlePop.last, isTrue, reason: 'the system leaves back to the app');

      controller().dismiss();
      await pumpFrames(tester);
      expect(canHandlePop.last, isFalse, reason: 'with no step showing, back leaves the app again');
    });

    testWidgets('passThrough leaves the predictive back gesture alone', (tester) async {
      await openStepsPage(tester, _Placement.aboveNavigator, BackButtonInteraction.passThrough);
      controller().startShowCase([first]);
      await pumpFrames(tester);
      final route = ModalRoute.of(tourContext)!;
      expect(route.popGestureEnabled, isTrue);
      expect(route.popDisposition, RoutePopDisposition.pop);
    });

    testWidgets('a step turns the page swipe-back gesture off only while it shows', (tester) async {
      await openStepsPage(tester, _Placement.aboveNavigator, BackButtonInteraction.dismiss);
      final route = ModalRoute.of(tourContext)!;
      expect(route.popGestureEnabled, isTrue);

      controller().startShowCase([first]);
      await pumpFrames(tester);
      expect(route.popGestureEnabled, isFalse);
      expect(route.popDisposition, RoutePopDisposition.doNotPop);

      controller().dismiss();
      await pumpFrames(tester);
      expect(route.popGestureEnabled, isTrue);
      expect(route.popDisposition, RoutePopDisposition.pop);
    });

    Future<void> backGesture(WidgetTester tester) async {
      const codec = StandardMethodCodec();
      Future<void> send(String method, [Object? arguments]) => tester.binding.defaultBinaryMessenger
          .handlePlatformMessage('flutter/backgesture', codec.encodeMethodCall(MethodCall(method, arguments)), (_) {});
      await send('startBackGesture', <String, Object?>{
        'touchOffset': <double>[5, 300],
        'progress': 0.0,
        'swipeEdge': 0,
      });
      await tester.pump();
      await send('updateBackGestureProgress', <String, Object?>{
        'touchOffset': <double>[100, 300],
        'progress': 0.5,
        'swipeEdge': 0,
      });
      await tester.pump();
      await send('commitBackGesture');
      await pumpFrames(tester);
    }

    for (final placement in _Placement.values) {
      testWidgets('an Android back gesture ends the tour, not the page (${placement.name})', (tester) async {
        await openStepsPage(tester, placement, BackButtonInteraction.dismiss);
        controller().startShowCase([first]);
        await pumpFrames(tester);

        await backGesture(tester);
        expect(stepsPageOpen(), isTrue);
        expect(dismissedAt, [first]);

        // With no step showing, the same gesture closes the page.
        await backGesture(tester);
        expect(stepsPageOpen(), isFalse);
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));
    }
  });
}
