// What is this file for?
// The debug file test and the two-step "Teach a name" flow for contacts.

part of 'voice_controller.dart';

/// Part of VoiceController for test audio and taught names.
extension VoiceControllerTeaching on VoiceController {
  /// Matches a debug name and shows the top guesses for device testing.
  Future<void> checkName(String name) async {
    final guesses = await _matcher.match(name);
    final text = guesses
        .map(
          (guess) => '${guess.contact.name}:${guess.score.toStringAsFixed(2)}',
        )
        .join(', ');
    message = 'Name check "$name" -> $text';
    _notify();
  }

  /// Transcribes a pushed WAV file through the selected real speech engine.
  Future<void> runDebugAudioFile(String path) async {
    if (isBusy) return;
    status = VoiceStatus.finishing;
    message = 'Transcribing test audio...';
    _notify();
    try {
      final text = await _speech.transcribeFile(path);
      transcript = text;
      candidates = await _matcher.match(text);
      message = 'Test transcript: $text';
      status = VoiceStatus.idle;
      _notify();
      if (canRunCommands() && text.isNotEmpty) {
        await onTranscript(text, candidates);
      }
    } on Object catch (error) {
      status = VoiceStatus.idle;
      message = 'Test audio failed: $error';
      _notify();
    }
  }

  /// Starts the two-step "Teach a name" flow for one contact.
  Future<void> startTeaching(Contact contact) async {
    teachingContact = contact;
    teachingSample = 0;
    _taughtNames.clear();
    message = 'Say the name for ${contact.name}';
    _notify();
    await _startListening();
  }

  /// Saves the first or second taught name and starts the next recording.
  Future<void> _saveTeachingSample(String text) async {
    final contact = teachingContact!;
    if (text.isNotEmpty) _taughtNames.add(text);
    teachingSample++;
    if (teachingSample < 2) {
      message = 'Say the name for ${contact.name} again';
      _notify();
      await _startListening();
      return;
    }
    for (final name in _taughtNames) {
      await VoiceController._aliasStore.addAlias(contact.name, name);
    }
    teachingContact = null;
    message = 'Saved names for ${contact.name}';
    _notify();
  }
}
