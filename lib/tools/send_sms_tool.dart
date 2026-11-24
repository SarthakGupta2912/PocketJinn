// What is this file for?
// Defines the Stage 2 tool that sends an SMS to the approved test contact.

import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../services/android_tool_service.dart';
import 'base_tool.dart';

/// Sends one SMS to the approved contact through the Kotlin phone action.
class SendSmsTool extends BaseTool {
  SendSmsTool({required this.androidTools});

  /// Bridge that reaches the Kotlin side.
  final AndroidToolService androidTools;

  @override
  String get name => 'send_sms_to_test_contact';

  @override
  String get description =>
      'Send a text message to sarthak, the only approved contact, at '
      '$testContactNumber.';

  @override
  bool get isRisky => true;

  @override
  String get confirmationMessage =>
      'Send an SMS to $testContactName at $testContactNumber?';

  @override
  String get confirmationLabel => 'Send';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': {
      'message': {'type': 'string', 'description': 'The SMS text to send.'},
    },
    'required': ['message'],
  };

  /// Sends the message or returns a friendly validation or platform error.
  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    final message = (arguments['message'] as String?)?.trim() ?? '';
    if (message.isEmpty) {
      return const {'status': 'error', 'message': smsEmptyMessage};
    }
    if (message.length > maxSmsLength) {
      return const {'status': 'error', 'message': smsTooLongMessage};
    }
    try {
      final reply = await androidTools.sendSmsToTestContact(message);
      return {'status': 'success', 'message': reply};
    } on PlatformException catch (error) {
      return {'status': 'error', 'message': error.message ?? smsFailedMessage};
    }
  }

  /// Shows the exact SMS text in the confirmation dialog.
  @override
  String confirmationMessageFor(Map<String, dynamic> arguments) {
    final message = (arguments['message'] as String?)?.trim() ?? '';
    return 'Send this SMS to $testContactName at $testContactNumber?\n\n'
        '$message';
  }
}
