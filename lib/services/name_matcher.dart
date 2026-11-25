// What is this file for?
// Finds which contact the user probably said, even in Hindi or another
// script, by using Android transliteration, a simple sound key and small
// spelling differences. This is only a helper; the user still confirms risky
// actions.

import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../models/contact.dart';
import '../models/contact_candidate.dart';
import 'name_alias_store.dart';

/// Ranks contacts against the words heard by the speech engine.
class NameMatcher {
  NameMatcher({required this.contacts, required this.aliasStore});

  /// Contacts the app is allowed to use.
  final List<Contact> contacts;

  /// Names the user taught the app.
  final NameAliasStore aliasStore;

  static const MethodChannel _channel = MethodChannel(androidToolsChannelName);

  /// Returns every known name and taught alias, useful as recognition hints.
  Future<List<String>> allNames() async {
    final names = <String>[];
    for (final contact in contacts) {
      names.add(contact.name);
      names.addAll(await aliasStore.aliasesFor(contact.name));
    }
    return names;
  }

  /// Returns the three best guesses, highest score first.
  Future<List<ContactCandidate>> match(String transcript) async {
    final spoken = await _toLatin(transcript);
    if (spoken.isEmpty) return <ContactCandidate>[];

    final results = <ContactCandidate>[];
    for (final contact in contacts) {
      final names = <String>[
        contact.name,
        ...await aliasStore.aliasesFor(contact.name),
      ];
      final candidate = await _bestForContact(spoken, contact, names);
      if (candidate != null) results.add(candidate);
    }
    results.sort((first, second) => second.score.compareTo(first.score));
    return results.take(3).toList();
  }

  /// True when the first guess is weak or very close to the second guess.
  bool isUncertain(List<ContactCandidate> candidates) {
    if (candidates.isEmpty) return true;
    if (candidates.first.score < 0.6) return true;
    if (candidates.length < 2) return false;
    return candidates.first.score - candidates[1].score < 0.15;
  }

  /// Finds the best taught name or real name for one contact.
  Future<ContactCandidate?> _bestForContact(
    String spoken,
    Contact contact,
    List<String> names,
  ) async {
    var bestScore = 0.0;
    var bestName = '';
    for (final name in names) {
      final score = await _scoreName(spoken, name);
      if (score > bestScore) {
        bestScore = score;
        bestName = name;
      }
    }
    if (bestScore < 0.3) return null;
    return ContactCandidate(
      contact: contact,
      score: bestScore,
      matchedName: bestName,
    );
  }

  /// Scores one name against the spoken words.
  Future<double> _scoreName(String spoken, String name) async {
    final latinName = await _toLatin(name);
    if (latinName.isEmpty) return 0;
    if (spoken.contains(latinName)) return 1;
    final spokenKey = _soundKey(spoken);
    final nameKey = _soundKey(latinName);
    if (spokenKey.contains(nameKey)) return 0.85;
    final distance = _editDistance(spokenKey, nameKey);
    final longest = spokenKey.length > nameKey.length
        ? spokenKey.length
        : nameKey.length;
    if (longest == 0) return 0;
    return (1 - distance / longest).clamp(0.0, 1.0);
  }

  /// Converts any script to plain Latin letters using Android ICU.
  Future<String> _toLatin(String text) async {
    try {
      final result = await _channel.invokeMethod<String>('transliterate', {
        'text': text,
      });
      if (result != null && result.trim().isNotEmpty) {
        return result.toLowerCase().trim();
      }
    } on Object {
      // Fall back to plain Latin letters if the native call is unavailable.
    }
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').trim();
  }

  /// Makes a simple sound key so common spelling choices still match.
  String _soundKey(String text) {
    var key = text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    key = key
        .replaceAll('ph', 'f')
        .replaceAll('sh', 's')
        .replaceAll('aa', 'a')
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u');
    return key;
  }

  /// Counts the smallest number of letter changes between two words.
  int _editDistance(String first, String second) {
    var previous = List<int>.generate(second.length + 1, (index) => index);
    for (var row = 1; row <= first.length; row++) {
      final current = <int>[row];
      for (var column = 1; column <= second.length; column++) {
        final cost = first[row - 1] == second[column - 1] ? 0 : 1;
        final best = current[column - 1] + 1 < previous[column] + 1
            ? current[column - 1] + 1
            : previous[column] + 1;
        current.add(
          best < previous[column - 1] + cost
              ? best
              : previous[column - 1] + cost,
        );
      }
      previous = current;
    }
    return previous.last;
  }
}
