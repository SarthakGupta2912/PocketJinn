// What is this file for?
// Gives the offline assistant the device's current local date and time.

import 'base_tool.dart';

/// Returns the current local time without network access.
class CurrentTimeTool extends BaseTool {
  @override
  String get name => 'get_current_time';

  @override
  String get description => 'Get the current local date and time.';

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  /// Returns an ISO timestamp and a readable local value.
  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    final now = DateTime.now();
    return {
      'status': 'success',
      'time': now.toIso8601String(),
      'message': 'The current time is ${_readableTime(now)}.',
    };
  }

  /// Formats a short spoken-style time with the full weekday and date.
  String _readableTime(DateTime time) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    final weekday = weekdays[time.weekday - 1];
    final month = months[time.month - 1];
    return '$hour:$minute $period on $weekday, ${time.day} $month ${time.year}';
  }
}
