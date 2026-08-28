// Two structurally identical scenes: the same N targets in the same layout,
// wrapped once by showcase_tutorial and once by showcaseview 5.1.0.
//
// Everything outside the showcase wrapper is byte-for-byte the same so any
// measured difference is attributable to the package.
import 'package:flutter/material.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart' as ours;
import 'package:showcaseview/showcaseview.dart' as theirs;

const int kStepCount = int.fromEnvironment('N', defaultValue: 30);

/// The widget every target wraps. Identical on both sides.
class Target extends StatelessWidget {
  const Target(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) =>
      Container(width: 64, height: 40, alignment: Alignment.center, color: Colors.blue.shade100, child: Text('$index'));
}

Widget _grid(List<Widget> children) => Directionality(
  textDirection: TextDirection.ltr,
  child: Scaffold(
    body: SafeArea(child: Wrap(spacing: 8, runSpacing: 24, children: children)),
  ),
);

// ---------------------------------------------------------------- ours

class OursScene extends StatelessWidget {
  const OursScene({super.key, required this.keys, required this.onContext});

  final List<GlobalKey> keys;
  final void Function(BuildContext) onContext;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ours.ShowCaseWidget(
      builder: Builder(
        builder: (inner) {
          onContext(inner);
          return _grid([
            for (var i = 0; i < keys.length; i++)
              ours.Showcase(key: keys[i], title: 'Step $i', description: 'Description for step $i', child: Target(i)),
          ]);
        },
      ),
    ),
  );
}

// -------------------------------------------------------------- theirs

class TheirsScene extends StatelessWidget {
  const TheirsScene({super.key, required this.keys});

  final List<GlobalKey> keys;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Builder(
      builder: (_) => _grid([
        for (var i = 0; i < keys.length; i++)
          theirs.Showcase(key: keys[i], title: 'Step $i', description: 'Description for step $i', child: Target(i)),
      ]),
    ),
  );
}
