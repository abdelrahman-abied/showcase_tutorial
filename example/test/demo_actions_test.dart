// Verifies the features demo really wires the tour-wide actions, rather than
// merely compiling. The demo leaves the looping tooltip animation on, so this
// pumps fixed durations instead of pumpAndSettle, which never settles.
import 'package:example/features_demo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

void main() {
  testWidgets('demo: tour-wide actions, suppressed on the first step', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: FeaturesDemoPage()));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Start tour'));
    await tester.tap(find.text('Start tour'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    List<String?> texts() =>
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();

    // The tour is really running.
    expect(texts(), contains('tooltipPosition.right'), reason: 'the first step tooltip is on screen');

    // Step 0 is _topLeft, which the demo lists in hideActionsForShowcase.
    expect(find.byType(ShowCaseDefaultActions), findsNothing, reason: 'suppressed on the first step');

    // Step 1 declares no actions of its own, so it gets the tour-wide ones.
    ShowCaseWidget.of(context).next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(texts(), contains('tooltipPosition.left'), reason: 'the tour advanced to the second step');
    expect(find.byType(ShowCaseDefaultActions), findsOneWidget, reason: 'tour-wide actions reach it');
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('demo: the inside toggle moves the buttons into the tooltip', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: FeaturesDemoPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Draw the tour buttons inside the tooltip'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Start tour'));
    await tester.tap(find.text('Start tour'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 0 suppresses the actions, so move to one that shows them.
    ShowCaseWidget.of(context).next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Inside placement puts the buttons within the tooltip's own clipped box;
    // the outside placement is a sibling of it in the overlay Stack.
    expect(
      find.ancestor(
        of: find.byType(ShowCaseDefaultActions),
        matching: find.byType(ClipRRect),
      ),
      findsWidgets,
    );
  });
}
