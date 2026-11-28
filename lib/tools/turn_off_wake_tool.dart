// What is this file for?
// A risky Tier 2 tool that stops the always-on listener. It asks first, because
// the user may not want the phone to stop listening for "Hey Jinn".
import 'base_tool.dart';

/// Stops the background wake detector after confirmation.
class TurnOffWakeTool extends BaseTool {
  const TurnOffWakeTool({required this.stopWake});

  final Future<void> Function() stopWake;

  @override
  String get name => 'turn_off_wake';

  @override
  String get description => 'Stop listening for "Hey Jinn" in the background.';

  @override
  bool get isRisky => true;

  @override
  String get confirmationMessage =>
      'Stop listening for "Hey Jinn" in the background?';

  @override
  String get confirmationLabel => 'Stop listening';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    await stopWake();
    return {
      'status': 'success',
      'message': 'Background listening is off. Turn it on in Settings.',
    };
  }
}
