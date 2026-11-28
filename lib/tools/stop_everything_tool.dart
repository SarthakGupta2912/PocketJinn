// What is this file for?
// A safe Tier 1 tool that gives the user one global stop. It never turns the
// user's saved wake switch off; it only stops the current activity.
import 'base_tool.dart';

/// Stops the current voice command and clears the in-memory command list.
class StopEverythingTool extends BaseTool {
  const StopEverythingTool({
    required this.stopVoice,
    required this.clearCommands,
  });

  /// Stops microphone capture when it is running.
  final Future<void> Function() stopVoice;

  /// Clears the recent commands held in memory.
  final void Function() clearCommands;

  @override
  String get name => 'stop_everything';

  @override
  String get description =>
      'Stop the current voice action and clear the recent commands.';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    await stopVoice();
    clearCommands();
    return {
      'status': 'success',
      'message': 'Everything is stopped. Say "Hey Jinn" when you are ready.',
    };
  }
}
