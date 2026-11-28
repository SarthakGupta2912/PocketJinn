// What is this file for?
// A safe Tier 1 tool that asks the system clock to show an alarm. Pocket Jinn
// never sets an alarm silently: the clock app always stays in the flow.
import '../services/android_tool_service.dart';
import 'base_tool.dart';

/// Opens the system clock with a validated alarm time.
class SetAlarmTool extends BaseTool {
  const SetAlarmTool({required this.androidTools});

  final AndroidToolService androidTools;

  @override
  String get name => 'set_alarm';

  @override
  String get description =>
      'Open the clock app to set an alarm at a given hour and minute.';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{
      'hour': {'type': 'integer'},
      'minute': {'type': 'integer'},
      'label': {'type': 'string'},
    },
    'required': <String>['hour', 'minute'],
  };

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    final hour = _readNumber(arguments['hour']);
    final minute = _readNumber(arguments['minute']);
    if (hour == null || hour < 0 || hour > 23) {
      return const {'status': 'error', 'error': 'Use an hour from 0 to 23.'};
    }
    if (minute == null || minute < 0 || minute > 59) {
      return const {'status': 'error', 'error': 'Use a minute from 0 to 59.'};
    }
    final label = arguments['label'];
    final safeLabel = label is String
        ? label.trim().replaceAll(RegExp(r'\s+'), ' ')
        : '';
    try {
      final message = await androidTools.setAlarm(
        hour: hour,
        minute: minute,
        label: safeLabel.length > 40 ? safeLabel.substring(0, 40) : safeLabel,
      );
      return {'status': 'success', 'message': message};
    } on Object catch (error) {
      return {
        'status': 'error',
        'error': 'The alarm could not be opened: $error',
      };
    }
  }

  /// Reads a whole number from a model argument or from a numeric string.
  int? _readNumber(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
