// What is this file for?
// Defines the common contract used by every local assistant tool.

/// Describes and runs one assistant action.
abstract class BaseTool {
  const BaseTool();

  /// The stable name the model uses.
  String get name;

  /// Short instructions shown to the model.
  String get description;

  /// JSON schema for the tool arguments.
  Map<String, dynamic> get parameters;

  /// Whether the user must approve this action first.
  bool get isRisky => false;

  /// Text shown in the confirmation dialog for risky actions.
  String get confirmationMessage => 'Allow Pocket Jinn to run $name?';

  /// Text on the confirmation button for risky actions.
  String get confirmationLabel => 'Continue';

  /// Confirmation text that may include the arguments being approved.
  String confirmationMessageFor(Map<String, dynamic> arguments) {
    return confirmationMessage;
  }

  /// Runs the action and returns a JSON-compatible result.
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments);
}
