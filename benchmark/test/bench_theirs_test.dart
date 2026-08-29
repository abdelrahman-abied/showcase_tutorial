import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';
import 'package:showcase_benchmark/scenes.dart';
import 'package:showcaseview/showcaseview.dart' as theirs;

class TheirsDriver extends Driver {
  @override
  String get name => 'showcaseview ${resolvedVersion('showcaseview')}';

  @override
  Future<void> pump(WidgetTester tester, List<GlobalKey> keys) async {
    theirs.ShowcaseView.register();
    await tester.pumpWidget(TheirsScene(keys: keys));
  }

  @override
  void start(List<GlobalKey> keys) => theirs.ShowcaseView.get().startShowCase(keys);

  @override
  void next() => theirs.ShowcaseView.get().next();

  @override
  void dismiss() => theirs.ShowcaseView.get().dismiss();

  @override
  void teardown() => theirs.ShowcaseView.get().unregister();
}

void main() {
  testWidgets('benchmark theirs', (tester) async {
    final keys = List.generate(kStepCount, (_) => GlobalKey());
    final driver = TheirsDriver();
    printResults(driver.name, await runBenchmark(tester, driver, keys));
  });
}
