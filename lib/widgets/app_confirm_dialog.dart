// What is this file for?
// A shared yes/no dialog used before the assistant does something risky,
// such as calling or messaging someone.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'app_button.dart';
import 'app_text.dart';

/// Shows a confirmation dialog and reports the user's decision.
class AppConfirmDialog {
  const AppConfirmDialog._();

  /// Opens the dialog and returns true only when the user confirms.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
  }) async {
    final bool? answer = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: AppText(title, role: AppTextRole.title),
          content: AppText(message),
          actionsPadding: const EdgeInsets.all(AppSpacing.medium),
          actions: [
            AppButton(
              label: cancelLabel,
              isSecondary: true,
              expand: false,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppButton(
              label: confirmLabel,
              expand: false,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    return answer ?? false;
  }
}
