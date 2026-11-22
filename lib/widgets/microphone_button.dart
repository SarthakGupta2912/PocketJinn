// What is this file for?
// The big round microphone button that is the main action of the home screen.

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/responsive.dart';

/// Shows a large circular microphone button with a touch ripple.
class MicrophoneButton extends StatelessWidget {
  const MicrophoneButton({
    super.key,
    required this.onPressed,
    this.isListening = false,
  });

  /// What happens when the user taps the microphone.
  final VoidCallback onPressed;

  /// When true, the button turns into a stop button with a red color.
  final bool isListening;

  /// Builds the circle using sizes that fit phones and tablets.
  @override
  Widget build(BuildContext context) {
    final double buttonSize = Responsive.value(
      context,
      phone: AppSizes.microphoneButtonPhone,
      tablet: AppSizes.microphoneButtonTablet,
    );
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = isListening
        ? colorScheme.error
        : colorScheme.primary;
    final Color iconColor = isListening
        ? colorScheme.onError
        : colorScheme.onPrimary;

    return Semantics(
      button: true,
      label: microphoneButtonLabel,
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Material(
          color: backgroundColor,
          elevation: AppSizes.microphoneElevation,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: iconColor,
              size: buttonSize * AppSizes.microphoneIconFraction,
            ),
          ),
        ),
      ),
    );
  }
}
