// What is this file for?
// A text input styled by the app theme, used for typing commands and names.

import 'package:flutter/material.dart';

/// Shows a single styled text field with a hint and submit callback.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.enabled = true,
  });

  /// Holds the text the user types.
  final TextEditingController controller;

  /// Grey helper text shown while the field is empty.
  final String hintText;

  /// Called when the user presses the keyboard action button.
  final ValueChanged<String>? onSubmitted;

  /// Called every time the text changes.
  final ValueChanged<String>? onChanged;

  /// Chooses the keyboard, for example text or phone number.
  final TextInputType? keyboardType;

  /// Chooses the keyboard action button, such as done or send.
  final TextInputAction? textInputAction;

  /// Smallest number of lines the field shows.
  final int? minLines;

  /// Largest number of lines the field grows to.
  final int maxLines;

  /// When true, the keyboard opens automatically.
  final bool autofocus;

  /// When false, the field is greyed out and cannot be edited.
  final bool enabled;

  /// Builds the text field using the shared decoration theme.
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      decoration: InputDecoration(hintText: hintText),
    );
  }
}
