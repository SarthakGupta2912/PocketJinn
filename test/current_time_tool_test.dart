// What is this file for?
// Checks that the existing safe time tool still returns a spoken-style answer.
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/tools/current_time_tool.dart';

void main() {
  test('returns a success message with the current time', () async {
    final result = await const CurrentTimeTool().run(const {});

    expect(result['status'], 'success');
    expect(result['time'], isA<String>());
    expect(result['message'], startsWith('The current time is '));
  });
}
