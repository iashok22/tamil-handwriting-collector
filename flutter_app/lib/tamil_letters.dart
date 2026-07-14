/// The 247 letters of the Tamil script (உயிர் + மெய் + உயிர்மெய் + ஆய்த எழுத்து),
/// generated from the base consonants and vowel signs rather than hand-typed,
/// since consonant + combining-vowel-sign concatenation is exactly how these
/// letters are represented in Unicode Tamil text.
library;

/// உயிர் எழுத்துக்கள் (12 independent vowels).
const List<String> _uyirVowels = [
  'அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ',
];

/// Combining vowel signs (உயிர்மெய் dependent forms), in the same order as
/// [_uyirVowels]. The empty string is the "அ" form: a bare consonant already
/// carries the inherent "அ" vowel, so no sign is appended.
const List<String> _vowelSigns = [
  '', 'ா', 'ி', 'ீ', 'ு', 'ூ', 'ெ', 'ே', 'ை', 'ொ', 'ோ', 'ௌ',
];

/// மெய் எழுத்துக்கள் (18 base consonants, before any vowel/pulli is applied).
const List<String> _meiBaseConsonants = [
  'க', 'ங', 'ச', 'ஞ', 'ட', 'ண', 'த', 'ந', 'ப', 'ம',
  'ய', 'ர', 'ல', 'வ', 'ழ', 'ள', 'ற', 'ன',
];

/// Pulli (virama, U+0BCD) — turns a base consonant into its "dead"/mெய் form.
const String _pulli = '்';

/// ஆய்த எழுத்து.
const String _aytham = 'ஃ';

/// All 247 Tamil letters: 12 உயிர் + 18 மெய் + 216 (18×12) உயிர்மெய் + 1 ஆய்தம்.
final List<String> tamilLetters = List.unmodifiable(_buildAllLetters());

List<String> _buildAllLetters() {
  final letters = <String>[
    ..._uyirVowels,
    for (final consonant in _meiBaseConsonants) '$consonant$_pulli',
    for (final consonant in _meiBaseConsonants)
      for (final sign in _vowelSigns) '$consonant$sign',
    _aytham,
  ];
  assert(letters.length == 247, 'Expected 247 Tamil letters, got ${letters.length}');
  assert(letters.toSet().length == letters.length, 'Duplicate letter generated');
  return letters;
}

/// A filesystem/URL-safe key for [letter]: its Unicode codepoints as
/// hex, joined by `-` (e.g. "கு" -> "0B95-0BC1"). Used as the storage
/// folder name so raw Tamil text never has to be used as a path segment.
String slugForLetter(String letter) {
  return letter.runes
      .map((codePoint) => codePoint.toRadixString(16).toUpperCase().padLeft(4, '0'))
      .join('-');
}

/// Reverse lookup from a slug (as returned by the /api/stats endpoint) back
/// to the displayable Tamil letter, for the analytics dashboard.
final Map<String, String> slugToLetter = Map.unmodifiable({
  for (final letter in tamilLetters) slugForLetter(letter): letter,
});
