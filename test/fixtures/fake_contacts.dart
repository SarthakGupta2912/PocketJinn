// What is this file for?
// Fake Indian contacts used only by unit tests. These are not real people and
// the numbers are deliberately invalid. Nothing here is ever sent to Android
// or added to the phone's real contact list.

import 'package:pocket_jinn/models/contact.dart';

/// One fake contact. Numbers start with 1000 so they cannot be real numbers.
const List<Contact> fakeContacts = [
  Contact(name: 'Sarthak Gupta', number: '1000000001'),
  Contact(name: 'Sarita Sharma', number: '1000000002'),
  Contact(name: 'Harpreet Singh', number: '1000000003'),
  Contact(name: 'Gurpreet Kaur', number: '1000000004'),
  Contact(name: 'Simran', number: '1000000005'),
  Contact(name: 'Vijay', number: '1000000006'),
  Contact(name: 'Vijaya', number: '1000000007'),
  Contact(name: 'Aman', number: '1000000008'),
  Contact(name: 'Amaan', number: '1000000009'),
  Contact(name: 'Ananya', number: '1000000010'),
  Contact(name: 'Anaya', number: '1000000011'),
  Contact(name: 'Rohit', number: '1000000012'),
  Contact(name: 'Rahul', number: '1000000013'),
  Contact(name: 'Priya', number: '1000000014'),
  Contact(name: 'Pooja', number: '1000000015'),
];

/// One spoken form and the contact it should find.
class FakeNameCase {
  const FakeNameCase({
    required this.spoken,
    required this.expected,
    required this.label,
  });

  /// What the speech engine heard, in Latin or Devanagari letters.
  final String spoken;

  /// The contact name that should be found.
  final String expected;

  /// Short note used in the accuracy report.
  final String label;
}

/// Correct spellings, misspellings and Devanagari forms to test.
const List<FakeNameCase> fakeNameCases = [
  FakeNameCase(
    spoken: 'call sarthak',
    expected: 'Sarthak Gupta',
    label: 'first name',
  ),
  FakeNameCase(
    spoken: 'sarthk',
    expected: 'Sarthak Gupta',
    label: 'misspelling',
  ),
  FakeNameCase(
    spoken: 'sarita',
    expected: 'Sarita Sharma',
    label: 'first name',
  ),
  FakeNameCase(
    spoken: 'harpreet',
    expected: 'Harpreet Singh',
    label: 'first name',
  ),
  FakeNameCase(
    spoken: 'harpreeth',
    expected: 'Harpreet Singh',
    label: 'misspelling',
  ),
  FakeNameCase(
    spoken: 'gurpreet',
    expected: 'Gurpreet Kaur',
    label: 'first name',
  ),
  FakeNameCase(spoken: 'simran', expected: 'Simran', label: 'exact'),
  FakeNameCase(spoken: 'vijay', expected: 'Vijay', label: 'exact'),
  FakeNameCase(spoken: 'vijai', expected: 'Vijay', label: 'misspelling'),
  FakeNameCase(spoken: 'vijaya', expected: 'Vijaya', label: 'exact'),
  FakeNameCase(spoken: 'aman', expected: 'Aman', label: 'exact'),
  FakeNameCase(spoken: 'amaan', expected: 'Amaan', label: 'exact'),
  FakeNameCase(spoken: 'ananya', expected: 'Ananya', label: 'exact'),
  FakeNameCase(spoken: 'anaya', expected: 'Anaya', label: 'exact'),
  FakeNameCase(spoken: 'rohit', expected: 'Rohit', label: 'exact'),
  FakeNameCase(spoken: 'rahul', expected: 'Rahul', label: 'exact'),
  FakeNameCase(spoken: 'priya', expected: 'Priya', label: 'exact'),
  FakeNameCase(spoken: 'pooja', expected: 'Pooja', label: 'exact'),
  FakeNameCase(
    spoken: 'सार्थक',
    expected: 'Sarthak Gupta',
    label: 'Devanagari',
  ),
  FakeNameCase(
    spoken: 'हरप्रीत',
    expected: 'Harpreet Singh',
    label: 'Devanagari',
  ),
  FakeNameCase(spoken: 'विजय', expected: 'Vijay', label: 'Devanagari'),
  FakeNameCase(spoken: 'अमन', expected: 'Aman', label: 'Devanagari'),
  FakeNameCase(spoken: 'पूजा', expected: 'Pooja', label: 'Devanagari'),
  FakeNameCase(spoken: 'प्रिया', expected: 'Priya', label: 'Devanagari'),
];
