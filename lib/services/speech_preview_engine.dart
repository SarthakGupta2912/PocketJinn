// What is this file for?
// Runs the small Whisper model in a background isolate for fast live words
// while the user speaks. The accurate Qwen3 result still runs after stopping.

part of 'speech_service.dart';

/// Starts and feeds the background worker that shows live words.
class WhisperPreviewEngine {
  final PreviewModelStore _modelStore = PreviewModelStore();
  final ReceivePort _inbox = ReceivePort();
  Isolate? _isolate;
  SendPort? _workerPort;
  Completer<void>? _readyCompleter;
  String _languageCode = '';
  void Function(String)? _onPartialText;
  bool _isListening = false;
  bool _hasFailed = false;
  bool _isInboxReady = false;

  /// Downloads the preview model once.
  Future<void> prepare({required void Function(int) onProgress}) =>
      _modelStore.download(onProgress: onProgress);

  /// True when all preview files are already on the device.
  Future<bool> isInstalled() => _modelStore.isInstalled();

  /// Starts live words for one recording without blocking the screen.
  Future<void> start({required void Function(String) onPartialText}) async {
    _onPartialText = onPartialText;
    _isListening = !_hasFailed && _workerPort != null;
  }

  /// Loads the worker ahead of time so the first words appear quickly.
  Future<void> warmUp({String languageCode = ''}) async {
    try {
      await _startWorkerFor(_whisperLanguage(languageCode));
    } on Object {
      _hasFailed = true;
    }
  }

  /// Sends one microphone chunk to the background worker.
  void accept(Float32List samples) {
    if (!_isListening) return;
    _workerPort?.send({'type': previewAudioMessage, 'samples': samples});
  }

  /// Stops live words for this recording.
  void stop() {
    _isListening = false;
    _onPartialText = null;
    _workerPort?.send({'type': previewStopMessage});
  }

  /// Frees the background worker and its model.
  Future<void> dispose() async {
    stop();
    await _shutdownWorker();
    if (_isInboxReady) {
      _inbox.close();
      _isInboxReady = false;
    }
  }

  /// Starts the worker when it is not already running for this language.
  Future<void> _startWorkerFor(String languageCode) async {
    if (_hasFailed) return;
    if (_workerPort != null && _languageCode == languageCode) return;
    await _shutdownWorker();
    _languageCode = languageCode;
    final folder = await previewDirectory();
    final ready = Completer<void>();
    _readyCompleter = ready;
    _listenToWorker();
    final started = DateTime.now();
    _isolate = await Isolate.spawn(previewWorkerMain, <String, Object>{
      'mainPort': _inbox.sendPort,
      'folder': folder.path,
      'language': languageCode,
    });
    await ready.future.timeout(const Duration(seconds: 20));
    if (kDebugMode && !_hasFailed) {
      final millis = DateTime.now().difference(started).inMilliseconds;
      debugPrint('Preview load ms: $millis');
    }
  }

  /// Listens once for messages from the worker.
  void _listenToWorker() {
    if (_isInboxReady) return;
    _inbox.listen(_handleWorkerMessage);
    _isInboxReady = true;
  }

  /// Handles the worker port, live words and load errors.
  void _handleWorkerMessage(Object? message) {
    if (message is SendPort) {
      _workerPort = message;
      return;
    }
    if (message is! Map) return;
    final type = message['type'];
    if (type == previewTextMessage) {
      final text = message['text'] as String? ?? '';
      if (_isListening && text.isNotEmpty) {
        if (kDebugMode) debugPrint('Preview text: $text');
        _onPartialText?.call(text);
      }
    } else if (type == previewReadyMessage) {
      _completeReady();
    } else if (type == previewErrorMessage) {
      _hasFailed = true;
      if (kDebugMode) {
        debugPrint('Preview worker error: ${message['message']}');
      }
      _completeReady();
    }
  }

  /// Marks the worker as loaded or failed.
  void _completeReady() {
    final ready = _readyCompleter;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  /// Stops the worker isolate so the model memory is released.
  Future<void> _shutdownWorker() async {
    _workerPort = null;
    _readyCompleter = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  /// Uses a clear language only when Whisper supports it; else auto-detects.
  String _whisperLanguage(String code) {
    if (code == 'hi' || code == 'en') return code;
    return '';
  }
}
