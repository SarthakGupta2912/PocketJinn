// What is this file for?
// Keeps the small live-word preview model details and the message names used by
// its background worker, so words appear quickly without freezing the screen.

/// Folder under app support storage that holds the live preview model.
const String previewFolderName = 'sherpa-whisper-base';

/// Verified Hugging Face URL for the multilingual Whisper base model.
const String previewBaseUrl =
    'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base/resolve/main';

/// The three preview model files in download order.
const List<String> previewFileNames = [
  'base-encoder.int8.onnx',
  'base-decoder.int8.onnx',
  'base-tokens.txt',
];

/// Sample rate the preview model expects.
const int previewSampleRate = 16000;

/// Longest recent audio decoded at once for a live word update.
const double previewWindowSeconds = 12;

/// How much new audio arrives before the worker decodes again.
const double previewDecodeStepSeconds = 0.5;

/// Audio needed before the very first live words, so they start accurate.
const double previewFirstDecodeSeconds = 2;

/// Seconds of newest audio checked for speech before decoding.
const double previewEnergyWindowSeconds = 1;

/// Longest audio the worker keeps in memory.
const double previewBufferSeconds = 30;

/// Tail padding frames that keep short windows fast to decode.
const int previewTailPaddingFrames = 300;

/// Smallest mean square value treated as real speech instead of silence.
const double previewMinMeanSquare = 0.0001;

/// Smallest mean square of one microphone chunk fed to the live preview.
const double previewChunkMinMeanSquare = 0.005;

/// Audio kept just before speech is confirmed, so the first word is not lost.
const double previewStartSeconds = 1.2;

/// How long the preview keeps listening after speech pauses.
const double previewSpeechHoldSeconds = 1.5;

/// Text patterns Whisper invents from noise and music; they are hidden.
const List<String> previewNoisePhrases = [
  'thank you',
  'thanks for watching',
  'please subscribe',
  'subtitles by',
  'music',
  'applause',
];

/// Message names sent between the app and the preview worker.
const String previewAudioMessage = 'audio';
const String previewStopMessage = 'stop';
const String previewDisposeMessage = 'dispose';
const String previewReadyMessage = 'ready';
const String previewTextMessage = 'text';
const String previewErrorMessage = 'error';
