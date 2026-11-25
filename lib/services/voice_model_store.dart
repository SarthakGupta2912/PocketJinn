// What is this file for?
// Downloads and stores the Qwen3-ASR speech model and the Silero VAD model, so
// speech recognition works without the internet after the first download.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/voice_constants.dart';

/// Returns the private app folder that holds the speech model files.
Future<Directory> voiceModelDirectory() async {
  final supportFolder = await getApplicationSupportDirectory();
  final modelFolder = Directory(
    p.join(supportFolder.path, voiceModelFolderName),
  );
  await modelFolder.create(recursive: true);
  return modelFolder;
}

/// Checks, downloads and keeps the offline speech model files.
class VoiceModelStore {
  /// All files in download order, with the small VAD model last.
  List<String> get fileNames => [...voiceModelFileNames, voiceVadFileName];

  /// True when every model file already exists with some content.
  Future<bool> isInstalled() async {
    final folder = await voiceModelDirectory();
    for (final name in fileNames) {
      final file = File(p.join(folder.path, name));
      if (!await file.exists()) return false;
      if (await file.length() == 0) return false;
    }
    return true;
  }

  /// Downloads each missing file and reports overall progress from 0 to 100.
  Future<void> download({required void Function(int) onProgress}) async {
    final folder = await voiceModelDirectory();
    final client = HttpClient();
    try {
      for (var index = 0; index < fileNames.length; index++) {
        await _downloadOneFile(
          client: client,
          folder: folder,
          fileName: fileNames[index],
          index: index,
          onProgress: onProgress,
        );
      }
    } finally {
      client.close(force: true);
    }
    onProgress(100);
  }

  /// Downloads one file into a temporary copy, then renames it when complete.
  Future<void> _downloadOneFile({
    required HttpClient client,
    required Directory folder,
    required String fileName,
    required int index,
    required void Function(int) onProgress,
  }) async {
    final target = File(p.join(folder.path, fileName));
    final fileCount = fileNames.length;
    if (await target.exists() && await target.length() > 0) {
      onProgress(((index + 1) * 100) ~/ fileCount);
      return;
    }

    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();

    final request = await client.getUrl(Uri.parse(_urlFor(fileName)));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await partial.delete();
      throw HttpException('Download failed with ${response.statusCode}.');
    }

    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    final sink = partial.openWrite();
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        _reportFileProgress(
          index: index,
          fraction: totalBytes > 0 ? receivedBytes / totalBytes : 0,
          onProgress: onProgress,
        );
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await partial.rename(target.path);
  }

  /// Picks the right verified URL for a model file.
  String _urlFor(String fileName) {
    if (fileName == voiceVadFileName) return voiceVadUrl;
    return '$voiceModelBaseUrl/$fileName';
  }

  /// Converts one file's progress into overall progress across all files.
  void _reportFileProgress({
    required int index,
    required double fraction,
    required void Function(int) onProgress,
  }) {
    final overall = (index + fraction) * 100 / fileNames.length;
    onProgress(overall.round());
  }
}
