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

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scales [child] by [scale] about [alignment], like [ScaleTransition].
///
/// [ScaleTransition] is an [AnimatedWidget]: every animation tick marks it
/// dirty, rebuilds it and hands a new [Transform] to its render object. Here
/// the render object listens to [scale] itself and only repaints, so a tick
/// costs no widget rebuild. The tooltip runs this animation every time a step
/// opens.
///
/// The output is the same [RenderTransform] that [ScaleTransition] builds,
/// with the same matrix, alignment, text direction and hit testing.
class ScaleTransitionBox extends SingleChildRenderObjectWidget {
  /// Scales [child] by the current value of [scale].
  const ScaleTransitionBox({super.key, required this.scale, this.alignment = Alignment.center, super.child});

  /// Drives the scale factor; `1.0` is the child's own size.
  final Animation<double> scale;

  /// The point the child is scaled about, as [ScaleTransition.alignment].
  final AlignmentGeometry alignment;

  @override
  RenderScaleTransitionBox createRenderObject(BuildContext context) {
    return RenderScaleTransitionBox(
      animation: scale,
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderScaleTransitionBox renderObject) {
    renderObject
      ..animation = scale
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context);
  }
}

/// The render object of [ScaleTransitionBox]: a [RenderTransform] whose matrix
/// follows an [Animation] while it is attached.
class RenderScaleTransitionBox extends RenderTransform {
  /// Creates a transform that follows [animation].
  RenderScaleTransitionBox({required Animation<double> animation, super.alignment, super.textDirection})
    : _animation = animation,
      super(transform: _matrixFor(animation.value));

  static Matrix4 _matrixFor(double value) => Matrix4.diagonal3Values(value, value, 1.0);

  /// The animation the scale factor follows.
  Animation<double> get animation => _animation;
  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (identical(value, _animation)) return;
    if (attached) _animation.removeListener(_update);
    _animation = value;
    if (attached) _animation.addListener(_update);
    _update();
  }

  double? _lastValue;

  void _update() {
    final value = _animation.value;
    if (value == _lastValue) return;
    _lastValue = value;
    // Marks paint (and semantics) dirty only; the child's layout is untouched.
    transform = _matrixFor(value);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(_update);
    _update();
  }

  @override
  void detach() {
    _animation.removeListener(_update);
    super.detach();
  }
}

/// Translates [child] by a fraction of its size, like [SlideTransition].
///
/// The render-level counterpart of [SlideTransition], for the same reason as
/// [ScaleTransitionBox]: the tooltip's bobbing animation never stops while a step
/// is open, and as an [AnimatedWidget] it rebuilt a widget on every frame. Here
/// a tick only repaints.
class SlideTransitionBox extends SingleChildRenderObjectWidget {
  /// Translates [child] by the current value of [position].
  const SlideTransitionBox({super.key, required this.position, super.child});

  /// Drives the translation, as a fraction of the child's size.
  final Animation<Offset> position;

  @override
  RenderSlideTransitionBox createRenderObject(BuildContext context) {
    return RenderSlideTransitionBox(position: position);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSlideTransitionBox renderObject) {
    renderObject.position = position;
  }
}

/// The render object of [SlideTransitionBox]: a
/// [RenderFractionalTranslation] whose translation follows an [Animation]
/// while it is attached.
class RenderSlideTransitionBox extends RenderFractionalTranslation {
  /// Creates a translation that follows [position].
  RenderSlideTransitionBox({required Animation<Offset> position})
    : _position = position,
      super(translation: position.value);

  /// The animation the translation follows.
  Animation<Offset> get position => _position;
  Animation<Offset> _position;
  set position(Animation<Offset> value) {
    if (identical(value, _position)) return;
    if (attached) _position.removeListener(_update);
    _position = value;
    if (attached) _position.addListener(_update);
    _update();
  }

  // The translation setter already ignores an unchanged value.
  void _update() => translation = _position.value;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position.addListener(_update);
    _update();
  }

  @override
  void detach() {
    _position.removeListener(_update);
    super.detach();
  }
}

/// A [RepaintBoundary] whose child may be drawn, and tapped, outside its box.
///
/// The tooltip's scale and slide draw it away from where it was laid out: a
/// tooltip above its target is moved up by its whole height. A plain
/// [RepaintBoundary] only hit-tests points inside its own box, so taps on a
/// tooltip drawn outside it would fall through to the dimmed background.
/// This one asks its child regardless, as the transforms below it do.
class OverflowRepaintBoundary extends SingleChildRenderObjectWidget {
  /// Puts [child] on its own layer without limiting where it can be tapped.
  const OverflowRepaintBoundary({super.key, super.child});

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) => _RenderOverflowRepaintBoundary();
}

class _RenderOverflowRepaintBoundary extends RenderRepaintBoundary {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }
}
