// What is this file for?
// Downloads and stores the four small files of the offline English speech
// model, so speech recognition never needs the internet after one download.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

/// The four model files in download order.
const List<String> voiceModelFileNames = [
  voiceEncoderFileName,
  voiceDecoderFileName,
  voiceJoinerFileName,
  voiceTokensFileName,
];

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
  /// True when all four files already exist with some content.
  Future<bool> isInstalled() async {
    final folder = await voiceModelDirectory();
    for (final fileName in voiceModelFileNames) {
      final file = File(p.join(folder.path, fileName));
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
      for (var index = 0; index < voiceModelFileNames.length; index++) {
        await _downloadOneFile(
          client: client,
          folder: folder,
          fileName: voiceModelFileNames[index],
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
    final fileCount = voiceModelFileNames.length;
    if (await target.exists() && await target.length() > 0) {
      onProgress(((index + 1) * 100) ~/ fileCount);
      return;
    }

    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();

    final request = await client.getUrl(
      Uri.parse('$voiceModelBaseUrl/$fileName'),
    );
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

  /// Converts one file's progress into overall progress across all files.
  void _reportFileProgress({
    required int index,
    required double fraction,
    required void Function(int) onProgress,
  }) {
    final overall = (index + fraction) * 100 / voiceModelFileNames.length;
    onProgress(overall.round());
  }
}
