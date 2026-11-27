import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

/// A small travel app whose tour uses most of what the package can do, in the
/// places a real app would use them:
///
/// | Step | Feature |
/// | --- | --- |
/// | Profile picture | `highlightExactShape` |
/// | Search | the default tooltip |
/// | Offer banner | closing it skips its step (`onShouldSkipUnmountedStep`) |
/// | Flight + hotel | two widgets in one step (`keys` + `MultiView`) |
/// | Popular place below the fold | auto-scroll, pulse ring |
/// | Saved tab | a fixed `tooltipPosition` |
/// | Check in | a highlight border; tapping it opens the next screen and the tour continues there |
/// | Boarding pass (next screen) | a custom tooltip (`Showcase.withWidget`) |
///
/// Around the steps: the tour starts by itself on first open
/// (`onShouldStartShowcase`), can be resumed where it was left (`startAt`),
/// skips the check-in step once you have checked in (`onResolveNextStep`), has
/// a floating "End tour" button, progress dots, Skip, and a highlight that
/// glides between steps. The settings menu switches light and dark mode,
/// English and Arabic, auto-play, a blurred background, and whether the
/// buttons sit inside or below the tooltip.
///
/// Nothing sets a colour: the tour takes them from the theme.
class TripsDemoApp extends StatefulWidget {
  const TripsDemoApp({super.key, this.onClose, this.startTourOnOpen = true});

  /// Called by the close button. When `null`, no close button is shown.
  final VoidCallback? onClose;

  /// Whether the tour starts by itself the first time the app opens.
  final bool startTourOnOpen;

  @override
  State<TripsDemoApp> createState() => _TripsDemoAppState();
}

class _TripsDemoAppState extends State<TripsDemoApp> {
  static const _brand = Color(0xff0077b6);

  final _keys = _TourKeys();

  // Settings.
  ThemeMode _mode = ThemeMode.light;
  bool _arabic = false;
  bool _autoPlay = false;
  bool _blur = false;
  bool _buttonsOutside = false;

  // App state the tour reacts to.
  bool _offerVisible = true;
  bool _checkedIn = false;

  // Tour progress. A real app would keep these in storage (for example
  // shared_preferences) so they survive a restart; here they live in memory.
  bool _tourSeen = false;
  int? _resumeAt;
  int? _currentStep;

  _Strings get _s => _arabic ? _Strings.ar : _Strings.en;

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // The tour takes its colours from here: nothing below sets a colour.
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _brand)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brand,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _mode,
      // ShowCaseWidget sits above the Navigator, so one tour reaches steps on
      // every page (here, the boarding pass page that check-in opens).
      builder: (context, child) => Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: ShowCaseWidget(
          // Progress dots, a Skip button and translated button labels.
          showProgress: true,
          showSkip: true,
          labels: s.labels,
          // The same Previous / Stop / Next buttons on every step.
          globalActions: (_) => const ShowCaseDefaultActions(
            previous: ActionButtonConfig(
              icon: Icon(Icons.arrow_back, size: 16),
            ),
            next: ActionButtonConfig(icon: Icon(Icons.arrow_forward, size: 16)),
          ),
          actionsPosition: _buttonsOutside
              ? TooltipActionPosition.outside
              : TooltipActionPosition.inside,
          // The boarding pass step brings its own buttons.
          hideActionsForShowcase: [_keys.boardingPass],
          // A button pinned to the screen for the whole tour.
          globalFloatingActionWidget: (context) => SafeArea(
            child: Align(
              // Over the title, clear of the app bar buttons the tour
              // points at.
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton.tonalIcon(
                  onPressed: ShowCaseWidget.of(context).dismiss,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(s.endTour),
                ),
              ),
            ),
          ),
          hideFloatingActionWidgetForShowcase: [_keys.boardingPass],
          enableStepTransition: true,
          enableAutoScroll: true,
          autoPlay: _autoPlay,
          autoPlayDelay: const Duration(seconds: 3),
          blurValue: _blur ? 2 : 0,
          // Starts by itself only the first time; "Take the tour" passes force.
          onShouldStartShowcase: (_) => !_tourSeen,
          // A step whose widget isn't on screen: wait for the boarding pass
          // (its page opens during the tour), skip anything else (the offer
          // banner, once closed).
          onShouldSkipUnmountedStep: (_, key) => key != _keys.boardingPass,
          // Already checked in? Go from Saved straight to the boarding pass.
          onResolveNextStep: (_, key) =>
              key == _keys.saved && _checkedIn ? _keys.boardingPass : null,
          // Remember where the tour is, to offer resuming it.
          onStart: (index, _) => _currentStep = index,
          onFinish: () => setState(() {
            _tourSeen = true;
            _resumeAt = null;
          }),
          onDismiss: (_) => setState(() {
            _tourSeen = true;
            _resumeAt = _currentStep;
          }),
          builder: child!,
        ),
      ),
      home: _TripsHome(
        s: s,
        keys: _keys,
        isDark: _mode == ThemeMode.dark,
        offerVisible: _offerVisible,
        checkedIn: _checkedIn,
        resumeAt: _resumeAt,
        startTourOnOpen: widget.startTourOnOpen,
        settings: _Settings(
          dark: _mode == ThemeMode.dark,
          arabic: _arabic,
          autoPlay: _autoPlay,
          blur: _blur,
          buttonsOutside: _buttonsOutside,
        ),
        onToggleTheme: () => setState(
          () => _mode = _mode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
        onToggleLanguage: () => setState(() => _arabic = !_arabic),
        onToggleAutoPlay: () => setState(() => _autoPlay = !_autoPlay),
        onToggleBlur: () => setState(() => _blur = !_blur),
        onToggleButtonsOutside: () =>
            setState(() => _buttonsOutside = !_buttonsOutside),
        onCloseOffer: () => setState(() => _offerVisible = false),
        onCheckIn: () => setState(() => _checkedIn = true),
        onClose: widget.onClose,
      ),
    );
  }
}

/// The tour's steps, in order.
class _TourKeys {
  final profile = GlobalKey();
  final search = GlobalKey();
  final offer = GlobalKey();
  final flight = GlobalKey();
  final hotel = GlobalKey();
  final popular = GlobalKey();
  final saved = GlobalKey();
  final checkIn = GlobalKey();
  final boardingPass = GlobalKey();

  List<GlobalKey> get steps => [
    profile,
    search,
    offer,
    flight,
    popular,
    saved,
    checkIn,
    boardingPass,
  ];
}

class _Settings {
  const _Settings({
    required this.dark,
    required this.arabic,
    required this.autoPlay,
    required this.blur,
    required this.buttonsOutside,
  });

  final bool dark, arabic, autoPlay, blur, buttonsOutside;
}

enum _Setting { theme, language, autoPlay, blur, buttonsOutside }

class _TripsHome extends StatefulWidget {
  const _TripsHome({
    required this.s,
    required this.keys,
    required this.isDark,
    required this.offerVisible,
    required this.checkedIn,
    required this.resumeAt,
    required this.startTourOnOpen,
    required this.settings,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    required this.onToggleAutoPlay,
    required this.onToggleBlur,
    required this.onToggleButtonsOutside,
    required this.onCloseOffer,
    required this.onCheckIn,
    this.onClose,
  });

  final _Strings s;
  final _TourKeys keys;
  final bool isDark, offerVisible, checkedIn, startTourOnOpen;
  final int? resumeAt;
  final _Settings settings;
  final VoidCallback onToggleTheme,
      onToggleLanguage,
      onToggleAutoPlay,
      onToggleBlur;
  final VoidCallback onToggleButtonsOutside, onCloseOffer, onCheckIn;
  final VoidCallback? onClose;

  @override
  State<_TripsHome> createState() => _TripsHomeState();
}

class _TripsHomeState extends State<_TripsHome> {
  @override
  void initState() {
    super.initState();
    if (widget.startTourOnOpen) {
      // Without `force`, onShouldStartShowcase decides: only the first time.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ShowCaseWidget.of(context).startShowCase(widget.keys.steps);
      });
    }
  }

  void _openBoardingPass() {
    widget.onCheckIn();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BoardingPassPage(s: widget.s, keys: widget.keys),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final keys = widget.keys;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tour = ShowCaseWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: widget.onClose == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: s.close,
                onPressed: widget.onClose,
              ),
        title: Text(s.title),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: s.darkMode,
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: s.arabic,
            onPressed: widget.onToggleLanguage,
          ),
          _settingsMenu(s),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12, start: 4),
            child: Showcase(
              key: keys.profile,
              title: s.profileTitle,
              description: s.profileBody,
              // A snapshot of the avatar is drawn above the dimmed background,
              // so the highlight is exactly round.
              highlightExactShape: true,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.tertiaryContainer,
                foregroundColor: scheme.onTertiaryContainer,
                child: const Text('S'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.greeting, style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            s.subtitle,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => tour.startShowCase(keys.steps, force: true),
                icon: const Icon(Icons.play_arrow),
                label: Text(s.takeTour),
              ),
              if (widget.resumeAt != null)
                OutlinedButton.icon(
                  onPressed: () => tour.startShowCase(
                    keys.steps,
                    force: true,
                    startAt: widget.resumeAt!,
                  ),
                  icon: const Icon(Icons.replay),
                  label: Text(s.resume(widget.resumeAt! + 1)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Showcase(
            key: keys.search,
            title: s.searchTitle,
            description: s.searchBody,
            targetBorderRadius: const BorderRadius.all(Radius.circular(28)),
            child: SearchBar(
              hintText: s.searchHint,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
          if (widget.offerVisible) ...[
            const SizedBox(height: 16),
            Showcase(
              key: keys.offer,
              title: s.offerTitle,
              description: s.offerBody,
              targetBorderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Card.outlined(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.local_offer_outlined,
                    color: scheme.primary,
                  ),
                  title: Text(s.offer),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: s.close,
                    onPressed: widget.onCloseOffer,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card.filled(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.nextTrip,
                    style: text.labelLarge?.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(s.destination, style: text.titleLarge),
                  Text(
                    s.dates,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // One step, two widgets: the flight chip carries the
                      // tooltip and lists the hotel chip as an extra target.
                      Showcase(
                        key: keys.flight,
                        keys: [keys.hotel],
                        title: s.bookingsTitle,
                        description: s.bookingsBody,
                        targetBorderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        child: Chip(
                          avatar: const Icon(Icons.flight, size: 18),
                          label: Text(s.flight),
                        ),
                      ),
                      MultiView(
                        key: keys.hotel,
                        child: Chip(
                          avatar: const Icon(Icons.hotel, size: 18),
                          label: Text(s.hotel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Showcase(
                      key: keys.checkIn,
                      title: widget.checkedIn
                          ? s.boardingPassTitle
                          : s.checkInTitle,
                      description: widget.checkedIn
                          ? s.openPassBody
                          : s.checkInBody,
                      targetBorderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                      highlightBorderColor: scheme.primary,
                      // Tapping the highlighted button does what it always
                      // does, and the tour follows onto the next screen.
                      disposeOnTap: false,
                      onTargetClick: () {
                        tour.next();
                        _openBoardingPass();
                      },
                      child: FilledButton.icon(
                        onPressed: _openBoardingPass,
                        icon: Icon(
                          widget.checkedIn ? Icons.qr_code : Icons.how_to_reg,
                        ),
                        label: Text(
                          widget.checkedIn ? s.boardingPass : s.checkIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(s.popular, style: text.titleMedium),
          const SizedBox(height: 8),
          for (final (i, place) in s.places.indexed)
            if (i == s.places.length - 1)
              // Below the fold: the tour scrolls here before showing the step.
              Showcase(
                key: keys.popular,
                title: s.popularTitle,
                description: s.popularBody,
                enablePulseAnimation: true,
                targetBorderRadius: const BorderRadius.all(Radius.circular(12)),
                child: _PlaceTile(place: place),
              )
            else
              _PlaceTile(place: place),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: s.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            label: s.explore,
          ),
          NavigationDestination(
            icon: Showcase(
              key: keys.saved,
              title: s.savedTitle,
              description: s.savedBody,
              targetShapeBorder: const CircleBorder(),
              targetPadding: const EdgeInsets.all(8),
              tooltipPosition: TooltipPosition.top,
              child: const Icon(Icons.favorite_outline),
            ),
            label: s.saved,
          ),
        ],
      ),
    );
  }

  Widget _settingsMenu(_Strings s) {
    final settings = widget.settings;
    return PopupMenuButton<_Setting>(
      icon: const Icon(Icons.tune),
      tooltip: s.settings,
      onSelected: (setting) => switch (setting) {
        _Setting.theme => widget.onToggleTheme(),
        _Setting.language => widget.onToggleLanguage(),
        _Setting.autoPlay => widget.onToggleAutoPlay(),
        _Setting.blur => widget.onToggleBlur(),
        _Setting.buttonsOutside => widget.onToggleButtonsOutside(),
      },
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: _Setting.theme,
          checked: settings.dark,
          child: Text(s.darkMode),
        ),
        CheckedPopupMenuItem(
          value: _Setting.language,
          checked: settings.arabic,
          child: Text(s.arabic),
        ),
        CheckedPopupMenuItem(
          value: _Setting.autoPlay,
          checked: settings.autoPlay,
          child: Text(s.autoPlay),
        ),
        CheckedPopupMenuItem(
          value: _Setting.blur,
          checked: settings.blur,
          child: Text(s.blur),
        ),
        CheckedPopupMenuItem(
          value: _Setting.buttonsOutside,
          checked: settings.buttonsOutside,
          child: Text(s.buttonsOutside),
        ),
      ],
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place});

  final (String, String) place;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: const Icon(Icons.place_outlined),
      ),
      title: Text(place.$1),
      subtitle: Text(place.$2),
      trailing: const Icon(Icons.favorite_outline),
    );
  }
}

/// The screen check-in opens. Its step is part of the same tour: it waits
/// until this page is open, then shows a custom tooltip.
class _BoardingPassPage extends StatelessWidget {
  const _BoardingPassPage({required this.s, required this.keys});

  final _Strings s;
  final _TourKeys keys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.boardingPass)),
      body: Center(
        child: Showcase.withWidget(
          key: keys.boardingPass,
          width: 260,
          height: 160,
          targetBorderRadius: const BorderRadius.all(Radius.circular(16)),
          // A tooltip of your own, styled like the rest of the app.
          // The container is laid out at its own size, so give it a width.
          container: Builder(
            builder: (context) => SizedBox(
              width: 260,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.celebration, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.passTitle, style: text.titleMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(s.passBody, style: text.bodyMedium),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton(
                          onPressed: ShowCaseWidget.of(context).next,
                          child: Text(s.done),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child: Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, size: 120, color: scheme.onSurface),
                  const SizedBox(height: 8),
                  Text('LIS · TP 1342 · 08:40', style: text.titleMedium),
                  Text(
                    s.seat,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

class _Strings {
  const _Strings({
    required this.labels,
    required this.title,
    required this.close,
    required this.settings,
    required this.darkMode,
    required this.arabic,
    required this.autoPlay,
    required this.blur,
    required this.buttonsOutside,
    required this.endTour,
    required this.greeting,
    required this.subtitle,
    required this.takeTour,
    required this.resumeStep,
    required this.profileTitle,
    required this.profileBody,
    required this.searchHint,
    required this.searchTitle,
    required this.searchBody,
    required this.offer,
    required this.offerTitle,
    required this.offerBody,
    required this.nextTrip,
    required this.destination,
    required this.dates,
    required this.flight,
    required this.hotel,
    required this.bookingsTitle,
    required this.bookingsBody,
    required this.checkIn,
    required this.checkInTitle,
    required this.checkInBody,
    required this.boardingPass,
    required this.boardingPassTitle,
    required this.openPassBody,
    required this.popular,
    required this.places,
    required this.popularTitle,
    required this.popularBody,
    required this.home,
    required this.explore,
    required this.saved,
    required this.savedTitle,
    required this.savedBody,
    required this.passTitle,
    required this.passBody,
    required this.seat,
    required this.done,
  });

  final ShowcaseLabels labels;
  final String title,
      close,
      settings,
      darkMode,
      arabic,
      autoPlay,
      blur,
      buttonsOutside,
      endTour;
  final String greeting,
      subtitle,
      takeTour,
      resumeStep,
      profileTitle,
      profileBody;
  final String searchHint,
      searchTitle,
      searchBody,
      offer,
      offerTitle,
      offerBody;
  final String nextTrip,
      destination,
      dates,
      flight,
      hotel,
      bookingsTitle,
      bookingsBody;
  final String checkIn,
      checkInTitle,
      checkInBody,
      boardingPass,
      boardingPassTitle,
      openPassBody;
  final String popular,
      popularTitle,
      popularBody,
      home,
      explore,
      saved,
      savedTitle,
      savedBody;
  final String passTitle, passBody, seat, done;
  final List<(String, String)> places;

  String resume(int step) => resumeStep.replaceAll('{n}', '$step');

  static const en = _Strings(
    labels: ShowcaseLabels(),
    title: 'Trips',
    close: 'Close',
    settings: 'Tour settings',
    darkMode: 'Dark mode',
    arabic: 'Arabic',
    autoPlay: 'Auto-play',
    blur: 'Blur the background',
    buttonsOutside: 'Buttons below the tooltip',
    endTour: 'End tour',
    greeting: 'Good morning, Sara',
    subtitle: 'Your trip to Lisbon is in 3 days.',
    takeTour: 'Take the tour',
    resumeStep: 'Resume at step {n}',
    profileTitle: 'Your profile',
    profileBody: 'Passport details and travel preferences.',
    searchHint: 'Where to next?',
    searchTitle: 'Find a trip',
    searchBody: 'Search 120 destinations by city or country.',
    offer: '20% off flights to Porto',
    offerTitle: 'Offers for you',
    offerBody: 'Close the banner and this step is skipped.',
    nextTrip: 'NEXT TRIP',
    destination: 'Lisbon, Portugal',
    dates: '12 – 18 June · 2 travellers',
    flight: 'TP 1342 · 08:40',
    hotel: 'Hotel Avenida · 6 nights',
    bookingsTitle: 'Your bookings',
    bookingsBody: 'Flight and hotel, highlighted together.',
    checkIn: 'Check in',
    checkInTitle: 'Check in now',
    checkInBody: 'Tap it: the tour follows you to your boarding pass.',
    boardingPass: 'Boarding pass',
    boardingPassTitle: 'Your boarding pass',
    openPassBody: 'You are checked in. Tap to open your pass.',
    popular: 'Popular this week',
    places: [
      ('Porto', 'Portugal'),
      ('Seville', 'Spain'),
      ('Marrakesh', 'Morocco'),
      ('Istanbul', 'Türkiye'),
      ('Cairo', 'Egypt'),
    ],
    popularTitle: 'Trending now',
    popularBody: 'The tour scrolled down to show you this.',
    home: 'Home',
    explore: 'Explore',
    saved: 'Saved',
    savedTitle: 'Saved places',
    savedBody: 'Tap the heart on any place to keep it here.',
    passTitle: 'You are all set',
    passBody: 'Show this at the gate. It works offline.',
    seat: 'Seat 14A · Gate 23',
    done: 'Done',
  );

  static const ar = _Strings(
    labels: ShowcaseLabels(
      next: 'التالي',
      previous: 'السابق',
      stop: 'إنهاء',
      skip: 'تخطي',
    ),
    title: 'رحلاتي',
    close: 'إغلاق',
    settings: 'إعدادات الجولة',
    darkMode: 'الوضع الداكن',
    arabic: 'العربية',
    autoPlay: 'تشغيل تلقائي',
    blur: 'تمويه الخلفية',
    buttonsOutside: 'الأزرار أسفل التلميح',
    endTour: 'إنهاء الجولة',
    greeting: 'صباح الخير يا سارة',
    subtitle: 'رحلتك إلى لشبونة بعد 3 أيام.',
    takeTour: 'ابدأ الجولة',
    resumeStep: 'أكمل من الخطوة {n}',
    profileTitle: 'ملفك الشخصي',
    profileBody: 'بيانات جواز السفر وتفضيلات السفر.',
    searchHint: 'إلى أين بعد ذلك؟',
    searchTitle: 'ابحث عن رحلة',
    searchBody: 'ابحث بين 120 وجهة حسب المدينة أو البلد.',
    offer: 'خصم 20% على الرحلات إلى بورتو',
    offerTitle: 'عروض لك',
    offerBody: 'أغلق الإعلان وستُتخطى هذه الخطوة.',
    nextTrip: 'الرحلة القادمة',
    destination: 'لشبونة، البرتغال',
    dates: '12 – 18 يونيو · مسافران',
    flight: 'TP 1342 · 08:40',
    hotel: 'فندق أفينيدا · 6 ليالٍ',
    bookingsTitle: 'حجوزاتك',
    bookingsBody: 'الطيران والفندق معاً في خطوة واحدة.',
    checkIn: 'تسجيل الوصول',
    checkInTitle: 'سجّل الآن',
    checkInBody: 'اضغط عليه: الجولة تتبعك إلى بطاقة الصعود.',
    boardingPass: 'بطاقة الصعود',
    boardingPassTitle: 'بطاقة الصعود',
    openPassBody: 'أنت مسجّل. اضغط لفتح بطاقتك.',
    popular: 'الأكثر رواجاً هذا الأسبوع',
    places: [
      ('بورتو', 'البرتغال'),
      ('إشبيلية', 'إسبانيا'),
      ('مراكش', 'المغرب'),
      ('إسطنبول', 'تركيا'),
      ('القاهرة', 'مصر'),
    ],
    popularTitle: 'رائج الآن',
    popularBody: 'مرّرت الجولة الصفحة لتريك هذا.',
    home: 'الرئيسية',
    explore: 'استكشف',
    saved: 'المحفوظة',
    savedTitle: 'الأماكن المحفوظة',
    savedBody: 'اضغط القلب على أي مكان ليظهر هنا.',
    passTitle: 'كل شيء جاهز',
    passBody: 'أظهرها عند البوابة. تعمل دون اتصال.',
    seat: 'المقعد 14A · البوابة 23',
    done: 'تم',
  );
}
