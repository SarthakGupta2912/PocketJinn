// What is this file for?
// A small themed icon button used in app bars, such as the Settings gear.

import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Shows one icon button with a screen-reader label.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  /// Icon drawn inside the button.
  final IconData icon;

  /// Label read by screen readers and shown on long press.
  final String tooltip;

  /// What happens when the button is tapped.
  final VoidCallback onPressed;

  /// Builds a button with the minimum recommended touch size.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.minimumTouchTarget,
      height: AppSizes.minimumTouchTarget,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
