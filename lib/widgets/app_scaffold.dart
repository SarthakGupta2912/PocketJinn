// What is this file for?
// The page frame for every screen: a flat app bar plus a safe, padded body.

import 'package:flutter/material.dart';

/// Wraps a screen with the shared app bar and safe area.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  /// Text shown at the top of the screen.
  final String title;

  /// The main screen content.
  final Widget body;

  /// Optional icon buttons shown on the right side of the app bar.
  final List<Widget>? actions;

  /// Builds the scaffold and keeps content away from system bars.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: body),
    );
  }
}
