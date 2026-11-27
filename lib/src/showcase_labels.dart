import 'package:flutter/foundation.dart';

/// The text of the tour's built-in buttons, set once for the whole tour.
///
/// Pass it to [ShowCaseWidget.labels] to translate the tour:
///
/// ```dart
/// ShowCaseWidget(
///   labels: const ShowcaseLabels(
///     next: 'التالي',
///     previous: 'السابق',
///     stop: 'إنهاء',
///     skip: 'تخطي',
///   ),
///   builder: ...,
/// )
/// ```
///
/// [next], [previous] and [stop] are used by every [ShowCaseDefaultActions]
/// in the tour, including the ones passed to [Showcase.actions] and
/// [ShowCaseWidget.globalActions]. [skip] is the label of the Skip button
/// shown by [ShowCaseWidget.showSkip].
///
/// A button's own [ActionButtonConfig.text] wins over these labels, so one
/// step can still say something different. A label is also what screen
/// readers announce for a button whose text is hidden
/// ([ActionButtonConfig.buttonTextVisible] set to `false`).
///
/// Every label you leave out keeps its English default.
@immutable
class ShowcaseLabels {
  /// Label of the Next button. Defaults to `'Next'`.
  final String next;

  /// Label of the Previous button. Defaults to `'Previous'`.
  final String previous;

  /// Label of the Stop button, which ends the tour. Defaults to `'Stop'`.
  final String stop;

  /// Label of the Skip button shown by [ShowCaseWidget.showSkip].
  /// Defaults to `'Skip'`.
  final String skip;

  /// Creates the labels for the tour's built-in buttons.
  const ShowcaseLabels({this.next = 'Next', this.previous = 'Previous', this.stop = 'Stop', this.skip = 'Skip'});

  /// Returns a copy with the given labels replaced.
  ShowcaseLabels copyWith({String? next, String? previous, String? stop, String? skip}) {
    return ShowcaseLabels(
      next: next ?? this.next,
      previous: previous ?? this.previous,
      stop: stop ?? this.stop,
      skip: skip ?? this.skip,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowcaseLabels &&
          other.next == next &&
          other.previous == previous &&
          other.stop == stop &&
          other.skip == skip;

  @override
  int get hashCode => Object.hash(next, previous, stop, skip);

  @override
  String toString() => 'ShowcaseLabels(next: $next, previous: $previous, stop: $stop, skip: $skip)';
}
