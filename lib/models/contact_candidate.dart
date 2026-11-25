// What is this file for?
// Holds one possible contact match and how sure the matcher is about it.

import 'contact.dart';

/// One contact guess with a score between zero and one.
class ContactCandidate {
  const ContactCandidate({
    required this.contact,
    required this.score,
    required this.matchedName,
  });

  /// The contact that may have been spoken.
  final Contact contact;

  /// Higher means a better match.
  final double score;

  /// The name or taught alias that produced this score.
  final String matchedName;
}
