// What is this file for?
// A tiny helper for showing friendly messages without repeating snack bar
// code in every screen.

import 'package:flutter/material.dart';

/// Shows one floating message at the bottom of the screen.
void showAppMessage(BuildContext context, String message) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
