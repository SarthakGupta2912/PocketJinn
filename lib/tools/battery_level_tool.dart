// What is this file for?
// A safe Tier 1 tool that reads the device battery without network access.
import '../services/android_tool_service.dart';
import 'base_tool.dart';

/// Reports the battery percent and whether the device is charging.
class BatteryLevelTool extends BaseTool {
  const BatteryLevelTool({required this.androidTools});

  final AndroidToolService androidTools;

  @override
  String get name => 'get_battery_level';

  @override
  String get description =>
      'Get the device battery percent and charging state.';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    try {
      final battery = await androidTools.getBatteryLevel();
      final percent = battery['percent'];
      final charging = battery['charging'] == true;
      if (percent is! int || percent < 0 || percent > 100) {
        return const {'status': 'error', 'error': 'Battery state is invalid.'};
      }
      final state = charging ? 'charging' : 'not charging';
      return {
        'status': 'success',
        'percent': percent,
        'charging': charging,
        'message': 'The battery is $percent percent and $state.',
      };
    } on Object catch (error) {
      return {
        'status': 'error',
        'error': 'The battery could not be read: $error',
      };
    }
  }
}
