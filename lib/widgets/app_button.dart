// What is this file for?
// One button widget with a filled and an outlined style, so screens never
// build buttons by hand.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';

/// Shows a filled or outlined button with an optional icon and loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.expand = true,
  });

  /// The words written on the button.
  final String label;

  /// What happens when the user taps the button.
  final VoidCallback? onPressed;

  /// Optional small icon shown before the label.
  final IconData? icon;

  /// When true, the button shows a spinner and cannot be tapped.
  final bool isLoading;

  /// When true, uses the quieter outlined style.
  final bool isSecondary;

  /// When true, the button fills the available width.
  final bool expand;

  /// Builds the matching button style and content.
  @override
  Widget build(BuildContext context) {
    final VoidCallback? safeOnPressed = isLoading ? null : onPressed;
    final Widget content = _buildContent(context);
    final Widget button = isSecondary
        ? OutlinedButton(onPressed: safeOnPressed, child: content)
        : FilledButton(onPressed: safeOnPressed, child: content);

    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }

  /// Puts the icon, label or spinner inside the button.
  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator(context);
    }
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.smallIconSize),
        const SizedBox(width: AppSpacing.small),
        Text(label),
      ],
    );
  }

  /// Shows a small spinner using a color that stays visible on the button.
  Widget _buildLoadingIndicator(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppSizes.loadingIndicatorSize,
      height: AppSizes.loadingIndicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.loadingIndicatorStroke,
        color: isSecondary ? colorScheme.primary : colorScheme.onPrimary,
      ),
    );
  }
}
