// What is this file for?
// The microphone part of the home screen: a short headline, a hint and the
// big round button that starts a voice command.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import 'app_text.dart';
import 'microphone_button.dart';

/// Shows the headline, hint and microphone button in a centered column.
class MicrophoneSection extends StatelessWidget {
  const MicrophoneSection({
    super.key,
    required this.onPressed,
    this.isListening = false,
  });

  /// What happens when the microphone is tapped.
  final VoidCallback onPressed;

  /// When true, the microphone shows its listening state.
  final bool isListening;

  /// Builds the centered microphone area.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppText(
          homeAskTitle,
          role: AppTextRole.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.extraSmall),
        const AppText(
          homeMicrophoneHint,
          role: AppTextRole.caption,
          textAlign: TextAlign.center,
          useMutedColor: true,
        ),
        const SizedBox(height: AppSpacing.large),
        MicrophoneButton(onPressed: onPressed, isListening: isListening),
      ],
    );
  }
}
