// What is this file for?
// Provides one small helper that tells every screen whether it is running
// on a phone, a tablet or a very wide screen.

import 'package:flutter/widgets.dart';

/// Width limits, in logical pixels, that separate device classes.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  /// Anything narrower than this is treated as a phone.
  static const double phoneMaximumWidth = 600;

  /// Anything narrower than this (but wider than a phone) is a tablet.
  static const double tabletMaximumWidth = 1024;
}

/// Answers simple layout questions about the current window size.
class Responsive {
  const Responsive._();

  /// True when the window is narrower than 600 logical pixels.
  static bool isPhone(BuildContext context) {
    return _windowWidth(context) < ResponsiveBreakpoints.phoneMaximumWidth;
  }

  /// True when the window is between 600 and 1024 logical pixels.
  static bool isTablet(BuildContext context) {
    final double width = _windowWidth(context);
    return width >= ResponsiveBreakpoints.phoneMaximumWidth &&
        width < ResponsiveBreakpoints.tabletMaximumWidth;
  }

  /// True when the window is 1024 logical pixels or wider.
  static bool isLarge(BuildContext context) {
    return _windowWidth(context) >= ResponsiveBreakpoints.tabletMaximumWidth;
  }

  /// Returns the value that matches the current device class.
  static double value(
    BuildContext context, {
    required double phone,
    required double tablet,
    double? large,
  }) {
    if (isLarge(context)) {
      return large ?? tablet;
    }
    if (isTablet(context)) {
      return tablet;
    }
    return phone;
  }

  /// Reads the current window width from MediaQuery.
  static double _windowWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }
}
