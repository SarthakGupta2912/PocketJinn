// What is this file for?
// The only text widget the app uses, so every font size comes from the theme
// instead of being typed inside a screen.

import 'package:flutter/material.dart';

/// The text roles the app is allowed to show.
enum AppTextRole { heading, subheading, title, body, caption }

/// Displays short text using one role from the shared text theme.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.role = AppTextRole.body,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.useMutedColor = false,
    this.color,
  });

  /// The words to display.
  final String text;

  /// Which theme text style should be used.
  final AppTextRole role;

  /// How the text should line up inside the available width.
  final TextAlign? textAlign;

  /// Maximum number of lines before the text is cut.
  final int? maxLines;

  /// What to show when the text is too long for its box.
  final TextOverflow? overflow;

  /// When true, uses the softer secondary text color.
  final bool useMutedColor;

  /// Optional exact color, used by widgets such as the status chip.
  final Color? color;

  /// Builds the text with the style chosen for its role.
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: _pickStyle(context),
    );
  }

  /// Converts the role and color options into a real TextStyle.
  TextStyle? _pickStyle(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextStyle? style = _styleForRole(textTheme);

    if (useMutedColor) {
      style = style?.copyWith(color: colorScheme.onSurfaceVariant);
    } else {
      style = style?.copyWith(color: colorScheme.onSurface);
    }
    if (color != null) {
      style = style?.copyWith(color: color);
    }
    return style;
  }

  /// Matches each role with one style from the shared text theme.
  TextStyle? _styleForRole(TextTheme textTheme) {
    switch (role) {
      case AppTextRole.heading:
        return textTheme.headlineLarge;
      case AppTextRole.subheading:
        return textTheme.headlineMedium;
      case AppTextRole.title:
        return textTheme.titleLarge;
      case AppTextRole.body:
        return textTheme.bodyLarge;
      case AppTextRole.caption:
        return textTheme.bodySmall;
    }
  }
}
