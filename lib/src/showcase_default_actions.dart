import 'package:flutter/material.dart';

import '../showcase_tutorial.dart';
import 'utilities/_showcase_context_provider.dart';

/// Default action buttons widget for a [Showcase] tooltip.
///
/// Lays out the Previous, Stop and Next buttons in a [Row], each configurable
/// through an [ActionButtonConfig]. Pass it to the `actions` property of a
/// [Showcase] and style its container with [ActionsSettings].
class ShowCaseDefaultActions extends StatelessWidget {
  /// How the buttons are placed along the main (horizontal) axis of the [Row].
  final MainAxisAlignment mainAxisAlignment;

  /// How much horizontal space the [Row] should occupy.
  final MainAxisSize mainAxisSize;

  /// How the buttons are aligned along the cross (vertical) axis of the [Row].
  final CrossAxisAlignment crossAxisAlignment;

  /// The text direction used to order the buttons, or null to inherit it.
  final TextDirection? textDirection;

  /// The order in which buttons are laid out vertically.
  final VerticalDirection verticalDirection;

  /// The baseline used to align children when [crossAxisAlignment] is baseline.
  final TextBaseline? textBaseline;

  /// Thickness of the vertical divider drawn between buttons.
  ///
  /// Defaults to `1.0`.
  final double? dividerThickness;

  /// Color of the vertical divider drawn between buttons.
  final Color verticalDividerColor;

  /// Configuration for the Next button.
  final ActionButtonConfig next;

  /// Configuration for the Previous button.
  final ActionButtonConfig previous;

  /// Configuration for the Stop button.
  final ActionButtonConfig stop;

  /// Creates the default Previous / Stop / Next action buttons for a tooltip.
  const ShowCaseDefaultActions({
    super.key,
    this.next = const ActionButtonConfig(),
    this.previous = const ActionButtonConfig(),
    this.stop = const ActionButtonConfig(),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.dividerThickness = 1.0,
    this.verticalDividerColor = const Color(0xffcaf0f8),
  });

  /// Builds the [Row] of Previous, Stop and Next buttons for the tooltip.
  @override
  Widget build(BuildContext context) {
    final showcaseContext = ShowcaseContextProvider.of(context)?.context;

    return Row(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      verticalDirection: verticalDirection,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: textBaseline,
      textDirection: textDirection,
      children: [
        if (previous.buttonVisible)
          _getButtonWidget(
            previous,
            showcaseContext,
            previous.text ?? 'Previous',
            previous.callback ??
                () {
                  if (showcaseContext != null &&
                      ShowCaseWidget.of(showcaseContext).ids != null) {
                    ShowCaseWidget.of(showcaseContext).previous();
                  }
                },
          ),
        if (previous.buttonVisible && stop.buttonVisible ||
            previous.buttonVisible && next.buttonVisible)
          _getVerticalDivider(),
        if (stop.buttonVisible)
          _getButtonWidget(
            stop,
            showcaseContext,
            stop.text ?? 'Stop',
            stop.callback ??
                () {
                  if (showcaseContext != null &&
                      ShowCaseWidget.of(showcaseContext).ids != null) {
                    ShowCaseWidget.of(showcaseContext).dismiss();
                  }
                },
          ),
        if (stop.buttonVisible && next.buttonVisible) _getVerticalDivider(),
        if (next.buttonVisible)
          _getButtonWidget(
            next,
            showcaseContext,
            next.text ?? 'Next',
            next.callback ??
                () {
                  if (showcaseContext != null &&
                      ShowCaseWidget.of(showcaseContext).ids != null) {
                    ShowCaseWidget.of(showcaseContext).completed(
                        ShowCaseWidget.of(showcaseContext).ids![
                            ShowCaseWidget.of(showcaseContext).activeWidgetId ??
                                0]);
                  }
                },
          ),
      ],
    );
  }

  Widget _getVerticalDivider() {
    return VerticalDivider(
      width: 1.0,
      thickness: dividerThickness,
      color: verticalDividerColor,
    );
  }

  Widget _getButtonWidget(ActionButtonConfig actionConfig,
      BuildContext? showcaseContext, String buttonText, VoidCallback onClick) {
    return Expanded(
      child: Directionality(
        textDirection: actionConfig.textDirection,
        child: TextButton.icon(
          label: actionConfig.buttonTextVisible
              ? Text(
                  buttonText,
                  style: TextStyle(color: actionConfig.textColor),
                )
              : const SizedBox.shrink(),
          icon: actionConfig.icon ?? const SizedBox.shrink(),
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(
                  actionConfig.textButtonBgColor)),
          onPressed: onClick,
        ),
      ),
    );
  }
}

/// Styling and behavior configuration for a single action button rendered by
/// [ShowCaseDefaultActions], such as Next, Previous or Stop.
class ActionButtonConfig {
  /// button text
  final String? text;

  /// button icon or image
  final Widget? icon;

  /// Color of button text.
  final Color textColor;

  /// Color of button background.
  final Color textButtonBgColor;

  /// Callback on button tap.
  ///
  /// Note: Default callback will be overridden by this one.
  final VoidCallback? callback;

  /// Defines visibility of button.
  final bool buttonVisible;

  /// Defines visibility of button.
  final bool buttonTextVisible;

  /// Defines icon and text direction.
  final TextDirection textDirection;

  /// Creates a configuration for a single tooltip action button.
  const ActionButtonConfig({
    this.text,
    this.icon,
    this.textColor = const Color(0xff48cae4),
    this.textButtonBgColor = Colors.transparent,
    this.callback,
    this.buttonVisible = true,
    this.buttonTextVisible = true,
    this.textDirection = TextDirection.ltr,
  });
}
