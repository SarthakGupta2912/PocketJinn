// What is this file for?
// A small Dart wrapper for the Android pages that keep the wake listener
// alive: battery settings, notification settings, app info and auto-start.
import 'package:flutter/services.dart';

import '../core/wake_constants.dart';

/// Opens the phone pages that keep background listening allowed.
class KeepAliveService {
  static const MethodChannel _channel = MethodChannel(wakeChannelName);

  /// Opens one page by name and returns true when Android accepted it.
  Future<bool> openPage(String page) async {
    try {
      final result = await _channel.invokeMethod<bool>('openSettingsPage', {
        'page': page,
      });
      return result ?? false;
    } on Object {
      return false;
    }
  }

  /// True when Android already lets Pocket Jinn ignore battery savings.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } on Object {
      return false;
    }
  }

  /// Asks for notification access and returns whether it is allowed.
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestNotificationPermission',
      );
      return result ?? false;
    } on Object {
      return false;
    }
  }
}
