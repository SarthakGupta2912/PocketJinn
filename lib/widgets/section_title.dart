// What is this file for?
// A title and optional subtitle used at the top of every card section.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'app_text.dart';

/// Shows a bold section title with a softer explanation underneath.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.subtitle});

  /// The main heading of the section.
  final String title;

  /// Optional smaller sentence that explains the section.
  final String? subtitle;

  /// Builds the title and subtitle in a simple column.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(title, role: AppTextRole.title),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.extraSmall),
          AppText(subtitle!, role: AppTextRole.caption, useMutedColor: true),
        ],
      ],
    );
  }
}
