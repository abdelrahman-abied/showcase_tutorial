// Drives the cross-screen demo the way a user would: start the tour, tap the
// first step's target, and land on the next screen with its step showing. The
// demo leaves the looping tooltip animation on, so this pumps fixed durations
// instead of pumpAndSettle, which never settles.
import 'package:example/cross_screen_demo_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'demo: one tour continues from the inbox onto the settings screen',
    (tester) async {
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }

      await tester.pumpWidget(const MaterialApp(home: CrossScreenDemoPage()));
      await settle();

      await tester.tap(find.text('Start cross-screen tour'));
      await settle();
      expect(
        find.text('Tap here. The tour continues on the next screen.'),
        findsOneWidget,
      );

      // Tap the highlighted settings button through the overlay's cut-out.
      await tester.tapAt(tester.getCenter(find.byIcon(Icons.settings)));
      await settle();
      await settle();

      expect(
        find.widgetWithText(AppBar, 'Settings'),
        findsOneWidget,
        reason: 'the tour opened the settings screen',
      );
      expect(
        find.text('This step lives on the settings screen.'),
        findsOneWidget,
      );
      expect(
        find.text('Tap here. The tour continues on the next screen.'),
        findsNothing,
      );

      // The last step is on the same screen. Tapping a target waits out the
      // tooltip's closing animation before the tour moves on.
      await tester.tapAt(tester.getCenter(find.byType(SwitchListTile)));
      await tester.pump(const Duration(seconds: 1));
      await settle();
      expect(
        find.text('The last step. Tap anywhere to finish the tour.'),
        findsOneWidget,
      );
    },
  );
}
