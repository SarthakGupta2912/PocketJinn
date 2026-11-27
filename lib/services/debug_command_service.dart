// What is this file for?
// Listens for the DEBUG_COMMAND broadcast from adb and feeds either a saved
// audio file or a plain text command into the real app flow for testing.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';

/// Connects the debug broadcast to the app for device testing.
class DebugCommandService {
  DebugCommandService({
    required this.onAudioFile,
    required this.onText,
    required this.onName,
    this.onWakeFile,
  });

  /// Called with a WAV path pushed to the device.
  final Future<void> Function(String path) onAudioFile;

  /// Called with a typed command from the broadcast.
  final Future<void> Function(String text) onText;

  /// Called with a WAV path pushed to the device for the wake detector.
  final Future<void> Function(String path)? onWakeFile;

  /// Called with a name to check in the contact matcher.
  final Future<void> Function(String name) onName;

  static const MethodChannel _channel = MethodChannel(debugCallbackChannelName);

  /// Starts listening for debug events.
  void start() {
    _channel.setMethodCallHandler(_handleCall);
  }

  /// Stops listening when the screen is removed.
  void stop() {
    _channel.setMethodCallHandler(null);
  }

  /// Sends each event to the right app callback.
  Future<void> _handleCall(MethodCall call) async {
    debugPrint('Debug call: ${call.method}');
    final arguments = call.arguments as Map<dynamic, dynamic>?;
    if (call.method == 'onDebugAudioFile') {
      final path = arguments?['path'] as String?;
      if (path != null && path.isNotEmpty) await onAudioFile(path);
      return;
    }
    if (call.method == 'onDebugWakeFile') {
      final path = arguments?['path'] as String?;
      if (path != null && path.isNotEmpty) await onWakeFile?.call(path);
      return;
    }
    if (call.method == 'onDebugCommand') {
      final text = arguments?['text'] as String?;
      if (text != null && text.isNotEmpty) await onText(text);
      return;
    }
    if (call.method == 'onDebugName') {
      final name = arguments?['name'] as String?;
      if (name != null && name.isNotEmpty) await onName(name);
    }
  }
}
