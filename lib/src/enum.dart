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

/// The side of the target on which a [Showcase] tooltip is placed.
///
/// Set it on [Showcase.tooltipPosition]. When left unset the tooltip is placed
/// wherever vertical space is available, or beside the target when it fits
/// neither above nor below it.
///
/// A side the tooltip does not fit on gives way to the opposite one when the
/// tooltip fits there: [top] to [bottom], [left] to [right], and back. Where
/// neither fits, it stays on the side asked for.
enum TooltipPosition {
  /// Place the tooltip above the target.
  top,

  /// Place the tooltip below the target.
  bottom,

  /// Place the tooltip to the left of the target.
  left,

  /// Place the tooltip to the right of the target.
  right;

  /// Whether this position sits beside the target ([left] or [right]).
  bool get isHorizontal => this == left || this == right;

  /// Whether this position sits above or below the target ([top] or [bottom]).
  bool get isVertical => this == top || this == bottom;
}

/// How the built-in step indicator is rendered in the default tooltip.
///
/// Set it on [ShowCaseWidget.progressStyle] (only applies when
/// [ShowCaseWidget.showProgress] is `true`).
/// Where a step's action buttons ([Showcase.actions]) are drawn relative to the
/// tooltip.
enum TooltipActionPosition {
  /// Inside the tooltip, flowing below the title, description and progress
  /// footer, so the tooltip grows to contain them.
  inside,

  /// Outside the tooltip box, positioned absolutely. This is how actions have
  /// always been drawn, so it stays the default.
  outside;

  /// Whether the actions are drawn within the tooltip's own box.
  bool get isInside => this == inside;
}

enum ShowcaseProgressStyle {
  /// One dot per step, with the active step highlighted (the default).
  dots,

  /// A compact "current / total" counter, e.g. `1/6`.
  numeric,
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

/// What the system back button does while a showcase step is showing: the
/// Android back button and back gesture (predictive back included) and the
/// browser's back button.
///
/// Set it on [ShowCaseWidget.backButtonInteraction]. Every value but
/// [passThrough] works like a `PopScope(canPop: false)` on the step's page:
/// it also turns off the iOS swipe from the edge that closes the page, for as
/// long as the step shows, and a `Navigator.maybePop` call counts as a back
/// press. A `Navigator.pop` call still closes the page. It applies only while a
/// step is actually on screen. While the tour waits for a step's page, while a
/// step is hidden because another page or a dialog covers its page, and
/// before and after the tour, back works as it always does.
///
/// The <kbd>Esc</kbd> key is not the back button: it keeps dismissing the
/// tour through [ShowCaseWidget.enableKeyboardNavigation], whatever this is
/// set to.
enum BackButtonInteraction {
  /// The tour leaves back alone: it does what it would do without a tour,
  /// usually closing the page the step is on (the default).
  ///
  /// When the [ShowCaseWidget] is on that page, the tour goes away with it.
  passThrough,

  /// Back dismisses the whole tour, as <kbd>Esc</kbd> does, and the page
  /// stays open. A second press, once the tour is gone, closes the page.
  ///
  /// The tooltip animates out first, unless it already is, for example just
  /// after a Next tap: the tour then ends at once, so a press is never lost to
  /// the step change.
  dismiss,

  /// Back goes to the previous step, as [ShowCaseWidgetState.previous] does.
  ///
  /// On the first step, or wherever [ShowCaseWidgetState.previous] would have
  /// nowhere to go, back dismisses the tour instead, so the user can always
  /// leave the tour with back. The page stays open either way.
  previous,

  /// Back does nothing while a step shows: the step stays and the page stays
  /// open. The user leaves the tour from the tour itself, for example its
  /// Skip or Stop button.
  block,
}
