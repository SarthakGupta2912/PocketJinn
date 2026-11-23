// What is this file for?
// Defines the safe, package-independent shape of a Pocket Jinn tool call.

import 'dart:convert';

/// Holds one model-requested tool and its JSON-compatible arguments.
class ToolCall {
  const ToolCall({required this.tool, required this.arguments});

  /// The registered tool name.
  final String tool;

  /// Arguments supplied by the model.
  final Map<String, dynamic> arguments;

  /// Returns the app's stable tool-call JSON shape.
  Map<String, dynamic> toJson() => {'tool': tool, 'args': arguments};

  /// Safely reads the app's stable tool-call JSON shape.
  static ToolCall? tryParse(String text) {
    try {
      final value = jsonDecode(text);
      if (value is! Map || value['tool'] is! String || value['args'] is! Map) {
        return null;
      }
      return ToolCall(
        tool: value['tool'] as String,
        arguments: Map<String, dynamic>.from(value['args'] as Map),
      );
    } on Object {
      return null;
    }
  }
}
