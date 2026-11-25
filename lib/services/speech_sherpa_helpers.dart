// What is this file for?
// Small helpers for the Sherpa engine: VAD setup, live partial decoding and
// the final offline transcription pass.

part of 'speech_service.dart';

/// Part of SherpaSpeechEngine for VAD and decoding.
extension SherpaSpeechEngineHelpers on SherpaSpeechEngine {
  /// Builds the voice activity detector that finds the end of a sentence.
  sherpa.VoiceActivityDetector createVoiceDetector(String folder) {
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

  /// Decodes the latest speech window with Qwen3 for a slower live result.
  Future<void> decodePartial() async {
    if (_recognizer == null || _recordedSamples.isEmpty) return;
    final windowSize = voicePartialWindow.inSeconds * voiceSampleRate;
    final start = _recordedSamples.length > windowSize
        ? _recordedSamples.length - windowSize
        : 0;
    try {
      final text = await transcribeSamples(_recordedSamples.skip(start));
      if (text.isNotEmpty) {
        if (kDebugMode) debugPrint('Qwen3 partial: $text');
        _onPartialText?.call(text);
      }
    } on Object {
      // A partial result is optional; the final pass after stop still runs.
    }
  }

  /// Runs the offline recognizer on a list of audio samples.
  Future<String> transcribeSamples(Iterable<double> samples) async {
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
