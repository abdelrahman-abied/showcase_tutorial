// Profile-mode benchmark for the showcase overlay, driving the example's real
// FeaturesDemoPage rather than a synthetic screen.
//
// Run with:
//   flutter run --profile -t lib/perf_harness.dart
//
// It presses the page's own "Start tour" button, walks the whole tour so every
// step type is covered (plain, multi-widget, exact-shape, pulsing, styled), and
// reports frame build/raster percentiles. It samples twice: once on the page as
// it is, and once with an ancestor rebuilding every frame — standing in for a
// screen that also has an animation on it.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

import 'features_demo_page.dart';

const Duration kSample = Duration(seconds: 8);

final List<FrameTiming> _timings = [];
bool _recording = false;

// ignore: avoid_print
void _emit(String line) => print(line);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.addTimingsCallback((list) {
    if (_recording) _timings.addAll(list);
  });
  runApp(const _Driver());
}

String _report(String label) {
  if (_timings.isEmpty) return 'RESULT $label: no frames';
  int pct(List<int> xs, double p) =>
      xs[(xs.length * p).clamp(0, xs.length - 1).floor()];
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

/// Walks the live element tree looking for a widget of type [T].
T? _find<T>(Element root, bool Function(Element) test) {
  T? found;
  void visit(Element e) {
    if (found != null) return;
    if (test(e)) {
      found = e.widget as T;
      return;
    }
    e.visitChildren(visit);
  }

  visit(root);
  return found;
}

ShowCaseWidgetState? _tourState(Element root) {
  ShowCaseWidgetState? found;
  void visit(Element e) {
    if (found != null) return;
    if (e is StatefulElement && e.state is ShowCaseWidgetState) {
      found = e.state as ShowCaseWidgetState;
      return;
    }
    e.visitChildren(visit);
  }

  visit(root);
  return found;
}

class _Driver extends StatefulWidget {
  const _Driver();
  @override
  State<_Driver> createState() => _DriverState();
}

class _DriverState extends State<_Driver> {
  bool _everyFrame = false;
  bool _started = false;

  Future<void> _sample(String label) async {
    final root = WidgetsBinding.instance.rootElement!;

    // Press the page's own "Start tour" button.
    final button = _find<ElevatedButton>(
      root,
      (e) =>
          e.widget is ElevatedButton &&
          (e.widget as ElevatedButton).child is Text &&
          ((e.widget as ElevatedButton).child! as Text).data == 'Start tour',
    );
    if (button?.onPressed == null) {
      _emit('RESULT : could not find the Start tour button');
      return;
    }
    button!.onPressed!.call();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final tour = _tourState(root);
    if (tour == null) {
      _emit('RESULT : no ShowCaseWidgetState');
      return;
    }

    // Sample while walking the tour, so every step type is covered: plain,
    // multi-widget, exact-shape, pulsing, styled, conditional.
    _timings.clear();
    _recording = true;
    final stepper = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => tour.next(),
    );
    await Future<void>.delayed(kSample);
    stepper.cancel();
    _recording = false;
    _emit(_report(label));
    tour.dismiss();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    await _sample('features-demo plain');

    setState(() => _everyFrame = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _sample('features-demo animated-screen');

    _emit('RESULT done');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      _started = true;
      scheduleMicrotask(_run);
    }
    const page = MaterialApp(home: FeaturesDemoPage());
    return _everyFrame ? const _EveryFrame(child: page) : page;
  }
}

/// Rebuilds [child] on every frame — a screen that also has an animation on it.
class _EveryFrame extends StatefulWidget {
  const _EveryFrame({required this.child});
  final Widget child;
  @override
  State<_EveryFrame> createState() => _EveryFrameState();
}

class _EveryFrameState extends State<_EveryFrame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}))..start();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
