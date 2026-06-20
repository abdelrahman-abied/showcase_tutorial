/*
 * Copyright (c) 2021 Simform Solutions
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

enum TooltipPosition {
  top,
  bottom,
  left,
  right;

  bool get isHorizontal => this == left || this == right;

  bool get isVertical => this == top || this == bottom;
}

/// What happens when the user taps the dimmed background (the barrier) while a
/// showcase step is visible.
///
/// Set it on [ShowCaseWidget.barrierInteraction].
enum BarrierInteraction {
  /// Advance to the next step (the default behaviour).
  next,

  /// Dismiss the whole showcase tour.
  dismiss,

  /// Ignore taps on the barrier — nothing happens.
  none,
}
