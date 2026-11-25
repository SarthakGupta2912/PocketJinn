// What is this file for?
// The Sherpa offline speech engine: downloads Qwen3-ASR, captures the mic,
// uses Silero VAD to find the end of speech, then transcribes on the device.

part of 'speech_service.dart';

/// Offline multilingual recognition with the Qwen3-ASR model.
class SherpaSpeechEngine implements SpeechEngine {
  final VoiceModelStore _modelStore = VoiceModelStore();
  sherpa.OfflineRecognizer? _recognizer;
  sherpa.VoiceActivityDetector? _voiceDetector;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSubscription;
  final List<double> _recordedSamples = <double>[];
  bool _areBindingsLoaded = false;
  bool _speechEnded = false;
  void Function()? _onSpeechEnd;

  @override
  String get displayName => sherpaEngineName;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> prepare({required void Function(int) onProgress}) =>
      _modelStore.download(onProgress: onProgress);

  @override
  Future<void> initialize({List<String> hotwords = const []}) async {
    if (_recognizer != null) return;
    final loadStarted = DateTime.now();
    if (!_areBindingsLoaded) {
      await sherpa.initBindingsAsync();
      _areBindingsLoaded = true;
    }
    final folder = await voiceModelDirectory();
    _recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          qwen3Asr: sherpa.OfflineQwen3AsrModelConfig(
            convFrontend: p.join(folder.path, 'conv_frontend.onnx'),
            encoder: p.join(folder.path, 'encoder.int8.onnx'),
            decoder: p.join(folder.path, 'decoder.int8.onnx'),
            tokenizer: p.join(folder.path, 'tokenizer'),
            hotwords: hotwords.join(','),
            maxNewTokens: 128,
          ),
          tokens: '',
          numThreads: 4,
          debug: false,
        ),
      ),
    );
    _voiceDetector = _createVoiceDetector(folder.path);
    if (kDebugMode) {
      debugPrint(
        'Qwen3 load ms: ${DateTime.now().difference(loadStarted).inMilliseconds}',
      );
    }
  }

  @override
  Future<void> startListening({required void Function() onSpeechEnd}) async {
    await initialize();
    _recordedSamples.clear();
    _speechEnded = false;
    _onSpeechEnd = onSpeechEnd;
    _voiceDetector?.reset();
    _recorder ??= AudioRecorder();
    final audio = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: voiceSampleRate,
        numChannels: 1,
      ),
    );
    _audioSubscription = audio.listen(_handleAudioChunk);
  }

  @override
  Future<String> stopAndTranscribe() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    try {
      await _recorder?.stop();
    } on Object {
      // The recorder may already be stopped; nothing else to do here.
    }
    return _transcribeSamples(_recordedSamples);
  }

  @override
  Future<String> transcribeFile(String path) async {
    final started = DateTime.now();
    await initialize();
    final wave = sherpa.readWave(path);
    final text = await _transcribeSamples(wave.samples);
    if (kDebugMode) {
      debugPrint(
        'Qwen3 decode ms: ${DateTime.now().difference(started).inMilliseconds}',
      );
    }
    return text;
  }

  @override
  Future<void> dispose() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder?.dispose();
    _recorder = null;
    _voiceDetector?.free();
    _voiceDetector = null;
    _recognizer?.free();
    _recognizer = null;
  }

  /// Builds the voice activity detector that finds the end of a sentence.
  sherpa.VoiceActivityDetector _createVoiceDetector(String folder) {
    return sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: p.join(folder, voiceVadFileName),
          threshold: 0.2,
          minSilenceDuration: 0.5,
          minSpeechDuration: 0.2,
          maxSpeechDuration: 10,
        ),
        debug: false,
      ),
      bufferSizeInSeconds: voiceVadBufferSeconds,
    );
  }

  /// Feeds one audio chunk to VAD and keeps the spoken parts.
  void _handleAudioChunk(Uint8List bytes) {
    final samples = Float32List(bytes.length ~/ 2);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    // Keep every chunk. VAD only decides when to stop; it must not decide
    // which audio is sent to the recognizer, or quiet speech is lost.
    _recordedSamples.addAll(samples);
    _voiceDetector?.acceptWaveform(samples);
    while (_voiceDetector != null && !_voiceDetector!.isEmpty()) {
      if (_voiceDetector!.isDetected()) {
        _voiceDetector!.pop();
        _notifySpeechEndOnce();
      } else {
        _voiceDetector!.pop();
      }
    }
  }

  /// Calls the controller only once per recording.
  void _notifySpeechEndOnce() {
    if (_speechEnded) return;
    _speechEnded = true;
    _onSpeechEnd?.call();
  }

  /// Runs the offline recognizer on a list of audio samples.
  Future<String> _transcribeSamples(Iterable<double> samples) async {
    final recognizer = _recognizer;
    if (recognizer == null || samples.isEmpty) return '';
    final wave = Float32List.fromList(samples.toList());
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: wave, sampleRate: voiceSampleRate);
      recognizer.decode(stream);
      return recognizer.getResult(stream).text.trim();
    } finally {
      stream.free();
    }
  }
}
