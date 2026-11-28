// What is this file for?
// Saves the names the user teaches the app in a small JSON file on the device.

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'name_matcher.dart';

/// Reads and writes extra spoken names for each contact.
class NameAliasStore implements NameAliasSource {
  Map<String, List<String>> _aliases = <String, List<String>>{};
  bool _isLoaded = false;

  /// Returns all names taught for one contact.
  @override
  Future<List<String>> aliasesFor(String contactName) async {
    await _load();
    return List<String>.from(_aliases[contactName.toLowerCase()] ?? <String>[]);
  }

  /// Saves one taught name. The same name is not saved twice.
  Future<void> addAlias(String contactName, String alias) async {
    await _load();
    final key = contactName.toLowerCase();
    final cleaned = alias.trim().toLowerCase();
    if (cleaned.isEmpty) return;
    final names = _aliases[key] ?? <String>[];
    if (!names.contains(cleaned)) names.add(cleaned);
    _aliases[key] = names;
    await _save();
  }

  /// Reads the JSON file once.
  Future<void> _load() async {
    if (_isLoaded) return;
    final file = await _aliasFile();
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        _aliases = decoded.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((item) => item.toString()).toList(),
          ),
        );
      }
    }
    _isLoaded = true;
  }

  /// Writes the JSON file.
  Future<void> _save() async {
    final file = await _aliasFile();
    await file.writeAsString(jsonEncode(_aliases));
  }

  /// Returns the private JSON file path.
  Future<File> _aliasFile() async {
    final folder = await getApplicationSupportDirectory();
    return File(p.join(folder.path, 'name_aliases.json'));
  }
}
