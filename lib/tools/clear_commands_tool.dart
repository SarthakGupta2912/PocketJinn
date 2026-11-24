// What is this file for?
// Defines the first genuinely destructive in-app action for confirmation tests.

import 'base_tool.dart';

/// Clears the current in-memory command list after user approval.
class ClearCommandsTool extends BaseTool {
  ClearCommandsTool({required this.clearCommands});

  /// Callback owned by the assistant controller.
  final void Function() clearCommands;

  @override
  String get name => 'clear_recent_commands';

  @override
  String get description => 'Delete all recent commands shown in this app.';

  @override
  bool get isRisky => true;

  @override
  String get confirmationMessage => 'Delete all recent commands?';

  @override
  String get confirmationLabel => 'Delete';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  /// Deletes the commands and reports the completed action.
  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    clearCommands();
    return const {'status': 'success', 'message': 'Recent commands cleared.'};
  }
}
