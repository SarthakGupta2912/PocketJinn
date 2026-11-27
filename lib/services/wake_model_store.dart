// What is this file for?
// Copies the five verified wake-word model files out of the app assets into
// private app storage, where the sherpa-onnx keyword spotter can read them.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/wake_constants.dart';

/// Returns the private app folder that holds the wake-word model files.
Future<Directory> wakeDirectory() async {
  final supportFolder = await getApplicationSupportDirectory();
  final modelFolder = Directory(p.join(supportFolder.path, wakeFolderName));
  await modelFolder.create(recursive: true);
  return modelFolder;
}

/// Copies the bundled model files once and writes the keyword list.
class WakeModelStore {
  /// True when every model file already has the verified size.
  Future<bool> isInstalled() async {
    final folder = await wakeDirectory();
    for (var index = 0; index < wakeModelFileNames.length; index++) {
      final file = File(p.join(folder.path, wakeModelFileNames[index]));
      if (!await file.exists()) return false;
      if (await file.length() != wakeModelFileSizes[index]) return false;
    }
    return true;
  }

  /// Copies missing or damaged files and reports progress from 0 to 100.
  Future<void> prepare({required void Function(int) onProgress}) async {
    final folder = await wakeDirectory();
    for (var index = 0; index < wakeModelFileNames.length; index++) {
      await _copyOne(
        folder: folder,
        name: wakeModelFileNames[index],
        expectedSize: wakeModelFileSizes[index],
      );
      onProgress(((index + 1) * 100) ~/ wakeModelFileNames.length);
    }
    await _writeKeywords(folder);
    onProgress(100);
  }

  /// Copies one asset when it is missing or the wrong size.
  Future<void> _copyOne({
    required Directory folder,
    required String name,
    required int expectedSize,
  }) async {
    final target = File(p.join(folder.path, name));
    if (await target.exists() && await target.length() == expectedSize) return;
    final data = await rootBundle.load('$wakeAssetFolder/$name');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final partial = File('${target.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    if (await target.exists()) await target.delete();
    await partial.rename(target.path);
  }

  /// Writes the BPE keyword line the spotter reads at start-up.
  Future<void> _writeKeywords(Directory folder) async {
    final file = File(p.join(folder.path, wakeKeywordsFileName));
    await file.writeAsString('$wakeKeywordTokens\n', flush: true);
  }
}
