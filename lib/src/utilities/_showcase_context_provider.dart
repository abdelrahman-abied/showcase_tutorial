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

import 'package:flutter/widgets.dart';

import '../showcase_labels.dart';

/// This class is used to provide context of Showcase widget to Overlay so
/// that we can access ShowcaseWidget in widget tree from overlay.
///
/// It also carries the tour's [ShowcaseLabels], so the buttons in the overlay
/// are rebuilt when the labels change (for example when the app switches
/// language), even when the buttons widget is a `const` instance that the
/// overlay's own rebuild would skip.
class ShowcaseContextProvider extends InheritedWidget {
  final BuildContext context;

  /// The labels of the tour's built-in buttons (`ShowCaseWidget.labels`).
  final ShowcaseLabels labels;

  const ShowcaseContextProvider({
    super.key,
    required this.context,
    this.labels = const ShowcaseLabels(),
    required super.child,
  });

  static ShowcaseContextProvider? of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<ShowcaseContextProvider>();
    return result;
  }

  @override
  bool updateShouldNotify(ShowcaseContextProvider oldWidget) => oldWidget.labels != labels;
}
