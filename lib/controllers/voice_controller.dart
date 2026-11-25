// What is this file for?
// Holds the simple voice state for the home screen and Settings: preparing,
// listening, finishing, engine choice, language hint and name teaching.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/contact_data.dart';
import '../core/constants.dart';
import '../models/contact.dart';
import '../models/contact_candidate.dart';
import '../services/name_alias_store.dart';
import '../services/name_matcher.dart';
import '../services/preview_model_store.dart';
import '../services/speech_service.dart';
import '../services/voice_model_store.dart';

part 'voice_controller_teaching.dart';
part 'voice_controller_helpers.dart';

/// The voice states shown by the microphone section.
enum VoiceStatus { idle, preparing, listening, finishing }

/// Downloads, runs and stops the selected offline speech engine.
class VoiceController extends ChangeNotifier {
  VoiceController({required this.onTranscript, required this.canRunCommands})
    : _matcher = NameMatcher(contacts: knownContacts, aliasStore: _aliasStore) {
    _engines = {
      sherpaEngineName: SherpaSpeechEngine(),
      androidEngineName: AndroidSpeechEngine(languageCode: ''),
    };
    _speech = SpeechService(initialEngine: _engines[sherpaEngineName]!);
  }

  static final NameAliasStore _aliasStore = NameAliasStore();
  final VoiceModelStore _modelStore = VoiceModelStore();
  final PreviewModelStore _previewStore = PreviewModelStore();

  /// Sends a finished transcript and its contact guesses to the assistant.
  final Future<void> Function(String command, List<ContactCandidate> candidates)
  onTranscript;

  /// Tells whether the offline brain is ready to understand a command.
  final bool Function() canRunCommands;

  late final Map<String, SpeechEngine> _engines;
  late final SpeechService _speech;
  late final NameMatcher _matcher;
  VoiceStatus status = VoiceStatus.idle;
  String message = homeMicrophoneHint;
  String transcript = '';
  int downloadPercent = 0;
  bool isDownloading = false;
  String selectedEngine = sherpaEngineName;
  String selectedLanguage = 'Auto';
  List<ContactCandidate> candidates = <ContactCandidate>[];
  Contact? teachingContact;
  int teachingSample = 0;
  final List<String> _taughtNames = <String>[];
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

  /// Changes the engine and forgets the loaded model.
  Future<void> selectEngine(String engineName) async {
    if (!_engines.containsKey(engineName) || isBusy) return;
    selectedEngine = engineName;
    _speech.selectEngine(_engines[engineName]!);
    message = 'Selected $engineName';
    _notify();
  }

  /// Changes the language hint shown in Settings and passed to Android.
  Future<void> selectLanguage(String language) async {
    selectedLanguage = language;
    final code = _languageCode(language);
    final engine = _engines[androidEngineName];
    if (engine is AndroidSpeechEngine) {
      _engines[androidEngineName] = AndroidSpeechEngine(languageCode: code);
      if (selectedEngine == androidEngineName) {
        _speech.selectEngine(_engines[androidEngineName]!);
      }
    }
    message = 'Language: $language. The model still auto-detects.';
    _notify();
  }

  /// Releases engines when the home screen is removed.
  @override
  void dispose() {
    _isDisposed = true;
    _maximumListenTimer?.cancel();
    for (final engine in _engines.values) {
      unawaited(engine.dispose());
    }
    super.dispose();
  }

  /// Prepares the selected engine, then starts recording.
  Future<void> _startListening() async {
    status = VoiceStatus.preparing;
    transcript = '';
    downloadPercent = 0;
    isDownloading = false;
    _notify();
    try {
      await _prepareEngine();
      await _speech.startListening(
        onSpeechEnd: _handleSpeechEnd,
        onPartialText: _showPartialText,
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

  /// Downloads once, then loads the engine with name hints.
  Future<void> _prepareEngine() async {
    if (!await _speech.isAvailable()) {
      throw StateError('This speech engine is not available.');
    }
    message = voicePreparingMessage;
    _notify();
    if (selectedEngine == sherpaEngineName &&
        (!await _modelStore.isInstalled() ||
            !await _previewStore.isInstalled())) {
      isDownloading = true;
      await _speech.prepare(onProgress: _showDownloadProgress);
      isDownloading = false;
    }
    await _speech.initialize(hotwords: await _matcher.allNames());
  }

  /// Finishes recording, matches names and hands the text to the assistant.
  Future<void> _finishListening() async {
    if (status != VoiceStatus.listening) return;
    status = VoiceStatus.finishing;
    _maximumListenTimer?.cancel();
    message = voiceFinishingMessage;
    _notify();

    String heardText;
    try {
      heardText = await _speech.stopAndTranscribe();
    } on Object {
      heardText = '';
    }
    final transcript = _removeWakeName(heardText);
    this.transcript = transcript;
    status = VoiceStatus.idle;
    if (teachingContact != null) {
      await _saveTeachingSample(transcript);
      return;
    }
    if (transcript.isEmpty) {
      message = voiceNoSpeechMessage;
      _notify();
      return;
    }
    candidates = await _matcher.match(transcript);
    message = candidates.isEmpty
        ? homeMicrophoneHint
        : 'Heard: ${candidates.first.matchedName}';
    _notify();
    if (!canRunCommands()) {
      message = voiceBrainNotReadyMessage;
      _notify();
      return;
    }
    await onTranscript(transcript, candidates);
  }

  /// Avoids notifying a home screen that has already been removed.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}
