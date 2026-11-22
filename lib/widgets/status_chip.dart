// What is this file for?
// A small rounded label that shows the app state, such as ready, warning
// or error, with one shared color style.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import 'app_text.dart';

/// The meaning of a status chip, which decides its colors.
enum StatusTone { neutral, success, warning, danger }

/// Shows a short status word with an icon and a soft colored background.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusTone.neutral,
  });

  /// Short text such as "Ready" or "Microphone off".
  final String label;

  /// Optional icon shown before the label.
  final IconData? icon;

  /// The meaning of the status, used to pick colors.
  final StatusTone tone;

  /// Builds the pill-shaped label.
  @override
  Widget build(BuildContext context) {
    final StatusChipColors colors = _colorsFor(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.border, width: AppSizes.thinBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.smallIconSize, color: colors.foreground),
            const SizedBox(width: AppSpacing.small),
          ],
          AppText(label, role: AppTextRole.caption, color: colors.foreground),
        ],
      ),
    );
  }

  /// Chooses background, border and text colors for the current tone.
  StatusChipColors _colorsFor(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainColor = _mainColorForTone(isDark);

    if (tone == StatusTone.neutral) {
      return StatusChipColors(
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
        border: colorScheme.outlineVariant,
      );
    }
    return StatusChipColors(
      background: mainColor.withValues(alpha: AppOpacity.softFill),
      foreground: mainColor,
      border: mainColor.withValues(alpha: AppOpacity.softBorder),
    );
  }

  /// Returns the strong color that matches the chosen tone.
  Color _mainColorForTone(bool isDark) {
    switch (tone) {
      case StatusTone.success:
        return isDark ? AppColors.successGreenDark : AppColors.successGreen;
      case StatusTone.warning:
        return isDark ? AppColors.warningAmberDark : AppColors.warningAmber;
      case StatusTone.danger:
        return isDark ? AppColors.dangerRedDark : AppColors.dangerRed;
      case StatusTone.neutral:
        return AppColors.seedPurple;
    }
  }
}

/// Holds the three colors needed to draw one status chip.
class StatusChipColors {
  const StatusChipColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  /// Soft fill behind the label.
  final Color background;

  /// Color of the text, icon and outline.
  final Color foreground;

  /// Color of the thin border around the chip.
  final Color border;
}
