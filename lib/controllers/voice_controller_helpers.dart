// What is this file for?
// Small helpers for voice messages, wake words and safe screen updates.

part of 'voice_controller.dart';

/// Part of VoiceController for small voice helpers.
extension VoiceControllerHelpers on VoiceController {
  /// True when the top name guesses are weak or very close together.
  bool isNameMatchUncertain(List<ContactCandidate> guesses) =>
      _matcher.isUncertain(guesses);

  /// True when a named engine can run on this device.
  Future<bool> isEngineAvailable(String engineName) {
    final engine = _engines[engineName];
    if (engine == null) return Future.value(false);
    return engine.isAvailable();
  }

  /// Stops once when VAD hears the end of speech.
  void _handleSpeechEnd() {
    if (status != VoiceStatus.listening) return;
    unawaited(_finishListening());
  }

  /// Updates the download message only when the whole percentage changes.
  void _showDownloadProgress(int percent) {
    if (percent == downloadPercent) return;
    downloadPercent = percent;
    message = '$voiceDownloadingMessage $percent%';
    _notify();
  }

  /// Drops a leading "Hey Jinn" or "Jinn" from the spoken words.
  String _removeWakeName(String text) {
    var cleaned = text.trim();
    final lowerText = cleaned.toLowerCase();
    for (final wakeName in _wakeNames) {
      if (!lowerText.startsWith(wakeName)) continue;
      cleaned = cleaned.substring(wakeName.length).trim();
      cleaned = cleaned.replaceFirst(RegExp(r'^[,.\s]+'), '');
      break;
    }
    return cleaned.trim();
  }

  /// Returns the short code from a language label such as "Hindi (hi)".
  String _languageCode(String language) {
    final match = RegExp(r'\(([a-z]+)\)').firstMatch(language);
    return match?.group(1) ?? '';
  }
}

/// Wake names that may be spoken before the real command.
const List<String> _wakeNames = ['hey jinn', 'hi jinn', 'jinn'];
