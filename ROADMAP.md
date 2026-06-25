# Roadmap / Ideas

Possible future work for `showcase_tutorial`. The core feature set is considered
complete as of **1.6.0**; the items below are optional.

## Recommended next: stabilization & polish

- [x] **Trim the published archive**
      Was ~7 MB, mostly the two preview GIFs. Both GIFs are now losslessly
      optimized with `gifsicle -O3` (demo.gif 4.6 MB → 0.4 MB, showcase_tutorial.gif
      2.6 MB → 0.5 MB; pixel-identical, both still ship as pub.dev screenshots), and
      a `.pubignore` drops the maintainer publish script, this ROADMAP, and the
      example app's native scaffolding (keeping `example/lib` + assets). Archive is
      now ~925 KB.

- [x] **Improve the pub.dev score (API docs)**
      pub.dev grades documentation coverage of public APIs. Add `///` dartdoc
      comments to any public class, field, or method that still lacks one so the
      package scores full marks and the API is easier to discover from the docs
      tab.

- [x] **Fix README markdown-lint warnings**
      The README has cosmetic linter warnings (property-table pipes not aligned,
      an ordered-list prefix). They render fine but tidying them keeps the source
      clean and silences the IDE warnings.

- [x] **Migration / upgrade note in the README**
      A short "Upgrading" section summarizing what landed across 1.4 → 1.6 (exact
      shape, lifecycle callbacks, barrier behavior, accessibility, progress/skip)
      so existing users can see what's new and how to opt in at a glance.

- [x] **Ship `demo.gif` as a pub.dev screenshot**
      pub.dev shows `screenshots:` from the pubspec in a dedicated carousel, but
      each file must be under 4 MiB. `demo.gif` is 4.59 MiB, so it's currently
      README-only. Compress/shorten it under the limit, then add it to the
      pubspec `screenshots` list.

## Potential features (only if revisited)

- [x] **Pulsing / animated highlight ring**
      An animated ring that pulses outward around the highlighted target to draw
      the eye to it, in addition to the static cut-out. Opt in per step with
      `Showcase(enablePulseAnimation: true)`; configurable color (`pulseColor`,
      or `ShowcaseStyle.pulseColor` tour-wide) and speed (`pulseDuration`). The
      ring follows the highlight shape, works alongside `highlightExactShape`,
      and honors the platform "reduce motion" setting (single static ring).

- [ ] **Animated step transitions**
      Smoothly glide the highlight cut-out and the tooltip from one target to the
      next when advancing, instead of cutting instantly — a polished "guided
      tour" feel. This is the biggest UX upgrade remaining, but also the largest
      change to the overlay rendering (it currently rebuilds per step).

- [x] **Tooltip & highlight styling**
      Finer visual control for the default tooltip without writing a custom
      `container`: custom arrow (`arrowColor` / `arrowWidth` / `arrowHeight`, or
      hide it with `showArrow: false`) and a highlight border
      (`highlightBorderColor` / `highlightBorderWidth`) that follows the cut-out
      shape. Each is also settable tour-wide via `ShowcaseStyle`. Per-step
      overlay color was already supported via `Showcase.overlayColor`.

- [x] **Conditional / branching tours**
      Let a step decide the next step at runtime via a predicate/callback, so a
      tour can skip ahead or branch based on app state (e.g. "if the user already
      has items, jump to step 5"). Builds on the existing `goTo` / `goToKey` API.

## Upstream parity (missing vs Simform showcaseview ≤ 5.1.0)

Features present in upstream `showcaseview` (through 5.1.0) that this fork does not
yet have. All are additive and backward-compatible. The contextless `ShowcaseView` /
`ShowcaseService` rewrite is intentionally **out of scope** — this fork keeps the
context-based `ShowCaseWidget`.

### Quick-win options

- [ ] **Tooltip spacing controls**
      `Showcase.targetTooltipGap` (space between the target and the tooltip) and
      `Showcase.toolTipMargin` (tooltip margin from the screen edges, also for
      `Showcase.withWidget`).

- [ ] **Auto-scroll alignment**
      `scrollAlignment` to control where the target lands when `enableAutoScroll`
      brings an off-screen target into view.

- [ ] **Tour-level `onDismiss`**
      `ShowCaseWidget.onDismiss(GlobalKey? dismissedAt)`, fired when the whole tour
      is dismissed (barrier-dismiss, Esc, skip, or a manual `dismiss()`). Distinct
      from the existing per-step `Showcase.onDismiss`.

- [ ] **`onBarrierClick`**
      `ShowCaseWidget.onBarrierClick`, a hook for taps on the dimmed background, in
      addition to the configured `barrierInteraction` behaviour.

- [ ] **Per-step auto-play delay**
      `Showcase.autoPlayDelay` to override the tour-wide `autoPlayDelay` for a single
      step.

### Floating action widget

- [ ] **Screen-anchored action widget**
      `Showcase.floatingActionWidget` (per step), `ShowCaseWidget.globalFloatingActionWidget`
      (tour-wide default), and `hideFloatingActionWidgetForShowcase` to suppress the
      global one on specific steps — e.g. a fixed Skip/Next button that doesn't move
      with the tooltip.

### Callbacks & introspection

- [ ] **Dynamic callback registration**
      `addOnCompleteCallback` / `removeOnCompleteCallback` and `addOnStartCallback` /
      `removeOnStartCallback` on the controller, for listeners that come and go.

- [ ] **`onTargetRectUpdate`**
      `Showcase.onTargetRectUpdate(Rect)`, fired when the highlighted target's rect
      changes.

- [ ] **`isTargetRendered(key)`**
      Controller helper to check whether a step's target is currently laid out,
      replacing manual `key.currentContext` checks.

- [ ] **Per-step barrier override**
      Let an individual `Showcase` override the tour-level `barrierInteraction` (or
      disable the barrier for just that step).

### Cursor polish (web / desktop)

- [ ] **Pointer cursor on hover**
      Show `SystemMouseCursors.click` when hovering clickable targets and tooltips,
      with `MouseRegion(opaque: false)` for pass-through hover where appropriate.

> Already shipped (progress dots + skip, accessibility, lifecycle callbacks,
> barrier behavior, exact-shape highlight, positions/RTL, show-once, …) are
> recorded in [CHANGELOG.md](CHANGELOG.md).
