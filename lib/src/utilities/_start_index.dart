/*

 * Copyright (c) 2026 Abdulrahman Mohamed
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/// The step a tour started with `startShowCase(startAt: ...)` opens on, before
/// unmounted steps are skipped.
///
/// [startAt] is clamped into `0..stepCount - 1`: a negative value opens the
/// first step and a value past the end opens the last one. An empty tour
/// returns `0`, which the caller treats as "nothing to show" and finishes.
///
/// Debug builds reject an out-of-range [startAt] with an assert in
/// `startShowCase` before this runs, so the clamp only matters in release
/// builds, where a stale saved index should not crash the app.
int clampStartIndex(int startAt, int stepCount) {
  if (stepCount <= 0) return 0;
  return startAt.clamp(0, stepCount - 1);
}
