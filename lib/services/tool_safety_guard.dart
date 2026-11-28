// What is this file for?
// The hard safety line for Stage 8. Pocket Jinn never handles payments, bank
// logins, passwords or instructions that arrive inside screen/notification
// text. This guard runs before any tool, including risky ones.
import '../models/tool_call.dart';

/// Refuses tool calls that cross the app's safety line.
class ToolSafetyGuard {
  const ToolSafetyGuard();

  /// Tool-name fragments that are never allowed, whatever the model asks for.
  static const List<String> blockedNameParts = [
    'pay',
    'payment',
    'bank',
    'upi',
    'card',
    'password',
    'passwd',
    'credential',
    'otp',
    'pin',
    'transfer',
    'withdraw',
    'login',
    'signin',
  ];

  /// Phrases that mean text came from another app and must not be obeyed.
  static const List<String> untrustedPhrases = [
    'ignore previous',
    'ignore all previous',
    'disregard previous',
    'system prompt',
    'send password',
    'type your password',
    'enter your pin',
    'enter pin',
    'reveal password',
    'credit card number',
    'cvv',
    'upi pin',
    'bank account number',
  ];

  /// True when the tool itself is forbidden.
  bool isBlockedTool(String name) {
    final lower = name.toLowerCase();
    for (final part in blockedNameParts) {
      if (lower.contains(part)) return true;
    }
    return false;
  }

  /// Returns a short reason when an argument tries to smuggle in an instruction.
  String? untrustedReason(Map<String, dynamic> arguments) {
    for (final value in arguments.values) {
      if (value is! String) continue;
      final lower = value.toLowerCase();
      for (final phrase in untrustedPhrases) {
        if (lower.contains(phrase)) {
          return 'Text from another app cannot change Pocket Jinn\'s rules.';
        }
      }
    }
    return null;
  }

  /// Checks a call and returns a refusal reason, or null when it is allowed.
  String? refusalFor(ToolCall call) {
    if (isBlockedTool(call.tool)) {
      return 'Pocket Jinn cannot pay, bank, log in or handle passwords.';
    }
    return untrustedReason(call.arguments);
  }
}
