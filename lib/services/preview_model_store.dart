// What is this file for?
// Downloads the small English streaming model used only for live word preview
// while Qwen3-ASR makes the final multilingual transcript after stopping.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/preview_constants.dart';

/// Checks and downloads the four live-preview model files.
class PreviewModelStore {
  /// True when all four live-preview files already exist.
  Future<bool> isInstalled() async {
    final folder = await previewDirectory();
    for (final name in previewFileNames) {
      final file = File(p.join(folder.path, name));
      if (!await file.exists()) return false;
      if (await file.length() == 0) return false;
    }
    return true;
  }

  /// Downloads missing files and reports overall progress from 0 to 100.
  Future<void> download({required void Function(int) onProgress}) async {
    final folder = await previewDirectory();
    final client = HttpClient();
    try {
      for (var index = 0; index < previewFileNames.length; index++) {
        await _downloadOne(
          client: client,
          folder: folder,
          name: previewFileNames[index],
          index: index,
          onProgress: onProgress,
        );
      }
    } finally {
      client.close(force: true);
    }
    onProgress(100);
  }

  /// Downloads one file to a temporary copy before renaming it.
  Future<void> _downloadOne({
    required HttpClient client,
    required Directory folder,
    required String name,
    required int index,
    required void Function(int) onProgress,
  }) async {
    final target = File(p.join(folder.path, name));
    if (await target.exists() && await target.length() > 0) {
      onProgress(((index + 1) * 100) ~/ previewFileNames.length);
      return;
    }
    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();
    final response = await (await client.getUrl(
      Uri.parse('$previewBaseUrl/$name'),
    )).close();
    if (response.statusCode != HttpStatus.ok) {
      await partial.delete();
      throw HttpException('Download failed with ${response.statusCode}.');
    }
    final total = response.contentLength;
    var received = 0;
    final sink = partial.openWrite();
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        final fraction = total > 0 ? received / total : 0.0;
        final percent = ((index + fraction) * 100 / previewFileNames.length)
            .round();
        onProgress(percent);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await partial.rename(target.path);
  }
}

/// Returns the private folder for the preview model.
Future<Directory> previewDirectory() async {
  final support = await getApplicationSupportDirectory();
  final folder = Directory(p.join(support.path, previewFolderName));
  await folder.create(recursive: true);
  return folder;
}
