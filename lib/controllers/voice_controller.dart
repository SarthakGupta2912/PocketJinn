// What is this file for?
// Holds the simple voice state for the home screen: preparing, listening,
// finishing, and sending the final transcript to the assistant.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../services/speech_service.dart';
import '../services/voice_model_store.dart';

/// The voice states shown by the microphone section.
enum VoiceStatus { idle, preparing, listening, finishing }

/// Downloads, runs and stops the offline speech recognizer.
class VoiceController extends ChangeNotifier {
  VoiceController({required this.onTranscript, required this.canRunCommands});

  /// Sends a finished transcript to the assistant controller.
  final Future<void> Function(String command) onTranscript;

  /// Tells whether the offline brain is ready to understand a command.
  final bool Function() canRunCommands;

  final VoiceModelStore _modelStore = VoiceModelStore();
  final SpeechService _speechService = SpeechService();
  VoiceStatus status = VoiceStatus.idle;
  String message = homeMicrophoneHint;
  String transcript = '';
  int downloadPercent = 0;
  bool isDownloading = false;
  Timer? _maximumListenTimer;
  bool _isDisposed = false;

  /// True while the microphone is recording speech.
  bool get isListening => status == VoiceStatus.listening;

  /// True while the user must wait before tapping again.
  bool get isBusy =>
      status == VoiceStatus.preparing || status == VoiceStatus.finishing;

  /// Starts or stops listening when the big microphone is tapped.
  Future<void> toggleMicrophone() async {
    if (status == VoiceStatus.listening) {
      await _finishListening();
      return;
    }
    if (isBusy) return;
    await _startListening();
  }

  /// Stops any running voice work when the home screen is removed.
  @override
  void dispose() {
    _isDisposed = true;
    _maximumListenTimer?.cancel();
    unawaited(_speechService.dispose());
    super.dispose();
  }

  /// Checks permission, downloads the model if needed, then records.
  Future<void> _startListening() async {
    transcript = '';
    status = VoiceStatus.preparing;
    message = voicePreparingMessage;
    downloadPercent = 0;
    isDownloading = false;
    _notify();
    try {
      if (!await _speechService.requestMicrophonePermission()) {
        status = VoiceStatus.idle;
        message = voicePermissionDeniedMessage;
        _notify();
        return;
      }
      await _downloadModelWhenMissing();
      await _speechService.startListening(
        onPartialText: _showPartialText,
        onRecordingError: _handleSpeechEnd,
      );
      status = VoiceStatus.listening;
      message = voiceListeningHint;
      _maximumListenTimer = Timer(voiceMaxListeningDuration, _handleSpeechEnd);
    } on Object {
      status = VoiceStatus.idle;
      message = voiceUnavailableMessage;
    }
    _notify();
  }

  /// Downloads the four model files once and keeps the progress message fresh.
  Future<void> _downloadModelWhenMissing() async {
    if (await _modelStore.isInstalled()) return;
    isDownloading = true;
    _notify();
    await _modelStore.download(onProgress: _showDownloadProgress);
    isDownloading = false;
    message = voicePreparingMessage;
    _notify();
  }

  /// Stops the microphone and passes a non-empty transcript to the assistant.
  Future<void> _finishListening() async {
    if (status != VoiceStatus.listening) return;
    status = VoiceStatus.finishing;
    _maximumListenTimer?.cancel();
    message = voiceFinishingMessage;
    _notify();

    String heardText;
    try {
      heardText = await _speechService.stopListening();
    } on Object {
      heardText = '';
    }
    transcript = _removeWakeName(heardText);
    status = VoiceStatus.idle;

    if (transcript.isEmpty) {
      message = voiceNoSpeechMessage;
      _notify();
      return;
    }
    if (!canRunCommands()) {
      message = voiceBrainNotReadyMessage;
      _notify();
      return;
    }
    message = homeMicrophoneHint;
    _notify();
    await onTranscript(transcript);
  }

  /// Stops once when the recognizer hears the end of a spoken sentence.
  void _handleSpeechEnd() {
    if (status != VoiceStatus.listening) return;
    unawaited(_finishListening());
  }

  /// Shows live words without rebuilding for the same text twice.
  void _showPartialText(String text) {
    if (text == transcript) return;
    transcript = text;
    _notify();
  }

  /// Updates the download message only when the whole percentage changes.
  void _showDownloadProgress(int percent) {
    if (percent == downloadPercent) return;
    downloadPercent = percent;
    message = '$voiceDownloadingMessage $percent%';
    _notify();
  }

  /// Drops a leading "Hey Jinn" or "Jinn" so the model sees the command alone.
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

  /// Avoids notifying a home screen that has already been removed.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  /// Wake names that may be spoken before the real command.
  static const List<String> _wakeNames = ['hey jinn', 'hi jinn', 'jinn'];
}
