// What is this file for?
// Gives live English words while the user speaks. Qwen3-ASR still makes the
// final transcript after the microphone stops.

part of 'speech_service.dart';

/// Small streaming recognizer used only for the live word preview.
class StreamingPreviewEngine {
  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;

  /// Downloads the four preview model files once.
  Future<void> prepare({required void Function(int) onProgress}) =>
      PreviewModelStore().download(onProgress: onProgress);

  /// Creates the native recognizer when first needed.
  Future<void> initialize() async {
    if (_recognizer != null) return;
    final folder = await previewDirectory();
    _recognizer = sherpa.OnlineRecognizer(
      sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: p.join(folder.path, previewFileNames[0]),
            decoder: p.join(folder.path, previewFileNames[1]),
            joiner: p.join(folder.path, previewFileNames[2]),
          ),
          tokens: p.join(folder.path, previewFileNames[3]),
          modelType: previewModelType,
          debug: false,
        ),
      ),
    );
  }

  /// Starts one live recognition stream.
  Future<void> start() async {
    await initialize();
    _stream = _recognizer?.createStream();
  }

  /// Feeds one audio chunk and reports the current words.
  void accept(Float32List samples, void Function(String) onPartial) {
    final recognizer = _recognizer;
    final stream = _stream;
    if (recognizer == null || stream == null) return;
    stream.acceptWaveform(samples: samples, sampleRate: voiceSampleRate);
    while (recognizer.isReady(stream)) {
      recognizer.decode(stream);
    }
    final text = recognizer.getResult(stream).text.trim();
    if (text.isNotEmpty) onPartial(text);
  }

  /// Closes the live stream after recording stops.
  void finish() {
    _stream?.free();
    _stream = null;
  }

  /// Releases the native recognizer.
  void dispose() {
    _recognizer?.free();
    _recognizer = null;
  }
}
