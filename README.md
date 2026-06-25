# showcase_tutorial

[![pub package](https://img.shields.io/badge/showcase_tutorial-1.8.0-blue)](https://pub.dev/packages/showcase_tutorial)
[![GitHub stars](https://img.shields.io/github/stars/abdelrahman-abied/showcase_tutorial?style=social)](https://github.com/abdelrahman-abied/showcase_tutorial)

A Flutter package to **showcase / highlight your widgets step by step** — perfect for
onboarding tours and feature discovery.

## Preview

![Feature walkthrough](https://raw.githubusercontent.com/abdelrahman-abied/showcase_tutorial/main/preview/demo.gif)

![The example app running in iOS](https://raw.githubusercontent.com/abdelrahman-abied/showcase_tutorial/main/preview/showcase_tutorial.gif)

## Features

- Step-by-step highlight of any widget with an auto-positioned tooltip.
- Default tooltip (title + description) or a fully custom tooltip widget.
- Tooltip on any side — top / bottom / left / right — with full **RTL** support.
- **Highlight any widget by its exact shape** — circle, pill, star, icon — with `highlightExactShape`.
- **Pulsing highlight ring** — an optional animated ring that pings around the target to draw the eye.
- **Tooltip & highlight styling** — custom arrow color/size and a colored border around the target.
- **Highlight multiple widgets in a single step** (e.g. multi-select).
- **Global tooltip styling** via `ShowcaseStyle` — set it once, not per step.
- Built-in **action buttons** (Next / Previous / Stop) with customizable text.
- Built-in **progress dots** and a **Skip** button in the default tooltip.
- Auto-play, auto-scroll, and background blur.
- Programmatic control & progress: `next()`, `previous()`, `goTo()`, `dismiss()`, "Step x of y".
- Per-step **lifecycle callbacks** (`onShow` / `onDismiss`) and configurable background-tap behavior.
- **Show the tour only once** for onboarding, and auto-skip steps not on screen.
- **Accessibility**: keyboard navigation (Esc / arrows / Enter) and screen-reader announcements.
- Target interaction callbacks: tap, double-tap, long-press.
- Enable/disable the whole tour with a single flag.

## Installing

1. Add the dependency to your `pubspec.yaml` (get the latest version from the
   ['Installing' tab on pub.dev](https://pub.dev/packages/showcase_tutorial/install)):

   ```yaml
   dependencies:
     showcase_tutorial: <latest-version>
   ```

2. Import it:

   ```dart
   import 'package:showcase_tutorial/showcase_tutorial.dart';
   ```

## Upgrading (1.4 → 1.6)

Everything added since 1.4 is **additive and backward-compatible** — upgrading
needs no code changes. Every new capability is opt-in, and the only defaults that
changed are safe, focus-scoped accessibility improvements. At a glance:

### 1.6

- **Progress dots & Skip button** in the default tooltip — opt in with
  `ShowCaseWidget(showProgress: true, showSkip: true)` (both default to `false`;
  customize the label with `skipButtonText`). See
  [Progress dots & Skip button](#progress-dots--skip-button).

### 1.5

- **Keyboard navigation** (Esc / arrows / Enter) via `enableKeyboardNavigation`
  — **on by default**, but focus-scoped so it never hijacks your app's keys.
- **Screen-reader announcements** of each step via `enableAutoAnnouncements`
  — **on by default**; override the spoken text per step with
  `Showcase.semanticLabel`. See
  [Accessibility & keyboard navigation](#accessibility--keyboard-navigation).

### 1.4

- **Exact-shape highlight** — `Showcase(highlightExactShape: true)` hugs the
  target's actual painted shape instead of a geometric box.
- **Per-step lifecycle callbacks** — `Showcase(onShow: ..., onDismiss: ...)`.
- **Background-tap behavior** — `ShowCaseWidget(barrierInteraction: ...)` with
  `BarrierInteraction.next` (default, unchanged), `.dismiss`, or `.none`. The
  legacy `disableBarrierInteraction: true` still works (equivalent to `.none`).
- **Side tooltip positions** — `Showcase(tooltipPosition: TooltipPosition.left)`
  or `.right`.
- **Progress & jump-to API** on `ShowCaseWidget.of(context)`: `currentIndex`,
  `totalSteps`, `isShowcaseRunning`, `goTo(index)`, `goToKey(key)`.
- **Skip off-screen steps** — `ShowCaseWidget(autoSkipUnmountedSteps: true)`.
- **RTL support** — automatic; the tooltip follows the ambient text direction.

> Only two defaults changed across these releases — **keyboard navigation** and
> **screen-reader announcements** (both 1.5, both on by default). Both are
> additive and focus-scoped; set either flag to `false` to restore the pre-1.5
> behavior.

## Basic usage

**1. Wrap your screen (or app) in a `ShowCaseWidget`.**

```dart
ShowCaseWidget(
  builder: Builder(builder: (context) => const HomePage()),
);
```

**2. Wrap each target widget in a `Showcase` with a unique `GlobalKey`.**

```dart
final GlobalKey _one = GlobalKey();
final GlobalKey _two = GlobalKey();

Showcase(
  key: _one,
  title: 'Menu',
  description: 'Tap here to open the menu',
  child: const Icon(Icons.menu),
);

Showcase(
  key: _two,
  title: 'Profile',
  description: 'Your account lives here',
  targetShapeBorder: const CircleBorder(),
  child: const CircleAvatar(child: Icon(Icons.person)),
);
```

**3. Start the showcase** (the order of keys is the order of the steps):

```dart
ShowCaseWidget.of(context).startShowCase([_one, _two]);
```

To start it automatically once the first frame is rendered:

```dart
WidgetsBinding.instance.addPostFrameCallback(
  (_) => ShowCaseWidget.of(context).startShowCase([_one, _two]),
);
```

## Custom tooltip with `Showcase.withWidget`

When the default title/description tooltip isn't enough, build your own with
`Showcase.withWidget`:

```dart
Showcase.withWidget(
  key: _three,
  height: 80,
  width: 140,
  targetShapeBorder: const CircleBorder(),
  container: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text('This is a custom tooltip', style: TextStyle(color: Colors.white)),
      SizedBox(height: 8),
      Icon(Icons.touch_app, color: Colors.white),
    ],
  ),
  child: const Icon(Icons.star),
);
```

## Tooltip action buttons (Next / Previous / Stop)

Add navigation buttons to the tooltip with `ShowCaseDefaultActions`:

```dart
Showcase(
  key: _one,
  title: 'Menu',
  description: 'Open the menu',
  actions: const ShowCaseDefaultActions(), // Previous | Stop | Next
  child: const Icon(Icons.menu),
);
```

Customize each button with `ActionButtonConfig`:

```dart
Showcase(
  key: _one,
  title: 'Menu',
  description: 'Open the menu',
  actions: ShowCaseDefaultActions(
    next: ActionButtonConfig(
      text: 'Next',
      icon: const Icon(Icons.arrow_forward, size: 16),
      textDirection: TextDirection.rtl,
    ),
    previous: const ActionButtonConfig(text: 'Back'),
    stop: const ActionButtonConfig(text: 'Skip'),
  ),
  actionSettings: const ActionsSettings(
    containerColor: Colors.white,
    containerHeight: 40,
  ),
  child: const Icon(Icons.menu),
);
```

## Progress dots & Skip button

Add a built-in step indicator and a skip control to the default tooltip — no
custom container needed. Both are set once on the `ShowCaseWidget` and default
to off:

```dart
ShowCaseWidget(
  showProgress: true,           // dots: one per step, active step highlighted
  showSkip: true,               // a "Skip" button that ends the whole tour
  skipButtonText: 'Skip tour',  // optional, defaults to 'Skip'
  builder: Builder(builder: (context) => const HomePage()),
);
```

The dots use the tooltip's text color and reflect `currentIndex` / `totalSteps`.
This only affects the **default** tooltip; a custom `container` tooltip is left
untouched (build your own indicator there if you want one).

## Highlight a widget by its exact shape

By default the highlight is a geometric box you control with `targetShapeBorder`
(e.g. `CircleBorder()` for a round target). For irregular widgets — a star, a
pill, an icon, a logo — set `highlightExactShape: true` and the highlight hugs
the widget's **actual painted shape** automatically, with no `targetShapeBorder`
to match by hand.

```dart
Showcase(
  key: starKey,
  highlightExactShape: true, // highlight follows the star, not a box
  title: 'Favourites',
  description: 'Tap the star to save this item',
  child: const Icon(Icons.star, size: 48, color: Colors.amber),
);
```

How it works: the target is captured as a snapshot and drawn above the dimmed
overlay (the child is wrapped in a `RepaintBoundary` for you).

> Note: while the step is showing, the target is rendered as a **static image**,
> so it won't animate or update until the showcase moves on. For typical static
> UI this is invisible. `targetShapeBorder`/`targetBorderRadius` are ignored for
> the highlight when this is on.

## Pulsing highlight ring

For an extra nudge toward the target, set `enablePulseAnimation: true` to draw an
animated ring that pings outward around the highlight — like a sonar ping — in
addition to the static cut-out. Tune the look with `pulseColor` and
`pulseDuration` (one full cycle; smaller is faster).

```dart
Showcase(
  key: fabKey,
  enablePulseAnimation: true,
  pulseColor: Colors.amber,                       // defaults to white
  pulseDuration: const Duration(milliseconds: 1200),
  title: 'Compose',
  description: 'Tap here to start a new message',
  child: const Icon(Icons.add),
);
```

The ring follows the highlight's shape (`targetShapeBorder` / `targetBorderRadius`);
with `highlightExactShape` it pulses around the target's bounding box. Set a
default color for the whole tour once via
`ShowCaseWidget(style: ShowcaseStyle(pulseColor: ...))`.

> Accessibility: when the platform **"reduce motion"** setting is on, the pulse
> falls back to a single static ring instead of animating.

## Tooltip & highlight styling

Fine-tune the default tooltip and the highlight without writing a custom
`container`. Style the arrow (`arrowColor`, `arrowWidth`, `arrowHeight`, or hide
it with `showArrow: false`) and draw a colored border around the target
(`highlightBorderColor`, `highlightBorderWidth`):

```dart
Showcase(
  key: inboxKey,
  title: 'Inbox',
  description: 'Your messages live here',
  tooltipBackgroundColor: const Color(0xFF023047),
  textColor: Colors.white,
  // Arrow:
  arrowColor: const Color(0xFFF4A261), // defaults to the tooltip background
  arrowWidth: 26,                      // base, default 18
  arrowHeight: 13,                     // depth, default 9
  // Highlight border (off unless a color is set):
  highlightBorderColor: const Color(0xFFF4A261),
  highlightBorderWidth: 3,
  child: const Icon(Icons.inbox),
);
```

The border follows the highlight's shape (`targetShapeBorder` /
`targetBorderRadius`); with `highlightExactShape` it outlines the bounding box.
Set any of these once for the whole tour via `ShowcaseStyle`, e.g.
`ShowCaseWidget(style: ShowcaseStyle(arrowColor: ..., highlightBorderColor: ...))`.

> The per-step overlay (scrim) color is controlled by `Showcase.overlayColor`
> and `overlayOpacity`.

## Highlight multiple widgets in a single step

Sometimes one step should highlight several widgets at once — for example a
multi-select control, or a few non-adjacent items in a `ListView`. Pass the
extra widgets' keys to `Showcase(keys: ...)` and wrap each of those widgets in a
`MultiView` (a `RepaintBoundary`) so a snapshot of it can be drawn above the
overlay.

```dart
final GlobalKey mainKey = GlobalKey();
final GlobalKey extraOne = GlobalKey();
final GlobalKey extraTwo = GlobalKey();

// The primary target carries the tooltip and lists the extra keys.
Showcase(
  key: mainKey,
  keys: [extraOne, extraTwo],
  description: 'Tap the star to mark important emails',
  child: const MailTile(),
);

// Each extra widget is wrapped so it can be captured.
MultiView(key: extraOne, child: const SomeListItem());
MultiView(key: extraTwo, child: FloatingActionButton(onPressed: () {}));
```

> Note: the extra widgets must currently be in the widget tree (rendered) when
> the step starts so their keys resolve. A widget that is missing is simply
> skipped — the remaining ones are still highlighted.

## Set default tooltip styling once (`ShowcaseStyle`)

Instead of repeating the same tooltip styling on every `Showcase`, set it once
on the `ShowCaseWidget` with `ShowcaseStyle`. Each `Showcase` still overrides
any value it provides; anything left unset falls back to the style, then to the
built-in default.

```dart
ShowCaseWidget(
  style: const ShowcaseStyle(
    tooltipBackgroundColor: Color(0xFF023047),
    textColor: Colors.white,
    tooltipBorderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  builder: Builder(builder: (context) => const HomePage()),
);
```

Resolution order for each value: **`Showcase` → `ShowcaseStyle` → built-in default**.

## Show the tour only once

By default the package stores nothing, so the tour replays every time you call
`startShowCase`. To show it only once (typical onboarding), give the
`ShowCaseWidget` a `showcaseId` and an `onShouldStartShowcase` guard, and persist
completion yourself in `onFinish` — with any storage (`shared_preferences`,
Hive, a backend, …):

```dart
ShowCaseWidget(
  showcaseId: 'home_v1',
  onShouldStartShowcase: (id) async =>
      !(prefs.getBool(id!) ?? false),       // skip if already seen
  onFinish: () => prefs.setBool('home_v1', true),
  builder: Builder(builder: (context) => const HomePage()),
);
```

Call `startShowCase([...])` as usual — it silently does nothing when the guard
returns `false`. The guard may be synchronous or asynchronous. To force a replay
(e.g. a "Show tutorial again" button), pass `force: true`:

```dart
ShowCaseWidget.of(context).startShowCase([_one, _two], force: true);
```

## Auto play

Advance through all steps automatically:

```dart
ShowCaseWidget(
  autoPlay: true,
  autoPlayDelay: const Duration(seconds: 3),
  enableAutoPlayLock: true, // block taps while auto-playing
  builder: Builder(builder: (context) => const HomePage()),
);
```

## Controlling the showcase programmatically

```dart
ShowCaseWidget.of(context).next();      // go to the next step
ShowCaseWidget.of(context).previous();  // go to the previous step
ShowCaseWidget.of(context).dismiss();   // stop the whole tour
```

Jump to a specific step and read progress — useful for a "Step 2 of 5"
indicator or a skip-to control:

```dart
final show = ShowCaseWidget.of(context);
show.goTo(2);                 // jump to a step by index
show.goToKey(profileKey);     // ...or by its GlobalKey
final label = '${(show.currentIndex ?? 0) + 1} of ${show.totalSteps}';
final running = show.isShowcaseRunning;
```

Lifecycle callbacks on `ShowCaseWidget`:

```dart
ShowCaseWidget(
  onStart: (index, key) => debugPrint('started step $index'),
  onComplete: (index, key) => debugPrint('finished step $index'),
  onFinish: () => debugPrint('tour complete'),
  builder: Builder(builder: (context) => const HomePage()),
);
```

## Target interactions

Respond to taps on the highlighted widget. `onTargetClick` requires
`disposeOnTap` to be set:

```dart
Showcase(
  key: _one,
  description: 'Tap to open details',
  disposeOnTap: true,
  onTargetClick: () => Navigator.pushNamed(context, '/details'),
  onTargetDoubleTap: () => debugPrint('double tapped'),
  onTargetLongPress: () => debugPrint('long pressed'),
  child: const Icon(Icons.info),
);
```

## Step lifecycle callbacks

Each `Showcase` can report when it becomes visible and when it's left — handy
for analytics or per-step side effects:

```dart
Showcase(
  key: _one,
  title: 'Menu',
  description: 'Open the menu',
  onShow: () => analytics.log('tour_step_shown', {'step': 'menu'}),
  onDismiss: () => analytics.log('tour_step_left', {'step': 'menu'}),
  child: const Icon(Icons.menu),
);
```

`onShow` fires when the step becomes the active showcase; `onDismiss` fires when
it stops being active — advanced past, navigated away, or the whole tour ended.

## Background (barrier) tap behavior

By default, tapping the dimmed background advances to the next step. Change it
with `barrierInteraction`:

```dart
ShowCaseWidget(
  barrierInteraction: BarrierInteraction.dismiss, // tap background → end tour
  // BarrierInteraction.next    → advance (default)
  // BarrierInteraction.none    → ignore background taps
  builder: Builder(builder: (context) => const HomePage()),
);
```

> The legacy `disableBarrierInteraction: true` still works and is equivalent to
> `BarrierInteraction.none`.

## Accessibility & keyboard navigation

The active step is keyboard-navigable and announced to screen readers out of the
box (both default to on):

```dart
ShowCaseWidget(
  enableKeyboardNavigation: true,   // default
  enableAutoAnnouncements: true,    // default
  builder: Builder(builder: (context) => const HomePage()),
);
```

**Keyboard** (web/desktop; harmless on mobile):

| Key                  | Action            |
|----------------------|-------------------|
| `→` / `↓` / `Enter`  | Next step         |
| `←` / `↑`            | Previous step     |
| `Esc`                | Dismiss the tour  |

Keyboard handling is focus-scoped: it only acts while the showcase overlay holds
focus, so it never hijacks keys from the rest of your app.

**Screen readers**: each step's title and description are announced via
TalkBack / VoiceOver as it becomes active. Override the spoken text per step
(handy for a custom `container` tooltip with no title/description):

```dart
Showcase(
  key: _logo,
  semanticLabel: 'Your company logo. Double tap to go home.',
  child: const FlutterLogo(),
);
```

## Blur the background

```dart
// For all steps:
ShowCaseWidget(blurValue: 2, builder: ...);

// Or per step:
Showcase(blurValue: 2, key: _one, description: '...', child: ...);
```

## Tooltip position

Force the tooltip to a side of the target with `TooltipPosition.top`,
`.bottom`, `.left`, or `.right` (defaults to whatever vertical space is
available):

```dart
Showcase(
  key: _one,
  description: 'Shown to the right of the target',
  tooltipPosition: TooltipPosition.right,
  child: const Icon(Icons.menu),
);
```

> `left` / `right` use the default title/description tooltip; custom
> `container` tooltips and action buttons keep top/bottom placement.

## Skip steps whose target isn't on screen

If some showcased widgets are rendered conditionally, enable
`autoSkipUnmountedSteps` so steps whose target isn't currently in the widget
tree are skipped automatically instead of showing an empty overlay:

```dart
ShowCaseWidget(
  autoSkipUnmountedSteps: true,
  builder: Builder(builder: (context) => const HomePage()),
);
```

## Right-to-left (RTL)

The tooltip inherits the ambient text direction, so RTL text (e.g. Arabic) is
measured and laid out correctly when your app is RTL — no extra configuration
needed.

## Enable or disable showcasing globally

```dart
ShowCaseWidget(
  enableShowcase: false, // every Showcase just renders its child, no overlay
  builder: Builder(builder: (context) => const HomePage()),
);
```

## Functions of `ShowCaseWidget.of(context)`

| Function                                   | Description              |
|--------------------------------------------|--------------------------|
| `startShowCase(List<GlobalKey> widgetIds)` | Start the showcase       |
| `next()`                                   | Go to the next step      |
| `previous()`                               | Go to the previous step  |
| `dismiss()`                                | Dismiss all showcases    |

## Properties of `ShowCaseWidget`

| Name                      | Type                       | Default                        | Description                                                                      |
| ------------------------- | -------------------------- | ------------------------------ | -------------------------------------------------------------------------------- |
| builder                   | Builder                    | required                       | Builds the subtree that contains the `Showcase` widgets.                         |
| style                     | ShowcaseStyle              | `const ShowcaseStyle()`        | Default tooltip styling for every `Showcase` in the tree.                        |
| blurValue                 | double                     | 0                              | Gaussian blur applied to the overlay.                                            |
| autoPlay                  | bool                       | false                          | Automatically advance to the next showcase.                                      |
| autoPlayDelay             | Duration                   | `Duration(milliseconds: 2000)` | Visibility time of a showcase when `autoPlay` is enabled.                        |
| enableAutoPlayLock        | bool                       | false                          | Block user interaction on the overlay while auto-playing.                        |
| enableAutoScroll          | bool                       | false                          | Auto-scroll so the next target becomes visible.                                  |
| scrollDuration            | Duration                   | `Duration(milliseconds: 300)`  | Duration of the auto-scroll animation.                                           |
| barrierInteraction        | BarrierInteraction         | `BarrierInteraction.next`      | What a background tap does: `next` (advance), `dismiss` (end tour), `none`.      |
| disableBarrierInteraction | bool                       | false                          | Legacy flag; `true` makes the barrier inert (same as `BarrierInteraction.none`). |
| disableScaleAnimation     | bool                       | false                          | Disable the tooltip scale transition for all showcases.                          |
| disableMovingAnimation    | bool                       | false                          | Disable the bouncing/moving transition for all showcases.                        |
| onStart                   | Function(int?, GlobalKey)? |                                | Called on the start of each showcase.                                            |
| onComplete                | Function(int?, GlobalKey)? |                                | Called on the completion of each showcase.                                       |
| onFinish                  | VoidCallback?              |                                | Called when all showcases are completed.                                         |
| enableShowcase            | bool                       | true                           | Enable or disable showcasing globally.                                           |
| autoSkipUnmountedSteps    | bool                       | false                          | Skip steps whose target widget is not currently mounted.                         |
| enableKeyboardNavigation  | bool                       | true                           | Drive the active step with a hardware keyboard (Esc / arrows / Enter).           |
| enableAutoAnnouncements   | bool                       | true                           | Announce each step's title/description to screen readers.                        |
| showProgress              | bool                       | false                          | Show built-in progress dots in the default tooltip.                              |
| showSkip                  | bool                       | false                          | Show a "Skip" button in the default tooltip that ends the tour.                  |
| skipButtonText            | String                     | 'Skip'                         | Label for the skip button.                                                       |

## Properties of `Showcase` and `Showcase.withWidget`

| Name                         | Type                   | Default                                            | Description                                                                                 | `Showcase` | `Showcase.withWidget` |
| ---------------------------- | ---------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------- | :--------: | :-------------------: |
| key                          | GlobalKey              | required                                           | Unique global key for the showcase.                                                         |     ✅     |          ✅           |
| child                        | Widget                 | required                                           | The target widget to be showcased.                                                          |     ✅     |          ✅           |
| keys                         | List<GlobalKey>?       |                                                    | Extra widgets to highlight in the same step (wrap each in a `MultiView`).                   |     ✅     |          ✅           |
| title                        | String?                |                                                    | Title of the default tooltip.                                                               |     ✅     |                       |
| description                  | String?                |                                                    | Description of the default tooltip (optional).                                              |     ✅     |                       |
| container                    | Widget?                |                                                    | A fully custom tooltip widget.                                                              |            |          ✅           |
| height                       | double?                |                                                    | Height of the custom tooltip.                                                               |            |          ✅           |
| width                        | double?                |                                                    | Width of the custom tooltip.                                                                |            |          ✅           |
| titleTextStyle               | TextStyle?             | `ShowcaseStyle`                                    | Text style of the title.                                                                    |     ✅     |                       |
| descTextStyle                | TextStyle?             | `ShowcaseStyle`                                    | Text style of the description.                                                              |     ✅     |                       |
| titleAlignment               | TextAlign              | `TextAlign.start`                                  | Alignment of the title.                                                                     |     ✅     |                       |
| descriptionAlignment         | TextAlign              | `TextAlign.start`                                  | Alignment of the description.                                                               |     ✅     |                       |
| tooltipBackgroundColor       | Color?                 | `ShowcaseStyle` → `Colors.white`                   | Background color of the default tooltip.                                                    |     ✅     |                       |
| textColor                    | Color?                 | `ShowcaseStyle` → `Colors.black`                   | Text color of the default tooltip.                                                          |     ✅     |                       |
| tooltipBorderRadius          | BorderRadius?          | `ShowcaseStyle` → `BorderRadius.circular(8)`       | Border radius of the default tooltip.                                                       |     ✅     |                       |
| tooltipPadding               | EdgeInsets             | `EdgeInsets.symmetric(vertical: 8, horizontal: 8)` | Padding inside the tooltip.                                                                 |     ✅     |                       |
| titlePadding                 | EdgeInsets?            | `EdgeInsets.zero`                                  | Padding around the title.                                                                   |     ✅     |                       |
| descriptionPadding           | EdgeInsets?            | `EdgeInsets.zero`                                  | Padding around the description.                                                             |     ✅     |                       |
| showArrow                    | bool                   | true                                               | Show the tooltip arrow pointing at the target.                                              |     ✅     |                       |
| tooltipPosition              | TooltipPosition?       |                                                    | Force the tooltip above (`top`) or below (`bottom`) the target.                             |     ✅     |          ✅           |
| actions                      | Widget?                |                                                    | Action buttons widget (e.g. `ShowCaseDefaultActions`).                                      |     ✅     |          ✅           |
| actionSettings               | ActionsSettings?       | `const ActionsSettings()`                          | Container styling for the action buttons.                                                   |     ✅     |          ✅           |
| actionButtonsPosition        | ActionButtonsPosition? |                                                    | Manual position for the action buttons.                                                     |     ✅     |          ✅           |
| targetShapeBorder            | ShapeBorder            | `RoundedRectangleBorder(...)`                      | Shape applied to the highlighted target (used when `targetBorderRadius` is null).           |     ✅     |          ✅           |
| highlightExactShape          | bool                   | false                                              | Highlight the target by its actual painted shape (snapshot) instead of `targetShapeBorder`. |     ✅     |          ✅           |
| targetBorderRadius           | BorderRadius?          |                                                    | Border radius of the highlighted target.                                                    |     ✅     |          ✅           |
| enablePulseAnimation         | bool                   | false                                              | Draw an animated ring that pulses outward around the highlight.                             |     ✅     |          ✅           |
| pulseColor                   | Color?                 | `ShowcaseStyle` → `Colors.white`                   | Color of the pulsing ring.                                                                  |     ✅     |          ✅           |
| pulseDuration                | Duration               | `Duration(milliseconds: 1500)`                     | Length of one full pulse cycle (smaller is faster).                                         |     ✅     |          ✅           |
| highlightBorderColor         | Color?                 |                                                    | Color of a border drawn around the highlighted target (off when null).                      |     ✅     |          ✅           |
| highlightBorderWidth         | double?                | `2`                                                | Width of the highlight border.                                                              |     ✅     |          ✅           |
| arrowColor                   | Color?                 | `ShowcaseStyle` → tooltip bg                       | Color of the default tooltip arrow.                                                         |     ✅     |                       |
| arrowWidth                   | double?                | `18`                                               | Width (base) of the default tooltip arrow.                                                  |     ✅     |                       |
| arrowHeight                  | double?                | `9`                                                | Height (depth) of the default tooltip arrow.                                                |     ✅     |                       |
| targetPadding                | EdgeInsets             | `EdgeInsets.zero`                                  | Padding around the highlighted target.                                                      |     ✅     |          ✅           |
| overlayColor                 | Color                  | `Colors.black45`                                   | Color of the overlay.                                                                       |     ✅     |          ✅           |
| overlayOpacity               | double                 | 0.75                                               | Opacity of the overlay.                                                                     |     ✅     |          ✅           |
| blurValue                    | double?                | `ShowCaseWidget.blurValue`                         | Gaussian blur on the overlay.                                                               |     ✅     |          ✅           |
| disableDefaultTargetGestures | bool                   | false                                              | Disable the default gestures on the target.                                                 |     ✅     |          ✅           |
| disposeOnTap                 | bool?                  |                                                    | Dismiss all showcases when the target/tooltip is tapped.                                    |     ✅     |          ✅           |
| onTargetClick                | VoidCallback?          |                                                    | Called when the target is tapped (requires `disposeOnTap`).                                 |     ✅     |          ✅           |
| onTargetDoubleTap            | VoidCallback?          |                                                    | Called when the target is double-tapped.                                                    |     ✅     |          ✅           |
| onTargetLongPress            | VoidCallback?          |                                                    | Called when the target is long-pressed.                                                     |     ✅     |          ✅           |
| onToolTipClick               | VoidCallback?          |                                                    | Called when the tooltip is tapped.                                                          |     ✅     |                       |
| onShow                       | VoidCallback?          |                                                    | Called when this step becomes the active showcase.                                          |     ✅     |          ✅           |
| onDismiss                    | VoidCallback?          |                                                    | Called when this step stops being active (advanced past, navigated away, or dismissed).     |     ✅     |          ✅           |
| semanticLabel                | String?                |                                                    | Text announced to screen readers for this step (defaults to title + description).           |     ✅     |          ✅           |
| disableMovingAnimation       | bool?                  | `ShowCaseWidget.disableMovingAnimation`            | Disable the bouncing/moving transition.                                                     |     ✅     |          ✅           |
| disableScaleAnimation        | bool?                  | `ShowCaseWidget.disableScaleAnimation`             | Disable the initial scale transition.                                                       |     ✅     |                       |
| movingAnimationDuration      | Duration               | `Duration(milliseconds: 2000)`                     | Duration of the moving animation.                                                           |     ✅     |          ✅           |
| scaleAnimationDuration       | Duration               | `Duration(milliseconds: 300)`                      | Duration of the scale animation.                                                            |     ✅     |                       |
| scaleAnimationCurve          | Curve                  | `Curves.easeIn`                                    | Curve of the scale animation.                                                               |     ✅     |                       |
| scaleAnimationAlignment      | Alignment?             |                                                    | Origin of the scale animation.                                                              |     ✅     |                       |
| scrollLoadingWidget          | Widget                 | `CircularProgressIndicator(...)`                   | Loading widget shown while auto-scrolling to the target.                                    |     ✅     |          ✅           |

## Auto-scrolling to the active showcase

Auto-scrolling does **not** work reliably in scroll views that build children on
demand (e.g. `ListView`, `GridView`), because the target widget may not be
attached to the tree when the showcase starts.

If you have a small number of children, prefer `SingleChildScrollView`. Otherwise,
assign a `ScrollController` and scroll to the target manually inside `onStart`:

```dart
final _controller = ScrollController();

ShowCaseWidget(
  onStart: (index, key) {
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Scroll to where the showcased widget is rendered (nearest
        // position works too — e.g. 990 instead of 1000).
        _controller.jumpTo(1000);
      });
    }
  },
  builder: Builder(builder: (context) => const HomePage()),
);
```

## Example

See the full [example app](example) for menu, profile, custom action buttons,
global styling, and the multi-widget step in action.

## Special thanks

This package builds on [showcaseview](https://github.com/SimformSolutionsPvtLtd/flutter-showcaseview)
by [Simform Solutions](https://github.com/SimformSolutionsPvtLtd). Thanks to the
original authors and contributors:

<table>
  <tr>
    <td align="center"><a href="https://github.com/birjuvachhani"><img src="https://avatars.githubusercontent.com/u/20423471?s=100" width="100px;" alt=""/><br /><sub><b>Birju Vachhani</b></sub></a></td>
    <td align="center"><a href="https://github.com/DevarshRanpara"><img src="https://avatars.githubusercontent.com/u/26064415?s=100" width="100px;" alt=""/><br /><sub><b>Devarsh Ranpara</b></sub></a></td>
    <td align="center"><a href="https://github.com/AnkitPanchal10"><img src="https://avatars.githubusercontent.com/u/38405884?s=100" width="100px;" alt=""/><br /><sub><b>Ankit Panchal</b></sub></a></td>
    <td align="center"><a href="https://github.com/Kashifalaliwala"><img src="https://avatars.githubusercontent.com/u/30998350?s=100" width="100px;" alt=""/><br /><sub><b>Kashifa Laliwala</b></sub></a></td>
    <td align="center"><a href="https://github.com/vatsaltanna"><img src="https://avatars.githubusercontent.com/u/25323183?s=100" width="100px;" alt=""/><br /><sub><b>Vatsal Tanna</b></sub></a></td>
    <td align="center"><a href="https://github.com/sanket-simform"><img src="https://avatars.githubusercontent.com/u/65167856?v=4" width="100px;" alt=""/><br /><sub><b>Sanket Kachhela</b></sub></a></td>
    <td align="center"><a href="https://github.com/ParthBaraiya"><img src="https://avatars.githubusercontent.com/u/36261739?v=4" width="100px;" alt=""/><br /><sub><b>Parth Baraiya</b></sub></a></td>
    <td align="center"><a href="https://github.com/ShwetaChauhan18"><img src="https://avatars.githubusercontent.com/u/34509457" width="80px;" alt=""/><br /><sub><b>Shweta Chauhan</b></sub></a></td>
    <td align="center"><a href="https://github.com/MehulKK"><img src="https://avatars.githubusercontent.com/u/60209725?s=100" width="100px;" alt=""/><br /><sub><b>Mehul Kabaria</b></sub></a></td>
    <td align="center"><a href="https://github.com/DhavalRKansara"><img src="https://avatars.githubusercontent.com/u/44993081?v=4" width="100px;" alt=""/><br /><sub><b>Dhaval Kansara</b></sub></a></td>
    <td align="center"><a href="https://github.com/HappyMakadiyaS"><img src="https://avatars.githubusercontent.com/u/97177197?v=4" width="100px;" alt=""/><br /><sub><b>Happy Makadiya</b></sub></a></td>
    <td align="center"><a href="https://github.com/Ujas-Majithiya"><img src="https://avatars.githubusercontent.com/u/56400956?v=4" width="100px;" alt=""/><br /><sub><b>Ujas Majithiya</b></sub></a></td>
  </tr>
</table>
