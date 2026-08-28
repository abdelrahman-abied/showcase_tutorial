# `showcase_tutorial` vs `showcaseview` — benchmark harness

A head-to-head benchmark of this package against
[`showcaseview`](https://pub.dev/packages/showcaseview) 5.1.0, the upstream
package this one was forked from (at 2.0.1, February 2023).

Maintainer-only. It is excluded from the published archive via `.pubignore`,
and it is a separate project because it depends on a competing package — that
dependency must never reach `showcase_tutorial`'s own `pubspec.yaml`.

## What it measures

Two harnesses, answering different questions.

| | `test/` (widget tests) | `lib/main.dart` (profile mode) |
| --- | --- | --- |
| Runs on | `flutter test`, fake clock | a real device, `--profile` |
| Measures | build + layout + paint CPU, element counts, **exact rebuild counts** | real frame timings incl. **GPU raster** |
| Deterministic | yes | no (real hardware) |
| Good for | attributing cost to a cause | confirming what a user would feel |

## Running it

```sh
cd benchmark
flutter pub get

# Deterministic CPU + rebuild counts. N is the number of steps in the tour.
flutter test --dart-define=N=30 test/bench_ours_test.dart test/bench_theirs_test.dart

# Real frame timings on a device (both must be run, one per package).
flutter run --profile -d <device> --dart-define=PKG=ours   --dart-define=N=30
flutter run --profile -d <device> --dart-define=PKG=theirs --dart-define=N=30
```

The native scaffolding under `android/` and `macos/` is generated; regenerate it
with `flutter create --platforms=android,macos .` if it is ever missing.

## How it stays fair

Both packages are driven through one `Driver` interface by a single measurement
routine (`test/harness.dart`), so neither can benefit from benchmark code
written in its favour. The scene (`lib/scenes.dart`) is identical outside the
showcase wrapper. Beyond that:

- **JIT warm-up.** Two full tours run untimed before any number is recorded, and
  each package runs in its own isolate (a separate test file), so whichever runs
  first is not penalised.
- **A fixed wall-clock window.** `showcaseview`'s `next()` awaits a 300 ms
  reverse scale animation before the next step appears; this package swaps on
  the following frame. Every timed region therefore spans 30 frames (480 ms) —
  long enough for the slower package to finish — so the two numbers describe the
  same amount of elapsed time rather than the same amount of progress.
- **Sanity gates.** `SANITY_step_advanced` asserts the tour actually moved on,
  and `SANITY_tooltip_visible` that a tooltip is really on screen. Without these
  the harness silently timed a no-op and reported a 10x win for `showcaseview`.
  Treat any result where a `SANITY_` value is `false` as void.
- **Medians, repeated.** Every figure is a median over many iterations; the
  reported sweeps take the median of three independent runs.

## What it does NOT measure

- **Heap memory.** `rss_*_kb` is reported but is dominated by JIT and the test
  framework. Measured deltas overlap between the two packages — treat it as
  inconclusive, not as parity.
- **Web or iOS.** Only the platforms the harness has been run on.

## Results

See [RESULTS.md](RESULTS.md).
