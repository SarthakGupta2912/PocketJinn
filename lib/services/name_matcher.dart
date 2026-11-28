// What is this file for?
// Finds which contact the user probably said, even in Hindi or another
// script, by using Android transliteration, a simple sound key and small
// spelling differences. This is only a helper; the user still confirms risky
// actions.

import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../models/contact.dart';
import '../models/contact_candidate.dart';

/// Supplies extra spoken names the user taught for one contact.
///
/// Kept as a small interface so the matcher can be tested with plain Dart,
/// without touching files or Android plugins.
abstract class NameAliasSource {
  /// Returns every taught name for one contact.
  Future<List<String>> aliasesFor(String contactName);
}

/// Ranks contacts against the words heard by the speech engine.
class NameMatcher {
  NameMatcher({required this.contacts, required this.aliasStore});

  /// Contacts the app is allowed to use.
  final List<Contact> contacts;

  /// Names the user taught the app.
  final NameAliasSource aliasStore;

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
  ///
  /// A full name and each of its words are tried, so saying only "Sarthak"
  /// still finds "Sarthak Gupta".
  Future<double> _scoreName(String spoken, String name) async {
    final latinName = await _toLatin(name);
    if (latinName.isEmpty) return 0;
    var best = _scoreLatin(spoken, latinName);
    for (final part in latinName.split(' ')) {
      if (part.isEmpty) continue;
      final score = _scoreLatin(spoken, part);
      if (score > best) best = score;
    }
    return best;
  }

  /// Scores one Latin name or word against the spoken words.
  double _scoreLatin(String spoken, String latinName) {
    if (spoken == latinName) return 1;
    final spokenWords = spoken.split(' ');
    if (spokenWords.contains(latinName)) return 0.95;
    final spokenKey = _soundKey(spoken);
    final nameKey = _soundKey(latinName);
    if (nameKey.isEmpty) return 0;
    if (spokenKey == nameKey) return 0.9;
    final wordKeys = spokenWords
        .map(_soundKey)
        .where((word) => word.isNotEmpty)
        .toList();
    if (wordKeys.contains(nameKey)) return 0.9;
    // Only a prefix counts as a partial word, so "Singh" does not match the
    // "sing" inside "crossing".
    if (nameKey.length >= 4) {
      for (final wordKey in wordKeys) {
        if (wordKey.length >= 4 &&
            (wordKey.startsWith(nameKey) || nameKey.startsWith(wordKey))) {
          return 0.8;
        }
      }
    }
    final distance = _editDistance(spokenKey, nameKey);
    final longest = spokenKey.length > nameKey.length
        ? spokenKey.length
        : nameKey.length;
    if (longest == 0) return 0;
    return (1 - distance / longest).clamp(0.0, 1.0);
  }

  /// Converts any script to plain Latin letters.
  ///
  /// Android's ICU transliterator is used first because it handles every
  /// Indian script. If that plugin is missing (for example in a unit test),
  /// a small built-in Devanagari converter keeps Hindi names working.
  Future<String> _toLatin(String text) async {
    try {
      final result = await _channel.invokeMethod<String>('transliterate', {
        'text': text,
      });
      if (result != null && result.trim().isNotEmpty) {
        return _cleanLatin(result);
      }
    } on Object {
      // Fall back to the built-in converter if the native call is unavailable.
    }
    return _cleanLatin(_devanagariToLatin(text));
  }

  /// Lowercases and removes everything that is not a letter, digit or space.
  String _cleanLatin(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Makes a simple sound key so common spelling choices still match.
  String _soundKey(String text) {
    var key = text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    key = key
        .replaceAll('ph', 'f')
        .replaceAll('sh', 's')
        .replaceAll('th', 't')
        .replaceAll('aa', 'a')
        .replaceAll('ee', 'i')
        .replaceAll('ii', 'i')
        .replaceAll('oo', 'u')
        .replaceAll('uu', 'u');
    if (key.endsWith('h') && key.length > 2) {
      key = key.substring(0, key.length - 1);
    }
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

/// Converts Devanagari letters to plain Latin letters.
///
/// This is a small, readable converter for names, not a full translator. It is
/// only used when Android's ICU transliterator is not available.
String _devanagariToLatin(String text) {
  // Two-character consonant forms must be replaced before single letters.
  const pairs = <String, String>{
    'क़': 'q',
    'ख़': 'kh',
    'ग़': 'g',
    'ज़': 'z',
    'ड़': 'r',
    'ढ़': 'rh',
    'फ़': 'f',
    'य़': 'y',
  };
  var working = text;
  for (final entry in pairs.entries) {
    working = working.replaceAll(entry.key, entry.value);
  }

  const consonants = <String, String>{
    'क': 'k',
    'ख': 'kh',
    'ग': 'g',
    'घ': 'gh',
    'ङ': 'ng',
    'च': 'ch',
    'छ': 'chh',
    'ज': 'j',
    'झ': 'jh',
    'ञ': 'n',
    'ट': 't',
    'ठ': 'th',
    'ड': 'd',
    'ढ': 'dh',
    'ण': 'n',
    'त': 't',
    'थ': 'th',
    'द': 'd',
    'ध': 'dh',
    'न': 'n',
    'प': 'p',
    'फ': 'ph',
    'ब': 'b',
    'भ': 'bh',
    'म': 'm',
    'य': 'y',
    'र': 'r',
    'ल': 'l',
    'ळ': 'l',
    'व': 'v',
    'श': 'sh',
    'ष': 'sh',
    'स': 's',
    'ह': 'h',
  };

  const independentVowels = <String, String>{
    'अ': 'a',
    'आ': 'aa',
    'इ': 'i',
    'ई': 'ii',
    'उ': 'u',
    'ऊ': 'uu',
    'ऋ': 'ri',
    'ए': 'e',
    'ऐ': 'ai',
    'ओ': 'o',
    'औ': 'au',
    'ॐ': 'om',
  };

  const matras = <String, String>{
    'ा': 'aa',
    'ि': 'i',
    'ी': 'ii',
    'ु': 'u',
    'ू': 'uu',
    'ृ': 'ri',
    'े': 'e',
    'ै': 'ai',
    'ो': 'o',
    'ौ': 'au',
  };

  const marks = <String, String>{'ं': 'n', 'ँ': 'n', 'ः': 'h'};

  final buffer = StringBuffer();
  var pendingInherentA = false;

  for (var index = 0; index < working.length; index++) {
    final character = working[index];
    final isMatra = matras.containsKey(character);
    final isVirama = character == '्';
    if (pendingInherentA && !isMatra && !isVirama) buffer.write('a');
    pendingInherentA = false;

    final consonant = consonants[character];
    if (consonant != null) {
      buffer.write(consonant);
      pendingInherentA = true;
      continue;
    }
    final vowel = independentVowels[character];
    if (vowel != null) {
      buffer.write(vowel);
      continue;
    }
    final matra = matras[character];
    if (matra != null) {
      buffer.write(matra);
      continue;
    }
    if (isVirama) continue;
    final mark = marks[character];
    if (mark != null) {
      buffer.write(mark);
      continue;
    }
    if (RegExp(r'[a-zA-Z0-9 ]').hasMatch(character)) buffer.write(character);
  }
  return buffer.toString();
}
