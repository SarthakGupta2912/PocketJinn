// What is this file for?
// A risky Tier 2 tool that removes only this app's own small temporary files.
// Model files and saved settings are never touched.
import 'dart:io';

import 'base_tool.dart';

/// Deletes only files named debug_*.wav or *.tmp in one private folder.
class DeleteTempFilesTool extends BaseTool {
  const DeleteTempFilesTool({required this.directory});

  /// Supplies the app-private folder to clean.
  final Future<Directory> Function() directory;

  @override
  String get name => 'delete_temp_files';

  @override
  String get description =>
      'Delete this app\'s temporary test recordings and .tmp files.';

  @override
  bool get isRisky => true;

  @override
  String get confirmationMessage =>
      'Delete Pocket Jinn\'s temporary test files? Model files stay safe.';

  @override
  String get confirmationLabel => 'Delete temp files';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    try {
      final folder = await directory();
      if (!await folder.exists()) {
        return const {
          'status': 'success',
          'message': 'There were no temp files.',
        };
      }
      var deleted = 0;
      await for (final entry in folder.list()) {
        if (entry is! File || !_isTemporary(entry.uri.pathSegments.last)) {
          continue;
        }
        await entry.delete();
        deleted++;
      }
      return {
        'status': 'success',
        'deleted': deleted,
        'message': 'Deleted $deleted temporary file(s).',
      };
    } on Object catch (error) {
      return {
        'status': 'error',
        'error': 'The temp files could not be deleted: $error',
      };
    }
  }

  /// True only for files this tool is allowed to remove.
  bool _isTemporary(String name) {
    return name.endsWith('.tmp') ||
        (name.startsWith('debug_') && name.endsWith('.wav'));
  }
}
