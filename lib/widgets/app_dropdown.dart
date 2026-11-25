// What is this file for?
// One dropdown widget so Settings uses the same padding and theme everywhere.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'app_text.dart';

/// Shows a labelled list of choices using the shared theme.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  /// Short explanation above the dropdown.
  final String label;

  /// Currently selected value.
  final T value;

  /// All allowed values.
  final List<T> items;

  /// Called with the new value.
  final ValueChanged<T> onChanged;

  /// Builds the labelled dropdown.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, role: AppTextRole.caption, useMutedColor: true),
        const SizedBox(height: AppSpacing.extraSmall),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: AppText(item.toString())),
          ],
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ],
    );
  }
}
