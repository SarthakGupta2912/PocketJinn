// What is this file for?
// Lets the user pick the speech engine and language hint, and teach the app
// extra spoken names for a contact.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/contact_data.dart';
import '../controllers/voice_controller.dart';
import '../controllers/wake_word_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text.dart';
import '../widgets/responsive_body.dart';
import '../widgets/section_title.dart';
import '../widgets/wake_word_card.dart';
import 'onboarding_screen.dart';

/// Settings for Stage 3B speech recognition and name learning.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.voiceController,
    required this.wakeController,
  });

  /// The same voice controller used by the home screen.
  final VoiceController voiceController;

  /// The background wake-word detector owned by the home screen.
  final WakeWordController wakeController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Holds the engine availability result.
class _SettingsScreenState extends State<SettingsScreen> {
  bool _androidAvailable = false;
  String _selectedContact = knownContacts.first.name;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAndroidAvailability());
  }

  /// Builds the four settings cards.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.voiceController,
        widget.wakeController,
      ]),
      builder: (context, child) => AppScaffold(
        title: settingsTitle,
        body: ResponsiveBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: AppSpacing.small,
              bottom: AppSpacing.extraLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEngineCard(),
                const SizedBox(height: AppSpacing.large),
                _buildLanguageCard(),
                const SizedBox(height: AppSpacing.large),
                _buildTeachingCard(),
                const SizedBox(height: AppSpacing.large),
                WakeWordCard(controller: widget.wakeController),
                const SizedBox(height: AppSpacing.large),
                _buildAlwaysOnCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the engine choice and Android availability.
  Widget _buildEngineCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: settingsEngineLabel),
          const SizedBox(height: AppSpacing.medium),
          AppDropdown<String>(
            label: settingsEngineLabel,
            value: widget.voiceController.selectedEngine,
            items: const [sherpaEngineName, androidEngineName],
            onChanged: (value) =>
                unawaited(widget.voiceController.selectEngine(value)),
          ),
          const SizedBox(height: AppSpacing.small),
          AppText(
            _androidAvailable ||
                    widget.voiceController.selectedEngine != androidEngineName
                ? widget.voiceController.message
                : settingsAndroidUnavailable,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
        ],
      ),
    );
  }

  /// Shows the language hint and its honest explanation.
  Widget _buildLanguageCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: settingsLanguageLabel),
          const SizedBox(height: AppSpacing.medium),
          AppDropdown<String>(
            label: settingsLanguageLabel,
            value: widget.voiceController.selectedLanguage,
            items: speechLanguages,
            onChanged: (value) =>
                unawaited(widget.voiceController.selectLanguage(value)),
          ),
          const SizedBox(height: AppSpacing.small),
          const AppText(
            settingsLanguageNote,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
        ],
      ),
    );
  }

  /// Shows the contact picker and the name recording button.
  Widget _buildTeachingCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: settingsTeachNameTitle),
          const SizedBox(height: AppSpacing.medium),
          AppDropdown<String>(
            label: settingsTeachNameTitle,
            value: _selectedContact,
            items: [for (final contact in knownContacts) contact.name],
            onChanged: (value) => setState(() => _selectedContact = value),
          ),
          const SizedBox(height: AppSpacing.medium),
          AppButton(label: settingsTeachButton, onPressed: _teachSelectedName),
          const SizedBox(height: AppSpacing.small),
          AppText(
            widget.voiceController.message,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
          const AppText(
            settingsTeachNameNote,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
        ],
      ),
    );
  }

  /// Shows the button that opens the always-on help screen.
  Widget _buildAlwaysOnCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: settingsAlwaysOnTitle),
          const SizedBox(height: AppSpacing.small),
          const AppText(
            settingsAlwaysOnNote,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
          const SizedBox(height: AppSpacing.medium),
          AppButton(
            label: settingsAlwaysOnButton,
            isSecondary: true,
            onPressed: _openAlwaysOnHelp,
          ),
        ],
      ),
    );
  }

  /// Opens the always-on help screen.
  void _openAlwaysOnHelp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const OnboardingScreen()),
    );
  }

  /// Asks Android whether its offline speech engine is available.
  Future<void> _checkAndroidAvailability() async {
    final available = await widget.voiceController.isEngineAvailable(
      androidEngineName,
    );
    if (mounted) setState(() => _androidAvailable = available);
  }

  /// Starts the two-sample teaching flow for the chosen contact.
  Future<void> _teachSelectedName() async {
    for (final contact in knownContacts) {
      if (contact.name != _selectedContact) continue;
      await widget.voiceController.startTeaching(contact);
      return;
    }
  }
}
