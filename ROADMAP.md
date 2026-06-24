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

- [ ] **Tooltip & highlight styling**
      Finer visual control for the default tooltip without writing a custom
      `container`: custom arrow (color / size / hide it), highlight border or
      glow color and width, and a per-step overlay color. Lets the default
      tooltip match more design systems out of the box.

- [ ] **Conditional / branching tours**
      Let a step decide the next step at runtime via a predicate/callback, so a
      tour can skip ahead or branch based on app state (e.g. "if the user already
      has items, jump to step 5"). Builds on the existing `goTo` / `goToKey` API.

> Already shipped (progress dots + skip, accessibility, lifecycle callbacks,
> barrier behavior, exact-shape highlight, positions/RTL, show-once, …) are
> recorded in [CHANGELOG.md](CHANGELOG.md).
