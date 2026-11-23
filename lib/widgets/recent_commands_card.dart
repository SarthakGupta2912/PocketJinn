// What is this file for?
// Shows the commands handled during this app session.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../controllers/assistant_controller.dart';
import 'app_card.dart';
import 'app_text.dart';
import 'recent_commands_placeholder.dart';
import 'section_title.dart';

/// Displays recent commands or the existing empty state.
class RecentCommandsCard extends StatelessWidget {
  const RecentCommandsCard({super.key, required this.items});

  /// Session history supplied by the controller.
  final List<AssistantHistoryItem> items;

  /// Builds the compact recent command list.
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const RecentCommandsPlaceholder();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: homeHistoryTitle),
          const SizedBox(height: AppSpacing.small),
          for (final item in items.take(maxVisibleRecentCommands))
            _buildItem(item),
        ],
      ),
    );
  }

  /// Builds one command and result row.
  Widget _buildItem(AssistantHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(item.command, role: AppTextRole.body),
          const SizedBox(height: AppSpacing.extraSmall),
          AppText(item.result, role: AppTextRole.caption, useMutedColor: true),
        ],
      ),
    );
  }
}
