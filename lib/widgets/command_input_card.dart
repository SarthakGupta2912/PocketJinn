// What is this file for?
// Provides the Stage 1 text command box and its submit action.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../controllers/assistant_controller.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_text_field.dart';
import 'section_title.dart';

/// Shows a text field for commands understood by the local model.
class CommandInputCard extends StatefulWidget {
  const CommandInputCard({super.key, required this.controller});

  /// Controller that receives submitted commands.
  final AssistantController controller;

  @override
  State<CommandInputCard> createState() => _CommandInputCardState();
}

/// Keeps the typed command alive while the screen rebuilds.
class _CommandInputCardState extends State<CommandInputCard> {
  final TextEditingController _fieldController = TextEditingController();

  @override
  void dispose() {
    _fieldController.dispose();
    super.dispose();
  }

  /// Builds the command entry card.
  @override
  Widget build(BuildContext context) {
    final enabled = widget.controller.status == AssistantStatus.ready;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: homeAskTitle),
          const SizedBox(height: AppSpacing.medium),
          AppTextField(
            controller: _fieldController,
            hintText: commandFieldHint,
            enabled: enabled,
            textInputAction: TextInputAction.send,
            onSubmitted: _submit,
          ),
          const SizedBox(height: AppSpacing.medium),
          AppButton(
            label: sendCommandLabel,
            icon: Icons.send_rounded,
            isLoading: widget.controller.status == AssistantStatus.thinking,
            onPressed: enabled ? () => _submit(_fieldController.text) : null,
          ),
        ],
      ),
    );
  }

  /// Sends non-empty text and clears the field.
  void _submit(String value) {
    if (value.trim().isEmpty) return;
    _fieldController.clear();
    widget.controller.ask(value);
  }
}
