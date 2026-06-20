# showcase_tutorial

[![pub package](https://img.shields.io/badge/showcase_tutorial-1.3.0-blue)](https://pub.dev/packages/showcase_tutorial)
[![GitHub stars](https://img.shields.io/github/stars/abdelrahman-abied/showcase_tutorial?style=social)](https://github.com/abdelrahman-abied/showcase_tutorial)

A Flutter package to **showcase / highlight your widgets step by step** — perfect for
onboarding tours and feature discovery.

## Preview

![The example app running in iOS](https://github.com/abdelrahman-abied/showcase_tutorial/blob/main/preview/showcase_tutorial.gif)

## Features

- Step-by-step highlight of any widget with an auto-positioned tooltip.
- Default tooltip (title + description) or a fully custom tooltip widget.
- **Highlight multiple widgets in a single step** (e.g. multi-select).
- **Global tooltip styling** via `ShowcaseStyle` — set it once, not per step.
- Built-in **action buttons** (Next / Previous / Stop).
- Auto-play, auto-scroll, and background blur.
- Programmatic control: `next()`, `previous()`, `dismiss()`.
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

## Blur the background

```dart
// For all steps:
ShowCaseWidget(blurValue: 2, builder: ...);

// Or per step:
Showcase(blurValue: 2, key: _one, description: '...', child: ...);
```

## Tooltip position

Force the tooltip above or below the target (defaults to whatever space is
available):

```dart
Showcase(
  key: _one,
  description: 'Always shown on top',
  tooltipPosition: TooltipPosition.top,
  child: const Icon(Icons.menu),
);
```

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

| Name                      | Type                       | Default                       | Description                                                              |
|---------------------------|----------------------------|-------------------------------|--------------------------------------------------------------------------|
| builder                   | Builder                    | required                      | Builds the subtree that contains the `Showcase` widgets.                 |
| style                     | ShowcaseStyle              | `const ShowcaseStyle()`       | Default tooltip styling for every `Showcase` in the tree.                |
| blurValue                 | double                     | 0                             | Gaussian blur applied to the overlay.                                    |
| autoPlay                  | bool                       | false                         | Automatically advance to the next showcase.                              |
| autoPlayDelay             | Duration                   | `Duration(milliseconds: 2000)`| Visibility time of a showcase when `autoPlay` is enabled.                |
| enableAutoPlayLock        | bool                       | false                         | Block user interaction on the overlay while auto-playing.                |
| enableAutoScroll          | bool                       | false                         | Auto-scroll so the next target becomes visible.                          |
| scrollDuration            | Duration                   | `Duration(milliseconds: 300)` | Duration of the auto-scroll animation.                                   |
| disableBarrierInteraction | bool                       | false                         | Disable advancing the tour by tapping the overlay.                       |
| disableScaleAnimation     | bool                       | false                         | Disable the tooltip scale transition for all showcases.                  |
| disableMovingAnimation    | bool                       | false                         | Disable the bouncing/moving transition for all showcases.               |
| onStart                   | Function(int?, GlobalKey)? |                               | Called on the start of each showcase.                                    |
| onComplete                | Function(int?, GlobalKey)? |                               | Called on the completion of each showcase.                               |
| onFinish                  | VoidCallback?              |                               | Called when all showcases are completed.                                 |
| enableShowcase            | bool                       | true                          | Enable or disable showcasing globally.                                   |

## Properties of `Showcase` and `Showcase.withWidget`

| Name                         | Type             | Default                                          | Description                                                                                   | `Showcase` | `Showcase.withWidget` |
|------------------------------|------------------|--------------------------------------------------|-----------------------------------------------------------------------------------------------|:----------:|:---------------------:|
| key                          | GlobalKey        | required                                         | Unique global key for the showcase.                                                           | ✅ | ✅ |
| child                        | Widget           | required                                         | The target widget to be showcased.                                                            | ✅ | ✅ |
| keys                         | List<GlobalKey>? |                                                  | Extra widgets to highlight in the same step (wrap each in a `MultiView`).                      | ✅ | ✅ |
| title                        | String?          |                                                  | Title of the default tooltip.                                                                 | ✅ | |
| description                  | String?          |                                                  | Description of the default tooltip (optional).                                                | ✅ | |
| container                    | Widget?          |                                                  | A fully custom tooltip widget.                                                                | | ✅ |
| height                       | double?          |                                                  | Height of the custom tooltip.                                                                 | | ✅ |
| width                        | double?          |                                                  | Width of the custom tooltip.                                                                  | | ✅ |
| titleTextStyle               | TextStyle?       | `ShowcaseStyle`                                  | Text style of the title.                                                                      | ✅ | |
| descTextStyle                | TextStyle?       | `ShowcaseStyle`                                  | Text style of the description.                                                                | ✅ | |
| titleAlignment               | TextAlign        | `TextAlign.start`                                | Alignment of the title.                                                                       | ✅ | |
| descriptionAlignment         | TextAlign        | `TextAlign.start`                                | Alignment of the description.                                                                 | ✅ | |
| tooltipBackgroundColor       | Color?           | `ShowcaseStyle` → `Colors.white`                 | Background color of the default tooltip.                                                      | ✅ | |
| textColor                    | Color?           | `ShowcaseStyle` → `Colors.black`                 | Text color of the default tooltip.                                                            | ✅ | |
| tooltipBorderRadius          | BorderRadius?    | `ShowcaseStyle` → `BorderRadius.circular(8)`     | Border radius of the default tooltip.                                                         | ✅ | |
| tooltipPadding               | EdgeInsets       | `EdgeInsets.symmetric(vertical: 8, horizontal: 8)` | Padding inside the tooltip.                                                                 | ✅ | |
| titlePadding                 | EdgeInsets?      | `EdgeInsets.zero`                                | Padding around the title.                                                                     | ✅ | |
| descriptionPadding           | EdgeInsets?      | `EdgeInsets.zero`                                | Padding around the description.                                                               | ✅ | |
| showArrow                    | bool             | true                                             | Show the tooltip arrow pointing at the target.                                               | ✅ | |
| tooltipPosition              | TooltipPosition? |                                                  | Force the tooltip above (`top`) or below (`bottom`) the target.                              | ✅ | ✅ |
| actions                      | Widget?          |                                                  | Action buttons widget (e.g. `ShowCaseDefaultActions`).                                        | ✅ | ✅ |
| actionSettings               | ActionsSettings? | `const ActionsSettings()`                        | Container styling for the action buttons.                                                     | ✅ | ✅ |
| actionButtonsPosition        | ActionButtonsPosition? |                                            | Manual position for the action buttons.                                                       | ✅ | ✅ |
| targetShapeBorder            | ShapeBorder      | `RoundedRectangleBorder(...)`                    | Shape applied to the highlighted target (used when `targetBorderRadius` is null).             | ✅ | ✅ |
| targetBorderRadius           | BorderRadius?    |                                                  | Border radius of the highlighted target.                                                      | ✅ | ✅ |
| targetPadding                | EdgeInsets       | `EdgeInsets.zero`                                | Padding around the highlighted target.                                                        | ✅ | ✅ |
| overlayColor                 | Color            | `Colors.black45`                                 | Color of the overlay.                                                                          | ✅ | ✅ |
| overlayOpacity               | double           | 0.75                                             | Opacity of the overlay.                                                                        | ✅ | ✅ |
| blurValue                    | double?          | `ShowCaseWidget.blurValue`                       | Gaussian blur on the overlay.                                                                  | ✅ | ✅ |
| disableDefaultTargetGestures | bool             | false                                            | Disable the default gestures on the target.                                                   | ✅ | ✅ |
| disposeOnTap                 | bool?            |                                                  | Dismiss all showcases when the target/tooltip is tapped.                                       | ✅ | ✅ |
| onTargetClick                | VoidCallback?    |                                                  | Called when the target is tapped (requires `disposeOnTap`).                                    | ✅ | ✅ |
| onTargetDoubleTap            | VoidCallback?    |                                                  | Called when the target is double-tapped.                                                       | ✅ | ✅ |
| onTargetLongPress            | VoidCallback?    |                                                  | Called when the target is long-pressed.                                                        | ✅ | ✅ |
| onToolTipClick               | VoidCallback?    |                                                  | Called when the tooltip is tapped.                                                             | ✅ | |
| disableMovingAnimation       | bool?            | `ShowCaseWidget.disableMovingAnimation`          | Disable the bouncing/moving transition.                                                       | ✅ | ✅ |
| disableScaleAnimation        | bool?            | `ShowCaseWidget.disableScaleAnimation`           | Disable the initial scale transition.                                                          | ✅ | |
| movingAnimationDuration      | Duration         | `Duration(milliseconds: 2000)`                   | Duration of the moving animation.                                                             | ✅ | ✅ |
| scaleAnimationDuration       | Duration         | `Duration(milliseconds: 300)`                    | Duration of the scale animation.                                                              | ✅ | |
| scaleAnimationCurve          | Curve            | `Curves.easeIn`                                  | Curve of the scale animation.                                                                 | ✅ | |
| scaleAnimationAlignment      | Alignment?       |                                                  | Origin of the scale animation.                                                                | ✅ | |
| scrollLoadingWidget          | Widget           | `CircularProgressIndicator(...)`                 | Loading widget shown while auto-scrolling to the target.                                       | ✅ | ✅ |

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
