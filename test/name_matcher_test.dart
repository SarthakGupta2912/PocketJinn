// What is this file for?
// Tests the contact name matcher with fake Indian names, misspellings and
// Devanagari forms. It prints top-1 and top-3 accuracy so the numbers can be
// reported honestly in the test report.

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_jinn/models/contact_candidate.dart';
import 'package:pocket_jinn/services/name_matcher.dart';

import 'fixtures/fake_contacts.dart';

/// The matcher asks for taught aliases; these tests teach none.
class _NoAliases implements NameAliasSource {
  const _NoAliases();

  @override
  Future<List<String>> aliasesFor(String contactName) async => const <String>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NameMatcher matcher;

  setUp(() {
    matcher = NameMatcher(
      contacts: fakeContacts,
      aliasStore: const _NoAliases(),
    );
  });

  test('every fake spoken name is found in the top three', () async {
    final misses = <String>[];
    for (final testCase in fakeNameCases) {
      final results = await matcher.match(testCase.spoken);
      final names = results.map((result) => result.contact.name).toList();
      if (!names.contains(testCase.expected)) {
        misses.add(
          '${testCase.spoken} -> wanted ${testCase.expected}, got $names',
        );
      }
    }
    expect(misses, isEmpty, reason: misses.join('\n'));
  });

  test('top-1 and top-3 accuracy over the fake contacts', () async {
    var topOne = 0;
    var topThree = 0;
    final rows = <String>[];

    for (final testCase in fakeNameCases) {
      final results = await matcher.match(testCase.spoken);
      final names = results.map((result) => result.contact.name).toList();
      final rank = names.indexOf(testCase.expected) + 1;
      if (rank == 1) topOne++;
      if (rank >= 1 && rank <= 3) topThree++;
      rows.add(
        '${testCase.label.padRight(12)} '
        '${testCase.spoken.padRight(14)} '
        'rank=$rank  top=${names.take(3).join(", ")}',
      );
    }

    final total = fakeNameCases.length;
    final topOnePercent = (topOne * 100 / total).toStringAsFixed(1);
    final topThreePercent = (topThree * 100 / total).toStringAsFixed(1);

    // ignore: avoid_print
    print('Name matcher accuracy over $total fake cases:');
    for (final row in rows) {
      // ignore: avoid_print
      print('  $row');
    }
    // ignore: avoid_print
    print('  TOP-1: $topOne/$total ($topOnePercent%)');
    // ignore: avoid_print
    print('  TOP-3: $topThree/$total ($topThreePercent%)');

    expect(topThree, total, reason: 'Top-3 must contain every expected name.');
    expect(
      topOne / total,
      greaterThanOrEqualTo(0.7),
      reason: 'Top-1 should stay above 70 percent.',
    );
  });

  test('close names are marked uncertain so the app can ask', () async {
    final aman = await matcher.match('aman');
    final amaan = await matcher.match('amaan');

    expect(aman.first.contact.name, 'Aman');
    expect(amaan.first.contact.name, 'Amaan');
    expect(matcher.isUncertain(aman), isTrue);
    expect(matcher.isUncertain(amaan), isTrue);
  });

  test('a name nobody said gets no confident match', () async {
    final results = await matcher.match('zebra crossing');
    final confident = results.where((result) => result.score >= 0.6);
    expect(confident, isEmpty);
  });

  test('a taught alias is checked before the real name', () async {
    final withAlias = NameMatcher(
      contacts: fakeContacts,
      aliasStore: const _OneAlias(),
    );
    final results = await withAlias.match('chotu');
    expect(results.first.contact.name, 'Rohit');
    expect(results.first.matchedName, 'chotu');
  });

  test('the uncertain helper rejects weak and missing guesses', () {
    expect(matcher.isUncertain(const <ContactCandidate>[]), isTrue);
  });
}

/// Teaches one nickname for the alias test.
class _OneAlias implements NameAliasSource {
  const _OneAlias();

  @override
  Future<List<String>> aliasesFor(String contactName) async {
    if (contactName == 'Rohit') return const <String>['chotu'];
    return const <String>[];
  }
}
