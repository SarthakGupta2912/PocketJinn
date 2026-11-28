// What is this file for?
// Checks that the alarm tool validates the time before handing it to Android.
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/services/android_tool_service.dart';
import 'package:pocket_jinn/tools/set_alarm_tool.dart';

/// Fake clock used instead of the Android method channel.
class FakeAlarmService extends AndroidToolService {
  FakeAlarmService({this.fail = false});

  final bool fail;
  int? hour;
  int? minute;
  String? label;

  @override
  Future<String> setAlarm({
    required int hour,
    required int minute,
    required String label,
  }) async {
    if (fail) throw const FormatException('no clock');
    this.hour = hour;
    this.minute = minute;
    this.label = label;
    return 'Opening the clock.';
  }
}

void main() {
  group('SetAlarmTool', () {
    test('passes a valid time to the clock app', () async {
      final service = FakeAlarmService();
      final tool = SetAlarmTool(androidTools: service);
      final result = await tool.run({
        'hour': '7',
        'minute': 30,
        'label': '  wake  up  ',
      });

      expect(result['status'], 'success');
      expect(service.hour, 7);
      expect(service.minute, 30);
      expect(service.label, 'wake up');
    });

    test('refuses impossible times', () async {
      final tool = SetAlarmTool(androidTools: FakeAlarmService());
      expect((await tool.run({'hour': 24, 'minute': 0}))['status'], 'error');
      expect((await tool.run({'hour': 1, 'minute': 60}))['status'], 'error');
      expect(
        (await tool.run({'hour': 'noon', 'minute': 0}))['status'],
        'error',
      );
    });

    test('shortens a long label', () async {
      final service = FakeAlarmService();
      final tool = SetAlarmTool(androidTools: service);
      await tool.run({'hour': 8, 'minute': 0, 'label': 'a' * 100});
      expect(service.label!.length, 40);
    });

    test('survives a device without a clock app', () async {
      final tool = SetAlarmTool(androidTools: FakeAlarmService(fail: true));
      expect((await tool.run({'hour': 8, 'minute': 0}))['status'], 'error');
    });
  });
}
