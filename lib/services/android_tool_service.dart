// What is this file for?
// Wraps the one Android method channel used by the Stage 2 call and SMS tools.

import 'package:flutter/services.dart';

import '../core/constants.dart';

/// Sends fixed-recipient call and SMS requests to the Kotlin side.
class AndroidToolService {
  const AndroidToolService();

  static const MethodChannel _channel = MethodChannel(androidToolsChannelName);

  /// Asks Android to call the one approved test contact.
  Future<String> callTestContact() async {
    final reply = await _channel.invokeMethod<String>('callTestContact');
    return reply ?? callStartedMessage;
  }

  /// Asks Android to send an SMS to the one approved test contact.
  Future<String> sendSmsToTestContact(String message) async {
    final reply = await _channel.invokeMethod<String>('sendSmsToTestContact', {
      'message': message,
    });
    return reply ?? smsHandedOffMessage;
  }
}
