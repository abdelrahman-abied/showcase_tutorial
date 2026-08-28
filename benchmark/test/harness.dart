// One measurement routine, driven by both packages, so neither can benefit
// from differently-written benchmark code.
//
// Both packages defer part of a step change to a post-frame callback, so every
// timed region spans [_settleFrames] frames -- enough for the deferred work to
// land -- rather than a single pump. Timings therefore include ALL the work a
// step change costs, whichever frame it happens on.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A step change is measured over a fixed wall-clock window, identical for
/// both packages, long enough for the slower one to finish: showcaseview
/// awaits a 300ms reverse scale animation before the next step appears, while
/// showcase_tutorial swaps on the next frame. 30 frames = 480ms covers both,
/// so the two numbers describe the same amount of elapsed time.
const int _windowFrames = 30;
const Duration _frame = Duration(milliseconds: 16);

abstract class Driver {
  String get name;
  Future<void> pump(WidgetTester tester, List<GlobalKey> keys);
  void start(List<GlobalKey> keys);
  void next();
  void dismiss();
  void teardown() {}
}

Future<int> countRebuilds(Future<void> Function() action) async {
  var count = 0;
  final saved = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && (message.startsWith('Rebuilding ') || message.startsWith('Building '))) {
      count++;
    }
  };
  debugPrintRebuildDirtyWidgets = true;
  await action();
  debugPrintRebuildDirtyWidgets = false;
  debugPrint = saved;
  return count;
}

int _overlayEntries(WidgetTester tester) =>
    tester.allElements.where((e) => e.widget.runtimeType.toString() == '_OverlayEntryWidget').length;

double _median(List<int> xs) {
  final s = [...xs]..sort();
  return s.length.isOdd ? s[s.length ~/ 2].toDouble() : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < _windowFrames; i++) {
    await tester.pump(_frame);
  }
}

/// Index of the step whose tooltip is currently on screen, or -1.
int visibleStep() {
  for (var i = 0; i < 60; i++) {
    if (find.text('Step $i').evaluate().isNotEmpty) return i;
  }
  return -1;
}

/// Restarts the tour if it has ended or is on its last step, so a measured
/// `next()` always has somewhere to go. Runs OUTSIDE every timed region.
Future<void> _rewindIfNeeded(WidgetTester tester, Driver driver, List<GlobalKey> keys) async {
  final step = visibleStep();
  if (step >= 0 && step < keys.length - 1) return;
  driver.dismiss();
  await tester.pumpAndSettle();
  driver.start(keys);
  await _settle(tester);
}

/// Frames until [expected] becomes the visible step (-1 if it never does).
Future<int> _framesUntilStep(WidgetTester tester, int expected) async {
  for (var f = 1; f <= _windowFrames; f++) {
    await tester.pump(_frame);
    if (visibleStep() == expected) return f;
  }
  return -1;
}

Future<Map<String, Object>> runBenchmark(WidgetTester tester, Driver driver, List<GlobalKey> keys) async {
  final out = <String, Object>{};

  // RSS is measured in a dedicated isolate per package, with identical harness
  // code either side, so the DELTA is comparable even though the absolute
  // figure is dominated by the test framework.
  final rssBefore = ProcessInfo.currentRss;
  await driver.pump(tester, keys);
  await tester.pumpAndSettle();
  out['rss_scene_kb'] = (ProcessInfo.currentRss - rssBefore) ~/ 1024;

  final idleEntries = _overlayEntries(tester);
  out['idle_elements'] = tester.allElements.length;
  out['idle_render_objects'] = tester.allRenderObjects.length;
  out['idle_overlay_entries'] = idleEntries;

  // ---------------- WARM-UP: run whole tours so the JIT has compiled every
  // path before a single number is recorded.
  for (var round = 0; round < 2; round++) {
    driver.start(keys);
    await _settle(tester);
    for (var i = 0; i < 20; i++) {
      await _rewindIfNeeded(tester, driver, keys);
      driver.next();
      await _settle(tester);
    }
    driver.dismiss();
    await tester.pumpAndSettle();
  }

  // ---------------- LATENCY: frames until a step change is actually on screen
  driver.start(keys);
  await _settle(tester);
  final latencies = <int>[];
  for (var i = 0; i < 5; i++) {
    await _rewindIfNeeded(tester, driver, keys);
    final target = visibleStep() + 1;
    driver.next();
    latencies.add(await _framesUntilStep(tester, target));
    await _settle(tester);
  }
  out['step_latency_frames_median'] = _median(latencies);
  out['SANITY_step_advanced'] = !latencies.contains(-1);
  driver.dismiss();
  await tester.pumpAndSettle();

  // ---------------- OPENING THE TOUR (fixed window)
  final startTimes = <int>[];
  final startRebuilds = <int>[];
  for (var trial = 0; trial < 7; trial++) {
    late int elapsed;
    final rebuilds = await countRebuilds(() async {
      final w = Stopwatch()..start();
      driver.start(keys);
      await _settle(tester);
      w.stop();
      elapsed = w.elapsedMicroseconds;
    });
    startTimes.add(elapsed);
    startRebuilds.add(rebuilds);
    if (trial == 0) {
      out['active_overlay_entries'] = _overlayEntries(tester);
      out['active_elements'] = tester.allElements.length;
      out['SANITY_tooltip_visible'] = visibleStep() == 0;
    }
    driver.dismiss();
    await tester.pumpAndSettle();
  }
  out['rss_running_kb'] = (ProcessInfo.currentRss - rssBefore) ~/ 1024;
  out['start_us_median'] = _median(startTimes);
  out['start_rebuilds_median'] = _median(startRebuilds);

  // ---------------- A STEP CHANGE (same 30-frame window for both)
  driver.start(keys);
  await _settle(tester);
  final stepTimes = <int>[];
  final stepRebuilds = <int>[];
  for (var i = 0; i < 20; i++) {
    await _rewindIfNeeded(tester, driver, keys);
    late int elapsed;
    final rebuilds = await countRebuilds(() async {
      final w = Stopwatch()..start();
      driver.next();
      await _settle(tester);
      w.stop();
      elapsed = w.elapsedMicroseconds;
    });
    stepTimes.add(elapsed);
    stepRebuilds.add(rebuilds);
  }
  out['step_window_us_median'] = _median(stepTimes);
  out['step_window_rebuilds_median'] = _median(stepRebuilds);
  driver.dismiss();
  await tester.pumpAndSettle();

  // ---------------- STEADY-STATE FRAMES with a step fully open
  final frameTimes = <int>[];
  final frameRebuilds = <int>[];
  for (var trial = 0; trial < 5; trial++) {
    driver.start(keys);
    await _settle(tester);
    for (var i = 0; i < 60; i++) {
      final w = Stopwatch()..start();
      await tester.pump(_frame);
      w.stop();
      frameTimes.add(w.elapsedMicroseconds);
    }
    for (var i = 0; i < 30; i++) {
      frameRebuilds.add(await countRebuilds(() => tester.pump(_frame)));
    }
    driver.dismiss();
    await tester.pumpAndSettle();
  }
  out['frame_us_median'] = _median(frameTimes);
  out['frame_rebuilds_median'] = _median(frameRebuilds);

  driver.teardown();
  return out;
}

void printResults(String name, Map<String, Object> out) {
  // ignore: avoid_print
  print('\n@@BENCH@@ $name');
  for (final e in out.entries) {
    // ignore: avoid_print
    print('@@ ${e.key}=${e.value}');
  }
}
