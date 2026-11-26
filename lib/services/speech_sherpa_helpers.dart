// What is this file for?
// Small helpers for the Sherpa engine: voice activity detection and the final
// offline transcription pass.

part of 'speech_service.dart';

/// Part of SherpaSpeechEngine for VAD and decoding.
extension SherpaSpeechEngineHelpers on SherpaSpeechEngine {
  /// Builds the voice activity detector that finds the end of a sentence.
  sherpa.VoiceActivityDetector createVoiceDetector(String folder) {
    return sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: p.join(folder, voiceVadFileName),
          threshold: 0.5,
          minSilenceDuration: 0.5,
          minSpeechDuration: 0.35,
          maxSpeechDuration: 30,
        ),
        debug: false,
      ),
      bufferSizeInSeconds: voiceVadBufferSeconds,
    );
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
