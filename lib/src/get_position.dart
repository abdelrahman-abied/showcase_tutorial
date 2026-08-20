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

import 'package:flutter/material.dart';

/// One measurement of the target's render box, taken once and reused by every
/// accessor on [GetPosition].
class _TargetMetrics {
  /// `localToGlobal(Offset.zero)` — the box's top-left in global coordinates.
  final Offset globalOrigin;

  /// `globalToLocal(Offset.zero)` — the global origin in the box's coordinates.
  final Offset localOrigin;

  final Size size;

  const _TargetMetrics(this.globalOrigin, this.localOrigin, this.size);
}

/// Reads the geometry of the widget behind [key].
///
/// Every accessor derives from a single [_TargetMetrics] reading, taken on the
/// first call and reused until [invalidate] is called. Laying out a tooltip asks
/// for the target's center, top, bottom and height dozens of times, and each ask
/// otherwise walked the render tree again (`findRenderObject` plus a
/// `localToGlobal`/`globalToLocal` transform chain).
///
/// The reading is only valid for one build pass, so **every consumer must call
/// [invalidate] at the start of its `build`** — geometry changes between frames,
/// and a reading held across one would position the tooltip against a stale
/// target. Invalidation is deliberately explicit rather than keyed on the frame
/// clock: `WidgetTester.pump()` with no duration produces consecutive frames
/// that share a timestamp, so a clock-keyed cache would serve stale geometry in
/// widget tests.
class GetPosition {
  final GlobalKey key;
  final EdgeInsets padding;
  final double? screenWidth;
  final double? screenHeight;

  GetPosition({required this.key, this.padding = EdgeInsets.zero, this.screenWidth, this.screenHeight});

  _TargetMetrics? _metrics;

  /// Drops the cached reading, so the next accessor measures the target again.
  ///
  /// Call this at the start of any `build` that reads this position.
  void invalidate() => _metrics = null;

  /// Measures the target once per build pass; returns `null` when it is not
  /// laid out.
  _TargetMetrics? get _target {
    final cached = _metrics;
    if (cached != null) return cached;

    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final metrics = _TargetMetrics(
      box.localToGlobal(Offset.zero),
      box.globalToLocal(Offset.zero),
      box.size,
    );
    _metrics = metrics;
    return metrics;
  }

  Rect getRect() {
    final target = _target;
    if (target == null) return Rect.zero;

    final boxOffset = target.globalOrigin;
    if (boxOffset.dx.isNaN || boxOffset.dy.isNaN) {
      return const Rect.fromLTRB(0, 0, 0, 0);
    }
    final topLeft = target.size.topLeft(boxOffset);
    final bottomRight = target.size.bottomRight(boxOffset);

    final rect = Rect.fromLTRB(
      topLeft.dx - padding.left < 0 ? 0 : topLeft.dx - padding.left,
      topLeft.dy - padding.top < 0 ? 0 : topLeft.dy - padding.top,
      bottomRight.dx + padding.right > screenWidth! ? screenWidth! : bottomRight.dx + padding.right,
      bottomRight.dy + padding.bottom > screenHeight! ? screenHeight! : bottomRight.dy + padding.bottom,
    );
    return rect;
  }

  ///Get the bottom position of the widget
  double getBottom() {
    final target = _target;
    if (target == null) return padding.bottom;
    final boxOffset = target.globalOrigin;
    if (boxOffset.dy.isNaN) return padding.bottom;
    return target.size.bottomRight(boxOffset).dy + padding.bottom;
  }

  ///Get the top position of the widget
  double getTop() {
    final target = _target;
    if (target == null) return 0 - padding.top;
    final boxOffset = target.globalOrigin;
    if (boxOffset.dy.isNaN) return 0 - padding.top;
    return target.size.topLeft(boxOffset).dy - padding.top;
  }

  ///Get the left position of the widget
  double getLeft() {
    final target = _target;
    if (target == null) return 0 - padding.left;
    final boxOffset = target.localOrigin;
    if (boxOffset.dx.isNaN) return 0 - padding.left;
    return target.size.topLeft(boxOffset).dx - boxOffset.dx;
  }

  ///Get the right position of the widget
  double getRight() {
    final target = _target;
    if (target == null) return padding.right;
    final boxOffset = target.localOrigin;
    if (boxOffset.dx.isNaN) return padding.right;
    return target.size.bottomRight(target.globalOrigin).dx - boxOffset.dx;
  }

  double getHeightContainer() => _target?.size.height ?? 0;

  double getHeight() => getBottom() - getTop();

  double getWidth() => getRight() - getLeft();

  double getCenter() => (getLeft() + getRight()) / 2;
}

