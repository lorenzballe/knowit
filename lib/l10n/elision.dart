/// The word before a number, said the way the number is read.
///
/// Italian writes "il 71%" but "l’89%", "del 50%" but "dell’89%", "dei 234
/// giocatori" but "degli 8": the article takes the form it takes before the
/// number's first word, and some numbers are read with a vowel — 8 (otto),
/// 11 (undici), the eighties (ottanta…), the eight hundreds (ottocento…),
/// eight thousand (ottomila), eleven thousand… — and 1 (uno) as a share,
/// "l’1%". 18 is not: it is "diciotto", "il 18%". A day of the month 1 is
/// "il primo", "il 1° dicembre", so a 1 that is no share keeps its "il".
///
/// Spanish has one such word: "o" is "u" before a number read with an o,
/// "7 u 8", "u 11 h".
///
/// A string built round a number cannot know which number it will be
/// given, so the phrase is mended once it is built: [elideBeforeNumbers],
/// or `l.elided(…)` with the strings of the language in use.
library;

import 'app_localizations.dart';

/// [text] in [language] (`it`, `es`, …), with each article or conjunction
/// before a number in the form that number takes. Any other language, or
/// a text with no number, is returned as it is.
String elideBeforeNumbers(String text, String language) {
  if (!text.contains(_digit)) return text;
  return switch (language) {
    'it' => text.replaceAllMapped(_italianBefore, (m) {
      final String word = m[1]!;
      final _Number? n = _numberAt(m.input, m.end);
      if (n == null || !n.italianVowel) return m[0]!;
      final String lower = word.toLowerCase();
      final String? elided = _italianElided[lower];
      if (elided != null) return _cased(word, elided);
      // A plural article stays a word of its own: "degli 8 giocatori".
      return '${_cased(word, _italianPlural[lower]!)}${m[2]}';
    }),
    'es' => text.replaceAllMapped(_spanishOr, (m) {
      final _Number? n = _numberAt(m.input, m.end);
      if (n == null || !n.spanishO) return m[0]!;
      return '${m[1] == 'O' ? 'U' : 'u'}${m[2]}';
    }),
    _ => text,
  };
}

/// The strings' own language, mending the phrases they build round numbers.
extension Elision on AppLocalizations {
  /// [text], said in this language with each article before a number in
  /// the form that number takes ([elideBeforeNumbers]).
  String elided(String text) =>
      elideBeforeNumbers(text, localeName.split(RegExp('[_-]')).first);
}

final RegExp _digit = RegExp(r'\d');

/// An Italian article, or an article joined to a preposition, then a space
/// (a plain one, or one that does not break) and a digit.
final RegExp _italianBefore = RegExp(
  r'(?<![\p{L}\p{N}’'
  "'"
  r'])'
  r'(il|del|al|dal|nel|sul|i|dei|ai|dai|nei|sui)([  ])(?=\d)',
  caseSensitive: false,
  unicode: true,
);

/// The singular articles, joined to the number by an apostrophe.
const Map<String, String> _italianElided = {
  'il': 'l’',
  'del': 'dell’',
  'al': 'all’',
  'dal': 'dall’',
  'nel': 'nell’',
  'sul': 'sull’',
};

/// The plural ones, which take another form and keep their space.
const Map<String, String> _italianPlural = {
  'i': 'gli',
  'dei': 'degli',
  'ai': 'agli',
  'dai': 'dagli',
  'nei': 'negli',
  'sui': 'sugli',
};

/// Spanish "o", alone, then a space and a digit.
final RegExp _spanishOr = RegExp(
  r'(?<![\p{L}\p{N}])(o|O)([  ])(?=\d)',
  unicode: true,
);

/// [form] written as [word] is: capitalised when it is ("Il" is "L’"),
/// in capitals when it is all capitals ("DEL" is "DELL’").
String _cased(String word, String form) {
  if (word.length > 1 && word == word.toUpperCase()) {
    return form.toUpperCase();
  }
  if (word[0] != word[0].toLowerCase()) {
    return form[0].toUpperCase() + form.substring(1);
  }
  return form;
}

/// A number as written at [at] in [text]: its whole part, whether a decimal
/// part or a percent sign follows it. Thousands are grouped with a point or
/// a space; a comma is the decimal mark ("8.000", "8,5%").
_Number? _numberAt(String text, int at) {
  final Match? m = _written.matchAsPrefix(text, at);
  if (m == null) return null;
  final String whole = m[1]!.replaceAll(RegExp(r'[.   ]'), '');
  final int? value = int.tryParse(whole);
  if (value == null) return null;
  final String rest = text.substring(m.end);
  return _Number(
    value,
    share: m[2] != null || RegExp(r'^[   ]?%').hasMatch(rest),
  );
}

/// Digits, grouped by threes with a point or a space, then a decimal part.
final RegExp _written = RegExp(r'(\d{1,3}(?:[.   ]\d{3})+(?!\d)|\d+)(,\d+)?');

class _Number {
  const _Number(this.value, {required this.share});

  /// The whole part.
  final int value;

  /// Read as a share: a percent, or with a decimal part ("1,5").
  final bool share;

  /// Whether Italian reads it with a vowel first: "uno" only as a share.
  bool get italianVowel => value == 1 ? share : _eightOrEleven(value);

  /// Whether Spanish reads it with an o first: ocho, once, ochenta,
  /// ochocientos, ocho mil…
  bool get spanishO => _eightOrEleven(value);

  /// Whether [n] is read starting from eight or eleven, as both languages
  /// count: from its largest group down, a thousand, a million or a billion
  /// alone is "mille", "un milione", "mil"…, never a vowel, and any other
  /// count of them is said as that count is; under a thousand, eight
  /// hundred and some starts "otto…", "ocho…"; under a hundred, 8, 11 and
  /// the eighties do. 18 is "diciotto", "dieciocho".
  static bool _eightOrEleven(int n) {
    for (final int group in const [1000000000, 1000000, 1000]) {
      if (n >= group) {
        final int count = n ~/ group;
        return count != 1 && _eightOrEleven(count);
      }
    }
    if (n >= 100) return n ~/ 100 == 8;
    return n == 8 || n == 11 || (n >= 80 && n < 90);
  }
}
