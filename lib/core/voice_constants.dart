// What is this file for?
// Keeps the Stage 3 speech model details and voice messages together, so the
// main constants file stays short and easy to scan.

/// Text on the microphone button while it is recording.
const String voiceStopButtonLabel = 'Stop listening';

/// Folder under app support storage that holds the offline voice model.
const String voiceModelFolderName = 'sherpa-en-large';

/// Base URL for the four files of the offline English speech model.
const String voiceModelBaseUrl =
    'https://huggingface.co/csukuangfj/'
    'sherpa-onnx-streaming-zipformer-en-2023-06-26/resolve/main';

/// Streaming Zipformer encoder file name.
const String voiceEncoderFileName =
    'encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx';

/// Streaming Zipformer decoder file name.
const String voiceDecoderFileName =
    'decoder-epoch-99-avg-1-chunk-16-left-128.onnx';

/// Streaming Zipformer joiner file name.
const String voiceJoinerFileName =
    'joiner-epoch-99-avg-1-chunk-16-left-128.int8.onnx';

/// Token table file name for the speech model.
const String voiceTokensFileName = 'tokens.txt';

/// Model family expected by the native sherpa-onnx recognizer.
const String voiceModelType = 'zipformer2';

/// Sample rate the streaming speech model expects.
const int voiceSampleRate = 16000;

/// Shown while the offline voice model downloads or loads.
const String voicePreparingMessage = 'Preparing offline voice...';

/// Shown while the microphone is listening and no words are heard yet.
const String voiceListeningHint = 'Listening... tap the microphone to stop.';

/// Shown while the recorded speech is being turned into text.
const String voiceFinishingMessage = 'Finishing the transcript...';

/// Shown while the four voice model files download, before the percentage.
const String voiceDownloadingMessage = 'Downloading the offline voice';

/// Shown when the user speaks before preparing the offline brain.
const String voiceBrainNotReadyMessage =
    'Prepare the offline brain first, then speak a command.';

/// Longest single voice command before the microphone stops itself.
const Duration voiceMaxListeningDuration = Duration(seconds: 15);

/// Shown when the user denies the microphone permission.
const String voicePermissionDeniedMessage =
    'Microphone permission is needed for voice commands.';

/// Shown when the microphone heard no speech.
const String voiceNoSpeechMessage = 'I did not catch that. Please try again.';

/// Shown when the offline voice model cannot start.
const String voiceUnavailableMessage = 'Offline voice is not ready.';
