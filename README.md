# showcase_tutorial

[![pub package](https://img.shields.io/pub/v/showcase_tutorial.svg)](https://pub.dev/packages/showcase_tutorial)
[![likes](https://img.shields.io/pub/likes/showcase_tutorial)](https://pub.dev/packages/showcase_tutorial/score)
[![GitHub stars](https://img.shields.io/github/stars/abdelrahman-abied/showcase_tutorial?style=social)](https://github.com/abdelrahman-abied/showcase_tutorial)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Flutter package for building **step-by-step product tours and feature
discovery**. Highlight any widget on screen, dim everything else, and show an
auto-positioned tooltip that walks the user from one feature to the next — ideal
for onboarding, "what's new" tours, and contextual help.

It works with a single widget you wrap your screen in, plus one `Showcase` per
target. No state management, no boilerplate: drive the whole tour through a small
controller API.

## Preview

![Feature walkthrough](https://raw.githubusercontent.com/abdelrahman-abied/showcase_tutorial/main/preview/demo.gif)

![The example app running on iOS](https://raw.githubusercontent.com/abdelrahman-abied/showcase_tutorial/main/preview/showcase_tutorial.gif)

## Features

- **Step-by-step highlighting** of any widget with an auto-positioned tooltip.
- **Default tooltip** (title + description) or a **fully custom tooltip** widget.
- **Tooltip on any side** — top / bottom / left / right — with full **RTL** support.
- **Exact-shape highlight** — hug a widget's actual painted shape (circle, pill,
  star, icon, logo) automatically with `highlightExactShape`.
- **Pulsing highlight ring** — an optional animated ring that pings around the
  target to draw the eye.
- **Tooltip & highlight styling** — custom arrow color/size, a colored border
  around the target, custom scrim color and opacity.
- **Highlight multiple widgets in one step** (e.g. a multi-select control).
- **Global tooltip styling** with `ShowcaseStyle` — set it once, not per step.
- Built-in **action buttons** (Next / Previous / Stop) with customizable text,
  icons, and layout.
- Built-in **progress indicator** (dots or a `1/6` counter) and a **Skip** button
  in the default tooltip.
- **Floating action widget** — a screen-anchored control (e.g. a fixed Skip /
  Next button) shown per step or tour-wide.
- **Auto-play**, **auto-scroll** to off-screen targets, and **background blur**.
- **Programmatic control**: `next()`, `previous()`, `goTo()`, `goToKey()`,
  `dismiss()`, plus live progress (`currentIndex`, `totalSteps`).
- **Conditional / branching tours** — let a step decide the next step at runtime
  with `onResolveNextStep`.
- **Lifecycle callbacks** — per-step (`onShow` / `onDismiss`) and tour-level
  (`onStart` / `onComplete` / `onFinish`, plus `onDismiss` for early close), and
  configurable background-tap behavior.
- **Run the tour only once** for onboarding, and **auto-skip** steps whose target
  isn't on screen.
- **Accessibility** built in — keyboard navigation (Esc / arrows / Enter) and
  screen-reader announcements.
- **Target interaction callbacks**: tap, double-tap, long-press.
- **Enable/disable** the whole tour with a single flag.

## Table of contents

- [Installation](#installation)
- [Getting started](#getting-started)
- [Custom tooltip](#custom-tooltip-with-showcasewithwidget)
- [Action buttons](#action-buttons-next--previous--stop)
- [Progress indicator & Skip button](#progress-indicator--skip-button)
- [Floating action widget](#floating-action-widget)
- [Exact-shape highlight](#exact-shape-highlight)
- [Pulsing highlight ring](#pulsing-highlight-ring)
- [Tooltip & highlight styling](#tooltip--highlight-styling)
- [Highlight multiple widgets in one step](#highlight-multiple-widgets-in-one-step)
- [Global styling with `ShowcaseStyle`](#global-styling-with-showcasestyle)
- [Run the tour only once](#run-the-tour-only-once)
- [Auto play](#auto-play)
- [Programmatic control & progress](#programmatic-control--progress)
- [Conditional / branching tours](#conditional--branching-tours)
- [Target interactions](#target-interactions)
- [Step lifecycle callbacks](#step-lifecycle-callbacks)
- [Background (barrier) tap behavior](#background-barrier-tap-behavior)
- [Accessibility & keyboard navigation](#accessibility--keyboard-navigation)
- [Blur the background](#blur-the-background)
- [Tooltip position](#tooltip-position)
- [Skip off-screen steps](#skip-off-screen-steps)
- [Right-to-left (RTL)](#right-to-left-rtl)
- [Enable or disable globally](#enable-or-disable-globally)
- [Auto-scrolling caveat](#auto-scrolling-caveat)
- [API reference](#api-reference)
- [Example](#example)
- [License](#license)

## Installation

1. Add the dependency to your `pubspec.yaml`:

   ```yaml
   dependencies:
     showcase_tutorial: ^1.10.0
   ```

   Or from the command line:

   ```sh
   flutter pub add showcase_tutorial
   ```

2. Import it:

   ```dart
   import 'package:showcase_tutorial/showcase_tutorial.dart';
   ```

## Getting started

A tour is three small steps: wrap the screen, wrap each target, then start.

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

**3. Start the tour** — the order of keys is the order of the steps:

```dart
ShowCaseWidget.of(context).startShowCase([_one, _two]);
```

To start it automatically once the first frame is rendered:

```dart
WidgetsBinding.instance.addPostFrameCallback(
  (_) => ShowCaseWidget.of(context).startShowCase([_one, _two]),
);
```

That's the whole flow. Everything below is optional.

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

## Action buttons (Next / Previous / Stop)

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

## Progress indicator & Skip button

Add a built-in step indicator and a skip control to the default tooltip — no
custom container needed. Both are set once on the `ShowCaseWidget` and default
to off:

```dart
ShowCaseWidget(
  showProgress: true,           // show the step indicator
  // dots (default) or a "1/6" counter:
  progressStyle: ShowcaseProgressStyle.numeric,
  showSkip: true,               // a "Skip" button that ends the whole tour
  skipButtonText: 'Skip tour',  // optional, defaults to 'Skip'
  builder: Builder(builder: (context) => const HomePage()),
);
```

The indicator uses the tooltip's text color and reflects `currentIndex` /
`totalSteps`. Choose its look with `progressStyle`:
`ShowcaseProgressStyle.dots` (one dot per step, active step highlighted — the
default) or `ShowcaseProgressStyle.numeric` (a compact `1/6` counter, handy for
long tours). This affects the **default** tooltip only; a custom `container`
tooltip is left untouched.

## Floating action widget

Pin a control to the screen that stays put while the tour runs — a fixed
**Skip** / **Next** button, a progress chip, a help button — instead of one that
moves with each tooltip. You position it yourself (wrap it in an `Align` or
`Positioned`); it's painted above the tooltip and receives taps.

Set one for the whole tour with `globalFloatingActionWidget` (a builder, so it
can read the tour state via `ShowCaseWidget.of(context)`):

```dart
ShowCaseWidget(
  globalFloatingActionWidget: (context) => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextButton(
        onPressed: ShowCaseWidget.of(context).dismiss, // skip the whole tour
        child: const Text('Skip tour'),
      ),
    ),
  ),
  builder: Builder(builder: (context) => const HomePage()),
);
```

Override it for a single step with `Showcase.floatingActionWidget`, or hide the
global one on specific steps with `hideFloatingActionWidgetForShowcase`:

```dart
ShowCaseWidget(
  globalFloatingActionWidget: (context) => const SkipButton(),
  hideFloatingActionWidgetForShowcase: [lastStepKey], // no Skip on the final step
  builder: ...,
);

Showcase(
  key: stepKey,
  description: 'This step has its own action',
  floatingActionWidget: const Align(
    alignment: Alignment.topRight,
    child: CustomBadge(),
  ),
  child: ...,
);
```

Resolution per step: **`Showcase.floatingActionWidget`** wins; otherwise the
**`globalFloatingActionWidget`** is used unless the step is listed in
**`hideFloatingActionWidgetForShowcase`**.

## Exact-shape highlight

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
> so it won't animate or update until the tour moves on. For typical static UI
> this is invisible. `targetShapeBorder` / `targetBorderRadius` are ignored for
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

## Highlight multiple widgets in one step

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

## Global styling with `ShowcaseStyle`

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

## Run the tour only once

By default the package stores nothing, so the tour replays every time you call
`startShowCase`. To show it only once (typical onboarding), give the
`ShowCaseWidget` a `showcaseId` and an `onShouldStartShowcase` guard, and persist
completion yourself in `onFinish` — with any storage (`shared_preferences`, Hive,
a backend, …):

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

Let a single step linger longer (or advance quicker) than the rest with a
per-step `Showcase.autoPlayDelay`, which overrides the tour-wide one:

```dart
Showcase(
  key: _details,
  description: 'This one has more to read, so it stays up longer.',
  autoPlayDelay: const Duration(seconds: 6), // overrides the tour-wide delay
  child: const Icon(Icons.info),
);
```

## Programmatic control & progress

Drive the tour from anywhere you have a `BuildContext` below the
`ShowCaseWidget`:

```dart
ShowCaseWidget.of(context).next();      // go to the next step
ShowCaseWidget.of(context).previous();  // go to the previous step
ShowCaseWidget.of(context).dismiss();   // stop the whole tour
```

Jump to a specific step and read progress — useful for a "Step 2 of 5" indicator
or a skip-to control:

```dart
final show = ShowCaseWidget.of(context);
show.goTo(2);                 // jump to a step by index
show.goToKey(profileKey);     // ...or by its GlobalKey
final label = '${(show.currentIndex ?? 0) + 1} of ${show.totalSteps}';
final running = show.isShowcaseRunning;
```

Listen to the tour lifecycle on `ShowCaseWidget`:

```dart
ShowCaseWidget(
  onStart: (index, key) => debugPrint('started step $index'),
  onComplete: (index, key) => debugPrint('finished step $index'),
  onFinish: () => debugPrint('tour complete'),
  // Fired only when the tour is closed early (barrier-dismiss, Esc, skip,
  // or dismiss()); `key` is the step the user left off on, or null.
  onDismiss: (key) => debugPrint('tour dismissed at $key'),
  builder: Builder(builder: (context) => const HomePage()),
);
```

`onFinish` fires when the tour completes normally (advances past the last step);
`onDismiss` fires when it's closed early. Exactly one of them runs per tour. Use
`onDismiss` to measure onboarding drop-off — it tells you *which* step the user
bailed on. (This is the tour-level callback; the per-step `Showcase.onDismiss`
fires for every step the tour leaves.)

## Conditional / branching tours

Let a step decide the next step at runtime so the tour can skip ahead or branch
based on app state. Set `onResolveNextStep` on `ShowCaseWidget`: it's called
whenever the tour advances **forward** and returns the `GlobalKey` of the step to
jump to (one of the keys passed to `startShowCase`), or `null` to advance to the
normal next step.

```dart
ShowCaseWidget(
  onResolveNextStep: (currentIndex, currentKey) {
    // e.g. if the user already has items, skip the "add to cart" step
    // and jump straight to checkout.
    if (currentKey == cartKey && userHasItems) return checkoutKey;
    return null; // otherwise advance normally
  },
  builder: Builder(builder: (context) => const HomePage()),
);
```

The resolver is honored by **every** forward path — the Next button, a tap on the
target or tooltip, the barrier, the keyboard, auto-play, and `next()`. The
returned step may be ahead of or behind the current one, and a branch is treated
as an explicit jump (like `goTo`), so `autoSkipUnmountedSteps` is not applied to
the target. `previous()`, `goTo()`, and `goToKey()` ignore the resolver.

## Target interactions

Respond to gestures on the highlighted widget. `onTargetClick` requires
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

Each `Showcase` can report when it becomes visible and when it's left — handy for
analytics or per-step side effects:

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

> Shortcut: `disableBarrierInteraction: true` is equivalent to
> `BarrierInteraction.none`.

To run your own code on a background tap — a hint nudge, a sound, analytics — add
`onBarrierClick`. It fires on every barrier tap **in addition to** the configured
`barrierInteraction`, and runs even when interaction is `.none`:

```dart
ShowCaseWidget(
  barrierInteraction: BarrierInteraction.none, // tap doesn't advance/dismiss…
  onBarrierClick: () => debugPrint('user tapped outside the highlight'), // …but you still hear about it
  builder: Builder(builder: (context) => const HomePage()),
);
```

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

Force the tooltip to a side of the target with `TooltipPosition.top`, `.bottom`,
`.left`, or `.right` (defaults to whichever vertical space is available):

```dart
Showcase(
  key: _one,
  description: 'Shown to the right of the target',
  tooltipPosition: TooltipPosition.right,
  child: const Icon(Icons.menu),
);
```

> `left` / `right` use the default title/description tooltip; custom `container`
> tooltips and action buttons keep top/bottom placement.

Add extra space between the target and the tooltip with `targetTooltipGap`
(logical pixels, default `0`). It applies to every side:

```dart
Showcase(
  key: _one,
  description: 'Sits a little further from the target',
  targetTooltipGap: 16,
  child: const Icon(Icons.menu),
);
```

Keep the tooltip clear of the screen edges with `toolTipMargin` (default
`EdgeInsets.all(20)`). The tooltip is clamped to stay at least this far from each
edge, and its size is capped to fit within the margins — useful to leave room
for a status bar, notch, or your own fixed UI:

```dart
Showcase(
  key: _one,
  description: 'Stays clear of the edges',
  toolTipMargin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
  child: const Icon(Icons.menu),
);
```

## Skip off-screen steps

If some showcased widgets are rendered conditionally, enable
`autoSkipUnmountedSteps` so steps whose target isn't currently in the widget tree
are skipped automatically instead of showing an empty overlay:

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

## Enable or disable globally

```dart
ShowCaseWidget(
  enableShowcase: false, // every Showcase just renders its child, no overlay
  builder: Builder(builder: (context) => const HomePage()),
);
```

## Auto-scrolling caveat

Set `enableAutoScroll: true` to scroll an off-screen target into view before its
step starts. This does **not** work reliably in scroll views that build children
on demand (e.g. `ListView`, `GridView`), because the target widget may not be
attached to the tree when the tour reaches that step.

Control where the target lands with `scrollAlignment` (a fraction of the scroll
axis: `0.0` = leading edge, `0.5` = centered, `1.0` = trailing edge). Set it
tour-wide on `ShowCaseWidget` (default `0.5`) and override it per step with
`Showcase.scrollAlignment`:

```dart
ShowCaseWidget(
  enableAutoScroll: true,
  scrollAlignment: 0.1, // rest targets near the top of the viewport
  builder: Builder(builder: (context) => const HomePage()),
);

// ...and per step:
Showcase(
  key: _key,
  scrollAlignment: 0.5, // this step centers instead
  description: 'Centered when scrolled into view',
  child: child,
);
```

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

## API reference

### Controller — `ShowCaseWidget.of(context)`

| Member                                       | Description                                                              |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| `startShowCase(List<GlobalKey> keys, {bool force})` | Start the tour in key order. `force: true` bypasses `onShouldStartShowcase`. |
| `next()`                                     | Advance to the next step.                                                |
| `previous()`                                 | Go back one step.                                                        |
| `goTo(int index)`                            | Jump to a step by its zero-based index.                                  |
| `goToKey(GlobalKey key)`                     | Jump to a step by its `GlobalKey`.                                       |
| `dismiss()`                                  | End the whole tour.                                                      |
| `currentIndex`                               | Zero-based index of the active step, or `null` when no tour is running.  |
| `totalSteps`                                 | Number of steps in the running tour (0 when none).                       |
| `isShowcaseRunning`                          | Whether a tour is currently active.                                      |

### `ShowCaseWidget` properties

| Name                      | Type                       | Default                        | Description                                                                      |
| ------------------------- | -------------------------- | ------------------------------ | -------------------------------------------------------------------------------- |
| builder                   | Builder                    | required                       | Builds the subtree that contains the `Showcase` widgets.                         |
| style                     | ShowcaseStyle              | `const ShowcaseStyle()`        | Default tooltip styling for every `Showcase` in the tree.                        |
| blurValue                 | double                     | 0                              | Gaussian blur applied to the overlay.                                            |
| autoPlay                  | bool                       | false                          | Automatically advance to the next step.                                          |
| autoPlayDelay             | Duration                   | `Duration(milliseconds: 2000)` | Visibility time of a step when `autoPlay` is enabled.                            |
| enableAutoPlayLock        | bool                       | false                          | Block user interaction on the overlay while auto-playing.                        |
| enableAutoScroll          | bool                       | false                          | Auto-scroll so the next target becomes visible.                                  |
| scrollDuration            | Duration                   | `Duration(milliseconds: 300)`  | Duration of the auto-scroll animation.                                           |
| scrollAlignment           | double                     | `0.5`                          | Where an auto-scrolled target rests (0 = leading, 0.5 = center, 1 = trailing).   |
| barrierInteraction        | BarrierInteraction         | `BarrierInteraction.next`      | What a background tap does: `next` (advance), `dismiss` (end tour), `none`.      |
| disableBarrierInteraction | bool                       | false                          | Shortcut; `true` makes the barrier inert (same as `BarrierInteraction.none`).    |
| onBarrierClick            | VoidCallback?              |                                | Called on every barrier tap (even when `barrierInteraction` is `none`).          |
| globalFloatingActionWidget | WidgetBuilder?            |                                | Screen-anchored widget shown above the overlay on every step (you position it).  |
| hideFloatingActionWidgetForShowcase | `List<GlobalKey>` | `const []`                    | Steps on which the global floating widget is hidden.                             |
| disableScaleAnimation     | bool                       | false                          | Disable the tooltip scale transition for all steps.                              |
| disableMovingAnimation    | bool                       | false                          | Disable the bouncing/moving transition for all steps.                            |
| onStart                   | Function(int?, GlobalKey)? |                                | Called on the start of each step.                                                |
| onComplete                | Function(int?, GlobalKey)? |                                | Called on the completion of each step.                                           |
| onFinish                  | VoidCallback?              |                                | Called when all steps are completed (normal finish).                             |
| onDismiss                  | `void Function(GlobalKey?)?` |                              | Called when the tour is closed early; receives the step it was dismissed at.     |
| enableShowcase            | bool                       | true                           | Enable or disable showcasing globally.                                           |
| autoSkipUnmountedSteps    | bool                       | false                          | Skip steps whose target widget is not currently mounted.                         |
| enableKeyboardNavigation  | bool                       | true                           | Drive the active step with a hardware keyboard (Esc / arrows / Enter).           |
| enableAutoAnnouncements   | bool                       | true                           | Announce each step's title/description to screen readers.                        |
| showProgress              | bool                       | false                          | Show the built-in step indicator in the default tooltip.                         |
| progressStyle             | ShowcaseProgressStyle      | `ShowcaseProgressStyle.dots`   | Indicator style: dots or a `1/6` numeric counter.                                |
| showSkip                  | bool                       | false                          | Show a "Skip" button in the default tooltip that ends the tour.                  |
| skipButtonText            | String                     | 'Skip'                         | Label for the skip button.                                                       |
| showcaseId                | String?                    |                                | Identifier passed to `onShouldStartShowcase`.                                    |
| onShouldStartShowcase     | `FutureOr<bool> Function(String?)?` |                         | Guard run before a tour starts; return `false` to skip it.                       |
| onResolveNextStep         | GlobalKey? Function(int, GlobalKey)? |                     | Decide the next step at runtime: return a step key to branch, or `null`.         |

### `Showcase` and `Showcase.withWidget` properties

| Name                         | Type                   | Default                                            | Description                                                                                 | `Showcase` | `Showcase.withWidget` |
| ---------------------------- | ---------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------- | :--------: | :-------------------: |
| key                          | GlobalKey              | required                                           | Unique global key for the step.                                                             |     ✅     |          ✅           |
| child                        | Widget                 | required                                           | The target widget to highlight.                                                             |     ✅     |          ✅           |
| keys                         | `List<GlobalKey>?`     |                                                    | Extra widgets to highlight in the same step (wrap each in a `MultiView`).                   |     ✅     |          ✅           |
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
| tooltipPosition              | TooltipPosition?       |                                                    | Force the tooltip to a side (`top` / `bottom` / `left` / `right`).                          |     ✅     |          ✅           |
| actions                      | Widget?                |                                                    | Action buttons widget (e.g. `ShowCaseDefaultActions`).                                      |     ✅     |          ✅           |
| actionSettings               | ActionsSettings?       | `const ActionsSettings()`                          | Container styling for the action buttons.                                                   |     ✅     |          ✅           |
| actionButtonsPosition        | ActionButtonsPosition? |                                                    | Manual position for the action buttons.                                                     |     ✅     |          ✅           |
| floatingActionWidget         | Widget?                |                                                    | Screen-anchored widget shown while this step is active (overrides the global one).          |     ✅     |          ✅           |
| autoPlayDelay                | Duration?              | `ShowCaseWidget.autoPlayDelay`                     | Per-step auto-play visibility time, overriding the tour-wide delay.                          |     ✅     |          ✅           |
| targetTooltipGap             | double                 | `0`                                                | Extra space (logical px) between the target and the tooltip; applies to all sides.          |     ✅     |          ✅           |
| toolTipMargin                | EdgeInsets             | `EdgeInsets.all(20)`                               | Minimum margin between the tooltip and the screen edges (also caps its size).               |     ✅     |          ✅           |
| scrollAlignment              | double?                | `ShowCaseWidget.scrollAlignment`                   | Where this step's target rests when auto-scrolled (0 = leading, 0.5 = center, 1 = trailing).|     ✅     |          ✅           |
| targetShapeBorder            | ShapeBorder            | `RoundedRectangleBorder(...)`                      | Shape applied to the highlight (used when `targetBorderRadius` is null).                    |     ✅     |          ✅           |
| highlightExactShape          | bool                   | false                                              | Highlight the target by its actual painted shape (snapshot) instead of `targetShapeBorder`. |     ✅     |          ✅           |
| targetBorderRadius           | BorderRadius?          |                                                    | Border radius of the highlight.                                                             |     ✅     |          ✅           |
| enablePulseAnimation         | bool                   | false                                              | Draw an animated ring that pulses outward around the highlight.                             |     ✅     |          ✅           |
| pulseColor                   | Color?                 | `ShowcaseStyle` → `Colors.white`                   | Color of the pulsing ring.                                                                  |     ✅     |          ✅           |
| pulseDuration                | Duration               | `Duration(milliseconds: 1500)`                     | Length of one full pulse cycle (smaller is faster).                                         |     ✅     |          ✅           |
| highlightBorderColor         | Color?                 |                                                    | Color of a border drawn around the highlight (off when null).                               |     ✅     |          ✅           |
| highlightBorderWidth         | double?                | `2`                                                | Width of the highlight border.                                                              |     ✅     |          ✅           |
| arrowColor                   | Color?                 | `ShowcaseStyle` → tooltip bg                       | Color of the default tooltip arrow.                                                         |     ✅     |                       |
| arrowWidth                   | double?                | `18`                                               | Width (base) of the default tooltip arrow.                                                  |     ✅     |                       |
| arrowHeight                  | double?                | `9`                                                | Height (depth) of the default tooltip arrow.                                                |     ✅     |                       |
| targetPadding                | EdgeInsets             | `EdgeInsets.zero`                                  | Padding around the highlight.                                                               |     ✅     |          ✅           |
| overlayColor                 | Color                  | `Colors.black45`                                   | Color of the overlay scrim.                                                                 |     ✅     |          ✅           |
| overlayOpacity               | double                 | 0.75                                               | Opacity of the overlay scrim.                                                               |     ✅     |          ✅           |
| blurValue                    | double?                | `ShowCaseWidget.blurValue`                         | Gaussian blur on the overlay.                                                               |     ✅     |          ✅           |
| disableDefaultTargetGestures | bool                   | false                                              | Disable the default gestures on the target.                                                 |     ✅     |          ✅           |
| disposeOnTap                 | bool?                  |                                                    | Dismiss the whole tour when the target/tooltip is tapped.                                   |     ✅     |          ✅           |
| onTargetClick                | VoidCallback?          |                                                    | Called when the target is tapped (requires `disposeOnTap`).                                 |     ✅     |          ✅           |
| onTargetDoubleTap            | VoidCallback?          |                                                    | Called when the target is double-tapped.                                                    |     ✅     |          ✅           |
| onTargetLongPress            | VoidCallback?          |                                                    | Called when the target is long-pressed.                                                     |     ✅     |          ✅           |
| onToolTipClick               | VoidCallback?          |                                                    | Called when the tooltip is tapped.                                                          |     ✅     |                       |
| onShow                       | VoidCallback?          |                                                    | Called when this step becomes active.                                                       |     ✅     |          ✅           |
| onDismiss                    | VoidCallback?          |                                                    | Called when this step stops being active (advanced past, navigated away, or dismissed).     |     ✅     |          ✅           |
| semanticLabel                | String?                |                                                    | Text announced to screen readers for this step (defaults to title + description).           |     ✅     |          ✅           |
| disableMovingAnimation       | bool?                  | `ShowCaseWidget.disableMovingAnimation`            | Disable the bouncing/moving transition.                                                     |     ✅     |          ✅           |
| disableScaleAnimation        | bool?                  | `ShowCaseWidget.disableScaleAnimation`             | Disable the initial scale transition.                                                       |     ✅     |                       |
| movingAnimationDuration      | Duration               | `Duration(milliseconds: 2000)`                     | Duration of the moving animation.                                                           |     ✅     |          ✅           |
| scaleAnimationDuration       | Duration               | `Duration(milliseconds: 300)`                      | Duration of the scale animation.                                                            |     ✅     |                       |
| scaleAnimationCurve          | Curve                  | `Curves.easeIn`                                    | Curve of the scale animation.                                                               |     ✅     |                       |
| scaleAnimationAlignment      | Alignment?             |                                                    | Origin of the scale animation.                                                              |     ✅     |                       |
| scrollLoadingWidget          | Widget                 | `CircularProgressIndicator(...)`                   | Loading widget shown while auto-scrolling to the target.                                    |     ✅     |          ✅           |

## Example

See the full [example app](example) for the menu, profile, custom action
buttons, global styling, and the multi-widget step in action.

## License

Released under the [MIT License](LICENSE).
