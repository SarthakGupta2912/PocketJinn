// What is this file for?
// Holds one contact that Pocket Jinn is allowed to call or message.

/// A person the assistant knows about.
class Contact {
  const Contact({required this.name, required this.number});

  /// Name shown in Settings and in confirmations.
  final String name;

  /// Phone number used by the fixed Stage 2 tools.
  final String number;
}
