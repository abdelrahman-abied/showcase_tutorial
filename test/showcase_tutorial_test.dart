import 'dart:async';

import 'package:flutter/material.dart';
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
}
