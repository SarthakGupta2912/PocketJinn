// What is this file for?
// Shows the latest result returned by the local assistant.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import 'app_card.dart';
import 'app_text.dart';
import 'section_title.dart';

/// Displays the latest assistant result when one exists.
class CommandResultCard extends StatelessWidget {
  const CommandResultCard({super.key, required this.result});

  /// Text returned by the controller.
  final String result;

  /// Builds an empty or populated result card.
  @override
  Widget build(BuildContext context) {
    if (result.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: latestResultTitle),
          const SizedBox(height: AppSpacing.small),
          AppText(result),
        ],
      ),
    );
  }
}
