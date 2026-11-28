// What is this file for?
// Checks that the battery tool reports a valid answer and never crashes when
// Android cannot provide battery data.
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/services/android_tool_service.dart';
import 'package:pocket_jinn/tools/battery_level_tool.dart';

/// Fake battery source used instead of the Android method channel.
class FakeBatteryService extends AndroidToolService {
  FakeBatteryService(this.reply);

  final Map<String, dynamic>? reply;

  @override
  Future<Map<String, dynamic>> getBatteryLevel() async {
    if (reply == null) throw const FormatException('unavailable');
    return reply!;
  }
}

void main() {
  group('BatteryLevelTool', () {
    test('reports charging battery', () async {
      final tool = BatteryLevelTool(
        androidTools: FakeBatteryService({'percent': 61, 'charging': true}),
      );
      final result = await tool.run(const {});

      expect(result['status'], 'success');
      expect(result['percent'], 61);
      expect(result['charging'], isTrue);
      expect(result['message'], contains('61 percent'));
      expect(result['message'], contains('charging'));
    });

    test('reports a discharging battery', () async {
      final tool = BatteryLevelTool(
        androidTools: FakeBatteryService({'percent': 20, 'charging': false}),
      );
      final result = await tool.run(const {});
      expect(result['message'], contains('not charging'));
    });

    test('rejects an invalid percent', () async {
      final tool = BatteryLevelTool(
        androidTools: FakeBatteryService({'percent': 140, 'charging': false}),
      );
      expect((await tool.run(const {}))['status'], 'error');
    });

    test('survives a missing battery', () async {
      final tool = BatteryLevelTool(androidTools: FakeBatteryService(null));
      expect((await tool.run(const {}))['status'], 'error');
    });
  });
}
