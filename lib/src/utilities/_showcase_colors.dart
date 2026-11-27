import 'package:material_ui/material_ui.dart';

/// The colours a step uses for anything the developer has not set.
///
/// They come from the app's `material_ui` [Theme], so a tour matches the app
/// in light and dark mode. An app without one (for example an app still on the
/// legacy `package:flutter/material.dart` `MaterialApp`, whose theme this
/// package cannot read) gets [fallback], the fixed colours used before 1.17.0.
@immutable
class ShowcaseColors {
  const ShowcaseColors._({
    required this.fromTheme,
    required this.tooltipBackground,
    required this.text,
    required this.scrim,
    required this.accent,
    required this.outline,
  });

  /// Takes the colours from [theme]'s colour scheme.
  factory ShowcaseColors.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return ShowcaseColors._(
      fromTheme: true,
      // The tooltip sits on a scrim like a dialog does, so it takes the same
      // surface a dialog has.
      tooltipBackground: scheme.surfaceContainerHigh,
      text: scheme.onSurface,
      scrim: scheme.scrim,
      accent: scheme.primary,
      outline: scheme.outlineVariant,
    );
  }

  /// The fixed colours used when the app has no `material_ui` theme.
  static const fallback = ShowcaseColors._(
    fromTheme: false,
    tooltipBackground: Colors.white,
    text: Colors.black,
    scrim: Colors.black45,
    accent: Color(0xff48cae4),
    outline: Color(0xffcaf0f8),
  );

  /// The colours for [context]: from its `material_ui` [Theme], or [fallback]
  /// when it is not under one.
  ///
  /// `Theme.of` alone cannot tell the two apart: without a theme it quietly
  /// returns a default one, which has nothing to do with the app. Finding out
  /// is a walk up the tree, so callers keep the result while the step shows.
  static ShowcaseColors of(BuildContext context) {
    final hasAppTheme = context.findAncestorWidgetOfExactType<Theme>() != null;
    return hasAppTheme ? ShowcaseColors.fromTheme(Theme.of(context)) : fallback;
  }

  /// Whether these colours come from the app's theme (as opposed to
  /// [fallback]).
  final bool fromTheme;

  /// Background of the default tooltip.
  final Color tooltipBackground;

  /// Text drawn on [tooltipBackground].
  final Color text;

  /// The dimmed background behind the tour. Its opacity is set separately.
  final Color scrim;

  /// Action button labels drawn on [tooltipBackground].
  final Color accent;

  /// The divider between action buttons drawn on [tooltipBackground].
  final Color outline;

  /// White or black, whichever is readable on [background].
  static Color contrastWith(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? Colors.white : Colors.black;
  }

  /// What is drawn straight on the dimmed background (the pulse ring, the
  /// loading spinner): readable against [scrimColor].
  Color onScrim(Color scrimColor) => fromTheme ? contrastWith(scrimColor) : Colors.white;

  /// Default text colour on a tooltip whose background is [background].
  ///
  /// The theme's own text colour is only right on the theme's own background.
  /// On a background the developer chose, pick whichever of black and white
  /// can be read on it.
  Color textOn(Color background, {required bool isThemeBackground}) {
    if (!fromTheme) return text;
    return isThemeBackground ? text : contrastWith(background);
  }

  /// Default action button label colour on [background].
  Color actionForegroundOn(Color background, {required bool isThemeBackground}) {
    if (!fromTheme) return accent;
    return isThemeBackground ? accent : contrastWith(background);
  }

  /// Default colour of the divider between action buttons on [background].
  Color actionDividerOn(Color background, {required bool isThemeBackground}) {
    if (!fromTheme) return outline;
    return isThemeBackground ? outline : contrastWith(background).withValues(alpha: 0.3);
  }
}

/// Hands the default action-button colours down to the buttons, which are
/// built by the developer and so cannot be given them directly.
class ShowcaseActionColors extends InheritedWidget {
  /// Provides [foreground] and [divider] to the action buttons in [child].
  const ShowcaseActionColors({super.key, required this.foreground, required this.divider, required super.child});

  /// Default colour of a button's label.
  final Color foreground;

  /// Default colour of the divider between buttons.
  final Color divider;

  /// The colours provided by the tooltip the buttons are in, if any.
  static ShowcaseActionColors? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShowcaseActionColors>();
  }

  @override
  bool updateShouldNotify(ShowcaseActionColors oldWidget) {
    return foreground != oldWidget.foreground || divider != oldWidget.divider;
  }
}
