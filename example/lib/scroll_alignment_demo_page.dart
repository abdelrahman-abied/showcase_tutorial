import 'package:flutter/material.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

/// Demonstrates [ShowCaseWidget.enableAutoScroll] together with `scrollAlignment`.
///
/// Three targets sit far apart in a (non-lazy) [SingleChildScrollView]. As the
/// tour advances, auto-scroll brings each one into view and rests it at a
/// different spot — leading edge, center, then trailing edge — using a per-step
/// [Showcase.scrollAlignment] that overrides the tour-wide default.
class ScrollAlignmentDemoPage extends StatelessWidget {
  const ScrollAlignmentDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final top = GlobalKey();
    final center = GlobalKey();
    final bottom = GlobalKey();

    return ShowCaseWidget(
      // Scroll an off-screen target into view before its step starts.
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 600),
      // Tour-wide landing position; each step below overrides it.
      scrollAlignment: 0.5,
      builder: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xff0077b6),
            foregroundColor: Colors.white,
            title: const Text('Auto-scroll alignment'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => ShowCaseWidget.of(context)
                      .startShowCase([top, center, bottom]),
                  child: const Text('Start auto-scroll tour'),
                ),
                const SizedBox(height: 16),
                const _Filler(
                    'Three targets are spaced far apart below. Each step\n'
                    'auto-scrolls its target to a different position.'),
                _Target(
                  showcaseKey: top,
                  // 0.0 = leading edge: rests near the top of the viewport.
                  scrollAlignment: 0.1,
                  color: Color(0xff0077b6),
                  label: 'Step 1 · leading (0.1)',
                  description: 'Auto-scrolled near the TOP of the viewport.',
                ),
                const _Filler('· · · scroll content · · ·'),
                _Target(
                  showcaseKey: center,
                  // 0.5 = centered (the tour-wide default, shown explicitly).
                  scrollAlignment: 0.5,
                  color: Color(0xff00b4d8),
                  label: 'Step 2 · center (0.5)',
                  description: 'Auto-scrolled to the CENTER of the viewport.',
                ),
                const _Filler('· · · more scroll content · · ·'),
                _Target(
                  showcaseKey: bottom,
                  // 1.0 = trailing edge: rests near the bottom of the viewport.
                  scrollAlignment: 0.9,
                  color: Color(0xff90e0ef),
                  label: 'Step 3 · trailing (0.9)',
                  description: 'Auto-scrolled near the BOTTOM of the viewport.',
                ),
                const _Filler('End of the list.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tall placeholder that pushes the targets apart so auto-scroll has to move.
class _Filler extends StatelessWidget {
  const _Filler(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      margin: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xfff1f3f5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black45),
      ),
    );
  }
}

/// A showcased card whose [scrollAlignment] controls where auto-scroll lands it.
class _Target extends StatelessWidget {
  const _Target({
    required this.showcaseKey,
    required this.scrollAlignment,
    required this.color,
    required this.label,
    required this.description,
  });

  final GlobalKey showcaseKey;
  final double scrollAlignment;
  final Color color;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      description: description,
      scrollAlignment: scrollAlignment,
      child: Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
