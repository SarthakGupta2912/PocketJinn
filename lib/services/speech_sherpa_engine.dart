// What is this file for?
// The Sherpa offline speech engine: downloads Qwen3-ASR, captures the mic,
// uses Silero VAD to find the end of speech, then transcribes on the device.

part of 'speech_service.dart';

/// Offline multilingual recognition with the Qwen3-ASR model.
class SherpaSpeechEngine implements SpeechEngine {
  final VoiceModelStore _modelStore = VoiceModelStore();
  final PreviewModelStore _previewStore = PreviewModelStore();
  final WhisperPreviewEngine _preview = WhisperPreviewEngine();
  sherpa.OfflineRecognizer? _recognizer;
  sherpa.VoiceActivityDetector? _voiceDetector;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSubscription;
  final List<double> _recordedSamples = <double>[];
  final List<Float32List> _pendingPreview = <Float32List>[];
  int _pendingPreviewSamples = 0;
  bool _previewStarted = false;
  DateTime? _lastSpeechAt;
  bool _areBindingsLoaded = false;
  bool _speechEnded = false;
  bool _speechAccepted = false;
  String _languageCode = '';
  void Function()? _onSpeechEnd;

  @override
  String get displayName => sherpaEngineName;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> prepare({required void Function(int) onProgress}) async {
    try {
      await _previewStore.download(
        onProgress: (percent) => onProgress((percent * 0.1).round()),
      );
    } on Object {
      // Live words are optional; the final transcript still works.
    }
    await _modelStore.download(
      onProgress: (percent) => onProgress(10 + (percent * 0.9).round()),
    );
  }

  @override
  Future<bool> isInstalled() async =>
      await _modelStore.isInstalled() && await _previewStore.isInstalled();

  @override
  Future<void> initialize({
    List<String> hotwords = const [],
    String languageCode = '',
  }) async {
    _languageCode = languageCode;
    final previewReady = _preview.warmUp(languageCode: languageCode);
    if (_recognizer == null) {
      await _loadQwen3(hotwords);
    }
    await previewReady;
  }

  /// Loads the multilingual Qwen3 model once.
  Future<void> _loadQwen3(List<String> hotwords) async {
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
    _voiceDetector = createVoiceDetector(folder.path);
    if (kDebugMode) {
      debugPrint(
        'Qwen3 load ms: ${DateTime.now().difference(loadStarted).inMilliseconds}',
      );
    }
  }

  @override
  Future<void> startListening({
    required void Function() onSpeechEnd,
    void Function(String)? onPartialText,
  }) async {
    await initialize(languageCode: _languageCode);
    _recordedSamples.clear();
    _pendingPreview.clear();
    _pendingPreviewSamples = 0;
    _previewStarted = false;
    _lastSpeechAt = null;
    _speechEnded = false;
    _speechAccepted = false;
    _onSpeechEnd = onSpeechEnd;
    _voiceDetector?.reset();
    if (onPartialText != null) {
      await _preview.start(onPartialText: onPartialText);
    }
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
    _preview.stop();
    try {
      await _recorder?.stop();
    } on Object {
      // The recorder may already be stopped; nothing else to do here.
    }
    if (!_hasRealSpeech()) return '';
    return transcribeSamples(_recordedSamples);
  }

  @override
  Future<String> transcribeFile(String path) async {
    final started = DateTime.now();
    await initialize(languageCode: _languageCode);
    final wave = sherpa.readWave(path);
    final text = await transcribeSamples(wave.samples);
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
    await _preview.dispose();
    await _recorder?.dispose();
    _recorder = null;
    _voiceDetector?.free();
    _voiceDetector = null;
    _recognizer?.free();
    _recognizer = null;
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
    _feedPreviewWhenSpeaking(samples);
    while (_voiceDetector != null && !_voiceDetector!.isEmpty()) {
      final segment = _voiceDetector!.front();
      _voiceDetector!.pop();
      final level = _meanSquare(segment.samples);
      if (kDebugMode) {
        final seconds = segment.samples.length / voiceSampleRate;
        debugPrint(
          'VAD segment ${seconds.toStringAsFixed(2)} s level '
          '${level.toStringAsFixed(4)}',
        );
      }
      if (level < voiceMinSpeechLevel) continue;
      _speechAccepted = true;
      _notifySpeechEndOnce();
    }
  }

  /// True when VAD heard real speech, or a manual stop captured a loud sound.
  bool _hasRealSpeech() {
    final peak = _peakOf(_recordedSamples);
    if (kDebugMode) {
      debugPrint('Recording peak: ${peak.toStringAsFixed(3)}');
    }
    return _speechAccepted || peak >= voiceMinSpeechPeak;
  }

  /// Highest absolute sample value in a recording.
  double _peakOf(Iterable<double> samples) {
    var peak = 0.0;
    for (final sample in samples) {
      final value = sample.abs();
      if (value > peak) peak = value;
    }
    return peak;
  }

  /// Mean square volume of a chunk, used to tell speech from quiet noise.
  double _meanSquare(Iterable<double> samples) {
    var total = 0.0;
    var count = 0;
    for (final sample in samples) {
      total += sample * sample;
      count++;
    }
    return count > 0 ? total / count : 0;
  }

  /// Calls the controller only once per recording.
  void _notifySpeechEndOnce() {
    if (_speechEnded) return;
    _speechEnded = true;
    _onSpeechEnd?.call();
  }

  /// Sends audio to the live preview only around real speech, and keeps a
  /// short pre-roll so the first word is not lost when speech is confirmed.
  void _feedPreviewWhenSpeaking(Float32List samples) {
    final detector = _voiceDetector;
    if (detector == null) return;
    final now = DateTime.now();
    final chunkLevel = _meanSquare(samples);
    final speaking =
        detector.isDetected() && chunkLevel >= previewChunkMinMeanSquare;
    if (speaking) _lastSpeechAt = now;
    final lastSpeechAt = _lastSpeechAt;
    final isRecent =
        lastSpeechAt != null &&
        now.difference(lastSpeechAt).inMilliseconds <=
            (previewSpeechHoldSeconds * 1000).round();
    if (!isRecent) _previewStarted = false;
    if (_previewStarted) {
      _preview.accept(samples);
      return;
    }
    _pendingPreview.add(samples);
    _pendingPreviewSamples += samples.length;
    final maxPreroll = (previewStartSeconds * previewSampleRate).round();
    while (_pendingPreviewSamples > maxPreroll) {
      _pendingPreviewSamples -= _pendingPreview.removeAt(0).length;
    }
    if (!speaking) return;
    for (final chunk in _pendingPreview) {
      _preview.accept(chunk);
    }
    _pendingPreview.clear();
    _pendingPreviewSamples = 0;
    _previewStarted = true;
  }
}
