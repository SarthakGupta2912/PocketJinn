// What is this file for?
// The main Pocket Jinn screen. It connects the assistant and voice controllers
// to the status, command, result and recent-command cards.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../controllers/assistant_controller.dart';
import '../controllers/voice_controller.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/brain_status_card.dart';
import '../widgets/command_input_card.dart';
import '../widgets/command_result_card.dart';
import '../widgets/how_it_works_card.dart';
import '../widgets/microphone_section.dart';
import '../widgets/recent_commands_card.dart';
import '../widgets/responsive_body.dart';
import '../widgets/welcome_card.dart';

/// The first screen a user sees when the app opens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Owns the assistant and voice controllers for the home screen lifetime.
class _HomeScreenState extends State<HomeScreen> {
  late final AssistantController _controller;
  late final VoiceController _voiceController;

  @override
  void initState() {
    super.initState();
    _controller = AssistantController(confirmRiskyAction: _confirmRiskyAction);
    _voiceController = VoiceController(
      onTranscript: _controller.ask,
      canRunCommands: () => _controller.status == AssistantStatus.ready,
    );
    unawaited(_controller.restoreBrain());
  }

  @override
  void dispose() {
    _voiceController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Builds a single centered column that scrolls on small screens.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _voiceController]),
      builder: (context, child) => AppScaffold(
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
                BrainStatusCard(controller: _controller),
                const SizedBox(height: AppSpacing.large),
                CommandInputCard(controller: _controller),
                const SizedBox(height: AppSpacing.large),
                CommandResultCard(result: _controller.latestResult),
                const SizedBox(height: AppSpacing.large),
                MicrophoneSection(
                  onPressed: _voiceController.toggleMicrophone,
                  statusText: _voiceController.message,
                  transcript: _voiceController.transcript,
                  isListening: _voiceController.isListening,
                  isBusy: _voiceController.isBusy,
                  progress: _voiceController.isDownloading
                      ? _voiceController.downloadPercent / 100
                      : null,
                ),
                const SizedBox(height: AppSpacing.large),
                const HowItWorksCard(),
                const SizedBox(height: AppSpacing.large),
                RecentCommandsCard(items: _controller.history),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Asks the user before a tool calls, messages or removes history.
  Future<bool> _confirmRiskyAction(String message, String confirmLabel) {
    return AppConfirmDialog.show(
      context: context,
      title: 'Confirm action',
      message: message,
      confirmLabel: confirmLabel,
    );
  }
}
