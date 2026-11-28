// What is this file for?
// A safe Tier 1 tool that does small arithmetic locally, with no code execution
// and no access to the device or the network.
import 'base_tool.dart';

/// Evaluates one short arithmetic expression such as "(12+3)*4".
class CalculatorTool extends BaseTool {
  const CalculatorTool();

  static const int maxLength = 120;

  @override
  String get name => 'calculate';

  @override
  String get description =>
      'Calculate a short arithmetic expression with +, -, *, / and brackets.';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{
      'expression': {'type': 'string'},
    },
    'required': <String>['expression'],
  };

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    final raw = arguments['expression'];
    if (raw is! String || raw.trim().isEmpty) {
      return const {'status': 'error', 'error': 'Give a sum to calculate.'};
    }
    final expression = _normalise(raw.trim());
    if (expression.length > maxLength) {
      return const {'status': 'error', 'error': 'That sum is too long.'};
    }
    if (!RegExp(r'^[0-9+\-*/(). ]+$').hasMatch(expression)) {
      return const {
        'status': 'error',
        'error': 'Only numbers and + - * / are allowed.',
      };
    }
    try {
      final value = _Parser(expression).parse();
      if (!value.isFinite) {
        return const {
          'status': 'error',
          'error': 'That sum has no finite answer.',
        };
      }
      return {
        'status': 'success',
        'value': value,
        'message': 'The answer is ${format(value)}.',
      };
    } on FormatException catch (error) {
      return {'status': 'error', 'error': error.message};
    }
  }

  /// Turns spoken operator words into symbols before validation.
  String _normalise(String text) {
    // A small model sometimes answers the sum itself as "12*5=60". Ignore the
    // claimed answer and calculate the real one instead.
    final expressionOnly = text.split('=').first.trim();
    return expressionOnly
        .toLowerCase()
        .replaceAll(RegExp(r'\bdivided by\b'), '/')
        .replaceAll(RegExp(r'\bmultiplied by\b'), '*')
        .replaceAll(RegExp(r'\bplus\b'), '+')
        .replaceAll(RegExp(r'\bminus\b'), '-')
        .replaceAll(RegExp(r'\btimes\b'), '*')
        .replaceAll(' x ', '*');
  }

  /// Formats whole numbers without a decimal part.
  String format(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '');
  }
}

/// A tiny recursive-descent parser: sum, product, then number or bracket.
class _Parser {
  _Parser(this._text);

  final String _text;
  int _index = 0;

  /// Parses the whole expression and rejects leftover characters.
  double parse() {
    final value = _sum();
    _skipSpaces();
    if (_index != _text.length) {
      throw const FormatException('That sum is not valid.');
    }
    return value;
  }

  /// Adds and subtracts terms from left to right.
  double _sum() {
    var value = _product();
    while (true) {
      _skipSpaces();
      if (_take('+')) {
        value += _product();
      } else if (_take('-')) {
        value -= _product();
      } else {
        return value;
      }
    }
  }

  /// Multiplies and divides factors from left to right.
  double _product() {
    var value = _factor();
    while (true) {
      _skipSpaces();
      if (_take('*')) {
        value *= _factor();
      } else if (_take('/')) {
        final divisor = _factor();
        if (divisor == 0) {
          throw const FormatException('You cannot divide by zero.');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  /// Reads a number, a bracketed sum, or a leading sign.
  double _factor() {
    _skipSpaces();
    if (_take('+')) return _factor();
    if (_take('-')) return -_factor();
    if (_take('(')) {
      final value = _sum();
      _skipSpaces();
      if (!_take(')')) throw const FormatException('A bracket is missing.');
      return value;
    }
    final start = _index;
    while (_index < _text.length && _isDigit(_text.codeUnitAt(_index))) {
      _index++;
    }
    if (_index < _text.length && _text[_index] == '.') {
      _index++;
      while (_index < _text.length && _isDigit(_text.codeUnitAt(_index))) {
        _index++;
      }
    }
    if (start == _index) throw const FormatException('That sum is not valid.');
    return double.parse(_text.substring(start, _index));
  }

  /// Consumes one character when it matches.
  bool _take(String character) {
    if (_index < _text.length && _text[_index] == character) {
      _index++;
      return true;
    }
    return false;
  }

  /// Moves past spaces.
  void _skipSpaces() {
    while (_index < _text.length && _text.codeUnitAt(_index) == 32) {
      _index++;
    }
  }

  /// True for an ASCII digit.
  bool _isDigit(int code) => code >= 48 && code <= 57;
}
