// What is this file for?
// Checks that the global stop always calls both of its callbacks, once each.
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/tools/stop_everything_tool.dart';

void main() {
  test('stops voice and clears commands once', () async {
    var voiceStops = 0;
    var clears = 0;
    final tool = StopEverythingTool(
      stopVoice: () async => voiceStops++,
      clearCommands: () => clears++,
    );

    final result = await tool.run(const {});

    expect(result['status'], 'success');
    expect(result['message'], contains('stopped'));
    expect(voiceStops, 1);
    expect(clears, 1);
  });
}
