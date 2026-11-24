// What is this file for?
// The microphone part of the home screen: a short headline, a live status
// line, the spoken words and the big round button that starts a command.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import 'app_text.dart';
import 'microphone_button.dart';

/// Shows the headline, voice status and microphone button in a centered column.
class MicrophoneSection extends StatelessWidget {
  const MicrophoneSection({
    super.key,
    required this.onPressed,
    required this.statusText,
    required this.transcript,
    this.isListening = false,
    this.isBusy = false,
    this.progress,
  });

  /// What happens when the microphone is tapped.
  final VoidCallback onPressed;

  /// The live preparation, listening or error message.
  final String statusText;

  /// Words heard so far, shown above the button when not empty.
  final String transcript;

  /// When true, the microphone shows its listening state.
  final bool isListening;

  /// When true, tapping the microphone does nothing until work finishes.
  final bool isBusy;

  /// Download progress from 0 to 1, or null when there is nothing to show.
  final double? progress;

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
        AppText(
          statusText,
          role: AppTextRole.caption,
          textAlign: TextAlign.center,
          useMutedColor: true,
        ),
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.small),
          SizedBox(
            width: AppSizes.voiceProgressWidth,
            child: LinearProgressIndicator(value: progress),
          ),
        ],
        if (transcript.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          AppText(
            transcript,
            role: AppTextRole.body,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.large),
        MicrophoneButton(
          onPressed: isBusy ? _doNothing : onPressed,
          isListening: isListening,
          semanticLabel: isListening
              ? voiceStopButtonLabel
              : microphoneButtonLabel,
        ),
      ],
    );
  }

  /// Keeps the button looking enabled while downloads or loading finish.
  void _doNothing() {}
}
