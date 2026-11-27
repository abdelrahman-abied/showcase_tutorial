import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

/// One tour across two screens: the first step is on an inbox screen, the
/// next two are on a settings screen the tour opens.
///
/// In an app, put [ShowCaseWidget] in `MaterialApp.builder` so it sits above
/// the app's Navigator. This demo is a single page of a bigger example, so it
/// nests its own [Navigator] under a [ShowCaseWidget] instead. The effect is
/// the same: every screen pushed here shares one tour.
class CrossScreenDemoPage extends StatelessWidget {
  const CrossScreenDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: Builder(
        builder: (context) => Navigator(
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const _InboxScreen()),
        ),
      ),
    );
  }
}

// The tour's steps. Keys from different screens go into one startShowCase call.
final _settingsButton = GlobalKey(debugLabel: 'settingsButton');
final _notificationsSwitch = GlobalKey(debugLabel: 'notificationsSwitch');
final _doneButton = GlobalKey(debugLabel: 'doneButton');

class _InboxScreen extends StatelessWidget {
  const _InboxScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        leading: IconButton(
          tooltip: 'Close demo',
          icon: const Icon(Icons.close),
          // This screen is the nested Navigator's first route, so leave the
          // demo through the app's own Navigator.
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        actions: [
          Showcase(
            key: _settingsButton,
            title: 'Settings',
            description: 'Tap here. The tour continues on the next screen.',
            // `false` keeps the tour running; `true` would end it before
            // onTargetClick runs.
            disposeOnTap: false,
            onTargetClick: () {
              // Advance first: the next step's screen isn't open yet, so the
              // tour waits for it and shows it once it's pushed.
              ShowCaseWidget.of(context).next();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _SettingsScreen(),
                ),
              );
            },
            child: IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _SettingsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'One tour, two screens. The first step is here; the next ones are on '
                'the settings screen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ShowCaseWidget.of(context).startShowCase([
                  _settingsButton,
                  _notificationsSwitch,
                  _doneButton,
                ]),
                child: const Text('Start cross-screen tour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  bool _notifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Showcase(
            key: _notificationsSwitch,
            title: 'Notifications',
            description: 'This step lives on the settings screen.',
            child: SwitchListTile(
              title: const Text('Notifications'),
              value: _notifications,
              onChanged: (value) => setState(() => _notifications = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Showcase(
              key: _doneButton,
              title: 'Done',
              description: 'The last step. Tap anywhere to finish the tour.',
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
