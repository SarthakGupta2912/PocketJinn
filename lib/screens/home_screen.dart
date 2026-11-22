// What is this file for?
// The main Pocket Jinn screen. It shows the welcome card, the big microphone
// button, a short explanation and the recent commands placeholder.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/how_it_works_card.dart';
import '../widgets/microphone_section.dart';
import '../widgets/recent_commands_placeholder.dart';
import '../widgets/responsive_body.dart';
import '../widgets/welcome_card.dart';

/// The first screen a user sees when the app opens.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Builds a single centered column that scrolls on small screens.
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: appName,
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpacing.small,
            bottom: AppSpacing.extraLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WelcomeCard(
                wakeName: defaultWakeName,
                statusLabel: homeStatusReady,
              ),
              const SizedBox(height: AppSpacing.large),
              MicrophoneSection(onPressed: () => _showVoiceComingSoon(context)),
              const SizedBox(height: AppSpacing.large),
              const HowItWorksCard(),
              const SizedBox(height: AppSpacing.large),
              const RecentCommandsPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  /// Tells the user that voice input arrives in a later stage.
  void _showVoiceComingSoon(BuildContext context) {
    showAppMessage(context, voiceComingSoonMessage);
  }
}
