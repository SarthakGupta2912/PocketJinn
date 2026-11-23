// What is this file for?
// Shows whether the offline language model is ready and offers preparation.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../controllers/assistant_controller.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_text.dart';

/// Displays model preparation progress and errors.
class BrainStatusCard extends StatelessWidget {
  const BrainStatusCard({super.key, required this.controller});

  /// Controller that owns preparation state.
  final AssistantController controller;

  /// Builds the current brain status and action.
  @override
  Widget build(BuildContext context) {
    final preparing = controller.status == AssistantStatus.preparing;
    final ready =
        controller.status == AssistantStatus.ready ||
        controller.status == AssistantStatus.thinking;
    final message = _message(ready, preparing);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText('Offline brain', role: AppTextRole.title),
          const SizedBox(height: AppSpacing.small),
          AppText(message, useMutedColor: true),
          if (preparing) ..._progressParts(),
          if (!ready && !preparing) ...[
            const SizedBox(height: AppSpacing.medium),
            AppButton(
              label: prepareBrainLabel,
              icon: Icons.memory_rounded,
              isLoading: preparing,
              onPressed: controller.prepareBrain,
            ),
          ],
        ],
      ),
    );
  }

  /// Chooses the short status sentence.
  String _message(bool ready, bool preparing) {
    if (preparing) return brainPreparingMessage;
    if (ready) return brainReadyMessage;
    if (controller.status == AssistantStatus.error) {
      return '$brainErrorMessage ${controller.errorMessage ?? ''}';
    }
    return brainNotReadyMessage;
  }

  /// Builds progress controls while the model downloads.
  List<Widget> _progressParts() => [
    const SizedBox(height: AppSpacing.medium),
    LinearProgressIndicator(value: _progressValue()),
    const SizedBox(height: AppSpacing.small),
    AppText('${controller.downloadPercent}%', role: AppTextRole.caption),
  ];

  /// Converts the integer progress to the Material value range.
  double? _progressValue() =>
      controller.downloadPercent == 0 ? null : controller.downloadPercent / 100;
}
