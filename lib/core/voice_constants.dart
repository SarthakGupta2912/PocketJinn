// What is this file for?
// Keeps the Stage 3B speech model details and voice messages together, so the
// main constants file stays short and easy to scan.

/// Text on the microphone button while it is recording.
const String voiceStopButtonLabel = 'Stop listening';

/// Folder under app support storage that holds the offline speech model.
const String voiceModelFolderName = 'qwen3_asr_0_6b_int8';

/// Base URL for the Qwen3-ASR int8 model files, verified in the sherpa-onnx docs.
const String voiceModelBaseUrl =
    'https://huggingface.co/csukuangfj2/'
    'sherpa-onnx-qwen3-asr-0.6B-int8-2026-03-25/resolve/main';

/// Silero VAD model URL, verified from the sherpa-onnx asr-models release.
const String voiceVadUrl =
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/'
    'asr-models/silero_vad.onnx';

/// The model files, including the three tokenizer files in their subfolder.
const List<String> voiceModelFileNames = [
  'conv_frontend.onnx',
  'encoder.int8.onnx',
  'decoder.int8.onnx',
  'tokenizer/merges.txt',
  'tokenizer/tokenizer_config.json',
  'tokenizer/vocab.json',
];

/// Name of the voice activity detection model file.
const String voiceVadFileName = 'silero_vad.onnx';

/// Sample rate the speech model expects.
const int voiceSampleRate = 16000;

/// Seconds of audio kept while waiting for the user to stop talking.
const double voiceVadBufferSeconds = 30;

/// Maximum length of one voice command before recording stops itself.
const Duration voiceMaxListeningDuration = Duration(seconds: 30);

/// Engine names shown in Settings.
const String sherpaEngineName = 'Sherpa offline (Qwen3-ASR)';
const String androidEngineName = 'Android offline recognizer';

/// The language choices shown in Settings. The model auto-detects by itself.
const List<String> speechLanguages = [
  'Auto',
  'Hindi (hi)',
  'English (en)',
  'Chinese (zh)',
  'Cantonese (yue)',
  'Arabic (ar)',
  'German (de)',
  'French (fr)',
  'Spanish (es)',
  'Portuguese (pt)',
  'Indonesian (id)',
  'Italian (it)',
  'Korean (ko)',
  'Russian (ru)',
  'Thai (th)',
  'Vietnamese (vi)',
  'Japanese (ja)',
  'Turkish (tr)',
  'Malay (ms)',
  'Dutch (nl)',
  'Swedish (sv)',
  'Danish (da)',
  'Finnish (fi)',
  'Polish (pl)',
  'Czech (cs)',
  'Filipino (fil)',
  'Persian (fa)',
  'Greek (el)',
  'Hungarian (hu)',
  'Macedonian (mk)',
  'Romanian (ro)',
];

/// Shown while the offline voice model downloads or loads.
const String voicePreparingMessage = 'Preparing offline voice...';

/// Shown while the microphone is listening for speech.
const String voiceListeningHint = 'Listening... stop when you are done.';

/// Shown while the recorded speech is being turned into text.
const String voiceFinishingMessage = 'Understanding your speech...';

/// Shown while the model files download, before the percentage.
const String voiceDownloadingMessage = 'Downloading the offline voice';

/// Shown when the user speaks before preparing the offline brain.
const String voiceBrainNotReadyMessage =
    'Prepare the offline brain first, then speak a command.';

/// Shown when the user denies the microphone permission.
const String voicePermissionDeniedMessage =
    'Microphone permission is needed for voice commands.';

/// Shown when the microphone heard no speech.
const String voiceNoSpeechMessage = 'I did not catch that. Please try again.';

/// Shown when the offline voice model cannot start.
const String voiceUnavailableMessage = 'Offline voice is not ready.';
