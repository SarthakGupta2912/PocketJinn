// What is this file for?
// Checks that the risky cleanup only removes app temporary files and never a
// model or a saved setting.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/tools/delete_temp_files_tool.dart';

void main() {
  test('deletes only debug wav and tmp files', () async {
    final folder = await Directory.systemTemp.createTemp('pj_clean_test');
    addTearDown(() => folder.delete(recursive: true));
    for (final name in [
      'debug_en.wav',
      'cache.tmp',
      'keep.txt',
      'model.litertlm',
    ]) {
      await File('${folder.path}/$name').writeAsString('x');
    }

    final tool = DeleteTempFilesTool(directory: () async => folder);
    final result = await tool.run(const {});

    expect(result['status'], 'success');
    expect(result['deleted'], 2);
    expect(File('${folder.path}/debug_en.wav').existsSync(), isFalse);
    expect(File('${folder.path}/cache.tmp').existsSync(), isFalse);
    expect(File('${folder.path}/keep.txt').existsSync(), isTrue);
    expect(File('${folder.path}/model.litertlm').existsSync(), isTrue);
  });

  test('asks for confirmation before deleting', () {
    final tool = DeleteTempFilesTool(
      directory: () async => Directory.systemTemp,
    );
    expect(tool.isRisky, isTrue);
    expect(tool.confirmationMessage, contains('Delete'));
    expect(tool.name, 'delete_temp_files');
  });

  test('survives a folder that does not exist', () async {
    final folder = Directory('${Directory.systemTemp.path}/pj_missing_12345');
    if (folder.existsSync()) await folder.delete(recursive: true);
    final tool = DeleteTempFilesTool(directory: () async => folder);
    expect((await tool.run(const {}))['status'], 'success');
  });
}
