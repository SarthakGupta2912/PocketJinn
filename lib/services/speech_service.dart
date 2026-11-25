// What is this file for?
// Defines the one speech engine interface used by the app and the small
// facade that picks the engine chosen in Settings. All engine code lives in
// this folder so a speech model can be swapped without touching the screens.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../core/constants.dart';
import 'voice_model_store.dart';

part 'speech_sherpa_engine.dart';
part 'speech_sherpa_helpers.dart';
part 'speech_android_engine.dart';

/// One way of turning speech into text, chosen in Settings.
abstract class SpeechEngine {
  /// Name shown in Settings.
  String get displayName;

  /// True when this engine can run on the current device.
  Future<bool> isAvailable();

  /// Downloads its model once and reports progress from 0 to 100.
  Future<void> prepare({required void Function(int) onProgress});

  /// Loads the model. Names are passed as hints to help recognition.
  Future<void> initialize({List<String> hotwords = const []});

  /// Starts listening. The callback fires when the user stops talking.
  /// A partial-text callback may show live words when the engine supports it.
  Future<void> startListening({
    required void Function() onSpeechEnd,
    void Function(String)? onPartialText,
  });

  /// Stops listening and returns the recognised words.
  Future<String> stopAndTranscribe();

  /// Transcribes a saved WAV file. Used by the debug command broadcast.
  Future<String> transcribeFile(String path);

  /// Releases native resources.
  Future<void> dispose();
}

/// Holds the selected engine and passes calls through to it.
class SpeechService {
  SpeechService({required SpeechEngine initialEngine})
    : _engine = initialEngine;

  SpeechEngine _engine;

  /// The engine currently in use.
  SpeechEngine get engine => _engine;

  /// Changes the engine. The caller must dispose the old one.
  void selectEngine(SpeechEngine newEngine) {
    _engine = newEngine;
  }

  /// True when the selected engine can run here.
  Future<bool> isAvailable() => _engine.isAvailable();

  /// Downloads the selected engine's model once.
  Future<void> prepare({required void Function(int) onProgress}) =>
      _engine.prepare(onProgress: onProgress);

  /// Loads the selected engine with optional name hints.
  Future<void> initialize({List<String> hotwords = const []}) =>
      _engine.initialize(hotwords: hotwords);

  /// Starts recording through the selected engine.
  Future<void> startListening({
    required void Function() onSpeechEnd,
    void Function(String)? onPartialText,
  }) => _engine.startListening(
    onSpeechEnd: onSpeechEnd,
    onPartialText: onPartialText,
  );

  /// Stops recording and returns the transcript.
  Future<String> stopAndTranscribe() => _engine.stopAndTranscribe();

  /// Transcribes a saved WAV file for the debug broadcast.
  Future<String> transcribeFile(String path) => _engine.transcribeFile(path);

  /// Releases the selected engine.
  Future<void> dispose() => _engine.dispose();
}
