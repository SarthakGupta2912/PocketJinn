// What is this file for?
// Guards the bundled wake-word model files and the "Hey Jinn" keyword tokens,
// so a renamed file or a wrong token is caught before a device test.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/core/wake_constants.dart';

void main() {
  test('every bundled wake model file has its verified size', () {
    for (var index = 0; index < wakeModelFileNames.length; index++) {
      final file = File('assets/wake_model/${wakeModelFileNames[index]}');
      expect(file.existsSync(), isTrue, reason: wakeModelFileNames[index]);
      expect(
        file.lengthSync(),
        wakeModelFileSizes[index],
        reason: wakeModelFileNames[index],
      );
    }
  });

  test('every "Hey Jinn" token exists in the model vocabulary', () {
    final lines = File('assets/wake_model/tokens.txt').readAsLinesSync();
    final vocabulary = <String>{};
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) continue;
      final space = trimmed.lastIndexOf(' ');
      vocabulary.add(trimmed.substring(0, space));
    }
    expect(wakeKeywordTokens.startsWith('\u2581'), isTrue);
    for (final token in wakeKeywordTokens.split(' ')) {
      expect(vocabulary, contains(token), reason: token);
    }
  });
}
