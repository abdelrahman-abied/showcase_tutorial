# Changelog

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
