// What is this file for?
// Keeps page content centered and readable on tablets instead of stretching
// text from edge to edge.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/responsive.dart';

/// Centers content and limits its width on larger screens.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.padding});

  /// The page content that should stay readable.
  final Widget child;

  /// Optional padding; the default grows a little on bigger screens.
  final EdgeInsetsGeometry? padding;

  /// Builds the centered, width-limited content.
  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry defaultPadding = EdgeInsets.symmetric(
      horizontal: Responsive.value(
        context,
        phone: AppSpacing.medium,
        tablet: AppSpacing.large,
        large: AppSpacing.extraLarge,
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(padding: padding ?? defaultPadding, child: child),
      ),
    );
  }
}
