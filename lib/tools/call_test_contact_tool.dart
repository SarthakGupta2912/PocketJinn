// What is this file for?
// Defines the Stage 2 tool that calls the one approved test contact.

import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../services/android_tool_service.dart';
import 'base_tool.dart';

/// Calls the approved contact through the Kotlin phone action.
class CallTestContactTool extends BaseTool {
  CallTestContactTool({required this.androidTools});

  /// Bridge that reaches the Kotlin side.
  final AndroidToolService androidTools;

  @override
  String get name => 'call_test_contact';

  @override
  String get description =>
      'Call sarthak, the only approved contact, at $testContactNumber.';

  @override
  bool get isRisky => true;

  @override
  String get confirmationMessage =>
      'Call $testContactName at $testContactNumber?';

  @override
  String get confirmationLabel => 'Call';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  /// Starts the call or returns a friendly platform error.
  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    try {
      final reply = await androidTools.callTestContact();
      return {'status': 'success', 'message': reply};
    } on PlatformException catch (error) {
      return {'status': 'error', 'message': error.message ?? callFailedMessage};
    }
  }
}
