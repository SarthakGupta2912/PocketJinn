// What is this file for?
// The only place that defines Pocket Jinn colors, spacing, corner radius,
// text styles and the light/dark themes used by every screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

part 'app_theme_component_themes.dart';

/// Brand colors. Screens must never hard-code a color.
class AppColors {
  const AppColors._();

  /// Main purple used for buttons, the microphone and highlights.
  static const Color seedPurple = Color(0xFF6C4DFF);

  /// Soft lavender page background in light mode.
  static const Color lightBackground = Color(0xFFF7F5FC);

  /// Deep purple-black page background in dark mode.
  static const Color darkBackground = Color(0xFF14121C);

  /// Green used for a ready or successful state.
  static const Color successGreen = Color(0xFF2E7D32);

  /// Amber used for warnings such as a missing permission.
  static const Color warningAmber = Color(0xFF9A6700);

  /// Red used for errors and risky actions.
  static const Color dangerRed = Color(0xFFB3261E);

  /// Lighter green that stays readable on a dark background.
  static const Color successGreenDark = Color(0xFF7BD88F);

  /// Lighter amber that stays readable on a dark background.
  static const Color warningAmberDark = Color(0xFFFFC15E);

  /// Lighter red that stays readable on a dark background.
  static const Color dangerRedDark = Color(0xFFFF8A80);
}

/// Space between widgets, in logical pixels.
class AppSpacing {
  const AppSpacing._();

  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double extraLarge = 32;
  static const double huge = 48;
}

/// Corner radius values so every rounded box looks the same.
class AppRadius {
  const AppRadius._();

  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double pill = 999;
}

/// Fixed sizes are kept in constants.dart so they are easy to find.
class AppOpacity {
  const AppOpacity._();

  /// Faint fill behind a colored status chip.
  static const double softFill = 0.12;

  /// Slightly stronger line around a colored status chip.
  static const double softBorder = 0.35;
}

/// Font sizes used by the shared text theme.
class AppFontSizes {
  const AppFontSizes._();

  static const double headingLarge = 32;
  static const double headingMedium = 26;
  static const double title = 20;
  static const double body = 16;
  static const double caption = 13;
}

/// Builds the light and dark themes from one set of brand tokens.
class AppTheme {
  const AppTheme._();

  /// Theme used when the phone is in light mode.
  static ThemeData get light => _buildTheme(Brightness.light);

  /// Theme used when the phone is in dark mode.
  static ThemeData get dark => _buildTheme(Brightness.dark);

  /// Creates a complete theme for the given brightness.
  static ThemeData _buildTheme(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedPurple,
      brightness: brightness,
    );
    final ThemeData baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );
    final TextTheme textTheme = _buildTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: _pageBackground(brightness),
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(brightness, colorScheme, textTheme),
      cardTheme: _ComponentThemes.cardTheme(colorScheme),
      filledButtonTheme: _ComponentThemes.filledButtonTheme(),
      outlinedButtonTheme: _ComponentThemes.outlinedButtonTheme(),
      inputDecorationTheme: _ComponentThemes.inputDecorationTheme(colorScheme),
      snackBarTheme: _ComponentThemes.snackBarTheme(colorScheme, textTheme),
    );
  }

  /// Picks the page background color for the current brightness.
  static Color _pageBackground(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return AppColors.darkBackground;
    }
    return AppColors.lightBackground;
  }

  /// Defines every text size the app is allowed to use.
  static TextTheme _buildTextTheme(TextTheme baseTextTheme) {
    return baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: AppFontSizes.headingLarge,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: AppFontSizes.headingMedium,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: AppFontSizes.title,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: AppFontSizes.body,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: AppFontSizes.body,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: AppFontSizes.caption,
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: AppFontSizes.body,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Makes the app bar flat and picks readable status bar icons.
  static AppBarThemeData _buildAppBarTheme(
    Brightness brightness,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBarThemeData(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      // Why: dark icons are needed on a light page, light icons on a dark page.
      // The status bar color matches the page so there is no grey band.
      systemOverlayStyle:
          (brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: _pageBackground(brightness)),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }
}
