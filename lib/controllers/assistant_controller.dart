// What is this file for?
// Holds the simple assistant state and connects the screen to the local model
// and the local tools, including the call and SMS actions.

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/contact_candidate.dart';
import '../models/tool_call.dart';
import '../services/android_tool_service.dart';
import '../services/llm_service.dart';
import '../tools/tool_registry.dart';

/// The preparation and command states shown by the home screen.
enum AssistantStatus { notReady, preparing, ready, thinking, error }

/// One command shown in the in-memory recent command list.
class AssistantHistoryItem {
  const AssistantHistoryItem({required this.command, required this.result});

  /// The user's typed command.
  final String command;

  /// The assistant's displayed result.
  final String result;
}

/// Coordinates model preparation, safe tool execution and screen updates.
class AssistantController extends ChangeNotifier {
  AssistantController({
    required this.confirmRiskyAction,
    Future<void> Function()? stopVoice,
    Future<void> Function()? stopWake,
    Future<Directory> Function()? tempDirectory,
  }) {
    _registry = ToolRegistry(
      clearCommands: _clearCommands,
      androidTools: const AndroidToolService(),
      stopVoice: stopVoice,
      stopWake: stopWake,
      tempDirectory: tempDirectory,
    );
    _llmService = LlmService(tools: _registry.tools);
  }

  /// Asks the screen to approve a risky action and its button label.
  final Future<bool> Function(String message, String confirmLabel)
  confirmRiskyAction;
  late final ToolRegistry _registry;
  late final LlmService _llmService;
  AssistantStatus status = AssistantStatus.notReady;
  int downloadPercent = 0;
  String? errorMessage;
  String latestResult = '';
  final List<AssistantHistoryItem> history = [];
  bool _isDisposed = false;

  /// Loads the local model automatically when it is already installed.
  Future<void> restoreBrain() async {
    if (status != AssistantStatus.notReady) return;
    status = AssistantStatus.preparing;
    _notify();
    try {
      final loaded = await _llmService.openInstalledModel();
      status = loaded ? AssistantStatus.ready : AssistantStatus.notReady;
    } on Object catch (error) {
      status = AssistantStatus.error;
      errorMessage = error.toString();
    }
    _notify();
  }

  /// Downloads and loads the pinned local model.
  Future<void> prepareBrain() async {
    if (status == AssistantStatus.preparing) return;
    status = AssistantStatus.preparing;
    errorMessage = null;
    _notify();
    try {
      await _llmService.prepare(onProgress: _updateProgress);
      status = AssistantStatus.ready;
    } on Object catch (error) {
      status = AssistantStatus.error;
      errorMessage = error.toString();
    }
    _notify();
  }

  /// Sends one typed command to FunctionGemma and runs its requested tool.
  Future<void> ask(
    String command, {
    List<ContactCandidate> candidates = const [],
    bool confirmNames = false,
  }) async {
    final trimmedCommand = command.trim();
    if (trimmedCommand.isEmpty || status != AssistantStatus.ready) return;
    if (confirmNames && !await _confirmContactGuesses(candidates)) return;
    status = AssistantStatus.thinking;
    latestResult = '';
    _notify();
    try {
      final answer = await _llmService.ask(
        command: trimmedCommand,
        onToolCall: _runToolCall,
        extraContext: _contactContext(candidates),
      );
      latestResult = _displayAnswer(answer);
      history.insert(
        0,
        AssistantHistoryItem(command: trimmedCommand, result: latestResult),
      );
      status = AssistantStatus.ready;
    } on Object catch (error) {
      latestResult = 'The command could not be completed: $error';
      status = AssistantStatus.ready;
    }
    _notify();
  }

  /// Closes the native model when the screen goes away.
  @override
  void dispose() {
    _isDisposed = true;
    _llmService.close();
    super.dispose();
  }

  /// Updates the download percentage received from the model installer.
  void _updateProgress(int percent) {
    downloadPercent = percent;
    _notify();
  }

  /// Avoids notifying a screen that has already been removed.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  /// Confirms and executes one model-requested action.
  Future<Map<String, dynamic>> _runToolCall(ToolCall call) async {
    if (kDebugMode) debugPrint('Tool call: ${call.tool} ${call.arguments}');
    final tool = _registry.find(call.tool);
    if (tool == null) {
      return const {'status': 'error', 'error': 'Unknown tool.'};
    }
    if (tool.isRisky &&
        !await confirmRiskyAction(
          tool.confirmationMessageFor(call.arguments),
          tool.confirmationLabel,
        )) {
      return const {'status': 'cancelled', 'message': 'The user declined.'};
    }
    final result = await _registry.execute(call);
    if (kDebugMode) debugPrint('Tool ${call.tool}: $result');
    return result;
  }

  /// Asks the user before acting on a weak or close name match.
  Future<bool> _confirmContactGuesses(List<ContactCandidate> guesses) async {
    if (guesses.isEmpty) return true;
    final names = guesses
        .map(
          (guess) =>
              '${guess.contact.name} (${guess.score.toStringAsFixed(2)})',
        )
        .join(', ');
    return confirmRiskyAction(
      'Did you mean one of these contacts? $names',
      'Yes',
    );
  }

  /// Adds the name guesses to the model prompt without changing the command.
  String _contactContext(List<ContactCandidate> guesses) {
    if (guesses.isEmpty) return '';
    final names = guesses.map((guess) => guess.contact.name).join(', ');
    return 'Possible contacts heard: $names. Use only these names.';
  }

  /// Chooses useful user-facing text after a tool loop completes.
  String _displayAnswer(LlmAnswer answer) {
    final toolMessage = answer.toolResult?['message'];
    if (toolMessage is String && toolMessage.isNotEmpty) return toolMessage;
    if (answer.text.isNotEmpty) return answer.text;
    if (answer.toolCall != null) return 'Completed ${answer.toolCall!.tool}.';
    return 'I could not find an action for that command.';
  }

  /// Clears the in-memory history used by the risky Stage 1 tool.
  void _clearCommands() {
    history.clear();
    latestResult = '';
    _notify();
  }
}
