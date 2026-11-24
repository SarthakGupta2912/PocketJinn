// What is this file for?
// Captures microphone audio and turns it into text with the offline
// sherpa-onnx speech model, so Pocket Jinn can understand spoken commands.

import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../core/constants.dart';
import 'voice_model_store.dart';

/// Runs the streaming English recognizer on live microphone audio.
class SpeechService {
  sherpa.OnlineRecognizer? _recognizer;
  AudioRecorder? _recorder;
  sherpa.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _audioSubscription;
  bool _areBindingsLoaded = false;

  /// Loads the native speech library once, without needing model files.
  Future<void> _loadBindings() async {
    if (_areBindingsLoaded) return;
    await sherpa.initBindingsAsync();
    _areBindingsLoaded = true;
  }

  /// Creates the recognizer only after the four model files are downloaded.
  Future<void> _ensureRecognizer() async {
    if (_recognizer != null) return;
    await _loadBindings();
    final folder = await voiceModelDirectory();
    _recognizer = sherpa.OnlineRecognizer(
      sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: p.join(folder.path, voiceEncoderFileName),
            decoder: p.join(folder.path, voiceDecoderFileName),
            joiner: p.join(folder.path, voiceJoinerFileName),
          ),
          tokens: p.join(folder.path, voiceTokensFileName),
          modelType: voiceModelType,
          debug: false,
        ),
      ),
    );
  }

  /// Asks Android for the microphone permission, showing the dialog if needed.
  Future<bool> requestMicrophonePermission() async {
    _recorder ??= AudioRecorder();
    return _recorder!.hasPermission();
  }

  /// Starts listening and reports live words plus unexpected recording ends.
  Future<void> startListening({
    required void Function(String) onPartialText,
    required void Function() onRecordingError,
  }) async {
    await _ensureRecognizer();
    final recognizer = _recognizer;
    if (recognizer == null) throw StateError('Speech is not ready.');
    _recorder ??= AudioRecorder();

    final stream = recognizer.createStream();
    _stream = stream;
    try {
      final audioStream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: voiceSampleRate,
          numChannels: 1,
        ),
      );
      _audioSubscription = audioStream.listen(
        (bytes) => _handleAudioChunk(stream, bytes, onPartialText),
        onError: (Object error) => onRecordingError(),
      );
    } on Object {
      _stream = null;
      stream.free();
      rethrow;
    }
  }

  /// Stops the microphone and returns the final transcript.
  Future<String> stopListening() async {
    final stream = _stream;
    _stream = null;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    try {
      await _recorder?.stop();
    } on Object {
      // Android may already have stopped the recorder; there is nothing to do.
    }
    final recognizer = _recognizer;
    if (recognizer == null || stream == null) return '';
    try {
      stream.inputFinished();
      _decodeAvailable(recognizer, stream);
      return recognizer.getResult(stream).text.trim();
    } finally {
      recognizer.reset(stream);
      stream.free();
    }
  }

  /// Releases the recorder, stream and recognizer when the screen closes.
  Future<void> dispose() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder?.dispose();
    _recorder = null;
    _stream?.free();
    _stream = null;
    _recognizer?.free();
    _recognizer = null;
  }

  /// Feeds one microphone chunk to the recognizer and decodes ready audio.
  void _handleAudioChunk(
    sherpa.OnlineStream stream,
    Uint8List bytes,
    void Function(String) onPartialText,
  ) {
    final recognizer = _recognizer;
    if (recognizer == null || _stream != stream) return;
    stream.acceptWaveform(
      samples: _toFloatSamples(bytes),
      sampleRate: voiceSampleRate,
    );
    _decodeAvailable(recognizer, stream);
    final text = recognizer.getResult(stream).text.trim();
    if (text.isNotEmpty) onPartialText(text);
  }

  /// Decodes every chunk of audio that the recognizer has buffered.
  void _decodeAvailable(
    sherpa.OnlineRecognizer recognizer,
    sherpa.OnlineStream stream,
  ) {
    while (recognizer.isReady(stream)) {
      recognizer.decode(stream);
    }
  }

  /// Converts 16-bit little-endian microphone bytes into model samples.
  Float32List _toFloatSamples(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    final samples = Float32List(sampleCount);
    final data = ByteData.sublistView(bytes);
    for (var index = 0; index < sampleCount; index++) {
      samples[index] = data.getInt16(index * 2, Endian.little) / 32768.0;
    }
    return samples;
  }
}
