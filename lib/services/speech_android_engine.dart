// What is this file for?
// The Android speech engine. It uses the platform SpeechRecognizer with
// EXTRA_PREFER_OFFLINE, so recognition is done by Android when it has offline
// language data installed.

part of 'speech_service.dart';

/// Speech recognition through Android's own offline speech recognizer.
class AndroidSpeechEngine implements SpeechEngine {
  AndroidSpeechEngine({this.languageCode = ''});

  /// Short language code such as "hi" or "en"; empty means device default.
  final String languageCode;

  static const MethodChannel _channel = MethodChannel(androidToolsChannelName);
  Completer<String> _resultCompleter = Completer<String>();
  void Function()? _onSpeechEnd;
  bool _handlerReady = false;

  @override
  String get displayName => androidEngineName;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAndroidSpeechAvailable') ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> prepare({required void Function(int) onProgress}) async {
    onProgress(100);
  }

  @override
  Future<void> initialize({List<String> hotwords = const []}) async {
    if (_handlerReady) return;
    _channel.setMethodCallHandler(_handleNativeCall);
    _handlerReady = true;
  }

  @override
  Future<void> startListening({
    required void Function() onSpeechEnd,
    void Function(String)? onPartialText,
  }) async {
    await initialize();
    _resultCompleter = Completer<String>();
    _onSpeechEnd = onSpeechEnd;
    await _channel.invokeMethod<void>('startAndroidSpeech', {
      'languageCode': languageCode,
    });
  }

  @override
  Future<String> stopAndTranscribe() async {
    await _channel.invokeMethod<void>('stopAndroidSpeech');
    if (_resultCompleter.isCompleted) return '';
    try {
      return await _resultCompleter.future.timeout(const Duration(seconds: 10));
    } on Object {
      return '';
    }
  }

  @override
  Future<String> transcribeFile(String path) {
    throw UnsupportedError('Android speech cannot transcribe a saved file.');
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    _handlerReady = false;
  }

  /// Handles results sent back from the Kotlin speech recognizer.
  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onSpeechResult') {
      final arguments = call.arguments as Map<dynamic, dynamic>?;
      final text = arguments?['text'] as String? ?? '';
      if (!_resultCompleter.isCompleted) _resultCompleter.complete(text);
      return;
    }
    if (call.method == 'onSpeechEnd') {
      _onSpeechEnd?.call();
      return;
    }
    if (call.method == 'onSpeechError' && !_resultCompleter.isCompleted) {
      _resultCompleter.complete('');
    }
  }
}
