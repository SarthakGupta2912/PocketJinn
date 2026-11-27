// What is this file for?
// Runs the tiny sherpa-onnx keyword spotter in its own isolate, so checking
// every microphone chunk for "Hey Jinn" never freezes the screen.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../core/wake_constants.dart';

/// Entry point of the wake-word background worker.
void wakeWorkerMain(Map<String, Object> start) {
  final mainPort = start['mainPort'] as SendPort;
  final inbox = ReceivePort();
  mainPort.send(inbox.sendPort);
  sherpa.initBindings();
  final worker = _WakeWorker(mainPort);
  worker.load(folder: start['folder'] as String);
  inbox.listen(worker.handleMessage);
}

/// Holds the keyword spotter and checks each incoming microphone chunk.
class _WakeWorker {
  _WakeWorker(this._mainPort);

  final SendPort _mainPort;
  sherpa.KeywordSpotter? _spotter;
  sherpa.OnlineStream? _stream;

  /// Loads the model and tells the app that detection can start.
  void load({required String folder}) {
    try {
      _spotter = sherpa.KeywordSpotter(
        sherpa.KeywordSpotterConfig(
          model: sherpa.OnlineModelConfig(
            transducer: sherpa.OnlineTransducerModelConfig(
              encoder: p.join(folder, wakeModelFileNames[0]),
              decoder: p.join(folder, wakeModelFileNames[1]),
              joiner: p.join(folder, wakeModelFileNames[2]),
            ),
            tokens: p.join(folder, wakeModelFileNames[3]),
            numThreads: 1,
            provider: 'cpu',
            debug: false,
            modelingUnit: 'bpe',
            bpeVocab: p.join(folder, wakeModelFileNames[4]),
          ),
          keywordsFile: p.join(folder, wakeKeywordsFileName),
          keywordsScore: wakeKeywordScore,
          keywordsThreshold: wakeKeywordThreshold,
        ),
      );
      _stream = _spotter!.createStream();
      _mainPort.send({'type': wakeReadyMessage});
    } on Object catch (error) {
      _mainPort.send({'type': wakeErrorMessage, 'message': '$error'});
    }
  }

  /// Handles one message from the app.
  void handleMessage(Object? message) {
    if (message is! Map) return;
    final type = message['type'];
    if (type == wakeAudioMessage) {
      _accept(message['samples']);
    } else if (type == wakeFeedFileMessage) {
      unawaited(_feedFile(message['path'] as String));
    } else if (type == wakeStopMessage) {
      _reset();
    } else if (type == wakeDisposeMessage) {
      _free();
    }
  }

  /// Feeds one chunk and reports the keyword as soon as it is complete.
  void _accept(Object? audio) {
    final spotter = _spotter;
    final stream = _stream;
    if (audio is! Float32List || spotter == null || stream == null) return;
    try {
      stream.acceptWaveform(samples: audio, sampleRate: wakeSampleRate);
      while (spotter.isReady(stream)) {
        spotter.decode(stream);
        final keyword = spotter.getResult(stream).keyword;
        if (keyword.isEmpty) continue;
        _mainPort.send({'type': wakeDetectedMessage, 'keyword': keyword});
        _recreateStream();
        return;
      }
    } on Object catch (error) {
      _mainPort.send({'type': wakeErrorMessage, 'message': '$error'});
    }
  }

  /// Feeds a pushed WAV in real time for microphone-free wake tests.
  Future<void> _feedFile(String path) async {
    final spotter = _spotter;
    final stream = _stream;
    if (spotter == null || stream == null) return;
    try {
      final wave = sherpa.readWave(path);
      _recreateStream();
      final stream = _stream!;
      const chunkSize = 1280;
      for (var index = 0; index < wave.samples.length; index += chunkSize) {
        final end = index + chunkSize < wave.samples.length
            ? index + chunkSize
            : wave.samples.length;
        stream.acceptWaveform(
          samples: Float32List.sublistView(wave.samples, index, end),
          sampleRate: wave.sampleRate,
        );
        while (spotter.isReady(stream)) {
          spotter.decode(stream);
          final keyword = spotter.getResult(stream).keyword;
          if (keyword.isEmpty) continue;
          _mainPort.send({'type': wakeDetectedMessage, 'keyword': keyword});
          _recreateStream();
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      _mainPort.send({'type': wakeFeedDoneMessage});
    } on Object catch (error) {
      _mainPort.send({'type': wakeErrorMessage, 'message': '$error'});
    }
  }

  /// Clears the decoder state without releasing the model.
  void _reset() {
    _recreateStream();
  }

  /// Starts a fresh stream so no audio state survives a pause or a wake.
  void _recreateStream() {
    final spotter = _spotter;
    if (spotter == null) return;
    try {
      _stream?.free();
      _stream = spotter.createStream();
    } on Object {
      // A stream error must not stop the detector.
    }
  }

  /// Releases the native spotter before the isolate is stopped.
  void _free() {
    _stream?.free();
    _stream = null;
    _spotter?.free();
    _spotter = null;
  }
}
