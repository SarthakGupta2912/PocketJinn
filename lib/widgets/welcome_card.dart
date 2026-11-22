// What is this file for?
// The welcome card on the home screen. It shows the app name, a friendly
// sentence and two small status chips.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import 'app_card.dart';
import 'app_text.dart';
import 'status_chip.dart';

/// Shows the app identity, the ready state and the current wake name.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    super.key,
    required this.wakeName,
    required this.statusLabel,
  });

  /// The wake name the user chose, for example "Hey Jinn".
  final String wakeName;

  /// Short status such as "Ready".
  final String statusLabel;

  /// Builds the badge, text and status chips.
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          const SizedBox(height: AppSpacing.medium),
          _buildStatusRow(),
        ],
      ),
    );
  }

  /// Builds the round badge next to the app name and tagline.
  Widget _buildTitleRow() {
    return const Row(
      children: [
        _JinnBadge(),
        SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(appName, role: AppTextRole.subheading),
              SizedBox(height: AppSpacing.extraSmall),
              AppText(
                appTagline,
                role: AppTextRole.caption,
                useMutedColor: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the ready chip and the wake name chip, wrapping on small screens.
  Widget _buildStatusRow() {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        StatusChip(
          label: statusLabel,
          icon: Icons.check_circle_outline_rounded,
          tone: StatusTone.success,
        ),
        StatusChip(
          label: '$wakeNameLabel: $wakeName',
          icon: Icons.record_voice_over_outlined,
        ),
      ],
    );
  }
}

/// A small purple circle with a sparkle icon.
class _JinnBadge extends StatelessWidget {
  const _JinnBadge();

  /// Builds the soft colored badge.
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: AppSizes.welcomeBadgeSize,
      height: AppSizes.welcomeBadgeSize,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: colorScheme.onPrimaryContainer,
        size: AppSizes.welcomeBadgeIconSize,
      ),
    );
  }
}
