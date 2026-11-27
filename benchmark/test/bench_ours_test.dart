import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showcase_benchmark/scenes.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart' as ours;

import 'harness.dart';

class OursDriver extends Driver {
  late BuildContext ctx;

  @override
  String get name => 'showcase_tutorial ${resolvedVersion('showcase_tutorial')}';

  @override
  Future<void> pump(WidgetTester tester, List<GlobalKey> keys) =>
      tester.pumpWidget(OursScene(keys: keys, onContext: (c) => ctx = c));

  @override
  void start(List<GlobalKey> keys) => ours.ShowCaseWidget.of(ctx).startShowCase(keys);

  @override
  void next() => ours.ShowCaseWidget.of(ctx).next();

  @override
  void dismiss() => ours.ShowCaseWidget.of(ctx).dismiss();
}

void main() {
  testWidgets('benchmark ours', (tester) async {
    final keys = List.generate(kStepCount, (_) => GlobalKey());
    final driver = OursDriver();
    printResults(driver.name, await runBenchmark(tester, driver, keys));
  });
}
