// What is this file for?
// Owns every Flutter Edge AI call so the model package can be replaced in one
// place later without spreading model details through the app.

import 'dart:convert';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import '../models/tool_call.dart';
import '../tools/base_tool.dart';

/// A completed local-model answer, including any tool calls it made.
class LlmAnswer {
  const LlmAnswer({required this.text, this.toolCall, this.toolResult});

  /// Final natural-language answer, when the model supplied one.
  final String text;

  /// The normalized app tool call, when one was requested.
  final ToolCall? toolCall;

  /// The result sent back to the model after execution.
  final Map<String, dynamic>? toolResult;
}

/// Downloads, loads and queries the pinned FunctionGemma model.
class LlmService {
  LlmService({required this.tools});

  /// Registers the LiteRT-LM engine before the Flutter app starts.
  static Future<void> initialize() async {
    await FlutterEdgeAi.initialize(inferenceEngines: const [LiteRtLmEngine()]);
  }

  /// Tool implementations used to create model declarations.
  final List<BaseTool> tools;
  InferenceModel? _model;
  InferenceChat? _chat;

  /// Model folder name used by the catalog installer on this device.
  static const String _installedModelName = 'functiongemma-270m-it';

  /// Opens the pinned model only when it is already installed.
  Future<bool> openInstalledModel() async {
    if (!await _isModelInstalled()) return false;
    await _openChat(_pinnedVariant());
    return true;
  }

  /// Installs the catalog model and opens its function-calling chat.
  Future<void> prepare({required void Function(int) onProgress}) async {
    final variant = _pinnedVariant();
    if (!await _isModelInstalled()) {
      await FlutterEdgeAi.installModelFromCatalog(
        variant,
      ).withProgress(onProgress).install();
    }
    await _openChat(variant);
  }

  /// Sends one command and lets the caller execute each requested tool.
  Future<LlmAnswer> ask({
    required String command,
    required Future<Map<String, dynamic>> Function(ToolCall) onToolCall,
    String extraContext = '',
  }) async {
    final chat = _chat;
    if (chat == null) throw StateError('The local model is not ready.');
    final fullCommand = extraContext.isEmpty
        ? command
        : '$command\n$extraContext';
    await chat.addQueryChunk(Message.text(text: fullCommand, isUser: true));
    final text = StringBuffer();
    ToolCall? call;
    Map<String, dynamic>? result;
    await for (final response in chat.generateChatResponseWithTools(
      onToolCall: (functionCall) async {
        call = ToolCall(
          tool: functionCall.name,
          arguments: Map<String, dynamic>.from(functionCall.args),
        );
        result = await onToolCall(call!);
        return result!;
      },
      maxToolTurns: 2,
    )) {
      if (response case TextResponse(:final token)) text.write(token);
    }
    return LlmAnswer(
      text: _cleanText(text.toString()),
      toolCall: call,
      toolResult: result,
    );
  }

  /// Closes the native model and chat when the controller is disposed.
  Future<void> close() async {
    await _chat?.close();
    await _model?.close();
    _chat = null;
    _model = null;
  }

  /// Matches the installed file id with or without its `.litertlm` suffix.
  Future<bool> _isModelInstalled() async {
    final installed = await FlutterEdgeAi.listInstalledModels();
    return installed.any((name) {
      final lowerName = name.toLowerCase();
      return lowerName == _installedModelName ||
          lowerName == '$_installedModelName.litertlm';
    });
  }

  /// The single catalog variant this stage supports.
  InferenceVariant _pinnedVariant() =>
      LiteRtLmModels.functiongemma270mIt.generic;

  /// Opens a model and creates its package-managed FunctionGemma tool chat.
  Future<void> _openChat(InferenceVariant variant) async {
    _model = await FlutterEdgeAi.getActiveModel(
      defaults: variant.runtimeDefaults,
    );
    _chat = await _model!.openChat(
      modelType: ModelType.functionGemma,
      supportsFunctionCalls: true,
      tools: [for (final tool in tools) _toPackageTool(tool)],
      topK: 1,
      temperature: 0,
      maxOutputTokens: 128,
      systemInstruction:
          'Use the available tool when the command asks for an action. '
          'Give a short answer after the tool result.',
    );
  }

  /// Converts the app-neutral declaration to the package declaration.
  Tool _toPackageTool(BaseTool tool) => Tool(
    name: tool.name,
    description: tool.description,
    parameters: tool.parameters,
  );

  /// Removes accidental empty output without interpreting unsafe text.
  String _cleanText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final parsed = ToolCall.tryParse(trimmed);
    if (parsed != null) return jsonEncode(parsed.toJson());
    return trimmed;
  }
}
