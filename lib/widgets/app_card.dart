// What is this file for?
// A rounded card used for every grouped block of content in the app.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Displays content inside the shared rounded card style.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.large),
    this.onTap,
  });

  /// The content placed inside the card.
  final Widget child;

  /// Space between the card edge and the content.
  final EdgeInsetsGeometry padding;

  /// Optional tap action that adds a ripple effect.
  final VoidCallback? onTap;

  /// Builds a flat card, with a ripple only when it is tappable.
  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
