// What is this file for?
// The empty state for recent commands on the home screen. It will be
// replaced by real history items in a later stage.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import 'app_card.dart';
import 'app_text.dart';
import 'section_title.dart';

/// Shows the recent commands card with a friendly empty message.
class RecentCommandsPlaceholder extends StatelessWidget {
  const RecentCommandsPlaceholder({super.key});

  /// Builds the title and the empty message row.
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: homeHistoryTitle),
          const SizedBox(height: AppSpacing.medium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.history_rounded,
                size: AppSizes.mediumIconSize,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.small),
              const Expanded(
                child: AppText(
                  homeHistoryEmptyMessage,
                  role: AppTextRole.caption,
                  useMutedColor: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
