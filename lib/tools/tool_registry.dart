// What is this file for?
// Keeps all available tools in one simple registry for the model and app.

import '../models/tool_call.dart';
import 'base_tool.dart';
import 'clear_commands_tool.dart';
import 'current_time_tool.dart';

/// Stores tools, creates declarations and safely dispatches calls.
class ToolRegistry {
  ToolRegistry({required void Function() clearCommands})
    : _tools = [
        CurrentTimeTool(),
        ClearCommandsTool(clearCommands: clearCommands),
      ];

  final List<BaseTool> _tools;

  /// Returns the tools that the language model may call.
  List<BaseTool> get tools => List.unmodifiable(_tools);

  /// Finds a tool by its model-facing name.
  BaseTool? find(String name) {
    for (final tool in _tools) {
      if (tool.name == name) return tool;
    }
    return null;
  }

  /// Executes a call or returns a safe unknown-tool error.
  Future<Map<String, dynamic>> execute(ToolCall call) async {
    final tool = find(call.tool);
    if (tool == null) return {'status': 'error', 'error': 'Unknown tool.'};
    return tool.run(call.arguments);
  }
}
