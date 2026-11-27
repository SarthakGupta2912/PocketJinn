// What is this file for?
// The home-screen card that turns the offline "Hey Jinn" wake word on or off
// and shows what the detector is doing.

import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/wake_word_controller.dart';
import '../core/app_theme.dart';
import '../core/wake_constants.dart';
import 'app_card.dart';
import 'app_text.dart';
import 'section_title.dart';

/// Shows the wake-word switch, its current state and a short explanation.
class WakeWordCard extends StatelessWidget {
  const WakeWordCard({super.key, required this.controller});

  /// The detector owned by the home screen.
  final WakeWordController controller;

  /// Builds the card with the switch and the live status line.
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: wakeTitle),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Expanded(
                child: AppText(wakeToggleLabel, role: AppTextRole.body),
              ),
              Switch(
                value: controller.isEnabled,
                onChanged: controller.isBusy
                    ? null
                    : (value) => unawaited(controller.toggle(value)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.extraSmall),
          AppText(
            controller.message,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
          const SizedBox(height: AppSpacing.small),
          const AppText(
            wakeNote,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
        ],
      ),
    );
  }
}
