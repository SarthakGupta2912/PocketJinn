// What is this file for?
// Runs the offline "Hey Jinn" detector, keeps the Android microphone
// foreground service alive, and hands a detected wake to the voice controller.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:record/record.dart';

import '../core/wake_constants.dart';
import '../services/wake_model_store.dart';
import '../services/wake_settings_store.dart';
import '../services/wake_worker.dart';

/// The states shown by the wake-word card.
enum WakeStatus { off, preparing, listening, paused, error }

/// Starts, pauses and stops the background keyword spotter.
class WakeWordController extends ChangeNotifier with WidgetsBindingObserver {
  WakeWordController({required this.onWake});

  /// Starts a normal voice command and reports whether listening really began.
  final Future<bool> Function() onWake;

  static const MethodChannel _channel = MethodChannel(wakeChannelName);

  final WakeModelStore _modelStore = WakeModelStore();
  final WakeSettingsStore _settingsStore = WakeSettingsStore();
  final ReceivePort _inbox = ReceivePort();
  Isolate? _isolate;
  SendPort? _workerPort;
  Completer<void>? _readyCompleter;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _resumeTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastWakeAt;
  DateTime? _listeningSince;
  WakeStatus status = WakeStatus.off;
  String message = wakeOffMessage;
  bool _isInitialized = false;
  bool _isEnabled = false;
  bool _isPaused = false;
  bool _isRunning = false;
  bool _isPreparing = false;
  bool _isAppVisible = true;
  bool _isDisposed = false;
  bool _isInboxReady = false;
  bool _hasWorkerFailed = false;
  int _micToken = 0;
  int _chunkCount = 0;

  /// True when the user left the wake word switched on.
  bool get isEnabled => _isEnabled;

  /// True while the model is being prepared, so the switch is disabled.
  bool get isBusy => status == WakeStatus.preparing;

  /// A short honest line such as "Listening: yes, since 10:32".
  String get statusLine {
    if (!_isEnabled || status == WakeStatus.off || status == WakeStatus.error) {
      return wakeStatusStopped;
    }
    if (status == WakeStatus.preparing) return wakeStatusStarting;
    if (status == WakeStatus.paused) return wakeStatusPaused;
    final since = _listeningSince;
    if (since == null) return wakeStatusListening;
    final hour = since.hour.toString().padLeft(2, '0');
    final minute = since.minute.toString().padLeft(2, '0');
    return '$wakeStatusListening, $wakeStatusSince $hour:$minute';
  }

  /// Reads the saved switch, registers for app life, and starts if needed.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _listenToWorker();
    final pending = await _takePendingWake();
    final saved = await _settingsStore.isEnabled();
    if (saved) {
      _isEnabled = true;
      if (pending) {
        _isPaused = true;
        final started = await onWake();
        if (!started) {
          _isPaused = false;
          await _startRunning(save: false);
        }
      } else {
        await _startRunning(save: false);
      }
    } else if (pending) {
      await onWake();
    }
  }

  /// Turns the detector on.
  Future<void> start() async {
    if (_isDisposed) return;
    if (_isEnabled && (_isRunning || _isPreparing)) return;
    _isEnabled = true;
    await _startRunning();
  }

  /// Turns the detector off and releases the microphone and service.
  Future<void> stop() async {
    if (_isDisposed) return;
    _isEnabled = false;
    _isPaused = false;
    await _settingsStore.setEnabled(false);
    await _setNativeEnabled(false);
    await _stopRunning();
    status = WakeStatus.off;
    message = wakeOffMessage;
    _notify();
  }

  /// Called by the switch in the wake-word card.
  Future<void> toggle(bool value) async {
    if (value) {
      await start();
    } else {
      await stop();
    }
  }

  /// Stops the microphone while a normal voice command uses it.
  Future<void> pause() async {
    if (!_isEnabled || _isPaused) return;
    _isPaused = true;
    _resumeTimer?.cancel();
    _resumeTimer = null;
    await _stopMicrophone();
    _workerPort?.send({'type': wakeStopMessage});
    if (!_isDisposed) {
      status = WakeStatus.paused;
      message = wakePausedMessage;
      _notify();
    }
  }

  /// Starts the microphone again after the normal voice command ends.
  Future<void> resume() async {
    if (!_isEnabled || !_isPaused || _isDisposed) return;
    _isPaused = false;
    _resumeTimer?.cancel();
    _resumeTimer = null;
    if (!_isRunning) {
      await _startRunning(save: false);
      return;
    }
    try {
      if (_workerPort == null || _hasWorkerFailed) await _startWorker();
      await _startMicrophone();
      status = WakeStatus.listening;
      message = wakeListeningMessage;
      _listeningSince ??= DateTime.now();
      _startHeartbeat();
    } on Object catch (error) {
      status = WakeStatus.error;
      message = wakeServiceMessage;
      if (kDebugMode) debugPrint('Wake resume failed: $error');
    }
    _notify();
  }

  /// Releases everything when the home screen is removed.
  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _resumeTimer?.cancel();
    _stopHeartbeat();
    unawaited(_stopRunning());
    if (_isInboxReady) {
      _inbox.close();
      _isInboxReady = false;
    }
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) unawaited(recorder.dispose());
    super.dispose();
  }

  /// Copies the model, starts the service, the worker and the microphone.
  Future<void> _startRunning({bool save = true}) async {
    if (_isRunning || _isPreparing || _isDisposed) return;
    _isPreparing = true;
    status = WakeStatus.preparing;
    message = wakePreparingMessage;
    _notify();
    try {
      await _modelStore.prepare(onProgress: (percent) {});
      if (!_isEnabled) return;
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) {
        throw const WakeWordFailure(wakePermissionMessage);
      }
      if (!_isEnabled) return;
      final notifications =
          await _channel.invokeMethod<bool>('requestNotificationPermission') ??
          true;
      if (!notifications) {
        throw const WakeWordFailure(wakeNotificationMessage);
      }
      if (!_isEnabled) return;
      await _channel.invokeMethod<void>('startService');
      if (!_isEnabled) {
        await _stopRunning();
        return;
      }
      await _startWorker();
      _isRunning = true;
      await _setNativeEnabled(true);
      if (!_isEnabled) {
        await _stopRunning();
        return;
      }
      if (_isPaused) {
        status = WakeStatus.paused;
        message = wakePausedMessage;
        return;
      }
      await _startMicrophone();
      if (!_isEnabled) {
        await _stopRunning();
        return;
      }
      status = WakeStatus.listening;
      message = wakeListeningMessage;
      _listeningSince = DateTime.now();
      _startHeartbeat();
      if (save) await _settingsStore.setEnabled(true);
    } on WakeWordFailure catch (error) {
      _isEnabled = false;
      await _setNativeEnabled(false);
      await _stopRunning();
      status = WakeStatus.error;
      message = error.message;
      if (save) await _settingsStore.setEnabled(false);
    } on Object catch (error) {
      _isEnabled = false;
      await _setNativeEnabled(false);
      await _stopRunning();
      status = WakeStatus.error;
      message = wakeModelMessage;
      if (kDebugMode) debugPrint('Wake start failed: $error');
      if (save) await _settingsStore.setEnabled(false);
    } finally {
      _isPreparing = false;
      _notify();
    }
  }

  /// Stops the microphone, the worker and the Android foreground service.
  Future<void> _stopRunning() async {
    _resumeTimer?.cancel();
    _resumeTimer = null;
    _stopHeartbeat();
    _listeningSince = null;
    await _stopMicrophone();
    _workerPort?.send({'type': wakeStopMessage});
    await _stopWorker();
    try {
      await _channel.invokeMethod<void>('stopService');
    } on Object {
      // The service may already be stopped.
    }
    _isRunning = false;
    _hasWorkerFailed = false;
  }

  /// Starts the background worker and waits for its model to load.
  Future<void> _startWorker() async {
    if (_workerPort != null && !_hasWorkerFailed) return;
    await _stopWorker();
    final folder = await wakeDirectory();
    final ready = Completer<void>();
    _readyCompleter = ready;
    _hasWorkerFailed = false;
    final started = DateTime.now();
    _isolate = await Isolate.spawn(wakeWorkerMain, <String, Object>{
      'mainPort': _inbox.sendPort,
      'folder': folder.path,
    });
    await ready.future.timeout(wakeWorkerLoadTimeout);
    if (_hasWorkerFailed) {
      throw StateError('The wake word worker failed to load.');
    }
    if (kDebugMode) {
      final millis = DateTime.now().difference(started).inMilliseconds;
      debugPrint('Wake load ms: $millis');
    }
  }

  /// Sends the worker a dispose message, then stops its isolate.
  Future<void> _stopWorker() async {
    final port = _workerPort;
    _workerPort = null;
    _readyCompleter = null;
    if (port != null) {
      port.send({'type': wakeDisposeMessage});
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  /// Opens the microphone and sends each chunk to the worker.
  Future<void> _startMicrophone() async {
    if (_isPaused || _isDisposed) return;
    await _stopMicrophone();
    final token = ++_micToken;
    final recorder = _recorder ??= AudioRecorder();
    final audio = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: wakeSampleRate,
        numChannels: 1,
      ),
    );
    if (token != _micToken || _isPaused || _isDisposed) {
      try {
        await recorder.stop();
      } on Object {
        // The recorder may already be stopped.
      }
      return;
    }
    _audioSubscription = audio.listen(_handleAudioChunk);
  }

  /// Stops the microphone without touching the loaded worker.
  Future<void> _stopMicrophone() async {
    _micToken++;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    try {
      await _recorder?.stop();
    } on Object {
      // The recorder may already be stopped.
    }
  }

  /// Converts one PCM chunk to floats and sends it to the worker.
  void _handleAudioChunk(Uint8List bytes) {
    if (_isPaused || !_isRunning || _workerPort == null) return;
    final count = bytes.length ~/ 2;
    if (count == 0) return;
    final samples = Float32List(count);
    final data = ByteData.sublistView(bytes);
    for (var index = 0; index < count; index++) {
      samples[index] = data.getInt16(index * 2, Endian.little) / 32768.0;
    }
    _workerPort?.send({'type': wakeAudioMessage, 'samples': samples});
    if (kDebugMode) {
      _chunkCount++;
      if (_chunkCount % 100 == 0) {
        var sum = 0.0;
        for (final sample in samples) {
          sum += sample * sample;
        }
        debugPrint(
          'Wake audio chunk $_chunkCount meanSquare ${(sum / count).toStringAsFixed(6)}',
        );
      }
    }
  }

  /// Feeds a pushed WAV to the worker for microphone-free wake tests.
  Future<void> feedDebugWakeFile(String path) async {
    debugPrint('Wake debug feed start: $path');
    final port = _workerPort;
    if (!_isEnabled || !_isRunning || port == null) return;
    await _stopMicrophone();
    port.send({'type': wakeFeedFileMessage, 'path': path});
  }

  /// Listens once for messages from the worker isolate.
  void _listenToWorker() {
    if (_isInboxReady) return;
    _inbox.listen(_handleWorkerMessage);
    _isInboxReady = true;
  }

  /// Handles the worker port, a detection, and load or decode errors.
  void _handleWorkerMessage(Object? message) {
    if (message is SendPort) {
      _workerPort = message;
      return;
    }
    if (message is! Map) return;
    final type = message['type'];
    if (type == wakeDetectedMessage) {
      if (kDebugMode) debugPrint('Wake detected: ${message['keyword']}');
      unawaited(_handleWake());
    } else if (type == wakeReadyMessage) {
      _completeReady();
    } else if (type == wakeFeedDoneMessage) {
      if (!_isPaused && !_isDisposed && _isRunning) {
        unawaited(_startMicrophone());
      }
    } else if (type == wakeErrorMessage) {
      _hasWorkerFailed = true;
      if (kDebugMode) debugPrint('Wake worker error: ${message['message']}');
      if (_isPreparing) {
        _completeReady();
      } else {
        unawaited(_handleWorkerFailure());
      }
    }
  }

  /// Starts a command when the app is visible, or asks Android to show it.
  Future<void> _handleWake() async {
    if (!_isEnabled || _isPaused || _isDisposed) return;
    final now = DateTime.now();
    final last = _lastWakeAt;
    if (last != null && now.difference(last) < wakeRepeatDelay) return;
    _lastWakeAt = now;
    await pause();
    if (_isAppVisible) {
      final started = await onWake();
      if (!started) await resume();
      return;
    }
    message = wakeBackgroundMessage;
    _notify();
    try {
      final result = await _channel.invokeMethod<String>('notifyWake');
      if (result == 'foreground') {
        final started = await onWake();
        if (!started) await resume();
        return;
      }
    } on Object {
      await resume();
      return;
    }
    _resumeTimer?.cancel();
    _resumeTimer = Timer(wakeOpenTimeout, () {
      unawaited(resume());
    });
  }

  /// Handles a wake notification that opened the app, or resumes after a wait.
  Future<void> _handleAppResumed() async {
    if (await _takePendingWake()) {
      _resumeTimer?.cancel();
      _resumeTimer = null;
      if (_isEnabled && !_isPaused) await pause();
      final started = await onWake();
      if (!started && _isEnabled) await resume();
      return;
    }
    if (_resumeTimer != null) {
      _resumeTimer?.cancel();
      _resumeTimer = null;
      await resume();
    }
  }

  /// Asks Android whether a wake notification opened the app.
  Future<bool> _takePendingWake() async {
    try {
      return await _channel.invokeMethod<bool>('takePendingWake') ?? false;
    } on Object {
      return false;
    }
  }

  /// Marks the worker as loaded or failed.
  void _completeReady() {
    final ready = _readyCompleter;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  /// Turns the detector off after the worker fails while running.
  Future<void> _handleWorkerFailure() async {
    _isEnabled = false;
    await _setNativeEnabled(false);
    await _stopRunning();
    status = WakeStatus.error;
    message = wakeModelMessage;
    await _settingsStore.setEnabled(false);
    _notify();
  }

  /// Saves the switch in the Android service so the watchdog can read it.
  Future<void> _setNativeEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setWakeEnabled', {'enabled': enabled});
    } on Object {
      // The native side may not be ready during a unit test.
    }
  }

  /// Tells the Android service every few seconds that the detector is alive.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    unawaited(_sendHeartbeat());
    _heartbeatTimer = Timer.periodic(
      wakeHeartbeatInterval,
      (_) => unawaited(_sendHeartbeat()),
    );
  }

  /// Sends one heartbeat, ignoring a missing native channel.
  Future<void> _sendHeartbeat() async {
    try {
      await _channel.invokeMethod<void>('heartbeat');
    } on Object {
      // The service may already be stopped.
    }
  }

  /// Stops the heartbeat timer.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Remembers whether the app is on screen and checks for a pending wake.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppVisible = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      unawaited(_handleAppResumed());
    }
  }

  /// Avoids notifying a screen that has already been removed.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}

/// A start-up problem with a message that is safe to show the user.
class WakeWordFailure implements Exception {
  const WakeWordFailure(this.message);

  /// Short explanation shown on the wake-word card.
  final String message;
}
