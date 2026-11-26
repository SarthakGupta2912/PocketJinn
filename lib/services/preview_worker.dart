// What is this file for?
// Runs the small Whisper model in its own background isolate, so live words
// arrive quickly while listening and the main screen never freezes.

import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../core/preview_constants.dart';

/// Entry point of the live-word background worker.
void previewWorkerMain(Map<String, Object> start) {
  final mainPort = start['mainPort'] as SendPort;
  final inbox = ReceivePort();
  mainPort.send(inbox.sendPort);
  sherpa.initBindings();
  if (kDebugMode) {
    debugPrint('Preview language: "${start['language']}"');
  }
  final worker = _PreviewWorker(mainPort);
  worker.load(
    folder: start['folder'] as String,
    language: start['language'] as String,
  );
  inbox.listen(worker.handleMessage);
}

/// Holds the preview recognizer and decodes the newest audio window.
class _PreviewWorker {
  _PreviewWorker(this._mainPort);

  final SendPort _mainPort;
  final List<double> _samples = <double>[];
  sherpa.OfflineRecognizer? _recognizer;
  int _lastDecodedLength = 0;

  /// Loads the model and tells the app that live words can start.
  void load({required String folder, required String language}) {
    try {
      _recognizer = sherpa.OfflineRecognizer(
        sherpa.OfflineRecognizerConfig(
          model: sherpa.OfflineModelConfig(
            whisper: sherpa.OfflineWhisperModelConfig(
              encoder: p.join(folder, previewFileNames[0]),
              decoder: p.join(folder, previewFileNames[1]),
              language: language,
              task: 'transcribe',
              tailPaddings: previewTailPaddingFrames,
            ),
            tokens: p.join(folder, previewFileNames[2]),
            numThreads: 2,
            debug: false,
          ),
        ),
      );
      _mainPort.send({'type': previewReadyMessage});
    } on Object catch (error) {
      _mainPort.send({'type': previewErrorMessage, 'message': '$error'});
    }
  }

  /// Handles one message from the app.
  void handleMessage(Object? message) {
    if (message is! Map) return;
    final type = message['type'];
    if (type == previewAudioMessage) {
      _addAudio(message['samples']);
    } else if (type == previewStopMessage) {
      _samples.clear();
      _lastDecodedLength = 0;
    } else if (type == previewDisposeMessage) {
      _recognizer?.free();
      _recognizer = null;
    }
  }

  /// Keeps the newest audio and decodes once enough new sound has arrived.
  void _addAudio(Object? audio) {
    if (audio is! Float32List || _recognizer == null) return;
    _samples.addAll(audio);
    _trimOldSamples();
    final isFirst = _lastDecodedLength == 0;
    final stepSeconds = isFirst
        ? previewFirstDecodeSeconds
        : previewDecodeStepSeconds;
    final needed = (stepSeconds * previewSampleRate).round();
    if (_samples.length - _lastDecodedLength < needed) return;
    _lastDecodedLength = _samples.length;
    final text = _decodeNewestWindow();
    if (text.isNotEmpty) {
      _mainPort.send({'type': previewTextMessage, 'text': text});
    }
  }

  /// Drops the oldest audio so memory stays small.
  void _trimOldSamples() {
    final maxSamples = (previewBufferSeconds * previewSampleRate).round();
    final extra = _samples.length - maxSamples;
    if (extra <= 0) return;
    _samples.removeRange(0, extra);
    final remaining = _lastDecodedLength - extra;
    _lastDecodedLength = remaining < 0 ? 0 : remaining;
  }

  /// Decodes all audio heard so far into preview words.
  String _decodeNewestWindow() {
    final recognizer = _recognizer;
    if (recognizer == null || _samples.isEmpty) return '';
    final windowSize = (previewWindowSeconds * previewSampleRate).round();
    final start = _samples.length > windowSize
        ? _samples.length - windowSize
        : 0;
    final window = Float32List.fromList(_samples.sublist(start));
    if (_recentLevel(window) <= previewMinMeanSquare) return '';
    final started = DateTime.now();
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: window, sampleRate: previewSampleRate);
      recognizer.decode(stream);
      final text = _cleanPreviewText(recognizer.getResult(stream).text);
      if (kDebugMode) {
        final millis = DateTime.now().difference(started).inMilliseconds;
        debugPrint('Preview decode ms: $millis');
      }
      return text;
    } on Object {
      return '';
    } finally {
      stream.free();
    }
  }

  /// Removes music notes and noise words that are not real speech.
  String _cleanPreviewText(String raw) {
    final withoutNotes = raw.replaceAll(
      RegExp(r'\[[^\]]*\]|\([^)]*\)|\*[^*]*\*'),
      ' ',
    );
    final cleaned = withoutNotes.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    final wordsOnly = _wordsOnly(cleaned);
    if (previewNoisePhrases.contains(wordsOnly)) return '';
    return _dropTrailingRepeat(_collapseRepeats(cleaned));
  }

  /// Whisper often repeats the start of a sentence at the end. Keep only the
  /// finished sentence when the tail is just the beginning of it again.
  String _dropTrailingRepeat(String text) {
    for (final boundary in const ['. ', '? ', '! ']) {
      final index = text.lastIndexOf(boundary);
      if (index < 0) continue;
      final head = text.substring(0, index + 1).trim();
      final tail = text.substring(index + boundary.length).trim();
      if (tail.isEmpty) return head;
      final normalizedHead = _wordsOnly(head);
      final normalizedTail = _wordsOnly(tail);
      if (normalizedTail.isNotEmpty &&
          normalizedHead.startsWith(normalizedTail)) {
        return head;
      }
    }
    return text;
  }

  /// Lowercase letters only, used when comparing repeated words.
  String _wordsOnly(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Turns "what is the time? what is the time?" into one phrase.
  String _collapseRepeats(String text) {
    final words = text.split(' ');
    for (var size = words.length ~/ 2; size >= 2; size--) {
      if (words.length < size * 2) continue;
      var repeats = true;
      for (var index = 0; index < size; index++) {
        if (words[index].toLowerCase() != words[size + index].toLowerCase()) {
          repeats = false;
          break;
        }
      }
      if (repeats) return words.take(size).join(' ');
    }
    return text;
  }

  /// Mean square of the newest audio, used to spot speech.
  double _recentLevel(Float32List samples) {
    final recentCount = (previewEnergyWindowSeconds * previewSampleRate)
        .round();
    final start = samples.length > recentCount
        ? samples.length - recentCount
        : 0;
    var total = 0.0;
    var count = 0;
    for (var index = start; index < samples.length; index++) {
      total += samples[index] * samples[index];
      count++;
    }
    return count > 0 ? total / count : 0;
  }
}
