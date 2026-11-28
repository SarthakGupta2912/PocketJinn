// What is this file for?
// Keeps all available tools in one simple registry for the model and app.

import 'dart:io';

import '../models/tool_call.dart';
import '../services/android_tool_service.dart';
import 'base_tool.dart';
import 'battery_level_tool.dart';
import 'calculator_tool.dart';
import 'call_test_contact_tool.dart';
import 'clear_commands_tool.dart';
import 'current_time_tool.dart';
import 'delete_temp_files_tool.dart';
import 'send_sms_tool.dart';
import 'set_alarm_tool.dart';
import 'stop_everything_tool.dart';
import 'turn_off_wake_tool.dart';

/// Stores tools, creates declarations and safely dispatches calls.
class ToolRegistry {
  ToolRegistry({
    required void Function() clearCommands,
    required AndroidToolService androidTools,
    Future<void> Function()? stopVoice,
    Future<void> Function()? stopWake,
    Future<Directory> Function()? tempDirectory,
  }) : _tools = [
         const CurrentTimeTool(),
         ClearCommandsTool(clearCommands: clearCommands),
         CallTestContactTool(androidTools: androidTools),
         SendSmsTool(androidTools: androidTools),
         BatteryLevelTool(androidTools: androidTools),
         const CalculatorTool(),
         SetAlarmTool(androidTools: androidTools),
         StopEverythingTool(
           stopVoice: stopVoice ?? () async {},
           clearCommands: clearCommands,
         ),
         DeleteTempFilesTool(
           directory: tempDirectory ?? () async => Directory.systemTemp,
         ),
         TurnOffWakeTool(stopWake: stopWake ?? () async {}),
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
