# Changelog

## Unreleased

* **Docs fix:** the "Listening from anywhere in the tree" example called
  `ShowCaseWidget.of(context)` in `dispose`, which throws in debug builds, and
  registered its listener again on every dependency change. It now keeps the
  controller from `initState` and uses it in `dispose`. The listener methods'
  docs say the same.
* **Docs: [Coming from showcaseview](https://github.com/abdelrahman-abied/showcase_tutorial#coming-from-showcaseview).**
  A new README section for apps switching from showcaseview 5.x. It covers
  setup (`ShowcaseView.register` becomes `ShowCaseWidget`), controlling the
  tour, action buttons, a table that maps each showcaseview API to its
  equivalent here, and the behaviour that differs.
* **Start the tour after a delay:** `startShowCase(keys, delay: ...)`. The
  call returns at once and the tour starts when the delay ends, for example
  once a screen's entrance animation is done. An `onShouldStartShowcase`
  guard is asked when the delay ends, so it sees whether the tour was
  completed in the meantime. Without a delay the tour starts at once, as
  before. `isStartPending` tells whether a start is still waiting, and
  `cancelDelayedStart()` calls it off without firing any callback. A waiting
  start is also called off by `dismiss()`, by another `startShowCase`, by
  turning `enableShowcase` off, or when the `ShowCaseWidget` goes away. The
  delay belongs to the `ShowCaseWidget`, not to the screen that asked for it:
  a page that schedules a delayed start should call `cancelDelayedStart()` in
  its `dispose`, or the tour still starts after the page is closed.
* **Listen for the end of a tour from anywhere:** `addOnFinishCallback` /
  `removeOnFinishCallback` and `addOnDismissCallback` /
  `removeOnDismissCallback` on `ShowCaseWidget.of(context)`. They work like
  `addOnStartCallback`: they run after `onFinish` / `onDismiss`, in the order
  they were added, and a listener can remove itself while it runs.
* **Auto-scroll per step:** `Showcase.enableAutoScroll`. `true` scrolls to
  that step's target even when the tour doesn't auto-scroll, `false` leaves
  the page where it is for that step. Unset, it follows
  `ShowCaseWidget.enableAutoScroll`, as before.
* **Background taps per step:** `Showcase.onBarrierClick`, called when the
  dimmed background is tapped while that step shows. It runs after the
  tour-wide `ShowCaseWidget.onBarrierClick`, not instead of it, and both run
  on every tap, even with `BarrierInteraction.none`.
* **Set the dimmed background's opacity once:**
  `ShowcaseStyle(overlayOpacity: ...)`. A step's own `overlayOpacity` still
  wins, and with neither set it is 0.75, as before.
* **Text in the other direction:** `Showcase.titleTextDirection` and
  `Showcase.descriptionTextDirection`, for example an Arabic title in an
  English app. The tooltip is measured with the same direction, and screen
  readers announce the step in it. Unset, the text follows the app, as
  before.
* These cover the showcaseview 5.x features the "Coming from showcaseview"
  table listed as missing, under the same names.
* **Choose what the back button does during a step:**
  `ShowCaseWidget.backButtonInteraction`, with the new
  `BackButtonInteraction` enum. `passThrough`, the default, leaves back as it
  is today: it closes the page. `dismiss` ends the tour and keeps the page
  open, `previous` goes to the previous step (and ends the tour from the
  first step), and `block` ignores back. It covers the Android back button
  and gesture, predictive back included, and the browser's back button. It
  only acts while a step is on screen, not while the tour waits for a page
  or a step is hidden under another page or a dialog, and it works with
  `ShowCaseWidget` on a page or in `MaterialApp.builder`. Esc still
  dismisses the tour through keyboard navigation.
* **Prepare a step before it shows:** `ShowCaseWidget.onBeforeStep`, an
  `(index, key)` callback that runs before each step is shown. Return a
  `Future` and the tour waits for it, to scroll, load data or open the
  step's page first. It runs after the tour has chosen the step (`startAt`,
  `onResolveNextStep` and the unmounted-step skip rules work as before) and
  before that step's `onStart`. While it waits nothing is shown, and
  `isPreparingStep` is `true`. If the tour moves meanwhile (`next`,
  `previous`, `goTo`, `dismiss`, `startShowCase`, `enableShowcase` off), the
  step being prepared is given up and never shows; calling `next()` from the
  callback skips its step. An error in it is reported to
  `FlutterError.onError` and the step shows anyway. A callback that returns
  nothing shows the step on the same frame as before, and without the
  callback nothing changes.

**Fixed:**

* An asynchronous `onShouldStartShowcase` could start a tour that had been
  called off while it was deciding: after `dismiss()`, after
  `enableShowcase` was turned off (the tour then ran while disabled), or
  after a newer `startShowCase`, whose tour it then replaced. Its answer now
  only counts for the latest start, while the showcase is enabled.
* Closing a tour twice in quick succession, such as two taps on the dimmed
  background with `BarrierInteraction.dismiss`, or two of Skip, Esc or a
  `disposeOnTap` tap, reported the dismissal twice: `onDismiss` was called
  again with `null`. A tap now ends the tour only if the tour is still on
  that step when its closing animation is done, which also keeps it from
  ending a tour that started meanwhile.

**Types:** `Showcase.overlayOpacity` is now a `double?` (it was a `double`
that defaulted to 0.75), so that a step that doesn't set it can use
`ShowcaseStyle.overlayOpacity`. Passing a value works as before. Only code
that reads `overlayOpacity` back from a `Showcase` and expects a `double`
needs a change, for example `showcase.overlayOpacity ?? 0.75`.

## 2.0.3

Three fixes. Nothing to change in your code.

* **Fixed:** tapping the target of a step with `disposeOnTap: true` and no
  `onTargetClick` threw a null-check error. It happened with
  `Showcase.withWidget` in every build, and with `Showcase` in release builds
  (debug builds stopped it earlier with an assert). The tap now ends the tour,
  as `disposeOnTap` describes. This bug dates back to the package's origins.
* **`Showcase.withWidget` no longer needs `height` and `width`.** Leave them
  out and the container is placed by its own laid-out size: above or below
  the target by its height, within `toolTipMargin` by its width. It is
  measured before it is shown, so it never appears in the wrong place first.
  Code that passes them works as before, and the container lands exactly
  where it did.
* **A tooltip that does not fit moves to where it does.** A `tooltipPosition`
  the tooltip does not fit on, off screen or over the target, gives way to
  the opposite side when it fits there: `top` and `bottom` swap, as do `left`
  and `right`. With no position set, a default tooltip that fits neither
  above nor below its target, such as next to a tall one, goes to its left or
  right. It only moves to a side where all of it, buttons included, fits on
  the screen above the keyboard. A tooltip that fits stays exactly where it
  was (a test checks this across thousands of placements, on small screens,
  with large text and with the keyboard open), and one that fits nowhere is
  placed as before. A `Showcase.withWidget` container moves only when it is
  measured: with a `height` it stays on the side you ask for, as before.
  Buttons inside the tooltip count toward whether it fits where it is only
  with `ActionsSettings.containerHeight` set, so without it a tooltip that
  misses by less than its button row may stay where it is.

## 2.0.2

Fixes the pub.dev score. Nothing changes in the package or your code.

* **Fixed:** 2.0.1 scored 150 of 160 on pub.dev, because the preview's
  description in `pubspec.yaml` was longer than the 160 characters pub.dev
  allows. It is shorter now, and a test checks the length and that each
  listed screenshot exists.
* The example and benchmark apps build for Android with current Flutter
  without workarounds: Android Gradle Plugin 9.3.1, Kotlin 2.4.20 and Gradle
  9.5.0, up from 9.1.0, 2.4.0 and 9.3.1.

## 2.0.1

A faster tour, a migration guide, and one demo that shows the whole package.
Nothing to change in your code.

* **Faster.** A showing step does about half the work it did:

  | Widget rebuilds | 2.0.0 | Now |
  | --- | ---: | ---: |
  | When a tour starts | 100 | 51 |
  | On each step change | 121 | 48 |
  | On each frame while a step shows | 1 | 0 |

  * The tooltip's scale-in and its gentle bobbing are now applied when it is
    painted, instead of rebuilding widgets on every frame.
  * The animated tooltip is painted on its own layer, so a frame no longer
    repaints the dimmed background and the cut-out.
  * Keyboard focus stays in the tour from one step to the next, instead of
    going back to the page and returning.
  * The pulse ring repaints without rebuilding.

  In the repo's benchmark (a 60-step tour), tour start and step changes take
  about 28% less time and a steady frame 18% less. On a mid-range Android
  phone in profile mode, the app's own work per frame (build time) is about
  19% lower; total frame time is about the same, because drawing on the GPU
  dominates it and that did not change.
* **New: a migration guide** in the README,
  [Migrating from 1.x to 2.0](https://github.com/abdelrahman-abied/showcase_tutorial#migrating-from-1x-to-20).
  It covers what changes when you upgrade, how to keep the 1.x look, what to
  replace before 3.0.0, and which property types changed.
* **One preview instead of three.** The README and pub.dev now show one GIF,
  recorded on an Android phone, of a travel app whose tour uses most of the
  package: an exact-shape highlight, two widgets in one step, auto-scroll with
  a pulse ring, a step that continues on the next screen and ends in a custom
  tooltip, then the same tour in dark mode and in Arabic. The three old GIFs,
  which showed the 1.x look, are removed.
* **New example: `example/lib/trips_demo.dart`**, the app in the preview. It
  sets no colours. It starts its tour on first open, offers to resume a tour
  you stopped, skips the offer step once you close the banner, and skips
  check-in once you have checked in. Its settings menu switches dark mode,
  Arabic, auto-play, a blurred background and buttons below the tooltip. Open
  it from the example's Feature demos page, or run it on its own with
  `flutter run -t lib/trips_demo_main.dart`.
* Tests now tap the built-in Next, Previous and Stop buttons, inside and
  outside the tooltip, and on a tooltip drawn above its target.

## 2.0.0

A tour that matches your app: its colours follow your theme in light and dark
mode, its buttons follow right-to-left layouts and speak your language, and a
tour can pick up where the user left off.

**Most apps need no code changes**, but the tour looks different after
upgrading. See **Upgrading from 1.x** below.

### New

* **Colours follow your theme.** Any colour you don't set comes from your
  app's `material_ui` `ColorScheme`, so the tour matches your app and switches
  with light and dark mode. A step that is showing while the app switches is
  recoloured at once.

  | Part of the tour | Before | Now |
  | --- | --- | --- |
  | Tooltip background | white | `surfaceContainerHigh`, the surface a dialog has |
  | Title, description, progress, Skip | black | `onSurface` |
  | Action button labels and icons | light blue `0xff48cae4` | `primary` |
  | Divider between action buttons | pale blue `0xffcaf0f8` | `outlineVariant` |
  | Dimmed background | black | `scrim` (black unless your theme changes it) |

  A colour you set still wins, per step or in `ShowcaseStyle`. If you set a
  tooltip background but no text colour, the text is white or black,
  whichever can be read on it. Buttons on a background you chose, or directly
  on the dimmed background, are picked the same way, and so are the pulse ring
  and the scroll spinner.
* **Every colour in one place.** `ShowcaseStyle` gains `overlayColor`,
  `actionTextColor`, `actionDividerColor` and `loadingIndicatorColor`.
* **Translate the tour once.** `ShowCaseWidget.labels` takes a
  `ShowcaseLabels(next:, previous:, stop:, skip:)` for the built-in buttons.
  A button's own `ActionButtonConfig.text` still wins. Labels update while the
  tour is showing if the app changes language. An icon-only button now has its
  label for screen readers.
* **Resume a tour.** `startShowCase(keys, startAt: savedIndex)` opens the tour
  on that step. Save the index in `onStart` and clear it in `onFinish` /
  `onDismiss`. A saved index that no longer fits (say, after an update made
  the tour shorter) is clamped to the first or last step instead of failing.
* **`builder` takes any widget.** `builder: const HomePage()` works; you no
  longer need `Builder(builder: (context) => const HomePage())`, though it
  still works.

### Fixed

* **Right-to-left apps:** the built-in buttons forced left-to-right inside
  each button, so in Arabic or Hebrew the icon sat on the wrong side of its
  label. They now follow the app's direction.
* **A button label no longer breaks mid-word** ("Previou" / "s") in a narrow
  tooltip. Labels stay on one line, the tooltip is made wide enough for the
  built-in buttons, and a label that still doesn't fit is shrunk slightly
  (never below 70%) and then shortened with "…".
* **Action button icons take the label's colour.** On the dimmed background
  the labels were readable but the icons were not. An icon with its own colour
  keeps it.

### Upgrading from 1.x

* **The tour looks different.** To keep the 1.x look, set it once:

  ```dart
  ShowCaseWidget(
    style: const ShowcaseStyle(
      tooltipBackgroundColor: Colors.white,
      textColor: Colors.black,
      actionTextColor: Color(0xff48cae4),
      actionDividerColor: Color(0xffcaf0f8),
    ),
    builder: const HomePage(),
  );
  ```

  Apps without a `material_ui` theme (for example, still on `MaterialApp` from
  `package:flutter/material.dart`) keep the 1.x colours.
* **The built-in buttons changed shape slightly.** Text-only and icon-only
  buttons are centred, tooltips with built-in buttons may be a little wider so
  the labels fit, and `ActionsSettings.containerColor` now defaults to the
  tooltip's colour instead of white (pass `Colors.transparent` for none).
* **Right-to-left apps:** the icon in each built-in button now sits on the
  right of its label. Pass `textDirection: TextDirection.ltr` to a button's
  `ActionButtonConfig` to keep the old order.
* **Deprecated, removed in 3.0.0:**
  * `ShowCaseWidget.skipButtonText`: use `labels: ShowcaseLabels(skip: ...)`.
    It still works and wins over `labels.skip`.
  * `ShowCaseWidget.disableBarrierInteraction`: use
    `barrierInteraction: BarrierInteraction.none`.
* **Types.** Only code that reads these back (rather than passing them) can
  break:
  * Now nullable, where `null` means "follow the theme" or "follow the app":
    `Showcase.overlayColor`, `Showcase.scrollLoadingWidget`,
    `ActionButtonConfig.textColor`, `ActionButtonConfig.textDirection`,
    `ShowCaseDefaultActions.verticalDividerColor` and
    `ShowCaseWidget.skipButtonText`.
  * `ShowCaseWidget.onStart` / `onComplete` are typed `ShowcaseStepCallback`
    (`void Function(int? index, GlobalKey key)`) instead of an untyped
    `Function`.
  * `ShowCaseWidget.builder` is typed `Widget` instead of `Builder`.

## 1.16.0

Skip or wait for missing steps one by one, and theming help for apps still on
the old `MaterialApp`. Nothing to change in your code.

* **New: `ShowCaseWidget.onShouldSkipUnmountedStep`.** `autoSkipUnmountedSteps`
  applies to the whole tour, so a tour couldn't both wait for a step on a page
  the user opens later and skip a widget that's only built sometimes. The new
  callback is asked about each step whose widget isn't on screen: return
  `true` to skip it or `false` to wait for it. When set, it replaces
  `autoSkipUnmountedSteps`. `goTo`, `goToKey` and `onResolveNextStep` jumps
  ignore it, as they ignore the flag.
* **Docs: theming the tooltip in apps on the old `MaterialApp`.** Since 1.15.2
  the tooltip's default title and description text uses `material_ui`'s theme,
  which can't see a theme set on the old `package:flutter/material.dart`
  `MaterialApp`. The README now shows how to pass your text styles once through
  `ShowcaseStyle` until you migrate, and `ShowcaseStyle.titleTextStyle` /
  `descTextStyle` document what they fall back to.

## 1.15.4

A fix for tours across screens, a demo of them, and automated releases.
Nothing to change in your code.

* **Fixed:** a step that became active while its page was still animating in
  (the usual case when a tour moves to another screen) measured its target
  mid-animation. Its dimmed-background cut-out and tap area stayed where the
  target was in that frame, so tapping the target didn't advance the tour. A
  step now waits until its page has finished animating in, or back into view,
  before it shows.
* **Fixed:** only the bottom-right quarter of a highlighted target responded to
  taps. A tap anywhere else on it went to the widget underneath instead of the
  tour. With default settings the tour still moved on, so this showed only with
  a custom `onTargetClick` (for example, to open the next screen). The whole
  target responds now. This bug dates back to the package's origins.
* **Fixed:** with `autoPlay`, a step could hold two timers at once and advance
  the tour twice. A new timer now replaces the old one.
* **Faster navigation:** since 1.15.3 every `Showcase` on a page rebuilt
  whenever a page was opened or closed above it, even with no tour running.
  Now only the active step reacts. With 30 steps on a page, opening and closing
  another page costs 3 `Showcase` rebuilds during a tour and none otherwise,
  down from 60.
* **New demo:** the example app's Feature demos page has a *Tour across
  screens* demo, a working version of the
  [guide](https://github.com/abdelrahman-abied/showcase_tutorial#tours-across-screens).
* Releases are now published to pub.dev automatically from GitHub Actions when
  a version tag is pushed.

## 1.15.3

A fix for tours that span several screens, and a guide for building them.
Nothing to change in your code.

* **Fixed:** opening another page, a dialog or a bottom sheet while a step was
  showing left that step's dimmed background and tooltip on top of the new
  page, still catching taps. The step now hides while its page is covered and
  comes back when its page is on top again. It stays the tour's current step;
  its `onDismiss` fires as it hides and `onShow` as it returns.
* **Fixed:** with `autoPlay`, a hidden step's timer kept running and advanced
  the tour behind the page covering it. Auto-play now pauses while a step is
  hidden. A timer left over from a step the tour had moved past could also skip
  that step early when the user went back to it; it's cancelled now.
* **New guide: [Tours across screens](README.md#tours-across-screens).** Put
  `ShowCaseWidget` in `MaterialApp.builder` and one tour reaches steps on every
  page: a step on a page that isn't open yet waits until the user gets there.
* Screen-reader announcements use `SemanticsService.sendAnnouncement`, which
  replaces the deprecated `announce` and targets the view the step is in.

## 1.15.2

Moves to Flutter's new standalone Material library. No API changes.

* **Requires Flutter 3.47 or newer (Dart 3.13).** Flutter 3.47 deprecated
  `package:flutter/material.dart` in favour of the separate
  [`material_ui`](https://pub.dev/packages/material_ui) package, which this
  release now depends on. On an older Flutter, pub keeps you on 1.15.1
  automatically.
* **Migrate your app too.** `material_ui` keeps its own `Theme`, separate from
  the one in `package:flutter/material.dart`. In an app that still uses the old
  `MaterialApp`, the tooltip's default title and description text, and the
  font and press highlight of `ShowCaseDefaultActions` buttons, use the default
  Material theme instead of your app's. Run the official fix
  to move your app over:

  ```sh
  dart fix --apply --code=migrate_design_widgets
  ```

  If you can't migrate yet, set `titleTextStyle` and `descTextStyle` on your
  steps. Those are used exactly as before.
* Files that don't need Material now import only `package:flutter/widgets.dart`.

## 1.15.1

Performance and layout fixes. Nothing to change in your code.

* **Lighter tours.** A `Showcase` that isn't currently showing no longer adds
  anything to your widget tree. A 60-step tour now builds 120 fewer widgets than
  before, and advancing a step does less work. Tours with many steps benefit the
  most.
* **Fixed:** a step using `tooltipPosition: TooltipPosition.left` or `.right`
  *together with* action buttons could draw its tooltip off the top of the
  screen when the highlighted widget was near the top edge. It now stays beside
  its target, where you asked for it.
* **Fixed:** action buttons placed outside the tooltip could be drawn under the
  status bar and cut off, again for a widget near the top of the screen. They
  are kept on screen now. If you position them yourself with
  `Showcase.actionButtonsPosition`, your values are used exactly as before.
* **Tip:** if you show buttons on every step with `ShowCaseWidget.globalActions`,
  prefer `TooltipActionPosition.inside`. The `outside` placement has little room
  to work with when a target sits near a screen edge.

## 1.15.0

New action-button options, a fix, and a speed-up. Everything is additive —
existing tours behave exactly as before.

### New

* **Set the tooltip's buttons once for the whole tour.** Instead of repeating
  `actions:` on every `Showcase`, declare them on `ShowCaseWidget`:

  ```dart
  ShowCaseWidget(
    globalActions: (context) => const ShowCaseDefaultActions(),
    globalActionSettings: const ActionsSettings(containerHeight: 40),
    hideActionsForShowcase: [_lastStep], // steps that shouldn't show them
    builder: Builder(builder: (context) => const HomePage()),
  );
  ```

  A per-step `Showcase.actions` still wins. Styling
  (`globalActionSettings`) and placement (`globalActionButtonsPosition`) fall
  back separately, so a step can change just its buttons and keep the tour's
  look.

* **Buttons inside the tooltip.** `TooltipActionPosition.inside` draws them
  within the tooltip, below the description, with the tooltip growing to fit.
  Set it tour-wide with `ShowCaseWidget.actionsPosition` or per step with
  `Showcase.actionsPosition`. The default stays `outside`, which positions them
  separately from the tooltip as before. Give inside buttons more room with
  `ActionsSettings.containerHeight` if 40px isn't enough.

* `ShowCaseWidget.activeTargetWidget` now takes an optional `aspect`. Pass a
  step's `GlobalKey` to have your widget rebuild only when *that* step becomes
  active or inactive. Omit it for the previous behaviour.

### Fixed

* **`enableShowcase` now works at runtime.** Setting it to `false` while a tour
  was running used to leave the overlay on screen. It now ends the tour: the
  step that was showing gets its `onDismiss`, and `ShowCaseWidget.onDismiss`
  reports where the user was left. Turning it back on does not resume the tour —
  call `startShowCase` again.

### Faster

* **Advancing a step no longer rebuilds every `Showcase` on screen**, only the
  step being left and the one being entered. In a 60-step tour that is 125
  widget rebuilds per "next" instead of 299, and the number no longer grows with
  the length of the tour. This frees up work on the UI thread; it does not
  change how the tour looks or how fast it animates.

## 1.14.1

A performance pass over the showcase overlay. No API changes — every item below
is internal, and behaviour is unchanged.

* PERF: **an idle `Showcase` no longer mounts an overlay entry.** Every
  `Showcase` used to insert its own `OverlayEntry` as soon as it was built and
  keep it for the life of the route, so a screen with 30 steps carried 30
  entries — each rebuilt on every ancestor rebuild only to return an empty box.
  Only the step that is actually showing mounts one now, and it is removed when
  the tour moves on.
* PERF: **the target snapshot is captured once per step instead of once per
  rebuild.** `highlightExactShape` and multi-widget (`keys`) steps used a
  `FutureBuilder` whose future was created inside `build`, so every rebuild
  re-ran `RenderRepaintBoundary.toImage` followed by a full PNG encode and
  decode — several times a second while the tooltip animates — and leaked every
  `ui.Image` it produced. The capture now happens once when the step opens, the
  PNG round trip is gone (the image is painted directly), and the images are
  disposed when the step closes. The snapshot's *position* is still re-read each
  build, so it keeps tracking a target that scrolls.
* PERF: **the target's geometry is measured once per frame.** Laying out a
  tooltip asks for the target's center, top, bottom and height dozens of times,
  and each ask used to walk the render tree again. A single measurement is now
  shared for the frame — roughly 23x fewer render-tree walks per rebuild in a
  20-step tour.
* PERF: **the tour's state is resolved once per overlay build.** Building the
  overlay read ~20 values off `ShowCaseWidget.of(context)`, and each one was a
  fresh `findAncestorStateOfType` walk to the top of the element tree.
* PERF: **no more `LayoutBuilder` around every showcased widget.** It added a
  render object per `Showcase` and rebuilt the widget's whole subtree during
  layout on any constraint change (rotation, keyboard, window resize), while its
  constraints were never used.
* PERF: the tooltip is painted on its own layer, so the looping "moving"
  animation translates a cached layer instead of re-rasterising the tooltip's
  text, arrow and background every frame; the dimmed scrim is a plain
  `ColoredBox` rather than a decorated `Container`; and the `TextPainter` used to
  measure tooltip text is disposed instead of leaking its native paragraph.

## 1.14.0

* FEAT: **dynamic callback registration** — register step listeners on the
  controller at runtime with `addOnStartCallback` / `removeOnStartCallback` and
  `addOnCompleteCallback` / `removeOnCompleteCallback`. Unlike
  `ShowCaseWidget.onStart` / `onComplete`, which are fixed when the
  `ShowCaseWidget` is built, these let a screen, controller, or analytics service
  deeper in the tree observe the tour for as long as it lives (register in
  `initState`, remove in `dispose`). Listeners run in addition to the
  widget-level callbacks, in registration order, and receive the same
  `(int? index, GlobalKey key)` — now typed as `ShowcaseStepCallback`. Removing a
  listener while it is being dispatched is safe.
* FEAT: **`Showcase.onTargetRectUpdate`** — called with the highlighted target's
  bounds (a `Rect` in global coordinates) whenever they change while the step is
  active: after a scroll, a rotation, the keyboard opening, or the target
  resizing. Fires once with the initial bounds when the step becomes active and is
  delivered after layout, so it is safe to `setState` from it. Useful for
  anchoring your own UI — e.g. a `floatingActionWidget` that should follow just
  below the highlight. The rect describes the target itself; `targetPadding` is
  not included. Defaults to `null`.
* FEAT: **`ShowCaseWidget.of(context).isTargetRendered(key)`** — controller helper
  that reports whether a step's target is currently mounted **and** laid out,
  replacing manual `key.currentContext != null` checks (which are also `true` for a
  mounted but not-yet-laid-out widget). Handy before `goToKey` / `startShowCase`
  on steps whose targets render conditionally.
* FEAT: **per-step barrier override** — `Showcase.barrierInteraction` overrides
  the tour-wide `ShowCaseWidget.barrierInteraction` for a single step, so one step
  can make the background inert (`BarrierInteraction.none`) while the rest of the
  tour advances on a background tap. Takes precedence over the tour-wide value,
  including the legacy `disableBarrierInteraction` flag; `onBarrierClick` still
  fires on every barrier tap. Additive and backward-compatible — defaults to
  `null` (use the tour-wide behaviour).
* FEAT: **pointer cursor on hover (web / desktop)** — hovering a part of the
  showcase that reacts to a click now shows `SystemMouseCursors.click` instead of
  the plain arrow, so a tour reads as interactive on web and desktop. It applies
  to the highlighted target, a tooltip that has `onToolTipClick` or
  `disposeOnTap`, and the built-in "Skip" button. A tooltip that does nothing on
  tap deliberately keeps the default cursor, so the pointer never promises a
  click that isn't there. The buttons in `ShowCaseDefaultActions` are Material
  buttons and already behaved this way. No-op on mobile (no pointer).
* FEAT: **`ShowCaseWidget.enablePointerCursor`** — tour-wide switch for the
  above, defaulting to `true` (matching `enableKeyboardNavigation` and
  `enableAutoAnnouncements`, the package's other on-by-default polish flags). Set
  it to `false` to keep the previous cursor behaviour everywhere.
* FEAT: **`Showcase.targetMouseCursor` / `Showcase.tooltipMouseCursor`** —
  per-step overrides of the resolved cursor, e.g.
  `SystemMouseCursors.forbidden` on a "look, don't touch" step or
  `MouseCursor.defer` to leave one step alone. An explicit value wins even when
  `enablePointerCursor` is `false`. Both default to `null` (resolve
  automatically).
* The target's hover region is not opaque, so the real widget underneath still
  receives hover events and keeps its own hover states while the showcase cursor
  applies.
* FEAT: **animated step transitions** — the highlight cut-out now glides from the
  previous step's target to the next one when the tour advances, instead of
  cutting there instantly. The optional highlight border and the pulse ring
  follow the moving cut-out; the tooltip keeps its existing scale transition and
  appears at the new target. Opt in tour-wide with
  `ShowCaseWidget.enableStepTransition` (default `false`, so nothing changes for
  existing tours), and tune it with `stepTransitionDuration` (default 300 ms) and
  `stepTransitionCurve` (default `Curves.easeInOut`).
  * Applies to every forward and backward move — `next`, `previous`, `goTo`,
    `goToKey`, a branch, a barrier tap, autoplay. The first step of a tour has
    nothing to glide from, so it simply appears.
  * Honors the platform "reduce motion" accessibility setting by jumping
    straight to the target, like the pulsing ring already does.
  * No-op for a `highlightExactShape` step, which paints a snapshot of the
    target rather than a cut-out.
* FEAT: **`ShowCaseWidget.of(context).previousTargetRect`** — the global bounds of
  the step the tour just left (`null` while the tour is starting or once it
  ends). This is what drives the glide, and it is only recorded while
  `enableStepTransition` is on.
* No shared-overlay rewrite was needed: every step already paints its own
  full-screen scrim, so the scrim is continuous across a step change and only the
  cut-out moves. The step being entered animates its own cut-out from where the
  previous target was, and the step being left simply stops painting.

## 1.13.0

* FEAT: **floating action widget** — pin a screen-anchored control (e.g. a fixed
  Skip / Next button or a progress chip) above the overlay so it stays put while
  the tour runs, instead of moving with each tooltip. Set one tour-wide with
  `ShowCaseWidget.globalFloatingActionWidget` (a `WidgetBuilder`, so it can read
  the tour via `ShowCaseWidget.of(context)`), override it per step with
  `Showcase.floatingActionWidget`, and suppress the global one on specific steps
  with `ShowCaseWidget.hideFloatingActionWidgetForShowcase`. You position the
  widget yourself (e.g. with `Align`/`Positioned`); it is painted above the
  tooltip and receives taps. Additive and backward-compatible (defaults `null` /
  empty).
* FEAT: **per-step `autoPlayDelay`** — `Showcase.autoPlayDelay` overrides the
  tour-wide `ShowCaseWidget.autoPlayDelay` for a single step, so one step can
  linger longer (or advance quicker) than the rest during auto-play. Defaults to
  `null` (use the tour-wide delay). As part of this, the auto-play delay now uses
  the full `Duration` instead of being truncated to whole seconds.
* FEAT: **`targetTooltipGap`** — `Showcase.targetTooltipGap` adds extra space (in
  logical pixels) between the target and its tooltip, on top of the default
  offset. It applies to every tooltip position (top / bottom / left / right).
  Additive and backward-compatible — defaults to `0`, which keeps the original
  spacing.
* FEAT: **`toolTipMargin`** — `Showcase.toolTipMargin` (an `EdgeInsets`, default
  `EdgeInsets.all(20)`) sets the minimum margin kept between the tooltip and the
  screen edges: the tooltip is clamped to stay at least this far from each edge,
  and its width/height are capped to fit within the margins. Useful to leave room
  for a status bar, notch, or your own fixed UI. Completes the tooltip-spacing
  pair with `targetTooltipGap`. Backward-compatible — the default reproduces the
  previous edge spacing for ordinary tooltips. Also applies to the custom
  `Showcase.withWidget` container, which is now clamped within the same margins.
* FEAT: **`scrollAlignment`** — control where an auto-scrolled target lands in the
  viewport. `ShowCaseWidget.scrollAlignment` (a `double`, default `0.5`) sets it
  tour-wide and `Showcase.scrollAlignment` overrides it per step: `0.0` rests the
  target at the leading edge (top / left), `0.5` centers it, `1.0` rests it at the
  trailing edge (bottom / right). Forwarded to `Scrollable.ensureVisible` when
  `ShowCaseWidget.enableAutoScroll` brings an off-screen target into view. Additive
  and backward-compatible — the default `0.5` reproduces the previous centered
  behavior.
* CHORE: the example app's "Feature demos" page now demonstrates the floating
  action widget (a pinned "End tour" button, hidden on the last step), per-step
  `autoPlayDelay` (an "Auto-play" toggle where the star step lingers longer), a
  "Wide tooltip gap" toggle for `targetTooltipGap` on the center step, and a "Wide
  tooltip margin" toggle that pushes the edge-hugging "R" step's tooltip further in
  from the screen edge.
* CHORE: the example app adds an "Auto-scroll alignment" demo page (reachable from
  the "Feature demos" screen) where three far-apart targets in a scroll view each
  land at a different spot — leading edge, center, trailing edge — via per-step
  `scrollAlignment`.

## 1.12.0

* FEAT: **`onBarrierClick`** — a new `ShowCaseWidget.onBarrierClick` callback fires
  whenever the dimmed background (barrier) is tapped, **in addition to** the
  configured `barrierInteraction`. It runs even when `barrierInteraction` is
  `BarrierInteraction.none`, so you can react to "the user tapped outside the
  highlight" (a hint nudge, a sound, analytics) without changing what the tap
  does; with `.next` / `.dismiss` it runs first, then the configured action
  follows. Additive and backward-compatible (default `null`).

## 1.11.0

* FEAT: **tour-level `onDismiss`** — a new `ShowCaseWidget.onDismiss(GlobalKey?
  dismissedAt)` callback fires whenever a tour is closed early (a barrier tap with
  `BarrierInteraction.dismiss`, the `Esc` key, the built-in skip button, a
  `disposeOnTap` tap, or a manual `dismiss()`), and reports the `GlobalKey` of the
  step the user left off on. It is **not** called when the tour finishes normally
  by advancing past the last step — `onFinish` still covers that, and exactly one
  of the two runs per tour. Handy for measuring onboarding drop-off. Additive and
  backward-compatible; distinct from the per-step `Showcase.onDismiss`.

## 1.10.1

* DOCS: rewrote the README as standalone documentation — added a table of
  contents, a fuller API reference (controller methods and getters, complete
  `ShowCaseWidget` and `Showcase` / `Showcase.withWidget` property tables).

## 1.10.0

* FEAT: **conditional / branching tours** — a new `ShowCaseWidget.onResolveNextStep`
  callback lets a step decide the next step at runtime, so a tour can skip ahead
  or branch based on app state (e.g. "if the user already has items, jump to the
  checkout step"). It's consulted on every forward path (the Next button, a tap,
  the barrier, the keyboard, auto-play, and `next()`); return the `GlobalKey` of
  the step to jump to, or `null` to advance normally. Backward and forward jumps
  are both allowed, and a branch is treated as an explicit jump (like `goTo`).
  `previous()`, `goTo()`, and `goToKey()` are unaffected. Additive and
  backward-compatible — the default is `null` (no branching).

## 1.9.0

* FEAT: **numeric progress indicator** — `ShowCaseWidget.progressStyle` chooses
  how the built-in step indicator looks when `showProgress` is on:
  `ShowcaseProgressStyle.dots` (one dot per step, the existing default) or
  `ShowcaseProgressStyle.numeric` (a compact `1/6` counter, handy for long
  tours). Additive and backward-compatible — the default is unchanged.

## 1.8.0

* FEAT: **tooltip & highlight styling** — finer visual control for the default
  tooltip without a custom `container`. New per-`Showcase` options (each also
  settable tour-wide via `ShowcaseStyle`): `arrowColor`, `arrowWidth`,
  `arrowHeight` for the tooltip arrow, and `highlightBorderColor` /
  `highlightBorderWidth` to draw a colored border around the highlighted target.
  All additive and opt-in; the border follows the highlight shape and works
  alongside `highlightExactShape`. (Per-step overlay color is already supported
  via `Showcase.overlayColor`.)

## 1.7.0

* FEAT: **pulsing highlight ring** — opt in per step with
  `Showcase(enablePulseAnimation: true)` to draw an animated ring that pings
  outward around the highlight, drawing the eye to the target. Tune it with
  `pulseColor` (also settable tour-wide via `ShowcaseStyle.pulseColor`) and
  `pulseDuration`. Additive and off by default; the ring follows the highlight
  shape, works alongside `highlightExactShape`, and falls back to a single
  static ring when the platform "reduce motion" setting is on.

## 1.6.2

* DOCS: full dartdoc coverage of the public API — every exported class, field,
  enum value, and method now has a `///` comment — plus a fix for a few stale
  doc references. Improves the pub.dev documentation score and the docs tab.
* DOCS: add an "Upgrading (1.4 → 1.6)" section to the README summarising what
  landed across those releases and how to opt in (all additive, no code changes).
* DOCS: tidy the README markdown-lint warnings (aligned the property-table pipes
  and fixed the ordered-list prefix in the Installing section).
* CHORE: losslessly optimise the preview GIFs with `gifsicle -O3` — `demo.gif`
  4.6 MB → 0.4 MB and `showcase_tutorial.gif` 2.6 MB → 0.5 MB (pixel-identical) —
  and ship `demo.gif` as a second pub.dev screenshot.
* CHORE: add a `.pubignore` that excludes the example app's native scaffolding,
  the maintainer publish script, and internal docs from the published archive,
  dropping the package download from ~7 MB to ~0.9 MB.

## 1.6.1

* DOCS: fix the README preview GIFs.

## 1.6.0

* FEAT: built-in **progress indicator** and **skip button** in the default
  tooltip, via `ShowCaseWidget.showProgress` and `ShowCaseWidget.showSkip`
  (label customizable with `skipButtonText`). The progress shows one dot per
  step with the active step highlighted; the skip button dismisses the whole
  tour. Both default to `false` and only affect the default tooltip — custom
  `container` tooltips are untouched.

## 1.5.1

* DOCS: add a second example page ("Feature demos"), reachable from a button on
  the original mail demo, that walks through the newer features (left/right
  tooltip positions, progress indicator, multi-widget highlight, custom action
  text, `highlightExactShape`, `onShow`/`onDismiss`, `barrierInteraction`,
  auto-skip). Add a feature-walkthrough GIF to the README preview and complete
  the README's feature list. No library changes.

## 1.5.0

* FEAT: keyboard navigation (`ShowCaseWidget.enableKeyboardNavigation`, default
  `true`) — drive the active step with a hardware keyboard: `Esc` dismisses,
  `→`/`↓`/`Enter` go to the next step, `←`/`↑` go back. Focus-scoped, so it only
  acts while the overlay holds focus (never hijacks app-wide keys). Relevant on
  web/desktop, harmless on mobile.
* FEAT: screen-reader announcements (`ShowCaseWidget.enableAutoAnnouncements`,
  default `true`) — each step's title and description are announced to
  TalkBack/VoiceOver as it becomes active. `Showcase.semanticLabel` overrides
  the announced text (useful for custom-`container` tooltips).
* FIX: `Showcase.onShow` / `onDismiss` (added in 1.4.0) could throw
  "setState() called during build" when the callback called `setState` (e.g. to
  update a "Step x of y" indicator), which cascaded into "GlobalKey used
  multiple times" errors. The callbacks are now dispatched after the frame.

## 1.4.0

* FEAT: `TooltipPosition.left` and `.right` — place the default tooltip to the
  side of the target, with a horizontal arrow.
* FEAT: progress + navigation API on `ShowCaseWidget.of(context)`:
  `currentIndex`, `totalSteps`, `isShowcaseRunning`, `goTo(index)` and
  `goToKey(key)` (build "Step 2 of 5" indicators and skip-to controls).
* FEAT: `ShowCaseWidget.autoSkipUnmountedSteps` — skip steps whose target
  widget isn't currently in the tree instead of showing an empty overlay.
* FEAT: RTL support — the tooltip inherits the app's text direction and
  measures/lays out RTL text correctly.
* FEAT: `Showcase.highlightExactShape` — highlight the target by its **actual
  painted shape** (a star, a pill, an icon, an irregular logo) instead of a
  geometric `targetShapeBorder`. The target is captured as a snapshot and drawn
  above the dimmed overlay, so any shape is hugged exactly with no need to set
  `targetShapeBorder`/`targetBorderRadius` to match it.
* FEAT: per-step lifecycle callbacks `Showcase.onShow` and `Showcase.onDismiss`
  — fired when a step becomes the active showcase and when it stops being active
  (advanced past, navigated away, or the tour is dismissed). Handy for analytics.
* FEAT: `ShowCaseWidget.barrierInteraction` (`BarrierInteraction.next` /
  `.dismiss` / `.none`) — choose whether tapping the dimmed background advances
  to the next step (default), dismisses the whole tour, or does nothing. The
  legacy `disableBarrierInteraction: true` still works and maps to `.none`.

## 1.3.0

* FEAT: "show once" support for onboarding tours. `ShowCaseWidget` gains a
  `showcaseId` and an `onShouldStartShowcase` guard (sync or async).
  `startShowCase` consults the guard and starts only when it returns `true`,
  so a tour can be shown a single time. Pass `startShowCase(..., force: true)`
  to replay (e.g. a "show tutorial again" button). The package stays
  storage-agnostic — persist completion yourself in `onFinish`.

## 1.2.1

* DOCS: rewrite the README with a Features overview and runnable examples for
  every feature (custom tooltips, action buttons, multi-widget steps,
  `ShowcaseStyle`, auto-play, programmatic control, target interactions, blur,
  tooltip position, enable/disable). Correct the property tables and remove the
  stale pre-1.0.0 migration guide.

## 1.2.0

* FEAT: add `ShowCaseWidget(style: ShowcaseStyle(...))` to set default tooltip
  styling (`tooltipBackgroundColor`, `textColor`, `titleTextStyle`,
  `descTextStyle`, `tooltipBorderRadius`) once for every `Showcase` in the tree.
  An individual `Showcase` still overrides any value it sets.
* FEAT: `Showcase.description` is now optional. A showcase can show just a
  title (or a custom `container`) without passing `description: null`.
* BREAKING (minor): `Showcase.tooltipBackgroundColor` and `Showcase.textColor`
  are now nullable (`Color?`) so they can fall back to `ShowcaseStyle`. Code
  that passes these as named arguments is unaffected; only code that read the
  fields expecting a non-null `Color` needs a null check.
* FIX: the overlay barrier was being painted twice, so the default
  (non-blurred) overlay rendered at roughly double the configured opacity.
  It is now drawn once at the requested `overlayColor`/`overlayOpacity`.
* FIX: `ActionsSettings.containerColor` is now honoured for tooltip action
  buttons. Previously the action container used a hardcoded background
  (`Colors.white` / `Colors.lightBlueAccent`) and ignored the setting.
* FIX: guard `GetPosition.getRect()` against a null/unsized render object so
  it returns `Rect.zero` instead of throwing during teardown.
* FIX: multi-widget showcases (`Showcase(keys: ...)`) now skip an individual
  missing/unmounted widget instead of dropping every highlight for the step.
* PERF: `MeasureSize` now reads its size during layout via a `RenderProxyBox`
  instead of scheduling a post-frame measurement on every build, and the
  overlay no longer schedules a rebuild callback while no showcase is active.
* DOCS: document the multi-widget `keys` parameter.
* CHORE: correct the `flutter` SDK constraint (`>=3.27.0`, required by
  `Color.withValues`) and add `topics` and `screenshots` to the pubspec.

## 1.1.2

* FIX: guard `_scrollIntoView` against a use-after-dispose crash. A `Showcase`
  disposed within a frame of its first build (for example, a redirect right
  after the first build) no longer throws "Null check operator used on a null
  value" from its post-frame callback.
* CHORE: upgrade `flutter_lints` to `^6.0.0` and resolve the newly surfaced lints.

## 1.1.1

* Example app: add an `isImportant` field to the mail model and refine the
  `MailTile` and detail screen styling.
* Docs: fix the GitHub stars link in the README.

## 1.1.0

* FEAT: update dependency constraints to Dart SDK 3.9.0.
* Refactor the code structure for improved readability and maintainability.
* Fix minor bugs and improve performance.
* Update the documentation for new features.

## 1.0.4

* Update Flutter to 3.16.0.

## 1.0.0

* Initial release (14 Sep 2023).
