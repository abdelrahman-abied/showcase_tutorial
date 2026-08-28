// Profile-mode comparative harness: the same scripted tour, driven once by
// showcase_tutorial and once by showcaseview, reporting real frame timings
// including GPU raster time (which the widget-test benchmark cannot see).
//
// Run:
//   flutter run --profile -d macos --dart-define=PKG=ours   --dart-define=N=30
//   flutter run --profile -d macos --dart-define=PKG=theirs --dart-define=N=30
//
// Prints RESULT lines and exits.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart' as ours;
import 'package:showcaseview/showcaseview.dart' as theirs;

import 'scenes.dart';

const String kPackage = String.fromEnvironment('PKG', defaultValue: 'ours');

/// Time between scripted `next()` calls. Comfortably longer than the 300ms
/// reverse animation showcaseview awaits, so both packages complete every step.
const Duration kStepInterval = Duration(milliseconds: 600);

/// How long to sample with a step open and no interaction.
const Duration kSteadySample = Duration(seconds: 5);

final List<FrameTiming> _timings = [];
bool _recording = false;

void _emit(String line) => print(line);

String _report(String label) {
  if (_timings.isEmpty) return 'RESULT $label: no frames';

  int pct(List<int> xs, double p) => xs[(xs.length * p).clamp(0, xs.length - 1).floor()];

  String fmt(List<int> xs) {
    xs.sort();
    return 'p50=${(pct(xs, 0.50) / 1000).toStringAsFixed(2)} '
        'p90=${(pct(xs, 0.90) / 1000).toStringAsFixed(2)} '
        'p99=${(pct(xs, 0.99) / 1000).toStringAsFixed(2)}';
  }

  final build = _timings.map((t) => t.buildDuration.inMicroseconds).toList();
  final raster = _timings.map((t) => t.rasterDuration.inMicroseconds).toList();
  final total = _timings.map((t) => t.totalSpan.inMicroseconds).toList();
  final janky = _timings.where((t) => t.totalSpan.inMilliseconds > 16).length;

  return (StringBuffer()
        ..writeln('RESULT $label frames=${_timings.length} over16ms=$janky')
        ..writeln('  build  ms ${fmt(build)}')
        ..writeln('  raster ms ${fmt(raster)}')
        ..write('  total  ms ${fmt(total)}'))
      .toString();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kPackage == 'theirs') theirs.ShowcaseView.register();
  SchedulerBinding.instance.addTimingsCallback((list) {
    if (_recording) _timings.addAll(list);
  });
  runApp(const _Driver());
}

class _Driver extends StatefulWidget {
  const _Driver();

  @override
  State<_Driver> createState() => _DriverState();
}

class _DriverState extends State<_Driver> {
  final List<GlobalKey> _keys = List.generate(kStepCount, (_) => GlobalKey());
  BuildContext? _ourContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  void _start() {
    if (kPackage == 'ours') {
      ours.ShowCaseWidget.of(_ourContext!).startShowCase(_keys);
    } else {
      theirs.ShowcaseView.get().startShowCase(_keys);
    }
  }

  void _next() {
    if (kPackage == 'ours') {
      ours.ShowCaseWidget.of(_ourContext!).next();
    } else {
      theirs.ShowcaseView.get().next();
    }
  }

  void _dismiss() {
    if (kPackage == 'ours') {
      ours.ShowCaseWidget.of(_ourContext!).dismiss();
    } else {
      theirs.ShowcaseView.get().dismiss();
    }
  }

  /// Walks the whole tour once, one step per [kStepInterval].
  Future<void> _walkTour() async {
    _start();
    await Future<void>.delayed(kStepInterval);
    for (var i = 0; i < kStepCount - 1; i++) {
      _next();
      await Future<void>.delayed(kStepInterval);
    }
    _dismiss();
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // Warm up: one untimed tour so shaders and code paths are hot.
    await _walkTour();

    // Phase A: the whole tour, including every step transition.
    _timings.clear();
    _recording = true;
    await _walkTour();
    _recording = false;
    _emit(_report('$kPackage tour N=$kStepCount'));

    // Phase B: one step open, no interaction.
    _start();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _timings.clear();
    _recording = true;
    await Future<void>.delayed(kSteadySample);
    _recording = false;
    _emit(_report('$kPackage steady N=$kStepCount'));
    _dismiss();

    await Future<void>.delayed(const Duration(milliseconds: 300));
    _emit('BENCH_DONE');
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    if (kPackage == 'ours') {
      return OursScene(keys: _keys, onContext: (c) => _ourContext = c);
    }
    return TheirsScene(keys: _keys);
  }
}
