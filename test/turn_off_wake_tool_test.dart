// What is this file for?
// Checks that stopping the wake listener is marked risky and calls its callback.
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/tools/turn_off_wake_tool.dart';

void main() {
  test('stops wake once after confirmation', () async {
    var stops = 0;
    final tool = TurnOffWakeTool(stopWake: () async => stops++);

    final result = await tool.run(const {});

    expect(result['status'], 'success');
    expect(result['message'], contains('off'));
    expect(stops, 1);
    expect(tool.isRisky, isTrue);
    expect(tool.confirmationLabel, 'Stop listening');
  });
}
