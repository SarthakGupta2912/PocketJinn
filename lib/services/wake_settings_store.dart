// What is this file for?
// Remembers whether the user turned the wake word on, so it can start again
// the next time Pocket Jinn opens.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/wake_constants.dart';

/// Name of the small file that remembers the first-run help was shown.
const String wakeOnboardingFileName = 'wake_onboarding_done.txt';

/// Reads and writes the one-line wake-word setting file.
class WakeSettingsStore {
  /// True when the user left the wake word switched on.
  Future<bool> isEnabled() async {
    return await _readFlag(wakeSettingsFileName);
  }

  /// Saves the switch position.
  Future<void> setEnabled(bool value) async {
    await _writeFlag(wakeSettingsFileName, value);
  }

  /// True when the always-on help was shown once already.
  Future<bool> isOnboardingDone() async {
    return await _readFlag(wakeOnboardingFileName);
  }

  /// Remembers that the always-on help was shown.
  Future<void> setOnboardingDone() async {
    await _writeFlag(wakeOnboardingFileName, true);
  }

  /// Reads one true/false file, treating a missing file as false.
  Future<bool> _readFlag(String fileName) async {
    final file = await _settingsFile(fileName);
    if (!await file.exists()) return false;
    return (await file.readAsString()).trim() == 'true';
  }

  /// Writes one true/false file.
  Future<void> _writeFlag(String fileName, bool value) async {
    final file = await _settingsFile(fileName);
    await file.writeAsString(value ? 'true' : 'false', flush: true);
  }

  /// Returns the private setting file path.
  Future<File> _settingsFile(String fileName) async {
    final folder = await getApplicationSupportDirectory();
    return File(p.join(folder.path, fileName));
  }
}
