// What is this file for?
// Checks that the app's tool-call JSON reader is strict but never crashes.

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/models/tool_call.dart';

void main() {
  group('ToolCall.tryParse', () {
    test('reads the documented tool and args shape', () {
      final call = ToolCall.tryParse('{"tool":"get_current_time","args":{}}');

      expect(call, isNotNull);
      expect(call!.tool, 'get_current_time');
      expect(call.arguments, isEmpty);
    });

    test('keeps nested argument values', () {
      final call = ToolCall.tryParse(
        '{"tool":"call_contact","args":{"name":"sarthak",'
        '"number":"9023850632"}}',
      );

      expect(call?.tool, 'call_contact');
      expect(call?.arguments['name'], 'sarthak');
      expect(call?.arguments['number'], '9023850632');
    });

    test('rejects plain text instead of throwing', () {
      expect(ToolCall.tryParse('I did not understand that.'), isNull);
    });

    test('rejects malformed JSON instead of throwing', () {
      expect(ToolCall.tryParse('{"tool":'), isNull);
    });

    test('rejects a missing args object', () {
      expect(ToolCall.tryParse('{"tool":"get_current_time"}'), isNull);
    });

    test('rejects an argument list that is not an object', () {
      expect(ToolCall.tryParse('{"tool":"x","args":[]}'), isNull);
    });
  });
}
