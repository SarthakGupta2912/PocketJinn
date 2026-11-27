// What is this file for?
// Remembers whether the user turned the wake word on, so it can start again
// the next time Pocket Jinn opens.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/wake_constants.dart';

/// Reads and writes the one-line wake-word setting file.
class WakeSettingsStore {
  /// True when the user left the wake word switched on.
  Future<bool> isEnabled() async {
    final file = await _settingsFile();
    if (!await file.exists()) return false;
    return (await file.readAsString()).trim() == 'true';
  }

  /// Saves the switch position.
  Future<void> setEnabled(bool value) async {
    final file = await _settingsFile();
    await file.writeAsString(value ? 'true' : 'false', flush: true);
  }

  /// Returns the private setting file path.
  Future<File> _settingsFile() async {
    final folder = await getApplicationSupportDirectory();
    return File(p.join(folder.path, wakeSettingsFileName));
  }
}
