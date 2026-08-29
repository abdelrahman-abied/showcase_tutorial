# Results

`showcase_tutorial` vs `showcaseview` 5.1.0.

> The tables in the first section are the **1.14.1 baseline** — the state that
> motivated the `_InheritedShowCaseView` change. For where the package stands
> now, jump to [Current standing (1.15.0)](#current-standing-1150).

Environment: Flutter 3.47.2 / Dart 3.13.2, macOS 26.6.2 (Apple Silicon) for the
widget tests; Infinix X687 (Android 10, arm64, Mali GPU) for the profile runs.
Recorded 2026-08-28. Widget-test figures are the median of 3 independent runs;
all `SANITY_` gates passed for every cell below.

**Read the device section first.** The widget tests isolate real, reproducible
structural differences — but on real hardware those differences do not surface.

## CPU and rebuilds (`flutter test`)

`us` is build + layout + paint CPU over one fixed 30-frame (480 ms) window.
Lower is better in every column.

### Idle structure — 2 extra elements per `Showcase`

| steps | ours | showcaseview |
| ----: | ---: | -----------: |
| 5  | 233 | 221 |
| 15 | 333 | 301 |
| 30 | 483 | 421 |
| 60 | 783 | 661 |

Exact linear fits: **ours `183 + 10N`, showcaseview `181 + 8N`.** The two extra
elements per step are `AnchoredOverlay` and `OverlayBuilder`, which this package
wraps around every showcased widget whether or not the tour is running.
`showcaseview`'s `_ShowcaseState.build()` returns `widget.child` directly.

### A step change

| steps | ours (us) | theirs (us) | ours (rebuilds) | theirs (rebuilds) |
| ----: | --------: | ----------: | --------------: | ----------------: |
| 5  | 8,696 | 5,063 | 134 | 34 |
| 15 | 8,710 | 4,781 | 164 | 34 |
| 30 | 9,068 | 5,023 | 209 | 34 |
| 60 | 9,813 | 5,223 | 299 | 34 |

Rebuilds fit exactly: **ours `119 + 3N`, showcaseview a flat 34 regardless of
tour length.** The 3 per step are `Showcase` + `AnchoredOverlay` +
`OverlayBuilder`, all rebuilt because every `Showcase` depends on
`_InheritedShowCaseView`. A 60-step tour rebuilds 299 elements per "next".

Note the two halves disagree: rebuilds grow 2.2x from N=5 to N=60 while CPU
grows 13%. Those three `build` methods are cheap, so **most of the 1.7-1.9x CPU
gap comes from somewhere other than the rebuild fan-out.**

### Steady-state frame, one step open

| steps | ours (us) | theirs (us) |
| ----: | --------: | ----------: |
| 5  | 72 | 41 |
| 15 | 84 | 43 |
| 30 | 88 | 47 |
| 60 | 96 | 52 |

Consistently ~1.85x. This package rebuilds 1 element per frame; `showcaseview`
rebuilds **zero** — it animates the tooltip at the `RenderObject` level.

Both are far inside a 16 ms budget, so neither drops frames at these sizes on
this hardware. The ratio is headroom, not visible jank.

### Opening the tour

| steps | ours (us) | theirs (us) | ours (rebuilds) | theirs (rebuilds) |
| ----: | --------: | ----------: | --------------: | ----------------: |
| 5  | 10,489 | 9,447 | 114 | 82 |
| 15 | 11,365 | 8,801 | 144 | 82 |
| 30 | 11,061 | 9,312 | 189 | 82 |
| 60 | 13,268 | 9,406 | 279 | 82 |

### Step latency — the one this package wins

| | ours | showcaseview |
| --- | ---: | ---: |
| frames until the next step is on screen | **2** (~32 ms) | **21** (~336 ms) |

Independent of tour length. `showcaseview.next()` awaits a full reverse scale
animation before the next step appears; this package swaps on the next frame.
A user feels this one; the microseconds above they do not.

## Current standing (1.15.0)

The step-change rebuild count above is what 1.15.0 set out to fix: each
`Showcase` now depends on its own key as an `InheritedModel` aspect, so only the
step being left and the step being entered are notified.

| steps | rebuilds before | rebuilds after | showcaseview |
| ----: | --------------: | -------------: | -----------: |
| 5  | 134 | 125 | 34 |
| 15 | 164 | 125 | 34 |
| 30 | 209 | 125 | 34 |
| 60 | 299 | 125 | 34 |

`119 + 3N` becomes a flat 125 at every tour length; opening a tour goes from
`84 + 3N` to a flat 102. Everything else is unchanged: step CPU stays within
run-to-run noise (-13% to +2% across the four sizes), frame CPU within ±4%, step
latency still 2 frames, idle element counts identical — the wrappers are still
there, they are just no longer rebuilt.

That is the honest shape of this fix. **It removes work that scaled with the
tour; it does not make a frame faster.** The rebuilds it removed were cheap, as
the before/after CPU columns already predicted.

Head to head at 1.15.0, median of 3 runs per size:

| metric | ours | showcaseview | ours / theirs |
| --- | ---: | ---: | ---: |
| rebuilds per step change | 125 (flat) | 34 (flat) | 3.68x |
| rebuilds per tour start | 102 (flat) | 82 (flat) | 1.24x |
| CPU per step change | 8.2-9.1 ms | ~5.2 ms | 1.6-1.8x |
| CPU per steady frame | 73-90 us | 41-51 us | 1.8-1.9x |
| idle elements | `183 + 10N` | `181 + 8N` | 1.05-1.18x |
| step latency | 2 frames | 21 frames | **0.10x** |

Every figure on both sides is now flat in tour length except the idle element
counts, which are linear on both. The package had exactly one metric that grew
against a constant; it no longer does.

### Idle element counts, closed in 1.15.1

Each `Showcase` used to wrap its child in an `AnchoredOverlay` + `OverlayBuilder`
pair for the life of the route. The overlay entry is owned by the `State` now, so
`build` returns the child and nothing else:

| steps | 1.15.0 | 1.15.1 | showcaseview |
| ----: | -----: | -----: | -----------: |
| 5  | 233 | **223** | 221 |
| 15 | 333 | **303** | 301 |
| 30 | 483 | **423** | 421 |
| 60 | 783 | **663** | 661 |

`183 + 10N` becomes `183 + 8N`, the same slope as `showcaseview`. The gap at 60
steps went from 122 elements to 2, and what remains is a constant rather than
something that grows with the tour. Rebuilds per step change came down with it,
125 to 121, and per tour start 102 to 100.

### Where the remaining CPU gap comes from, and why it was left alone

The gap is not explained by rebuild counts. It is the per-frame animation path.

While a tooltip is on screen this package wraps it in `ScaleTransition` +
`SlideTransition` (`lib/src/tooltip_widget.dart`), both `AnimatedWidget`s, so
every animation tick rebuilds the transition element before painting. The moving
animation loops forever — a status listener reverses at the end and forwards at
the start — so the build phase runs every frame for as long as a step is open.

`showcaseview` drives the same animation from a custom `RenderObject`
(`_RenderAnimationDelegate`), which subscribes `markNeedsPaint` to the animations
and applies the transform inside `paint()`. No widget rebuild per frame: the
pipeline skips build and layout. (It also throttles repaints to 8 ms, but that is
~120 fps and therefore a no-op at 60 Hz, so the saving is not there.) That is the
whole of the 1 rebuild vs 0, and of the 73-90 us vs 41-51 us.

**Investigated and deliberately not adopted.** On the device, tour build time is
0.81 ms p50 on both sides — the ~40 us that separates them under `flutter test`
does not survive contact with real hardware, where raster (5.5-6.3 ms) dominates
the frame anyway. Matching their approach would mean replacing two stock Flutter
widgets with a custom render object owning positioning, scale and translation
together, inside the package's most feature-dense file (tooltip positions, RTL,
arrow, actions, margins). High risk on the densest code for a saving no user can
perceive.

### The device cannot rank these packages, and here is the evidence

Every profile run on the Infinix X687 draws the same scrim, cut-out and tooltip,
so raster time should be near-constant. It is not. Across runs of the *same*
workload in the same session, tour raster p50 ranged from **3.96 ms to 15.71 ms**.

That spread is far larger than any difference between the two packages, so device
numbers here can say "neither drops frames" and nothing finer. Treat any device
ranking as noise unless it survives repetition on both sides.

The artifact has a recognisable shape -- a raster-only spike, build time normal,
raster p50 pinned near the 16 ms vsync boundary, and only ever in the tour phase,
never in the steady phase. It was seen twice, on opposite sides:

| run | janky frames | raster p50 | outcome |
| --- | ---: | ---: | --- |
| `showcase_tutorial` 1.15.0, first run | 222 / 1091 | 15.79 p90 | did not reproduce over 2 repeats (0 and 1 janky) |
| `showcaseview` 5.1.0 | 801 / 1091 | 15.71 | did not reproduce on repeat (0 janky, 5.57 p50) |

It landed on this package first, which is exactly when it would have been
convenient to explain away as a competitor problem, and on `showcaseview` later,
which is exactly when it would have been convenient to publish as a win. Neither
is true: it is thermal or scheduling state on the phone, not a property of either
package. Repeat before believing a device number here.

## Real frame timings on a device (`--profile`)

Infinix X687, a mid-range Android phone. Identical script both sides: a 30-step
tour, one `next()` every 600 ms, after an untimed warm-up tour. All figures in
milliseconds.

### The tour, 1091 frames

| | build p50 | build p99 | raster p50 | raster p99 | total p50 | frames > 16 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| ours   | 0.82 | 2.85 | 5.55 | 7.91 | 7.35 | **0** |
| theirs | 0.81 | 2.89 | 5.68 | 8.19 | 7.51 | 1 |

### One step open, no interaction, 301 frames

| | build p50 | build p99 | raster p50 | raster p99 | total p50 | frames > 16 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| ours   | 1.10 | 1.64 | 6.30 | 7.71 | 8.38 | **0** |
| theirs | 1.12 | 1.62 | 6.19 | 7.86 | 8.28 | 0 |

**The two packages are indistinguishable on real hardware.** Every difference
here is smaller than the run-to-run noise, and neither drops frames.

The reason the widget-test gap does not show up: raster dominates the frame
(5.5-6.3 ms of a ~7.4-8.4 ms total) and is identical for both, because both draw
the same scrim, cut-out and tooltip. The build phase where the packages actually
differ is 0.8-1.1 ms, and the ~40 us that separated them under `flutter test` is
invisible inside it.

## Summary

> **On a real device, at 30 steps, there is no measurable difference.**
> `showcaseview` does less work in isolation — ~1.8x less CPU per step change,
> ~1.85x less per frame, and a rebuild count that does not grow with the tour.
> `showcase_tutorial` responds to "next" 10x faster. Neither shows up as a
> dropped frame on mid-range Android.

So the structural findings are real but currently **latent**. They are a
headroom argument, not a performance bug: they would start to matter on slower
hardware, with a much longer tour, or on a screen already spending most of its
frame budget elsewhere.

The one gap worth fixing on its own merits is `_InheritedShowCaseView` in
`lib/src/showcase_widget.dart`: rebuilding `119 + 3N` elements per step is
unnecessary work that grows with tour length, and scoping it to a notifier on
the active step would make it roughly constant. Treat it as hygiene, not as an
urgent fix — the device numbers say no user is feeling it today.

## Reproducing

The exact runs behind this file:

```sh
cd benchmark
for n in 5 15 30 60; do
  flutter test --dart-define=N=$n test/bench_ours_test.dart test/bench_theirs_test.dart
done
flutter run --profile -d <device> --dart-define=PKG=ours   --dart-define=N=30
flutter run --profile -d <device> --dart-define=PKG=theirs --dart-define=N=30
```
