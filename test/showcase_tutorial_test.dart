import 'dart:async';

import 'package:flutter/gestures.dart';
// The legacy library is deprecated since Flutter 3.47; it is imported only to
// build apps that are still on it.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';
import 'package:showcase_tutorial/src/get_position.dart';
import 'package:showcase_tutorial/src/measure_size.dart';
import 'package:showcase_tutorial/src/shape_clipper.dart';

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

  group('performance characteristics', () {
    // Counts the OverlayEntry widgets currently mounted in the app's Overlay.
    int overlayEntries(WidgetTester tester) {
      var count = 0;
      void visit(Element element) {
        if (element.widget.runtimeType.toString() == '_OverlayEntryWidget') count++;
        element.visitChildren(visit);
      }

      tester.element(find.byType(Overlay).first).visitChildren(visit);
      return count;
    }

    Widget manySteps(List<GlobalKey> keys) {
      return MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  for (final key in keys)
                    Showcase(
                      key: key,
                      title: 'Step',
                      description: 'd',
                      child: const SizedBox(height: 20, width: 100, child: Text('t')),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('GetPosition measures once per build pass, and re-measures after invalidate', (tester) async {
      final key = GlobalKey();
      var top = 0.0;
      late StateSetter setter;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setter = setState;
              return Stack(
                children: [
                  Positioned(
                    top: top,
                    left: 0,
                    child: SizedBox(key: key, width: 10, height: 10),
                  ),
                ],
              );
            },
          ),
        ),
      );

      final position = GetPosition(key: key, screenWidth: 800, screenHeight: 600);
      final first = position.getRect();
      expect(first.top, 0);

      setter(() => top = 120);
      // No duration on purpose: consecutive pumps share a frame timestamp, so
      // the reading must not be tied to the frame clock.
      await tester.pump();

      // The reading is reused until it is explicitly dropped...
      expect(position.getRect(), first);

      // ...and then the target is measured where it actually is now.
      position.invalidate();
      expect(position.getRect().top, 120);
    });

    testWidgets('the tooltip follows a target that moves', (tester) async {
      final targetKey = GlobalKey();
      var spacer = 0.0;
      late StateSetter setter;

      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    setter = setState;
                    return Column(
                      children: [
                        SizedBox(height: spacer),
                        Showcase(
                          key: targetKey,
                          title: 'Moves',
                          description: 'd',
                          child: const SizedBox(height: 20, width: 100, child: Text('t')),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      ShowCaseWidget.of(tester.element(find.byKey(targetKey))).startShowCase([targetKey]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final before = tester.getTopLeft(find.text('Moves')).dy;

      setter(() => spacer = 150);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // A stale geometry reading would leave the tooltip behind at `before`.
      expect(tester.getTopLeft(find.text('Moves')).dy, closeTo(before + 150, 1));
    });

    testWidgets('a step that mounts while it is already active still shows', (tester) async {
      final targetKey = GlobalKey();
      var mounted = false;
      late StateSetter setter;

      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    setter = setState;
                    return Column(
                      children: [
                        const SizedBox(height: 10, width: 10),
                        if (mounted)
                          Showcase(
                            key: targetKey,
                            title: 'Late',
                            description: 'd',
                            child: const SizedBox(height: 20, width: 100, child: Text('t')),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // The tour starts on a step whose Showcase is not in the tree yet, so no
      // overlay entry can have been inserted for it.
      ShowCaseWidget.of(tester.element(find.byType(Scaffold))).startShowCase([targetKey]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Late'), findsNothing);

      // It mounts already active: the entry has to be inserted on the way in.
      setter(() => mounted = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Late'), findsOneWidget);
    });

    testWidgets('opening and closing a page rebuilds only the active step', (tester) async {
      final keys = List.generate(30, (_) => GlobalKey());
      final navigator = GlobalKey<NavigatorState>();
      late BuildContext home;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(builder: (_) => child!),
          ),
          home: Builder(
            builder: (context) {
              home = context;
              return Scaffold(
                body: ListView(
                  children: [
                    for (final key in keys) Showcase(key: key, description: 'd', child: const SizedBox(height: 10)),
                  ],
                ),
              );
            },
          ),
        ),
      );

      Future<int> showcaseRebuildsDuringPushAndPop() async {
        var rebuilds = 0;
        debugOnRebuildDirtyWidget = (element, _) {
          if (element.widget is Showcase) rebuilds++;
        };
        try {
          navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('page'))));
          await tester.pumpAndSettle();
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
        } finally {
          debugOnRebuildDirtyWidget = null;
        }
        return rebuilds;
      }

      // Only an active step needs to know about its page. Steps that never
      // were active don't depend on the route at all.
      expect(await showcaseRebuildsDuringPushAndPop(), 0, reason: 'no tour running');

      ShowCaseWidget.of(home).startShowCase(keys);
      await tester.pumpAndSettle();
      // The active step hides on push, then reappears once the page is back
      // and settled: 3 rebuilds, regardless of how many steps the page has.
      expect(await showcaseRebuildsDuringPushAndPop(), 3, reason: 'tour running');
    });

    testWidgets('an idle Showcase mounts no overlay entry', (tester) async {
      final keys = List.generate(10, (_) => GlobalKey());
      await tester.pumpWidget(manySteps(keys));
      await tester.pumpAndSettle();

      final idle = overlayEntries(tester);

      ShowCaseWidget.of(tester.element(find.byKey(keys.first))).startShowCase([keys.first]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Exactly one step is showing, so exactly one entry was added — the other
      // nine Showcases must not each keep an entry inserted.
      expect(overlayEntries(tester), idle + 1);
    });

    testWidgets('the active step releases its overlay entry when the tour ends', (tester) async {
      final keys = List.generate(3, (_) => GlobalKey());
      await tester.pumpWidget(manySteps(keys));
      await tester.pumpAndSettle();

      final idle = overlayEntries(tester);
      final state = ShowCaseWidget.of(tester.element(find.byKey(keys.first)));
      state.startShowCase([keys.first]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(overlayEntries(tester), idle + 1);

      state.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(overlayEntries(tester), idle);
    });

    testWidgets('highlightExactShape captures the target once, not per rebuild', (tester) async {
      final targetKey = GlobalKey();
      final hostKey = GlobalKey<_RebuildHostState>();

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: ShowCaseWidget(
              disableMovingAnimation: true,
              disableScaleAnimation: true,
              builder: Builder(
                builder: (context) => _RebuildHost(
                  key: hostKey,
                  builder: (context) => Scaffold(
                    body: Center(
                      child: Showcase(
                        key: targetKey,
                        title: 'Exact',
                        description: 'Body',
                        highlightExactShape: true,
                        child: Container(key: const ValueKey('exactTarget'), width: 48, height: 48, color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final state = ShowCaseWidget.of(tester.element(find.byKey(targetKey)));
        state.startShowCase([targetKey]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        // The snapshot is painted as a raw image — no PNG encode/decode round
        // trip through Image.memory.
        expect(find.byType(RawImage), findsOneWidget);
        expect(find.byType(Image), findsNothing);

        // The snapshot is drawn exactly over the target it was captured from.
        expect(tester.getRect(find.byType(RawImage)), tester.getRect(find.byKey(const ValueKey('exactTarget'))));

        final first = tester.widget<RawImage>(find.byType(RawImage)).image!;

        // Rebuilding the screen must reuse the captured image rather than
        // re-encoding the target every frame.
        for (var i = 0; i < 3; i++) {
          hostKey.currentState!.rebuild();
          await tester.pump();
          await tester.pump();
        }

        final latest = tester.widget<RawImage>(find.byType(RawImage)).image!;
        expect(latest.isCloneOf(first), isTrue, reason: 'the target was re-captured on rebuild');
        expect(tester.getRect(find.byType(RawImage)), tester.getRect(find.byKey(const ValueKey('exactTarget'))));

        // Ending the tour drops the snapshot so its image memory is released
        // rather than being left to a finaliser.
        final handle = tester.widget<RawImage>(find.byType(RawImage)).image!;
        expect(handle.debugDisposed, isFalse);

        state.dismiss();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(RawImage), findsNothing);
        expect(handle.debugDisposed, isTrue);
      });
    });

    testWidgets('a multi-widget step paints one raw image per key', (tester) async {
      final anchor = GlobalKey();
      final one = GlobalKey();
      final two = GlobalKey();

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: ShowCaseWidget(
              disableMovingAnimation: true,
              disableScaleAnimation: true,
              builder: Builder(
                builder: (context) => Scaffold(
                  body: Column(
                    children: [
                      Showcase(
                        key: anchor,
                        keys: [one, two],
                        title: 'Multi',
                        description: 'd',
                        child: const SizedBox(height: 40, width: 100, child: Text('anchor')),
                      ),
                      MultiView(
                        key: one,
                        child: Container(key: const ValueKey('one'), width: 30, height: 30, color: Colors.red),
                      ),
                      MultiView(
                        key: two,
                        child: Container(key: const ValueKey('two'), width: 30, height: 30, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        ShowCaseWidget.of(tester.element(find.byKey(anchor))).startShowCase([anchor]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(RawImage), findsNWidgets(2));

        // Each copy is painted over the widget it was captured from.
        final drawn = tester
            .widgetList<RawImage>(find.byType(RawImage))
            .map((image) => tester.getRect(find.byWidget(image)));
        expect(
          drawn,
          containsAll(<Rect>[
            tester.getRect(find.byKey(const ValueKey('one'))),
            tester.getRect(find.byKey(const ValueKey('two'))),
          ]),
        );
      });
    });

    // Counts elements Flutter actually rebuilt while [action] ran, keyed by
    // widget type.
    Future<Map<String, int>> rebuildsDuring(Future<void> Function() action) async {
      final counts = <String, int>{};
      final savedPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message == null) return;
        if (!message.startsWith('Rebuilding ') && !message.startsWith('Building ')) return;
        final name = message.split(' ')[1].split('-').first.split('(').first;
        counts[name] = (counts[name] ?? 0) + 1;
      };
      debugPrintRebuildDirtyWidgets = true;
      await action();
      debugPrintRebuildDirtyWidgets = false;
      debugPrint = savedPrint;
      return counts;
    }

    // Advances a [stepCount]-long tour by one step and reports how many
    // Showcase elements were rebuilt doing it.
    Future<int> showcasesRebuiltAdvancing(WidgetTester tester, int stepCount) async {
      final keys = List.generate(stepCount, (_) => GlobalKey());
      await tester.pumpWidget(manySteps(keys));
      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();

      final counts = await rebuildsDuring(() async {
        ShowCaseWidget.of(context).next();
        await tester.pump();
      });
      return counts['Showcase'] ?? 0;
    }

    testWidgets('an idle Showcase wraps its child in nothing', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(manySteps([key]));

      // The overlay entry is owned by the State, so the element below Showcase
      // is the child itself. It used to be an AnchoredOverlay wrapping an
      // OverlayBuilder, two elements per step whether or not the tour ran.
      final children = <Element>[];
      tester.element(find.byType(Showcase)).visitChildren(children.add);

      expect(children, hasLength(1));
      expect(children.single.widget, isA<SizedBox>());
    });

    testWidgets('the child keeps its state when a step opens and closes', (tester) async {
      // Moving overlay ownership out of wrapper widgets is only safe if the
      // child's position in the tree does not change with the tour: otherwise
      // every highlighted widget would lose its State each time it is shown.
      final keys = List.generate(2, (_) => GlobalKey());
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    Showcase(
                      key: keys[0],
                      title: 'One',
                      description: 'd',
                      child: const SizedBox(height: 20, width: 100, child: _Counter()),
                    ),
                    Showcase(
                      key: keys[1],
                      title: 'Two',
                      description: 'd',
                      child: const SizedBox(height: 20, width: 100, child: Text('t')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<_CounterState>(find.byType(_Counter));
      state.bump();
      await tester.pump();
      expect(state.value, 1);

      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();
      ShowCaseWidget.of(context).next();
      await tester.pumpAndSettle();
      ShowCaseWidget.of(context).dismiss();
      await tester.pumpAndSettle();

      // Same State object, same value: the child was never rebuilt from scratch.
      expect(tester.state<_CounterState>(find.byType(_Counter)), same(state));
      expect(state.value, 1);
    });

    testWidgets('advancing a step rebuilds only the two steps involved', (tester) async {
      // The step being left and the step being entered - and nothing else,
      // however long the tour is. A plain InheritedWidget would rebuild every
      // Showcase on screen, so this count would track the tour's length.
      final short = await showcasesRebuiltAdvancing(tester, 3);
      final long = await showcasesRebuiltAdvancing(tester, 12);

      expect(short, 2);
      expect(long, equals(short));
    });

    testWidgets('a dependant that does not name a step still rebuilds on every step change', (tester) async {
      // ShowCaseWidget.activeTargetWidget(context) without an aspect keeps the
      // original contract: rebuild whenever the active step changes, whichever
      // step that is.
      final keys = List.generate(3, (_) => GlobalKey());
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    Builder(
                      builder: (inner) {
                        ShowCaseWidget.activeTargetWidget(inner);
                        builds++;
                        return const SizedBox.shrink();
                      },
                    ),
                    for (final key in keys)
                      Showcase(
                        key: key,
                        title: 'Step',
                        description: 'd',
                        child: const SizedBox(height: 20, width: 100, child: Text('t')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();

      final before = builds;
      ShowCaseWidget.of(context).next();
      await tester.pumpAndSettle();

      expect(builds, greaterThan(before));
    });
  });

  testWidgets('renders the child before the showcase starts', (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(buildApp(targetKey));

    expect(find.text('target'), findsOneWidget);
    expect(find.text('Title A'), findsNothing);
    expect(find.text('Description A'), findsNothing);
  });

  testWidgets('shows the tooltip title and description once started', (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(buildApp(targetKey));

    ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([targetKey]);

    // Let the overlay insert and the showcase rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Title A'), findsOneWidget);
    expect(find.text('Description A'), findsOneWidget);
  });

  testWidgets('dismiss() tears the showcase overlay back down', (tester) async {
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
                  child: Showcase(key: targetKey, title: 'Styled', description: 'Body', child: const Text('target')),
                ),
              );
            },
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([targetKey]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final title = tester.widget<Text>(find.text('Styled'));
    expect(title.style?.color, Colors.green);
  });

  group('default text style and the app theme', () {
    // material_ui keeps its own Theme, separate from the one the legacy
    // package:flutter/material.dart MaterialApp inserts, so the tooltip cannot
    // read a legacy theme by itself. ShowcaseStyle is how a legacy app passes
    // its text styles in once.
    final legacyTheme = legacy.ThemeData(
      textTheme: const legacy.TextTheme(
        titleLarge: TextStyle(fontFamily: 'LegacyTitle', fontSize: 31),
        titleSmall: TextStyle(fontFamily: 'LegacyBody', fontSize: 13),
      ),
    );

    Widget showcaseBody(GlobalKey key) {
      return Center(
        child: Showcase(key: key, title: 'Theme title', description: 'Theme body', child: const Text('target')),
      );
    }

    Future<void> startTour(WidgetTester tester, GlobalKey key) async {
      ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([key]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    TextStyle? styleOf(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style;

    testWidgets('a legacy MaterialApp theme reaches the tooltip through ShowcaseStyle', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: legacyTheme,
          home: legacy.Builder(
            builder: (context) {
              final textTheme = legacy.Theme.of(context).textTheme;
              return ShowCaseWidget(
                disableMovingAnimation: true,
                disableScaleAnimation: true,
                style: ShowcaseStyle(titleTextStyle: textTheme.titleLarge, descTextStyle: textTheme.titleSmall),
                builder: Builder(builder: (context) => showcaseBody(key)),
              );
            },
          ),
        ),
      );
      await startTour(tester, key);

      expect(tester.takeException(), isNull);
      final title = styleOf(tester, 'Theme title');
      final body = styleOf(tester, 'Theme body');
      expect(title?.fontFamily, 'LegacyTitle');
      expect(title?.fontSize, 31);
      expect(body?.fontFamily, 'LegacyBody');
      expect(body?.fontSize, 13);
    });

    testWidgets('without ShowcaseStyle a legacy theme is not visible to the tooltip', (tester) async {
      // Pins the limitation the README describes: if material_ui ever starts
      // reading the legacy theme, this fails and the README needs updating.
      final key = GlobalKey();
      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: legacyTheme,
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(builder: (context) => showcaseBody(key)),
          ),
        ),
      );
      await startTour(tester, key);

      expect(tester.takeException(), isNull);
      final fallback = Theme.of(tester.element(find.text('target'))).textTheme;
      final title = styleOf(tester, 'Theme title');
      final body = styleOf(tester, 'Theme body');
      expect(title?.fontFamily, isNot('LegacyTitle'));
      expect(title?.fontFamily, fallback.titleLarge!.fontFamily);
      expect(title?.fontSize, fallback.titleLarge!.fontSize);
      expect(body?.fontFamily, isNot('LegacyBody'));
      expect(body?.fontSize, fallback.titleSmall!.fontSize);
    });

    testWidgets('a material_ui theme still styles the default tooltip text', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontFamily: 'ModernTitle', fontSize: 27),
              titleSmall: TextStyle(fontFamily: 'ModernBody', fontSize: 11),
            ),
          ),
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(builder: (context) => showcaseBody(key)),
          ),
        ),
      );
      await startTour(tester, key);

      expect(tester.takeException(), isNull);
      final title = styleOf(tester, 'Theme title');
      final body = styleOf(tester, 'Theme body');
      expect(title?.fontFamily, 'ModernTitle');
      expect(title?.fontSize, 27);
      expect(body?.fontFamily, 'ModernBody');
      expect(body?.fontSize, 11);
      // The colour follows the theme too (see 'colours follow the app theme').
      final onSurface = Theme.of(tester.element(find.text('target'))).colorScheme.onSurface;
      expect(title?.color, onSurface);
      expect(body?.color, onSurface);
    });

    testWidgets('a material_ui theme wins over a legacy Theme nested below it', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(titleLarge: TextStyle(fontFamily: 'ModernTitle')),
          ),
          home: legacy.Theme(
            data: legacyTheme,
            child: ShowCaseWidget(
              disableMovingAnimation: true,
              disableScaleAnimation: true,
              builder: Builder(builder: (context) => showcaseBody(key)),
            ),
          ),
        ),
      );
      await startTour(tester, key);

      expect(tester.takeException(), isNull);
      expect(styleOf(tester, 'Theme title')?.fontFamily, 'ModernTitle');
    });
  });

  group('colours follow the app theme', () {
    // Anything the developer leaves unset comes from the app's material_ui
    // theme; anything they set, per step or in ShowcaseStyle, wins.
    final light = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal));
    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
    );

    Widget app({
      ThemeData? theme,
      ShowcaseStyle style = const ShowcaseStyle(),
      required GlobalKey stepKey,
      Color? tooltipBackgroundColor,
      Color? textColor,
      Color? overlayColor,
      Widget? actions,
      ActionsSettings? actionSettings,
      TooltipActionPosition actionsPosition = TooltipActionPosition.outside,
      bool enablePulseAnimation = false,
      bool showProgress = false,
    }) {
      return MaterialApp(
        theme: theme,
        home: ShowCaseWidget(
          style: style,
          showProgress: showProgress,
          showSkip: showProgress,
          progressStyle: ShowcaseProgressStyle.numeric,
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Showcase(
                  key: stepKey,
                  title: 'Title',
                  description: 'Body',
                  tooltipBackgroundColor: tooltipBackgroundColor,
                  textColor: textColor,
                  overlayColor: overlayColor,
                  actions: actions,
                  actionSettings: actionSettings,
                  actionsPosition: actionsPosition,
                  enablePulseAnimation: enablePulseAnimation,
                  child: const Text('target'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> startTour(WidgetTester tester, GlobalKey key) async {
      ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([key]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }

    Color? textColorOf(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

    // The tooltip box is the nearest coloured Container around the title.
    Color tooltipColor(WidgetTester tester) {
      return tester
          .widgetList<Container>(find.ancestor(of: find.text('Title'), matching: find.byType(Container)))
          .firstWhere((container) => container.color != null)
          .color!;
    }

    // The dimmed background is the only ColoredBox at the default 75% opacity.
    Color scrimColor(WidgetTester tester) {
      final scrim = tester.widget<ColoredBox>(
        find.byWidgetPredicate((w) => w is ColoredBox && (w.color.a - 0.75).abs() < 0.001),
      );
      return scrim.color.withValues(alpha: 1);
    }

    // The box drawn behind actions placed outside the tooltip.
    Color? actionsBoxColor(WidgetTester tester) {
      return tester
          .widget<Container>(
            find.ancestor(of: find.byType(ShowCaseDefaultActions), matching: find.byType(Container)).first,
          )
          .color;
    }

    Color pulseColor(WidgetTester tester) {
      final pulse = tester.widget(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_PulsingOverlay'));
      // ignore: avoid_dynamic_calls
      return (pulse as dynamic).color as Color;
    }

    testWidgets('a light theme colours the tooltip, text, scrim and buttons', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        app(
          theme: light,
          stepKey: key,
          showProgress: true,
          actions: const ShowCaseDefaultActions(),
          actionsPosition: TooltipActionPosition.inside,
        ),
      );
      await startTour(tester, key);

      final scheme = light.colorScheme;
      expect(tooltipColor(tester), scheme.surfaceContainerHigh);
      expect(textColorOf(tester, 'Title'), scheme.onSurface);
      expect(textColorOf(tester, 'Body'), scheme.onSurface);
      expect(textColorOf(tester, '1/1'), scheme.onSurface, reason: 'the progress counter');
      expect(textColorOf(tester, 'Skip'), scheme.onSurface.withValues(alpha: 0.7));
      expect(scrimColor(tester), scheme.scrim);
      expect(textColorOf(tester, 'Next'), scheme.primary);
      expect(textColorOf(tester, 'Previous'), scheme.primary);
      expect(tester.widget<VerticalDivider>(find.byType(VerticalDivider).first).color, scheme.outlineVariant);
    });

    testWidgets('a dark theme gives a dark tooltip with light text', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(app(theme: dark, stepKey: key));
      await startTour(tester, key);

      final scheme = dark.colorScheme;
      expect(tooltipColor(tester), scheme.surfaceContainerHigh);
      expect(ThemeData.estimateBrightnessForColor(tooltipColor(tester)), Brightness.dark);
      expect(textColorOf(tester, 'Title'), scheme.onSurface);
      expect(ThemeData.estimateBrightnessForColor(textColorOf(tester, 'Title')!), Brightness.light);
    });

    testWidgets('switching the app between light and dark recolours a showing step', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(app(theme: light, stepKey: key));
      await startTour(tester, key);
      expect(tooltipColor(tester), light.colorScheme.surfaceContainerHigh);

      await tester.pumpWidget(app(theme: dark, stepKey: key));
      // MaterialApp animates between themes.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(tooltipColor(tester), dark.colorScheme.surfaceContainerHigh);
      expect(textColorOf(tester, 'Title'), dark.colorScheme.onSurface);
    });

    testWidgets('colours set on the step win over the theme', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        app(
          theme: dark,
          stepKey: key,
          tooltipBackgroundColor: const Color(0xFF0077B6),
          textColor: const Color(0xFFFFEE00),
          overlayColor: const Color(0xFF112233),
        ),
      );
      await startTour(tester, key);

      expect(tooltipColor(tester), const Color(0xFF0077B6));
      expect(textColorOf(tester, 'Title'), const Color(0xFFFFEE00));
      expect(scrimColor(tester), const Color(0xFF112233));
    });

    testWidgets('ShowcaseStyle sets every colour once, and a button colour wins over it', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        app(
          theme: dark,
          stepKey: key,
          enablePulseAnimation: true,
          style: const ShowcaseStyle(
            tooltipBackgroundColor: Color(0xFF101010),
            textColor: Color(0xFFEEEEEE),
            overlayColor: Color(0xFF223344),
            actionTextColor: Color(0xFFFF8800),
            actionDividerColor: Color(0xFF00FF88),
            pulseColor: Color(0xFFAA00AA),
          ),
          actions: const ShowCaseDefaultActions(next: ActionButtonConfig(textColor: Color(0xFF0000FF))),
          actionsPosition: TooltipActionPosition.inside,
        ),
      );
      await startTour(tester, key);

      expect(tooltipColor(tester), const Color(0xFF101010));
      expect(textColorOf(tester, 'Title'), const Color(0xFFEEEEEE));
      expect(scrimColor(tester), const Color(0xFF223344));
      expect(pulseColor(tester), const Color(0xFFAA00AA));
      expect(textColorOf(tester, 'Previous'), const Color(0xFFFF8800));
      expect(textColorOf(tester, 'Next'), const Color(0xFF0000FF), reason: "the button's own colour wins");
      expect(tester.widget<VerticalDivider>(find.byType(VerticalDivider).first).color, const Color(0xFF00FF88));
    });

    testWidgets('a background set without a text colour gets readable text and buttons', (tester) async {
      // An app that only ever set a white tooltip must not get the dark
      // theme's light text on it.
      final key = GlobalKey();
      await tester.pumpWidget(
        app(
          theme: dark,
          stepKey: key,
          tooltipBackgroundColor: Colors.white,
          actions: const ShowCaseDefaultActions(),
          actionsPosition: TooltipActionPosition.inside,
        ),
      );
      await startTour(tester, key);
      expect(textColorOf(tester, 'Title'), Colors.black);
      expect(textColorOf(tester, 'Next'), Colors.black);

      // And a dark background in a light app gets white.
      final key2 = GlobalKey();
      await tester.pumpWidget(app(theme: light, stepKey: key2, tooltipBackgroundColor: const Color(0xFF001122)));
      await startTour(tester, key2);
      expect(textColorOf(tester, 'Title'), Colors.white);
    });

    testWidgets('actions outside the tooltip: the box matches the tooltip, or the buttons contrast with the scrim', (
      tester,
    ) async {
      // With ActionsSettings there is a box, and it takes the tooltip's colour.
      final key = GlobalKey();
      await tester.pumpWidget(
        app(
          theme: light,
          stepKey: key,
          actions: const ShowCaseDefaultActions(),
          actionSettings: const ActionsSettings(),
        ),
      );
      await startTour(tester, key);
      expect(actionsBoxColor(tester), light.colorScheme.surfaceContainerHigh);
      expect(textColorOf(tester, 'Next'), light.colorScheme.primary);

      // A colour set on the box wins, and the buttons stay readable on it.
      final key2 = GlobalKey();
      await tester.pumpWidget(
        app(
          theme: light,
          stepKey: key2,
          actions: const ShowCaseDefaultActions(),
          actionSettings: const ActionsSettings(containerColor: Color(0xFF001122)),
        ),
      );
      await startTour(tester, key2);
      expect(actionsBoxColor(tester), const Color(0xFF001122));
      expect(textColorOf(tester, 'Next'), Colors.white);

      // Without ActionsSettings there is no box: the buttons sit on the
      // dimmed background and take the colour that shows against it.
      final key3 = GlobalKey();
      await tester.pumpWidget(app(theme: light, stepKey: key3, actions: const ShowCaseDefaultActions()));
      await startTour(tester, key3);
      expect(actionsBoxColor(tester), isNull);
      expect(textColorOf(tester, 'Next'), Colors.white);
    });

    testWidgets('the pulse ring shows against the dimmed background', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(app(theme: light, stepKey: key, enablePulseAnimation: true));
      await startTour(tester, key);
      expect(pulseColor(tester), Colors.white, reason: 'the default scrim is black');

      final key2 = GlobalKey();
      await tester.pumpWidget(app(theme: light, stepKey: key2, enablePulseAnimation: true, overlayColor: Colors.white));
      await startTour(tester, key2);
      expect(pulseColor(tester), Colors.black);
    });

    testWidgets('an app without a material_ui theme keeps the fixed colours', (tester) async {
      // An app on the legacy MaterialApp: its theme can't be read, so the tour
      // must not pick up material_ui's unrelated default theme instead.
      final key = GlobalKey();
      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: legacy.ThemeData.dark(),
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Center(
                child: Showcase(
                  key: key,
                  title: 'Title',
                  description: 'Body',
                  actions: const ShowCaseDefaultActions(),
                  actionSettings: const ActionsSettings(),
                  child: const Text('target'),
                ),
              ),
            ),
          ),
        ),
      );
      await startTour(tester, key);

      expect(tooltipColor(tester), Colors.white);
      expect(textColorOf(tester, 'Title'), Colors.black);
      expect(scrimColor(tester), Colors.black);
      expect(actionsBoxColor(tester), Colors.white);
      expect(textColorOf(tester, 'Next'), const Color(0xff48cae4));
      expect(tester.widget<VerticalDivider>(find.byType(VerticalDivider).first).color, const Color(0xffcaf0f8));
    });

    testWidgets('the scroll spinner takes ShowcaseStyle.loadingIndicatorColor, else contrasts with the scrim', (
      tester,
    ) async {
      Future<Color?> spinnerColor(ShowcaseStyle style) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: light,
            home: ShowCaseWidget(
              style: style,
              enableAutoScroll: true,
              scrollDuration: const Duration(milliseconds: 300),
              disableMovingAnimation: true,
              disableScaleAnimation: true,
              builder: Builder(
                builder: (context) => Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 1200),
                        Showcase(key: key, description: 'Far down', child: const Text('t')),
                        const SizedBox(height: 1200),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
        // The scroll starts after the first frame; the spinner shows from the
        // frame after that until the scroll ends.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        final spinner = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
        final color = spinner.valueColor?.value;
        await tester.pumpAndSettle();
        ShowCaseWidget.of(tester.element(find.text('t'))).dismiss();
        await tester.pump(const Duration(seconds: 1));
        // Start the next run from an unscrolled page.
        await tester.pumpWidget(const SizedBox());
        return color;
      }

      expect(await spinnerColor(const ShowcaseStyle()), Colors.white);
      expect(
        await spinnerColor(const ShowcaseStyle(loadingIndicatorColor: Color(0xFF00AAFF))),
        const Color(0xFF00AAFF),
      );
    });
  });

  testWidgets('description is optional and the tooltip still renders', (tester) async {
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
                  child: Showcase(key: targetKey, title: 'Title only', child: const Text('target')),
                ),
              );
            },
          ),
        ),
      ),
    );

    ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([targetKey]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Title only'), findsOneWidget);
  });

  testWidgets('MeasureSize reports the laid-out size of its child', (tester) async {
    Size? reported;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MeasureSize(onSizeChange: (size) => reported = size, child: const SizedBox(width: 120, height: 48)),
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
              child: Showcase(key: targetKey, title: 'Guarded', description: 'Body', child: const Text('target')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('onShouldStartShowcase=false blocks the tour and receives the id', (tester) async {
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

    ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([targetKey]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(receivedId, 'home_v1');
    expect(find.text('Guarded'), findsNothing);
  });

  testWidgets('an async onShouldStartShowcase=true starts the tour', (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(buildGuardedApp(targetKey, onShouldStartShowcase: (id) async => true));

    ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([targetKey]);
    await tester.pump(); // kick off the guard future
    await tester.pump(); // resolve it
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Guarded'), findsOneWidget);
  });

  testWidgets('force:true bypasses a blocking guard', (tester) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(buildGuardedApp(targetKey, onShouldStartShowcase: (id) async => false));

    ShowCaseWidget.of(tester.element(find.text('target'))).startShowCase([targetKey], force: true);
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
                Showcase(key: k1, title: 'One', description: 'd', child: const Text('t1')),
                if (includeSecondTarget) Showcase(key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                Showcase(key: k3, title: 'Three', description: 'd', child: const Text('t3')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('progress getters and goTo / goToKey navigate steps', (tester) async {
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

  testWidgets('autoSkipUnmountedSteps skips a step whose target is absent', (tester) async {
    final k1 = GlobalKey();
    final kAbsent = GlobalKey(); // never attached to the tree
    final k3 = GlobalKey();
    await tester.pumpWidget(
      buildMultiStepApp(k1, kAbsent, k3, includeSecondTarget: false, autoSkipUnmountedSteps: true),
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

  testWidgets('tooltipPosition.right places the tooltip to the right of target', (tester) async {
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

  testWidgets('tooltipPosition.left places the tooltip to the left of target', (tester) async {
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

  testWidgets('highlightExactShape wraps the target and runs the snapshot highlight '
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
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
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
        find.ancestor(of: find.byKey(const ValueKey('exactChild')), matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );

      ShowCaseWidget.of(tester.element(find.byKey(targetKey))).startShowCase([targetKey]);
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
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
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

  testWidgets('per-step arrow + highlight-border styling renders without error', (tester) async {
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

  testWidgets('ShowcaseStyle arrow + highlight-border defaults are applied', (tester) async {
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
                  child: Showcase(key: key, title: 'عنوان', description: 'وصف', child: const Text('t')),
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
      find.ancestor(of: find.text('عنوان'), matching: find.byType(Directionality)).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  // Builds a two-step tour with a configurable barrier behaviour. Targets are
  // centered so a tap near a screen corner lands on the dimmed barrier.
  Widget buildBarrierApp(
    GlobalKey k1,
    GlobalKey k2, {
    BarrierInteraction barrierInteraction = BarrierInteraction.next,
    BarrierInteraction? step1Barrier,
    bool disableBarrierInteraction = false,
    bool enableKeyboardNavigation = true,
    VoidCallback? onBarrierClick,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        barrierInteraction: barrierInteraction,
        disableBarrierInteraction: disableBarrierInteraction,
        enableKeyboardNavigation: enableKeyboardNavigation,
        onBarrierClick: onBarrierClick,
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
                    barrierInteraction: step1Barrier,
                    child: const Text('t1'),
                  ),
                  Showcase(key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('barrier tap advances to the next step by default', (tester) async {
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

  testWidgets('barrierInteraction.dismiss closes the tour on a background tap', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(buildBarrierApp(k1, k2, barrierInteraction: BarrierInteraction.dismiss));

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
    await tester.pumpWidget(buildBarrierApp(k1, k2, barrierInteraction: BarrierInteraction.none));

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

  testWidgets('legacy disableBarrierInteraction:true makes the barrier inert', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(buildBarrierApp(k1, k2, disableBarrierInteraction: true));

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

  testWidgets('keyboard ArrowRight advances and ArrowLeft goes back', (tester) async {
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

  testWidgets('enableKeyboardNavigation:false ignores key presses', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(buildBarrierApp(k1, k2, enableKeyboardNavigation: false));

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
  Widget buildAnnounceApp(GlobalKey key, {bool enableAutoAnnouncements = true, String? semanticLabel}) {
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
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
      dynamic message,
    ) async {
      if (message is Map && message['type'] == 'announce') {
        announced.add((message['data'] as Map)['message'] as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(SystemChannels.accessibility, null),
    );

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
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
      dynamic message,
    ) async {
      if (message is Map && message['type'] == 'announce') {
        announced.add((message['data'] as Map)['message'] as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(SystemChannels.accessibility, null),
    );

    final key = GlobalKey();
    await tester.pumpWidget(buildAnnounceApp(key, semanticLabel: 'Open your profile'));
    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(announced, contains('Open your profile'));
  });

  testWidgets('enableAutoAnnouncements:false makes no announcement', (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
      dynamic message,
    ) async {
      if (message is Map && message['type'] == 'announce') {
        announced.add((message['data'] as Map)['message'] as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(SystemChannels.accessibility, null),
    );

    final key = GlobalKey();
    await tester.pumpWidget(buildAnnounceApp(key, enableAutoAnnouncements: false));
    ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(announced, isEmpty);
  });

  testWidgets('onShow/onDismiss can call setState without a "setState during build" '
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
                  Showcase(key: k1, title: 'One', description: 'd', child: const Text('t1')),
                  Showcase(key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                  Showcase(key: k3, title: 'Three', description: 'd', child: const Text('t3')),
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

    ShowCaseWidget.of(tester.element(find.text('t1'))).startShowCase([k1, k2, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('One'), findsOneWidget);
    // One dot (AnimatedContainer) per step.
    expect(find.byType(AnimatedContainer), findsNWidgets(3));
  });

  testWidgets('progressStyle.numeric shows "current/total" instead of dots', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    final k3 = GlobalKey();
    await tester.pumpWidget(
      buildProgressApp(k1, k2, k3, showProgress: true, progressStyle: ShowcaseProgressStyle.numeric),
    );

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

  testWidgets('showSkip renders a Skip button that dismisses the tour', (tester) async {
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
    await tester.pumpWidget(buildProgressApp(k1, k2, k3, showSkip: true, skipButtonText: 'Skip tour'));

    ShowCaseWidget.of(tester.element(find.text('t1'))).startShowCase([k1, k2, k3]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Skip tour'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  // Builds a four-step showcase wired with a branching resolver.
  Widget buildBranchApp(
    GlobalKey k1,
    GlobalKey k2,
    GlobalKey k3,
    GlobalKey k4, {
    GlobalKey? Function(int, GlobalKey)? onResolveNextStep,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        onResolveNextStep: onResolveNextStep,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Showcase(key: k1, title: 'One', description: 'd', child: const Text('t1')),
                Showcase(key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                Showcase(key: k3, title: 'Three', description: 'd', child: const Text('t3')),
                Showcase(key: k4, title: 'Four', description: 'd', child: const Text('t4')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('conditional / branching tours (onResolveNextStep)', () {
    testWidgets('next() branches ahead to the resolved step', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final k4 = GlobalKey();
      await tester.pumpWidget(buildBranchApp(k1, k2, k3, k4, onResolveNextStep: (index, key) => key == k1 ? k4 : null));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2, k3, k4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('One'), findsOneWidget);

      state.next(); // resolver branches k1 -> k4, skipping k2 and k3
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 3);
      expect(find.text('Four'), findsOneWidget);
      expect(find.text('Two'), findsNothing);
    });

    testWidgets('completed() (Next button / tap path) honors the branch', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final k4 = GlobalKey();
      await tester.pumpWidget(buildBranchApp(k1, k2, k3, k4, onResolveNextStep: (index, key) => key == k1 ? k3 : null));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2, k3, k4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // completed() is what the default Next button, target tap and barrier use.
      state.completed(k1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 2);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('returning null falls through to the normal next step', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final k4 = GlobalKey();
      await tester.pumpWidget(buildBranchApp(k1, k2, k3, k4, onResolveNextStep: (index, key) => null));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2, k3, k4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 1);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('resolver receives the current index and key', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final k4 = GlobalKey();
      int? seenIndex;
      GlobalKey? seenKey;
      await tester.pumpWidget(
        buildBranchApp(
          k1,
          k2,
          k3,
          k4,
          onResolveNextStep: (index, key) {
            seenIndex = index;
            seenKey = key;
            return null;
          },
        ),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2, k3, k4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.next();
      expect(seenIndex, 0);
      expect(seenKey, k1);
    });

    testWidgets('a branch can jump backward to an earlier step', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final k4 = GlobalKey();
      await tester.pumpWidget(buildBranchApp(k1, k2, k3, k4, onResolveNextStep: (index, key) => key == k3 ? k1 : null));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2, k3, k4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.goTo(2); // jump to k3 (goTo ignores the resolver)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Three'), findsOneWidget);

      state.next(); // resolver branches k3 -> k1
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 0);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('previous() ignores the resolver', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final k4 = GlobalKey();
      // Resolver would always branch forward to k4 if it were consulted.
      await tester.pumpWidget(buildBranchApp(k1, k2, k3, k4, onResolveNextStep: (index, key) => k4));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2, k3, k4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.goTo(2); // k3
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.previous(); // must step back to k2, not branch to k4
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 1);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('branching to the last step still finishes on the next advance', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final k4 = GlobalKey();
      await tester.pumpWidget(buildBranchApp(k1, k2, k3, k4, onResolveNextStep: (index, key) => key == k1 ? k4 : null));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2, k3, k4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.next(); // branch k1 -> k4 (the last step)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 3);
      expect(state.isShowcaseRunning, isTrue);

      state.next(); // from k4 the resolver returns null -> tour finishes
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.isShowcaseRunning, isFalse);
      expect(find.text('Four'), findsNothing);
    });
  });

  // Builds a two-step tour wired with tour-level onDismiss / onFinish callbacks.
  Widget buildDismissApp(
    GlobalKey k1,
    GlobalKey k2, {
    void Function(GlobalKey? dismissedAt)? onDismiss,
    VoidCallback? onFinish,
    BarrierInteraction barrierInteraction = BarrierInteraction.next,
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        barrierInteraction: barrierInteraction,
        onDismiss: onDismiss,
        onFinish: onFinish,
        builder: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Showcase(key: k1, title: 'One', description: 'd', child: const Text('t1')),
                  Showcase(key: k2, title: 'Two', description: 'd', child: const Text('t2')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('tour-level onDismiss (ShowCaseWidget.onDismiss)', () {
    testWidgets('fires with the active step key when dismiss() is called', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      GlobalKey? dismissedAt;
      var didDismiss = false;
      var finished = false;
      await tester.pumpWidget(
        buildDismissApp(
          k1,
          k2,
          onDismiss: (key) {
            didDismiss = true;
            dismissedAt = key;
          },
          onFinish: () => finished = true,
        ),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(didDismiss, isTrue);
      expect(dismissedAt, k1); // dismissed while the first step was active
      expect(finished, isFalse); // an early dismiss is not a normal finish
      expect(state.isShowcaseRunning, isFalse);
    });

    testWidgets('reports the step the user left off on', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      GlobalKey? dismissedAt;
      await tester.pumpWidget(buildDismissApp(k1, k2, onDismiss: (key) => dismissedAt = key));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.next(); // advance to the second step
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(dismissedAt, k2);
    });

    testWidgets('is NOT called when the tour finishes normally', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      var dismissed = false;
      var finished = false;
      await tester.pumpWidget(
        buildDismissApp(k1, k2, onDismiss: (_) => dismissed = true, onFinish: () => finished = true),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.next(); // -> step 2
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      state.next(); // advance past the last step -> normal finish
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(finished, isTrue);
      expect(dismissed, isFalse);
    });

    testWidgets('a barrier-dismiss tap triggers onDismiss with the active key', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      GlobalKey? dismissedAt;
      await tester.pumpWidget(
        buildDismissApp(k1, k2, barrierInteraction: BarrierInteraction.dismiss, onDismiss: (key) => dismissedAt = key),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tapAt(const Offset(10, 10)); // tap the dimmed barrier
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // reverse animation
      await tester.pump(const Duration(milliseconds: 400)); // teardown

      expect(state.isShowcaseRunning, isFalse);
      expect(dismissedAt, k1);
    });
  });

  group('onBarrierClick (ShowCaseWidget.onBarrierClick)', () {
    testWidgets('fires on a barrier tap and still advances by default', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      var clicks = 0;
      await tester.pumpWidget(buildBarrierApp(k1, k2, onBarrierClick: () => clicks++));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tapAt(const Offset(10, 10)); // tap the dimmed barrier
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // reverse animation
      await tester.pump(const Duration(milliseconds: 400)); // next step in

      expect(clicks, 1);
      expect(state.currentIndex, 1); // default .next still advanced
    });

    testWidgets('fires even when barrierInteraction is none', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      var clicks = 0;
      await tester.pumpWidget(
        buildBarrierApp(k1, k2, barrierInteraction: BarrierInteraction.none, onBarrierClick: () => clicks++),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(clicks, 1); // the hook fired…
      expect(state.currentIndex, 0); // …but `.none` did not advance
    });
  });

  // Builds a two-step tour with optional per-step + global floating widgets.
  Widget buildFloatingApp(
    GlobalKey k1,
    GlobalKey k2, {
    Widget? floating1,
    Widget? floating2,
    WidgetBuilder? globalFloatingActionWidget,
    List<GlobalKey> hideFloatingActionWidgetForShowcase = const [],
  }) {
    return MaterialApp(
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        globalFloatingActionWidget: globalFloatingActionWidget,
        hideFloatingActionWidgetForShowcase: hideFloatingActionWidgetForShowcase,
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
                    floatingActionWidget: floating1,
                    child: const Text('t1'),
                  ),
                  Showcase(
                    key: k2,
                    title: 'Two',
                    description: 'd',
                    floatingActionWidget: floating2,
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

  group('floating action widget', () {
    testWidgets('per-step floatingActionWidget renders while its step is active', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(
        buildFloatingApp(
          k1,
          k2,
          floating1: const Align(alignment: Alignment.bottomCenter, child: Text('FAB1')),
        ),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('FAB1'), findsOneWidget);

      state.next(); // -> step 2, which has no floating widget
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('FAB1'), findsNothing);
    });

    testWidgets('globalFloatingActionWidget renders on every step', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(
        buildFloatingApp(
          k1,
          k2,
          globalFloatingActionWidget: (_) => const Align(alignment: Alignment.bottomCenter, child: Text('GFAB')),
        ),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GFAB'), findsOneWidget);

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GFAB'), findsOneWidget); // still shown on step 2
    });

    testWidgets('hideFloatingActionWidgetForShowcase suppresses the global one', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(
        buildFloatingApp(
          k1,
          k2,
          globalFloatingActionWidget: (_) => const Align(alignment: Alignment.bottomCenter, child: Text('GFAB')),
          hideFloatingActionWidgetForShowcase: [k2],
        ),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GFAB'), findsOneWidget); // shown on k1

      state.next(); // k2 is in the hide list
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GFAB'), findsNothing);
    });

    testWidgets('per-step floatingActionWidget overrides the global one', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(
        buildFloatingApp(
          k1,
          k2,
          floating1: const Align(alignment: Alignment.bottomCenter, child: Text('LOCAL')),
          globalFloatingActionWidget: (_) => const Align(alignment: Alignment.bottomCenter, child: Text('GFAB')),
        ),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // The per-step widget wins on k1; the global one is not shown.
      expect(find.text('LOCAL'), findsOneWidget);
      expect(find.text('GFAB'), findsNothing);

      state.next(); // k2 has no per-step widget -> falls back to global
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GFAB'), findsOneWidget);
    });
  });

  testWidgets('per-step autoPlayDelay overrides the tour-wide autoPlayDelay', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          autoPlay: true,
          autoPlayDelay: const Duration(seconds: 2), // tour-wide default
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
                      // Much shorter than the 2s tour-wide delay.
                      autoPlayDelay: const Duration(milliseconds: 100),
                      child: const Text('t1'),
                    ),
                    Showcase(key: k2, title: 'Two', description: 'd', child: const Text('t2')),
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
    await tester.pump(); // insert the overlay; starts the 100ms step-1 timer
    await tester.pump(const Duration(milliseconds: 50)); // < 100ms override
    expect(state.currentIndex, 0); // not advanced yet
    expect(find.text('One'), findsOneWidget);

    // Cross the 100ms override threshold — still far short of the 2s tour-wide
    // delay — so advancing now proves the per-step override fired.
    await tester.pump(const Duration(milliseconds: 100)); // ~150ms total > 100ms
    await tester.pump(const Duration(milliseconds: 400)); // reverse animation
    await tester.pump(const Duration(milliseconds: 400)); // step 2 in
    expect(state.currentIndex, 1);

    // Let step 2's tour-wide timer fire so the tour finishes and no Timer leaks.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.isShowcaseRunning, isFalse);
  });

  testWidgets('targetTooltipGap pushes the tooltip further from the target', (tester) async {
    // Returns the tooltip's top y for a given gap. The target sits at a fixed
    // position near the top, so the tooltip renders below it (arrow up) and its
    // top shifts down by exactly the gap.
    Future<double> tooltipTopForGap(double gap) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Showcase(
                      key: key,
                      description: 'Body',
                      targetTooltipGap: gap,
                      child: const SizedBox(width: 40, height: 40, child: Text('t')),
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
      return tester.getTopLeft(find.text('Body')).dy;
    }

    final top0 = await tooltipTopForGap(0);
    final top40 = await tooltipTopForGap(40);
    // A 40px gap moves the tooltip 40px further down, away from the target.
    expect(top40 - top0, closeTo(40, 1));
  });

  testWidgets('toolTipMargin keeps the tooltip clear of the screen edge', (tester) async {
    // Target hugs the left edge, so the tooltip is clamped to toolTipMargin.left.
    // Returns the tooltip's left x for a given margin.
    Future<double> tooltipLeftForMargin(EdgeInsets margin) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: Showcase(
                    key: key,
                    title: 'T',
                    description: 'Desc',
                    toolTipMargin: margin,
                    child: const SizedBox(width: 30, height: 30, child: Text('t')),
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
      return tester.getTopLeft(find.text('Desc')).dx;
    }

    final left20 = await tooltipLeftForMargin(const EdgeInsets.all(20));
    final left60 = await tooltipLeftForMargin(const EdgeInsets.all(60));
    // A 40px-larger left margin pushes the clamped tooltip 40px further inward.
    expect(left60 - left20, closeTo(40, 1));
  });

  testWidgets('toolTipMargin keeps a Showcase.withWidget container clear of the screen edge', (tester) async {
    // A custom container on an edge-hugging target is clamped to toolTipMargin.left
    // (the old hardcoded behaviour would have pinned it at 16).
    const margin = EdgeInsets.all(50);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: Showcase.withWidget(
                  key: key,
                  height: 80,
                  width: 140,
                  toolTipMargin: margin,
                  container: const SizedBox(width: 140, height: 80, child: Text('Box')),
                  child: const SizedBox(width: 30, height: 30, child: Text('t')),
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
    // The container is clamped to the left margin rather than the old 16px.
    expect(tester.getTopLeft(find.text('Box')).dx, closeTo(50, 1));
  });

  testWidgets('scrollAlignment controls where auto-scroll lands the target', (tester) async {
    // A target sandwiched between two tall spacers in a scroll view. Auto-scroll
    // reveals it; the resting scroll offset depends on the alignment fraction.
    // Returns the scroll offset after the showcase scrolls the target into view.
    Future<double> offsetForAlignment({required double tourAlignment, double? stepAlignment}) async {
      final key = GlobalKey();
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            enableAutoScroll: true,
            scrollAlignment: tourAlignment,
            scrollDuration: const Duration(milliseconds: 100),
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(
              builder: (context) => Scaffold(
                body: SizedBox(
                  height: 600,
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      children: [
                        const SizedBox(height: 600),
                        Showcase(
                          key: key,
                          description: 'Target',
                          scrollAlignment: stepAlignment,
                          child: const SizedBox(width: 100, height: 50, child: Text('t')),
                        ),
                        const SizedBox(height: 600),
                      ],
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
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      return controller.offset;
    }

    // The target sits at content offset 600 in a 600px viewport; aligning it to
    // the leading edge rests further down the list than the trailing edge.
    final leading = await offsetForAlignment(tourAlignment: 0.0);
    final trailing = await offsetForAlignment(tourAlignment: 1.0);
    expect(leading, greaterThan(trailing));

    // A per-step scrollAlignment overrides the tour-wide value: a trailing-edge
    // step inside a leading-edge tour lands like the trailing case.
    final overridden = await offsetForAlignment(tourAlignment: 0.0, stepAlignment: 1.0);
    expect(overridden, closeTo(trailing, 1));
    expect(overridden, lessThan(leading));
  });

  group('dynamic callback registration', () {
    testWidgets('registered start/complete listeners fire alongside the '
        'widget-level callbacks', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      await tester.pumpWidget(buildMultiStepApp(k1, k2, k3));

      final started = <int?>[];
      final completed = <int?>[];
      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.addOnStartCallback((index, key) => started.add(index));
      state.addOnCompleteCallback((index, key) => completed.add(index));

      state.startShowCase([k1, k2, k3]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(started, [0]);
      expect(completed, isEmpty);

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(started, [0, 1]);
      expect(completed, [0]);
    });

    testWidgets('listeners receive the index and key of the step', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      await tester.pumpWidget(buildMultiStepApp(k1, k2, k3));

      final events = <String>[];
      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.addOnStartCallback((index, key) => events.add('start:$index:${key == k2 ? 'k2' : 'other'}'));

      state.startShowCase([k1, k2, k3]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(events, ['start:0:other', 'start:1:k2']);
    });

    testWidgets('removed listeners stop firing', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      await tester.pumpWidget(buildMultiStepApp(k1, k2, k3));

      final started = <int?>[];
      final completed = <int?>[];
      void onStart(int? index, GlobalKey key) => started.add(index);
      void onComplete(int? index, GlobalKey key) => completed.add(index);

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.addOnStartCallback(onStart);
      state.addOnCompleteCallback(onComplete);

      state.startShowCase([k1, k2, k3]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(started, [0]);

      expect(state.removeOnStartCallback(onStart), isTrue);
      expect(state.removeOnCompleteCallback(onComplete), isTrue);
      // Removing an unregistered callback reports false rather than throwing.
      expect(state.removeOnStartCallback(onStart), isFalse);

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(started, [0]); // unchanged
      expect(completed, isEmpty);
    });

    testWidgets('a listener that unregisters itself mid-dispatch is safe', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      await tester.pumpWidget(buildMultiStepApp(k1, k2, k3));

      final calls = <int?>[];
      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      late final ShowcaseStepCallback once;
      once = (index, key) {
        calls.add(index);
        state.removeOnStartCallback(once); // mutates the list while dispatching
      };
      state.addOnStartCallback(once);
      // A second listener must still run in the same dispatch.
      state.addOnStartCallback((index, key) => calls.add(100 + (index ?? 0)));

      state.startShowCase([k1, k2, k3]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(calls, [0, 100]);

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, [0, 100, 101]); // the self-removed listener did not re-run
    });
  });

  group('isTargetRendered', () {
    testWidgets('is true for a laid-out target and false for an absent one', (tester) async {
      final k1 = GlobalKey();
      final kAbsent = GlobalKey(); // never attached to the tree
      final k3 = GlobalKey();
      await tester.pumpWidget(buildMultiStepApp(k1, kAbsent, k3, includeSecondTarget: false));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      expect(state.isTargetRendered(k1), isTrue);
      expect(state.isTargetRendered(k3), isTrue);
      expect(state.isTargetRendered(kAbsent), isFalse);
    });

    testWidgets('turns false once the target leaves the tree', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      await tester.pumpWidget(buildMultiStepApp(k1, k2, k3));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      expect(state.isTargetRendered(k2), isTrue);

      // Rebuild without the middle target.
      await tester.pumpWidget(buildMultiStepApp(k1, k2, k3, includeSecondTarget: false));
      expect(state.isTargetRendered(k2), isFalse);
    });
  });

  group('onTargetRectUpdate', () {
    // A one-step tour whose target can be pushed down the screen at runtime, so
    // the reported rect changes without the step changing.
    Widget buildRectApp(
      GlobalKey key,
      ValueNotifier<double> topPadding, {
      required void Function(Rect) onTargetRectUpdate,
    }) {
      return MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (context) => Scaffold(
              body: ValueListenableBuilder<double>(
                valueListenable: topPadding,
                builder: (context, pad, _) => Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: pad),
                    child: Showcase(
                      key: key,
                      title: 'T',
                      description: 'd',
                      onTargetRectUpdate: onTargetRectUpdate,
                      child: const SizedBox(width: 40, height: 40, child: Text('t')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('reports the target bounds when the step becomes active, then '
        'again when the target moves', (tester) async {
      final key = GlobalKey();
      final topPadding = ValueNotifier<double>(0);
      addTearDown(topPadding.dispose);
      final rects = <Rect>[];

      await tester.pumpWidget(buildRectApp(key, topPadding, onTargetRectUpdate: rects.add));
      // Nothing reported while the step is inactive.
      await tester.pump();
      expect(rects, isEmpty);

      ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(rects, hasLength(1));
      final target = tester.getRect(find.text('t'));
      expect(rects.single.left, closeTo(target.left, 1));
      expect(rects.single.top, closeTo(target.top, 1));
      expect(rects.single.width, closeTo(40, 1));
      expect(rects.single.height, closeTo(40, 1));

      // Move the target 100px down; the new bounds are reported.
      topPadding.value = 100;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(rects.length, greaterThan(1));
      expect(rects.last.top - rects.first.top, closeTo(100, 1));
    });

    testWidgets('does not re-report an unchanged rect', (tester) async {
      final key = GlobalKey();
      final topPadding = ValueNotifier<double>(0);
      addTearDown(topPadding.dispose);
      final rects = <Rect>[];

      await tester.pumpWidget(buildRectApp(key, topPadding, onTargetRectUpdate: rects.add));
      ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(rects, hasLength(1));

      // Several idle frames with a stationary target report nothing new.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(rects, hasLength(1));
    });

    testWidgets('an inactive step reports nothing until it becomes active', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final rects = <Rect>[];

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
                      Showcase(key: k1, title: 'One', description: 'd', child: const Text('t1')),
                      Showcase(
                        key: k2,
                        title: 'Two',
                        description: 'd',
                        onTargetRectUpdate: rects.add,
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
      expect(rects, isEmpty); // step 2 is not active yet

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(rects, hasLength(1));
      expect(rects.single.top, closeTo(tester.getRect(find.text('t2')).top, 1));
    });
  });

  group('per-step barrierInteraction override', () {
    testWidgets('a step can opt out of a tour that advances on barrier taps', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildBarrierApp(k1, k2, step1Barrier: BarrierInteraction.none));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 0); // step 1 overrode the tour-wide `.next`

      // Step 2 has no override, so the tour-wide `.next` still applies there.
      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.isShowcaseRunning, isFalse); // advanced past the last step
    });

    testWidgets('a step can dismiss the tour inside a `.next` tour', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildBarrierApp(k1, k2, step1Barrier: BarrierInteraction.dismiss));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // reverse animation
      await tester.pump(const Duration(milliseconds: 400)); // overlay teardown

      expect(state.isShowcaseRunning, isFalse);
    });

    testWidgets('the override wins over legacy disableBarrierInteraction', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(
        buildBarrierApp(k1, k2, disableBarrierInteraction: true, step1Barrier: BarrierInteraction.next),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.currentIndex, 1);
    });

    testWidgets('onBarrierClick still fires when a step overrides to none', (tester) async {
      var clicks = 0;
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(
        buildBarrierApp(k1, k2, step1Barrier: BarrierInteraction.none, onBarrierClick: () => clicks++),
      );

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(clicks, 1);
      expect(state.currentIndex, 0); // …but the step's `.none` did not advance
    });
  });

  group('pointer cursor (web / desktop)', () {
    // Starts a one-step tour and returns the cursor resolved while a mouse
    // hovers [hover] (defaults to the target).
    Future<MouseCursor?> cursorOver(
      WidgetTester tester, {
      required Widget app,
      required GlobalKey key,
      Finder? hover,
    }) async {
      await tester.pumpWidget(app);
      ShowCaseWidget.of(tester.element(find.text('t'))).startShowCase([key]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(hover ?? find.text('t')));
      await tester.pump();
      return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
    }

    Widget buildCursorApp(
      GlobalKey key, {
      bool enablePointerCursor = true,
      bool disableDefaultTargetGestures = false,
      bool showSkip = false,
      MouseCursor? targetMouseCursor,
      MouseCursor? tooltipMouseCursor,
      VoidCallback? onToolTipClick,
    }) {
      return MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          enablePointerCursor: enablePointerCursor,
          showSkip: showSkip,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Showcase(
                  key: key,
                  title: 'T',
                  description: 'Body',
                  disableDefaultTargetGestures: disableDefaultTargetGestures,
                  targetMouseCursor: targetMouseCursor,
                  tooltipMouseCursor: tooltipMouseCursor,
                  onToolTipClick: onToolTipClick,
                  child: const SizedBox(width: 40, height: 40, child: Text('t')),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the highlighted target shows a click cursor', (tester) async {
      final key = GlobalKey();
      expect(await cursorOver(tester, app: buildCursorApp(key), key: key), SystemMouseCursors.click);
    });

    testWidgets('enablePointerCursor:false leaves the target cursor alone', (tester) async {
      final key = GlobalKey();
      expect(
        await cursorOver(tester, app: buildCursorApp(key, enablePointerCursor: false), key: key),
        SystemMouseCursors.basic,
      );
    });

    testWidgets('an inert target (disableDefaultTargetGestures) gets no click '
        'cursor', (tester) async {
      final key = GlobalKey();
      expect(
        await cursorOver(tester, app: buildCursorApp(key, disableDefaultTargetGestures: true), key: key),
        SystemMouseCursors.basic,
      );
    });

    testWidgets('a per-step targetMouseCursor wins, even with the tour-wide '
        'switch off', (tester) async {
      final key = GlobalKey();
      expect(
        await cursorOver(
          tester,
          app: buildCursorApp(key, enablePointerCursor: false, targetMouseCursor: SystemMouseCursors.forbidden),
          key: key,
        ),
        SystemMouseCursors.forbidden,
      );
    });

    testWidgets('a tooltip that does nothing on tap gets no click cursor', (tester) async {
      final key = GlobalKey();
      expect(
        await cursorOver(tester, app: buildCursorApp(key), key: key, hover: find.text('Body')),
        SystemMouseCursors.basic,
      );
    });

    testWidgets('a tooltip with onToolTipClick shows a click cursor', (tester) async {
      final key = GlobalKey();
      expect(
        await cursorOver(
          tester,
          app: buildCursorApp(key, onToolTipClick: () {}),
          key: key,
          hover: find.text('Body'),
        ),
        SystemMouseCursors.click,
      );
    });

    testWidgets('a per-step tooltipMouseCursor overrides the resolved one', (tester) async {
      final key = GlobalKey();
      expect(
        await cursorOver(
          tester,
          app: buildCursorApp(key, tooltipMouseCursor: SystemMouseCursors.help),
          key: key,
          hover: find.text('Body'),
        ),
        SystemMouseCursors.help,
      );
    });

    testWidgets('the built-in Skip button shows a click cursor', (tester) async {
      final key = GlobalKey();
      expect(
        await cursorOver(tester, app: buildCursorApp(key, showSkip: true), key: key, hover: find.text('Skip')),
        SystemMouseCursors.click,
      );
    });
  });

  group('animated step transitions', () {
    // The cut-out the overlay is currently painting, read off the clipper.
    Rect cutOut(WidgetTester tester) {
      final clipPath = tester.widget<ClipPath>(find.byType(ClipPath).first);
      return (clipPath.clipper! as RRectClipper).area;
    }

    void expectRect(Rect actual, Rect expected) {
      expect(actual.left, closeTo(expected.left, 0.5));
      expect(actual.top, closeTo(expected.top, 0.5));
      expect(actual.width, closeTo(expected.width, 0.5));
      expect(actual.height, closeTo(expected.height, 0.5));
    }

    // Two targets far apart, so a glide between them is unmistakable.
    Widget buildTransitionApp(GlobalKey k1, GlobalKey k2, {bool enableStepTransition = true}) {
      return MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          enableStepTransition: enableStepTransition,
          stepTransitionDuration: const Duration(milliseconds: 300),
          // Linear keeps the midpoint of the glide predictable.
          stepTransitionCurve: Curves.linear,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 40,
                    left: 20,
                    child: Showcase(
                      key: k1,
                      description: 'One',
                      child: const SizedBox(width: 50, height: 50, child: Text('t1')),
                    ),
                  ),
                  Positioned(
                    top: 400,
                    left: 220,
                    child: Showcase(
                      key: k2,
                      description: 'Two',
                      child: const SizedBox(width: 50, height: 50, child: Text('t2')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the cut-out glides from the previous target to the next one', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildTransitionApp(k1, k2));
      final r1 = tester.getRect(find.byKey(k1));
      final r2 = tester.getRect(find.byKey(k2));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expectRect(cutOut(tester), r1);

      state.next();
      await tester.pump(); // switch steps; the glide starts
      await tester.pump(const Duration(milliseconds: 100)); // ~1/3 through

      // Partway between the two targets: past the first, short of the second.
      final mid = cutOut(tester);
      expect(mid.top, greaterThan(r1.top));
      expect(mid.top, lessThan(r2.top));
      expect(mid.left, greaterThan(r1.left));
      expect(mid.left, lessThan(r2.left));

      await tester.pumpAndSettle();
      expectRect(cutOut(tester), r2);
    });

    testWidgets('the first step of a tour appears instead of gliding', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildTransitionApp(k1, k2));
      final r1 = tester.getRect(find.byKey(k1));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16)); // one frame in
      expectRect(cutOut(tester), r1); // already at the target, not gliding
    });

    testWidgets('transitions are off by default (the cut-out jumps)', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildTransitionApp(k1, k2, enableStepTransition: false));
      final r2 = tester.getRect(find.byKey(k2));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expectRect(cutOut(tester), r2); // straight to the new target
      expect(state.previousTargetRect, isNull); // not tracked when disabled
    });

    testWidgets('reduce-motion skips the glide', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildTransitionApp(k1, k2));
      final r2 = tester.getRect(find.byKey(k2));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      state.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expectRect(cutOut(tester), r2); // jumped despite the tour opting in
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('previousTargetRect reports the step the tour just left', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildTransitionApp(k1, k2));
      final r1 = tester.getRect(find.byKey(k1));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.previousTargetRect, isNull); // nothing left yet

      state.next();
      await tester.pumpAndSettle();
      expectRect(state.previousTargetRect!, r1);

      state.dismiss();
      await tester.pumpAndSettle();
      expect(state.previousTargetRect, isNull); // cleared with the tour
    });

    testWidgets('going back a step glides too', (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      await tester.pumpWidget(buildTransitionApp(k1, k2));
      final r1 = tester.getRect(find.byKey(k1));
      final r2 = tester.getRect(find.byKey(k2));

      final state = ShowCaseWidget.of(tester.element(find.text('t1')));
      state.startShowCase([k1, k2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      state.next();
      await tester.pumpAndSettle();

      state.previous();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Heading back up-left, still short of the first target.
      final mid = cutOut(tester);
      expect(mid.top, lessThan(r2.top));
      expect(mid.top, greaterThan(r1.top));

      await tester.pumpAndSettle();
      expectRect(cutOut(tester), r1);
    });
  });

  group('enableShowcase toggled at runtime', () {
    // A tour of [stepCount] steps whose enableShowcase can be flipped from the
    // returned setter.
    Widget togglableTour({
      required List<GlobalKey> keys,
      required void Function(ValueSetter<bool>) exposeSetter,
      void Function(GlobalKey?)? onDismiss,
      VoidCallback? onFinish,
      VoidCallback? onStepDismiss,
    }) {
      var enabled = true;
      return MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            exposeSetter((value) => setState(() => enabled = value));
            return ShowCaseWidget(
              enableShowcase: enabled,
              onDismiss: onDismiss,
              onFinish: onFinish,
              disableMovingAnimation: true,
              disableScaleAnimation: true,
              builder: Builder(
                builder: (inner) => Scaffold(
                  body: Column(
                    children: [
                      for (final key in keys)
                        Showcase(
                          key: key,
                          title: 'Step',
                          description: 'd',
                          onDismiss: onStepDismiss,
                          child: const SizedBox(height: 20, width: 100, child: Text('t')),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    testWidgets('disabling mid-tour hides the showcase and ends the tour', (tester) async {
      final keys = List.generate(3, (_) => GlobalKey());
      late ValueSetter<bool> setEnabled;
      GlobalKey? dismissedAt;
      var finished = 0;
      var stepDismissals = 0;

      await tester.pumpWidget(
        togglableTour(
          keys: keys,
          exposeSetter: (setter) => setEnabled = setter,
          onDismiss: (key) => dismissedAt = key,
          onFinish: () => finished++,
          onStepDismiss: () => stepDismissals++,
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();
      ShowCaseWidget.of(context).next();
      await tester.pumpAndSettle();
      expect(find.text('Step'), findsOneWidget);

      // Step 0 was already dismissed by the next() above; count from here so
      // this asserts the teardown of the step that was actually showing.
      final dismissalsBefore = stepDismissals;

      setEnabled(false);
      await tester.pumpAndSettle();

      // The overlay is gone...
      expect(find.text('Step'), findsNothing);
      // ...the step it was on was torn down properly...
      expect(stepDismissals, dismissalsBefore + 1);
      // ...and the tour reports where it was left, exactly once, through the
      // early-close callback rather than the completion one.
      expect(dismissedAt, same(keys[1]));
      expect(finished, 0);
    });

    testWidgets('the child still renders while the tour is disabled', (tester) async {
      final keys = List.generate(2, (_) => GlobalKey());
      late ValueSetter<bool> setEnabled;

      await tester.pumpWidget(togglableTour(keys: keys, exposeSetter: (setter) => setEnabled = setter));
      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();

      setEnabled(false);
      await tester.pumpAndSettle();

      // "every Showcase just renders its child, no overlay"
      expect(find.text('t'), findsNWidgets(keys.length));
    });

    testWidgets('re-enabling leaves no stale overlay and a new tour can start', (tester) async {
      final keys = List.generate(3, (_) => GlobalKey());
      late ValueSetter<bool> setEnabled;

      await tester.pumpWidget(togglableTour(keys: keys, exposeSetter: (setter) => setEnabled = setter));
      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();

      setEnabled(false);
      await tester.pumpAndSettle();
      setEnabled(true);
      await tester.pumpAndSettle();

      // Re-enabling on its own must not bring the dismissed tour back.
      expect(find.text('Step'), findsNothing);

      // And the tour is startable again, from the top.
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();
      expect(find.text('Step'), findsOneWidget);
      expect(ShowCaseWidget.of(context).currentIndex, 0);
    });

    testWidgets('startShowCase still refuses to run while disabled', (tester) async {
      final keys = List.generate(2, (_) => GlobalKey());
      late ValueSetter<bool> setEnabled;

      await tester.pumpWidget(togglableTour(keys: keys, exposeSetter: (setter) => setEnabled = setter));
      setEnabled(false);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      expect(() => ShowCaseWidget.of(context).startShowCase(keys), throwsException);
    });
  });

  group('tour-wide action buttons', () {
    const globalKeyed = ValueKey('global-actions');
    const perStepKeyed = ValueKey('per-step-actions');

    Widget tour({
      required List<GlobalKey> keys,
      WidgetBuilder? globalActions,
      ActionsSettings? globalActionSettings,
      List<GlobalKey> hideActionsForShowcase = const [],
      TooltipActionPosition actionsPosition = TooltipActionPosition.outside,
      Widget? stepZeroActions,
      TooltipActionPosition? stepZeroActionsPosition,
    }) {
      return MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          globalActions: globalActions,
          globalActionSettings: globalActionSettings,
          hideActionsForShowcase: hideActionsForShowcase,
          actionsPosition: actionsPosition,
          builder: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  for (var i = 0; i < keys.length; i++)
                    Showcase(
                      key: keys[i],
                      title: 'Step $i',
                      description: 'd',
                      actions: i == 0 ? stepZeroActions : null,
                      actionsPosition: i == 0 ? stepZeroActionsPosition : null,
                      child: const SizedBox(height: 20, width: 100, child: Text('t')),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('globalActions show on a step that declares none of its own', (tester) async {
      final keys = List.generate(2, (_) => GlobalKey());
      await tester.pumpWidget(
        tour(
          keys: keys,
          globalActions: (_) => const SizedBox(key: globalKeyed, height: 20),
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();

      expect(find.byKey(globalKeyed), findsOneWidget);

      // ...and on the next step too, without repeating `actions:` per step.
      ShowCaseWidget.of(context).next();
      await tester.pumpAndSettle();
      expect(find.byKey(globalKeyed), findsOneWidget);
    });

    testWidgets('a per-step actions widget wins over globalActions', (tester) async {
      final keys = List.generate(2, (_) => GlobalKey());
      await tester.pumpWidget(
        tour(
          keys: keys,
          globalActions: (_) => const SizedBox(key: globalKeyed, height: 20),
          stepZeroActions: const SizedBox(key: perStepKeyed, height: 20),
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();

      expect(find.byKey(perStepKeyed), findsOneWidget);
      expect(find.byKey(globalKeyed), findsNothing);
    });

    testWidgets('hideActionsForShowcase suppresses the global actions on that step only', (tester) async {
      final keys = List.generate(2, (_) => GlobalKey());
      await tester.pumpWidget(
        tour(
          keys: keys,
          globalActions: (_) => const SizedBox(key: globalKeyed, height: 20),
          hideActionsForShowcase: [keys.first],
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();
      expect(find.byKey(globalKeyed), findsNothing, reason: 'hidden on the first step');

      ShowCaseWidget.of(context).next();
      await tester.pumpAndSettle();
      expect(find.byKey(globalKeyed), findsOneWidget, reason: 'still shown on the others');
    });

    testWidgets('inside placement puts the actions in the tooltip box; outside does not', (tester) async {
      final keys = List.generate(1, (_) => GlobalKey());

      // The tooltip box is the ClipRRect the title lives in. Actions placed
      // outside are a sibling of it in the Stack, so they have no such ancestor.
      Finder insideTheBox() => find.ancestor(of: find.byKey(globalKeyed), matching: find.byType(ClipRRect));

      await tester.pumpWidget(
        tour(
          keys: keys,
          globalActions: (_) => const SizedBox(key: globalKeyed, height: 20),
        ),
      );
      var context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();
      expect(insideTheBox(), findsNothing, reason: 'outside is the default');

      await tester.pumpWidget(
        tour(
          keys: keys,
          globalActions: (_) => const SizedBox(key: globalKeyed, height: 20),
          actionsPosition: TooltipActionPosition.inside,
        ),
      );
      context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();
      expect(insideTheBox(), findsWidgets, reason: 'inside draws within the tooltip box');
    });

    testWidgets('outside actions stay on screen for a target near the top edge', (tester) async {
      // A tooltip above its target puts the action row above the tooltip, which
      // runs off the top of the screen when the target is near it: the buttons
      // draw over the status bar, clipped. Found by running the example on a
      // device, where every step gets the tour-wide actions.
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            globalActions: (_) => const SizedBox(key: globalKeyed, height: 20, width: 80),
            builder: Builder(
              builder: (context) => Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: Showcase(
                    key: key,
                    title: 'Top',
                    description: 'd',
                    tooltipPosition: TooltipPosition.top,
                    child: const SizedBox(height: 20, width: 100, child: Text('t')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase([key]);
      await tester.pumpAndSettle();

      expect(find.byKey(globalKeyed), findsOneWidget);

      final actions = tester.getRect(find.byKey(globalKeyed));
      final tooltip = tester.getRect(find.text('Top'));

      // On screen...
      expect(actions.top, greaterThanOrEqualTo(0));
      expect(actions.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
      // ...and not on top of the tooltip. Clamping alone would satisfy the
      // first check by pushing the buttons over the tooltip's own text.
      expect(actions.overlaps(tooltip), isFalse);
    });

    testWidgets('a left/right step with inside actions stays on screen', (tester) async {
      // Left/right placement has its own layout path, which was skipped
      // whenever a step had actions -- the step fell back to the vertical
      // layout, which positions the tooltip from the target with no top clamp
      // and puts it off screen for a target near the top edge. Inside actions
      // are part of the tooltip box the horizontal path already builds, so they
      // must not trigger that fallback. Without the fix the title renders at
      // top: -158.
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            showProgress: true,
            showSkip: true,
            globalActions: (_) => const SizedBox(key: globalKeyed, height: 20, width: 200),
            actionsPosition: TooltipActionPosition.inside,
            builder: Builder(
              builder: (context) => Scaffold(
                body: Align(
                  alignment: Alignment.topRight,
                  child: Showcase(
                    key: key,
                    title: 'Title',
                    description: 'beside the target',
                    tooltipPosition: TooltipPosition.left,
                    child: const SizedBox(height: 60, width: 60, child: Text('t')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase([key]);
      await tester.pumpAndSettle();

      final parts = {
        'title': find.text('Title'),
        'description': find.text('beside the target'),
        'actions': find.byKey(globalKeyed),
      };
      for (final part in parts.entries) {
        expect(tester.getRect(part.value).top, greaterThanOrEqualTo(0), reason: '${part.key} is off screen');
      }
    });

    testWidgets('a per-step actionsPosition overrides the tour-wide one', (tester) async {
      final keys = List.generate(1, (_) => GlobalKey());
      await tester.pumpWidget(
        tour(
          keys: keys,
          globalActions: (_) => const SizedBox(key: globalKeyed, height: 20),
          stepZeroActionsPosition: TooltipActionPosition.inside,
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      ShowCaseWidget.of(context).startShowCase(keys);
      await tester.pumpAndSettle();

      expect(find.ancestor(of: find.byKey(globalKeyed), matching: find.byType(ClipRRect)), findsWidgets);
    });
  });

  testWidgets('a tap anywhere on the target reaches onTargetClick, not just right of and below its centre', (
    tester,
  ) async {
    final key = GlobalKey();
    var targetClicks = 0;
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(
            builder: (ctx) {
              context = ctx;
              return Scaffold(
                body: Center(
                  child: Showcase(
                    key: key,
                    description: 'd',
                    disposeOnTap: false,
                    onTargetClick: () => targetClicks++,
                    child: const SizedBox(key: ValueKey('target'), width: 48, height: 48),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    ShowCaseWidget.of(context).startShowCase([key]);
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byKey(const ValueKey('target')));
    // One tap in each quarter of the target. The tap area used to be checked
    // against its box before the box was shifted onto the target, so only the
    // bottom-right quarter registered.
    for (final corner in const [Offset(-16, -16), Offset(16, -16), Offset(-16, 16), Offset(16, 16)]) {
      await tester.tapAt(center + corner);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(targetClicks, 4);
  });

  group('tours across screens', () {
    // ShowCaseWidget sits above the Navigator (MaterialApp.builder), so one
    // tour can reach steps on every page.
    late GlobalKey<NavigatorState> navigator;
    late GlobalKey homeStep;
    late GlobalKey homeStep2;
    late GlobalKey detailsStep;
    late BuildContext homeContext;
    late int homeShown;
    late int homeLeft;

    setUp(() {
      navigator = GlobalKey<NavigatorState>();
      homeStep = GlobalKey();
      homeStep2 = GlobalKey();
      detailsStep = GlobalKey();
      homeShown = 0;
      homeLeft = 0;
    });

    Widget app({bool autoPlay = false}) {
      return MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) => ShowCaseWidget(
          autoPlay: autoPlay,
          autoPlayDelay: const Duration(seconds: 1),
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(builder: (_) => child!),
        ),
        home: Builder(
          builder: (context) {
            homeContext = context;
            return Scaffold(
              body: Column(
                children: [
                  Showcase(
                    key: homeStep,
                    title: 'Home step',
                    description: 'd',
                    onShow: () => homeShown++,
                    onDismiss: () => homeLeft++,
                    child: const Text('home target'),
                  ),
                  Showcase(key: homeStep2, title: 'Second home step', description: 'd', child: const Text('second')),
                ],
              ),
            );
          },
        ),
      );
    }

    Route<void> detailsRoute() => MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Center(
          child: Showcase(key: detailsStep, title: 'Details step', description: 'd', child: const Text('details')),
        ),
      ),
    );

    ShowCaseWidgetState controller() => ShowCaseWidget.of(homeContext);

    testWidgets('a step on a page that is not open yet shows once the page is pushed', (tester) async {
      await tester.pumpWidget(app());
      controller().startShowCase([homeStep, detailsStep]);
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsOneWidget);

      // The tour waits on the step whose page is not open: nothing shows.
      controller().next();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);
      expect(find.text('Home step'), findsNothing);
      expect(find.text('Details step'), findsNothing);

      navigator.currentState!.push(detailsRoute());
      await tester.pumpAndSettle();
      expect(find.text('Details step'), findsOneWidget);
    });

    testWidgets('a step whose page is animating in waits, then measures the target where it settled', (tester) async {
      var finished = false;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => ShowCaseWidget(
            onFinish: () => finished = true,
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(builder: (_) => child!),
          ),
          home: Builder(
            builder: (context) {
              homeContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      controller().startShowCase([detailsStep]);
      await tester.pump();

      navigator.currentState!.push(detailsRoute());
      // Mid-transition the page, and the target with it, is still moving.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Details step'), findsNothing, reason: 'the step waits for its page to settle');

      await tester.pumpAndSettle();
      expect(find.text('Details step'), findsOneWidget);

      // The tap area sits on the target's settled position: tapping it there
      // advances (here: finishes) the tour.
      await tester.tapAt(tester.getCenter(find.text('details')));
      // The tap waits out the tooltip's closing animation (a plain delay that
      // pumpAndSettle doesn't advance) before completing the step.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(finished, isTrue);
    });

    testWidgets('the README recipe: a target tap advances the tour and opens the next page', (tester) async {
      final menuStep = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => ShowCaseWidget(
            disableMovingAnimation: true,
            disableScaleAnimation: true,
            builder: Builder(builder: (_) => child!),
          ),
          home: Builder(
            builder: (context) {
              homeContext = context;
              return Scaffold(
                body: Center(
                  child: Showcase(
                    key: menuStep,
                    title: 'Open settings',
                    description: 'd',
                    disposeOnTap: false,
                    onTargetClick: () {
                      ShowCaseWidget.of(context).next();
                      Navigator.of(context).push(detailsRoute());
                    },
                    child: const Text('settings button'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      controller().startShowCase([menuStep, detailsStep]);
      await tester.pumpAndSettle();
      expect(find.text('Open settings'), findsOneWidget);

      // The target sits under the overlay's cut-out; tap it there.
      await tester.tapAt(tester.getCenter(find.text('settings button')));
      await tester.pumpAndSettle();
      expect(find.text('Open settings'), findsNothing);
      expect(find.text('Details step'), findsOneWidget);
      expect(controller().currentIndex, 1);
    });

    testWidgets('an active step hides while another page covers it, and comes back on pop', (tester) async {
      await tester.pumpWidget(app());
      controller().startShowCase([homeStep, detailsStep]);
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsOneWidget);
      expect(homeShown, 1);

      // The home page stays mounted under the new one, but its step must not
      // paint, or take taps, over it.
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('other page'))));
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsNothing);
      expect(find.text('other page').hitTestable(), findsOneWidget);
      expect(controller().currentIndex, 0, reason: 'covering the step does not move the tour');
      expect(homeLeft, 1);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsOneWidget);
      expect(homeShown, 2);
      expect(controller().currentIndex, 0);
    });

    testWidgets('a dialog over the page hides the step until it closes', (tester) async {
      await tester.pumpWidget(app());
      controller().startShowCase([homeStep]);
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsOneWidget);

      showDialog<void>(
        context: homeContext,
        builder: (_) => const AlertDialog(content: Text('a dialog')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsNothing);
      expect(find.text('a dialog').hitTestable(), findsOneWidget);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsOneWidget);
    });

    testWidgets('auto-play does not advance the tour behind a covering page', (tester) async {
      await tester.pumpWidget(app(autoPlay: true));
      controller().startShowCase([homeStep, homeStep2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Home step'), findsOneWidget);

      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('other page'))));
      await tester.pumpAndSettle();
      // Well past the 1s auto-play delay.
      await tester.pump(const Duration(seconds: 3));
      expect(controller().currentIndex, 0);

      // Back on the page, the step shows again and auto-play resumes from it.
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home step'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);
      expect(find.text('Second home step'), findsOneWidget);
    });
  });

  group('per-step unmounted skip (onShouldSkipUnmountedStep)', () {
    // A tour across two pages that also has a step whose widget is never
    // built (a hidden banner). The details step must be waited for, the banner
    // step skipped.
    late GlobalKey<NavigatorState> navigator;
    late GlobalKey homeStep;
    late GlobalKey homeStep2;
    late GlobalKey bannerStep; // never attached to the tree
    late GlobalKey detailsStep;
    late BuildContext homeContext;
    late List<GlobalKey> asked;
    late bool finished;

    setUp(() {
      navigator = GlobalKey<NavigatorState>();
      homeStep = GlobalKey();
      homeStep2 = GlobalKey();
      bannerStep = GlobalKey();
      detailsStep = GlobalKey();
      asked = [];
      finished = false;
    });

    // Waits for the details page and skips any other unmounted step.
    bool waitForDetails(int index, GlobalKey key) {
      asked.add(key);
      return key != detailsStep;
    }

    Widget app({
      bool Function(int index, GlobalKey key)? onShouldSkipUnmountedStep,
      bool autoSkipUnmountedSteps = false,
      GlobalKey? Function(int currentIndex, GlobalKey currentKey)? onResolveNextStep,
    }) {
      return MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) => ShowCaseWidget(
          onShouldSkipUnmountedStep: onShouldSkipUnmountedStep,
          autoSkipUnmountedSteps: autoSkipUnmountedSteps,
          onResolveNextStep: onResolveNextStep,
          onFinish: () => finished = true,
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: Builder(builder: (_) => child!),
        ),
        home: Builder(
          builder: (context) {
            homeContext = context;
            return Scaffold(
              body: Column(
                children: [
                  Showcase(key: homeStep, title: 'Home step', description: 'd', child: const Text('home')),
                  Showcase(key: homeStep2, title: 'Second home step', description: 'd', child: const Text('home 2')),
                ],
              ),
            );
          },
        ),
      );
    }

    Route<void> detailsRoute() => MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Center(
          child: Showcase(key: detailsStep, title: 'Details step', description: 'd', child: const Text('details')),
        ),
      ),
    );

    ShowCaseWidgetState controller() => ShowCaseWidget.of(homeContext);

    testWidgets('a mixed tour skips a step that never mounts and waits for a page pushed later', (tester) async {
      await tester.pumpWidget(app(onShouldSkipUnmountedStep: waitForDetails));
      controller().startShowCase([homeStep, bannerStep, detailsStep, homeStep2]);
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 0);
      expect(find.text('Home step'), findsOneWidget);
      expect(asked, isEmpty, reason: 'a mounted step is never asked about');

      // Next skips the banner and stops on the details step, which waits.
      controller().next();
      await tester.pumpAndSettle();
      expect(asked, [bannerStep, detailsStep]);
      expect(controller().currentIndex, 2);
      expect(find.text('Home step'), findsNothing);
      expect(find.text('Details step'), findsNothing);

      navigator.currentState!.push(detailsRoute());
      await tester.pumpAndSettle();
      expect(find.text('Details step'), findsOneWidget);

      // Back on home, the last step shows and finishing it ends the tour.
      controller().next();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 3);
      expect(find.text('Second home step'), findsOneWidget);

      controller().next();
      await tester.pumpAndSettle();
      expect(finished, isTrue);
      expect(controller().isShowcaseRunning, isFalse);
    });

    testWidgets('previous() skips a skipped step and lands on a waited-for one', (tester) async {
      await tester.pumpWidget(app(onShouldSkipUnmountedStep: waitForDetails));
      controller().startShowCase([detailsStep, homeStep, bannerStep, homeStep2]);
      await tester.pumpAndSettle();
      // The first step waits for its page.
      expect(controller().currentIndex, 0);

      controller().goTo(3);
      await tester.pumpAndSettle();
      expect(find.text('Second home step'), findsOneWidget);

      // Going back skips the banner...
      controller().previous();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);
      expect(find.text('Home step'), findsOneWidget);

      // ...but stops on the details step, whose page isn't open yet.
      controller().previous();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 0);
      expect(find.text('Home step'), findsNothing);

      navigator.currentState!.push(detailsRoute());
      await tester.pumpAndSettle();
      expect(find.text('Details step'), findsOneWidget);
    });

    testWidgets('previous() stays put when every earlier step is skipped', (tester) async {
      await tester.pumpWidget(app(onShouldSkipUnmountedStep: (_, _) => true));
      // The banner before the home step is skipped, so the tour opens on 1.
      controller().startShowCase([bannerStep, homeStep]);
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);

      // Every step before it is skipped too: previous() leaves the tour where
      // it is instead of walking off the start.
      controller().previous();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);
      expect(find.text('Home step'), findsOneWidget);
      expect(controller().isShowcaseRunning, isTrue);
    });

    testWidgets('previous() walks back past a skipped step to the first one', (tester) async {
      await tester.pumpWidget(app(onShouldSkipUnmountedStep: (_, _) => true));
      controller().startShowCase([homeStep, bannerStep, homeStep2]);
      await tester.pumpAndSettle();
      controller().next();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 2);

      controller().previous();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 0);

      // Nothing before the first step: previous() does nothing.
      controller().previous();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 0);
      expect(find.text('Home step'), findsOneWidget);
    });

    testWidgets('starting on an unmounted first step skips it or waits, per step', (tester) async {
      await tester.pumpWidget(app(onShouldSkipUnmountedStep: waitForDetails));

      // Skipped: the tour opens on the next step.
      controller().startShowCase([bannerStep, homeStep]);
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);
      expect(find.text('Home step'), findsOneWidget);

      // Waited for: the tour sits on it until its page opens.
      controller().startShowCase([detailsStep, homeStep]);
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 0);
      expect(find.text('Home step'), findsNothing);

      navigator.currentState!.push(detailsRoute());
      await tester.pumpAndSettle();
      expect(find.text('Details step'), findsOneWidget);
    });

    testWidgets('a tour whose steps are all skipped finishes at once', (tester) async {
      await tester.pumpWidget(app(onShouldSkipUnmountedStep: waitForDetails));
      controller().startShowCase([bannerStep]);
      await tester.pumpAndSettle();
      expect(finished, isTrue);
      expect(controller().isShowcaseRunning, isFalse);
    });

    testWidgets('the predicate overrides autoSkipUnmountedSteps in both directions', (tester) async {
      // autoSkipUnmountedSteps would skip the details step; the predicate waits.
      await tester.pumpWidget(app(autoSkipUnmountedSteps: true, onShouldSkipUnmountedStep: waitForDetails));
      controller().startShowCase([homeStep, detailsStep]);
      await tester.pumpAndSettle();
      controller().next();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);
      expect(finished, isFalse);

      // With the flag off, the predicate still skips.
      await tester.pumpWidget(app(onShouldSkipUnmountedStep: (_, _) => true));
      controller().startShowCase([homeStep, bannerStep, homeStep2]);
      await tester.pumpAndSettle();
      controller().next();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 2);
    });

    testWidgets('without the predicate, autoSkipUnmountedSteps still applies to every step', (tester) async {
      await tester.pumpWidget(app(autoSkipUnmountedSteps: true));
      controller().startShowCase([bannerStep, homeStep, detailsStep, homeStep2]);
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);

      // The details step is skipped too: the flag can't tell it apart.
      controller().next();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 3);

      // And with neither set, the tour waits on every unmounted step.
      await tester.pumpWidget(app());
      controller().startShowCase([bannerStep, homeStep]);
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 0);
      expect(find.text('Home step'), findsNothing);
    });

    testWidgets('explicit jumps ignore the predicate', (tester) async {
      await tester.pumpWidget(
        app(
          onShouldSkipUnmountedStep: waitForDetails,
          onResolveNextStep: (index, key) => key == homeStep ? bannerStep : null,
        ),
      );
      controller().startShowCase([homeStep, bannerStep, homeStep2]);
      await tester.pumpAndSettle();

      // onResolveNextStep jumps onto the banner even though it would be skipped.
      controller().next();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);

      controller().goTo(0);
      await tester.pumpAndSettle();
      controller().goToKey(bannerStep);
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 1);
      expect(asked, isEmpty);

      // Moving on from the banner is a normal step forward again.
      controller().next();
      await tester.pumpAndSettle();
      expect(controller().currentIndex, 2);
      expect(find.text('Second home step'), findsOneWidget);
    });
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

/// Rebuilds its subtree on demand, standing in for an ordinary ancestor
/// `setState` in the app the showcase runs in.
class _RebuildHost extends StatefulWidget {
  const _RebuildHost({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<_RebuildHost> createState() => _RebuildHostState();
}

class _RebuildHostState extends State<_RebuildHost> {
  /// Rebuilds the subtree, reconstructing the Showcase widgets in it.
  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// A child with State, used to prove a showcased widget is not rebuilt from
/// scratch when its step opens or closes.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int value = 0;

  void bump() => setState(() => value++);

  @override
  Widget build(BuildContext context) => Text('$value');
}
