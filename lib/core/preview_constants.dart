// What is this file for?
// Holds the verified details of the English streaming model used only for the
// live word preview while speaking.

/// Folder under app support storage for the preview model.
const String previewFolderName = 'sherpa-en-large';

/// Verified Hugging Face URL for the English streaming Zipformer model.
const String previewBaseUrl =
    'https://huggingface.co/csukuangfj/'
    'sherpa-onnx-streaming-zipformer-en-2023-06-26/resolve/main';

/// The four preview model files in download order.
const List<String> previewFileNames = [
  'encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx',
  'decoder-epoch-99-avg-1-chunk-16-left-128.onnx',
  'joiner-epoch-99-avg-1-chunk-16-left-128.int8.onnx',
  'tokens.txt',
];

/// Model family expected by the native recognizer.
const String previewModelType = 'zipformer2';
