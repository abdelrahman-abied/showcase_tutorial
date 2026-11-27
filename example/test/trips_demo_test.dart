// Drives the trips demo (the README's preview) the way a user would, through
// every feature it shows. The tooltip keeps animating, so this pumps frames
// instead of pumpAndSettle.
import 'package:example/trips_demo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // Steps change after a short reverse animation, then glide in; an
  // auto-scroll takes a moment too. Pump frames rather than one long jump.
  Future<void> settle(WidgetTester tester, {int frames = 10}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> next(WidgetTester tester, {String label = 'Next'}) async {
    await tester.tap(find.text(label));
    await settle(tester);
  }

  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('demo: the whole tour, from first open to the boarding pass', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const TripsDemoApp());
    await settle(tester);

    // Starts by itself on first open.
    expect(find.text('Your profile'), findsOneWidget);
    expect(
      find.text('End tour'),
      findsOneWidget,
      reason: 'the floating button',
    );

    await next(tester);
    expect(find.text('Find a trip'), findsOneWidget);
    await next(tester);
    expect(find.text('Offers for you'), findsOneWidget);
    await next(tester);
    expect(find.text('Your bookings'), findsOneWidget);
    await next(tester);
    await settle(tester, frames: 15);
    expect(
      find.text('Trending now'),
      findsOneWidget,
      reason: 'after scrolling down to it',
    );
    await next(tester);
    expect(find.text('Saved places'), findsOneWidget);
    await next(tester);
    await settle(tester, frames: 15);
    expect(find.text('Check in now'), findsOneWidget);

    // Tapping the highlighted button opens the next screen, and the tour
    // continues there with its custom tooltip.
    await tester.tap(find.text('Check in'));
    await settle(tester, frames: 15);
    expect(find.widgetWithText(AppBar, 'Boarding pass'), findsOneWidget);
    expect(find.text('You are all set'), findsOneWidget);
    expect(find.text('End tour'), findsNothing, reason: 'hidden on this step');

    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('You are all set'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'demo: a closed banner is skipped, a stopped tour resumes, and check-in is skipped once done',
    (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(const TripsDemoApp(startTourOnOpen: false));
      await settle(tester);
      expect(find.text('Your profile'), findsNothing);

      // Close the offer: its step is skipped.
      await tester.tap(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byIcon(Icons.close),
        ),
      );
      await settle(tester);
      expect(find.text('20% off flights to Porto'), findsNothing);
      await tester.tap(find.text('Take the tour'));
      await settle(tester);
      await next(tester);
      expect(find.text('Find a trip'), findsOneWidget);
      await next(tester);
      expect(find.text('Your bookings'), findsOneWidget);

      // Stop here: a button offers to resume at this step.
      await next(tester, label: 'Stop');
      expect(find.text('Your bookings'), findsNothing);
      await tester.tap(find.text('Resume at step 4'));
      await settle(tester);
      expect(find.text('Your bookings'), findsOneWidget);
      await tester.tap(find.text('End tour'));
      await settle(tester);

      // Check in outside the tour, then come back.
      await tester.tap(find.text('Check in'));
      await settle(tester);
      await tester.pageBack();
      await settle(tester);
      expect(
        find.text('Boarding pass'),
        findsOneWidget,
        reason: 'the button now opens the pass',
      );

      // From Saved the tour goes straight to the boarding pass, which waits
      // until its page is open.
      await tester.tap(find.text('Resume at step 4'));
      await settle(tester);
      await next(tester);
      await settle(tester, frames: 15);
      expect(find.text('Trending now'), findsOneWidget);
      await next(tester);
      expect(find.text('Saved places'), findsOneWidget);
      await next(tester);
      expect(find.text('Check in now'), findsNothing);
      expect(find.text('Your boarding pass'), findsNothing);
      await tester.ensureVisible(find.text('Boarding pass'));
      await tester.tap(find.text('Boarding pass'), warnIfMissed: false);
      await settle(tester, frames: 15);
      expect(find.text('You are all set'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('demo: dark mode and Arabic', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const TripsDemoApp(startTourOnOpen: false));
    await settle(tester);
    expect(
      Theme.of(tester.element(find.text('Trips'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byIcon(Icons.dark_mode));
    await settle(tester);
    expect(
      Theme.of(tester.element(find.text('Trips'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byIcon(Icons.translate));
    await settle(tester);
    expect(
      Directionality.of(tester.element(find.text('رحلاتي'))),
      TextDirection.rtl,
    );

    await tester.tap(find.text('ابدأ الجولة'));
    await settle(tester);
    expect(find.text('ملفك الشخصي'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    await next(tester, label: 'التالي');
    expect(find.text('ابحث عن رحلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'demo: the settings menu turns on auto-play, blur and outside buttons',
    (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(const TripsDemoApp(startTourOnOpen: false));
      await settle(tester);

      for (final setting in [
        'Auto-play',
        'Blur the background',
        'Buttons below the tooltip',
      ]) {
        await tester.tap(find.byTooltip('Tour settings'));
        await settle(tester);
        await tester.tap(find.text(setting));
        await settle(tester);
      }

      await tester.tap(find.text('Take the tour'));
      await settle(tester);
      expect(find.text('Your profile'), findsOneWidget);
      // Auto-play moves on by itself after 3 seconds.
      await settle(tester, frames: 35);
      expect(find.text('Find a trip'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
