// What is this file for?
// Holds the small Material component themes (cards, buttons, text fields and
// snack bars) used by app_theme.dart. It is a part of that one library.

part of 'app_theme.dart';

/// Builds the component themes that sit on top of the color scheme.
class _ComponentThemes {
  const _ComponentThemes._();

  /// Gives cards a soft surface and a rounded shape.
  static CardThemeData cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    );
  }

  /// Sets the minimum touch target for filled buttons.
  static FilledButtonThemeData filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(
          AppSizes.minimumTouchTarget,
          AppSizes.minimumTouchTarget,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }

  /// Sets the minimum touch target for outlined buttons.
  static OutlinedButtonThemeData outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(
          AppSizes.minimumTouchTarget,
          AppSizes.minimumTouchTarget,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }

  /// Gives text fields a soft fill and rounded border.
  static InputDecorationThemeData inputDecorationTheme(
    ColorScheme colorScheme,
  ) {
    return InputDecorationThemeData(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.all(AppSpacing.medium),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// Makes snack bar messages float and stay readable.
  static SnackBarThemeData snackBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
    );
  }
}
