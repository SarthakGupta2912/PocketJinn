// What is this file for?
// Checks that the local calculator gives correct answers and refuses unsafe
// input instead of running any code.
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/tools/calculator_tool.dart';

void main() {
  const tool = CalculatorTool();

  Future<Map<String, dynamic>> calculate(String expression) =>
      tool.run({'expression': expression});

  group('CalculatorTool', () {
    test('adds, subtracts, multiplies and divides', () async {
      expect((await calculate('2+3*4'))['value'], 14.0);
      expect((await calculate('10-2-3'))['value'], 5.0);
      expect((await calculate('(2+3)*4'))['value'], 20.0);
      expect((await calculate('9/2'))['value'], 4.5);
    });

    test('handles a leading minus and decimals', () async {
      expect((await calculate('-5+2'))['value'], -3.0);
      expect((await calculate('1.5*2'))['value'], 3.0);
    });

    test('understands spoken operator words', () async {
      expect((await calculate('12 times 5'))['value'], 60.0);
      expect((await calculate('9 divided by 2'))['value'], 4.5);
      expect((await calculate('2 plus 3'))['value'], 5.0);
      expect((await calculate('12 * 5 = 60'))['value'], 60.0);
    });

    test('formats whole results without trailing zeroes', () async {
      expect(tool.format(20.0), '20');
      expect(tool.format(4.5), '4.5');
    });

    test('refuses division by zero', () async {
      final result = await calculate('7/0');
      expect(result['status'], 'error');
      expect(result['error'], contains('zero'));
    });

    test('refuses code, letters and missing brackets', () async {
      for (final expression in ['print(1)', '2**3', '(2+3', '2;3']) {
        final result = await calculate(expression);
        expect(result['status'], 'error', reason: expression);
      }
    });

    test('refuses an empty or very long sum', () async {
      expect((await calculate(''))['status'], 'error');
      expect((await calculate('1+' * 100))['status'], 'error');
    });
  });
}
