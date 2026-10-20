/// Words from the server in place of the build's own: the `strings` part of
/// the remote document, one object per language of arb keys and the words
/// for them, `{"it": {"reminderAskTitle": "Quando te lo ricordiamo?"}}`.
///
/// Any string the app shows can be replaced, without a release. The words
/// are written as the arb files write theirs — `{name}` for a placeholder,
/// `{n, plural, =1{…} other{…}}`, `{store, select, apple{…} other{…}}` — and
/// read here exactly as `flutter gen-l10n` reads an arb file: the same
/// syntax (quotes are only quotes, as l10n.yaml leaves escaping off), the
/// same plural cases mapped the same way, and every placeholder formatted
/// as the build's own code formats it — numbers through the very same
/// NumberFormat, chosen by tool/remote/gen_strings.py from the arb's
/// metadata. Date and time arguments inside a message (`{d, date, ::yMd}`)
/// are the one piece of ICU no arb file uses; they are not read, and
/// tool/remote/parts/strings.py refuses them before they ship.
///
/// Words that do not read, or that ask for a placeholder the string does not
/// have, are refused one string at a time: that string is the build's own,
/// and every other is still the server's.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import 'remote.dart';

/// The server's words for one language in one document. Each is read the
/// first time it is asked for, and kept.
class RemoteWords {
  RemoteWords._(this.language, this._raw);

  /// The words [config] has for [language], or null when it has none.
  static RemoteWords? of(RemoteConfig config, String language) {
    final Object? all = config['strings'];
    if (all is! Map) return null;
    final Object? words = all[language];
    if (words is! Map) return null;
    final Map<String, String> raw = {
      for (final MapEntry<Object?, Object?> e in words.entries)
        if (e.key case final String key)
          if (e.value case final String text)
            if (text.trim().isNotEmpty) key: text,
    };
    return raw.isEmpty ? null : RemoteWords._(language, raw);
  }

  /// The language these words are in: `it`, `en`, …
  final String language;

  final Map<String, String> _raw;
  final Map<String, RemoteMessage?> _read = {};

  /// Whether the server has words for [key], read or not.
  bool has(String key) => _raw.containsKey(key);

  /// The server's words for [key], a string that takes no placeholders, or
  /// null for the build's own. Words with a brace in them are words written
  /// for a string that takes some: refused.
  String? text(String key) {
    final String? raw = _raw[key];
    if (raw == null) return null;
    if (raw.contains('{') || raw.contains('}')) {
      _refuse(key, 'it takes no placeholders');
      return null;
    }
    return raw;
  }

  /// The server's words for [key], with [args] in their places — or null
  /// for the build's own, when there are none or they do not read.
  ///
  /// [args] are the string's placeholders as the app passes them; [shown],
  /// when given, is how those the build formats are written, number by
  /// number, made only when the words are there to use it. [locale] is the
  /// one the build's own strings choose plural forms by.
  String? format(
    String key,
    String locale,
    Map<String, Object?> args, [
    Map<String, String> Function()? shown,
  ]) {
    if (!_raw.containsKey(key)) return null;
    final RemoteMessage? message = _read.putIfAbsent(key, () {
      final RemoteMessage? read = RemoteMessage.parse(_raw[key]!);
      if (read == null) {
        _refuse(key, 'it does not read');
      } else if (!args.keys.toSet().containsAll(read.names)) {
        _refuse(key, 'it names a placeholder the string does not have');
        return null;
      }
      return read;
    });
    if (message == null) return null;
    final String? said = message.render(
      locale,
      args,
      shown?.call() ?? const {},
    );
    if (said == null) _refuse(key, 'a placeholder is not what it asks for');
    return said;
  }

  final Set<String> _refused = {};

  void _refuse(String key, String why) {
    if (!_refused.add(key)) return;
    debugPrint(
      'Astute: the server\'s words for $language.$key are not used, as '
      '$why; the build\'s own are shown.',
    );
  }
}

/// One message, read as `flutter gen-l10n` reads one: text, `{name}`,
/// `{name, plural, …}` and `{name, select, …}`, nested as deep as they go.
@immutable
class RemoteMessage {
  const RemoteMessage._(this._pieces, this.names);

  final List<_Piece> _pieces;

  /// Every placeholder the message asks for, as text or to choose by.
  final Set<String> names;

  /// The message [text], or null when it does not read: a brace with no
  /// partner, a plural with a case no language has, a plural or a select
  /// with no `other`, a date or time argument.
  static RemoteMessage? parse(String text) {
    try {
      final _Reader reader = _Reader(text);
      final List<_Piece> pieces = reader.message(top: true);
      return RemoteMessage._(pieces, reader.names);
    } on FormatException {
      return null;
    }
  }

  /// The message with [args] in their places, a placeholder written as
  /// [shown] writes it where it does, and as itself otherwise. Plurals
  /// choose by [locale]'s rules, through the same Intl.pluralLogic the
  /// build's own strings call. Null when a placeholder is missing, or is
  /// not a number for a plural or a string for a select.
  String? render(
    String locale,
    Map<String, Object?> args,
    Map<String, String> shown,
  ) {
    final StringBuffer out = StringBuffer();
    return _write(_pieces, out, locale, args, shown) ? out.toString() : null;
  }

  static bool _write(
    List<_Piece> pieces,
    StringBuffer out,
    String locale,
    Map<String, Object?> args,
    Map<String, String> shown,
  ) {
    for (final _Piece piece in pieces) {
      switch (piece) {
        case _Text(:final String text):
          out.write(text);
        case _Arg(:final String name):
          if (!args.containsKey(name)) return false;
          out.write(shown[name] ?? '${args[name]}');
        case _Plural(
          :final String name,
          :final Map<String, List<_Piece>> cases,
        ):
          final Object? n = args[name];
          if (n is! num) return false;
          final List<_Piece> chosen = intl.Intl.pluralLogic<List<_Piece>>(
            n,
            locale: locale,
            zero: cases['zero'],
            one: cases['one'],
            two: cases['two'],
            few: cases['few'],
            many: cases['many'],
            other: cases['other']!,
          );
          if (!_write(chosen, out, locale, args, shown)) return false;
        case _Select(
          :final String name,
          :final Map<String, List<_Piece>> cases,
        ):
          final Object? choice = args[name];
          if (choice is! String) return false;
          final List<_Piece> chosen = intl.Intl.selectLogic<List<_Piece>>(
            choice,
            cases,
          );
          if (!_write(chosen, out, locale, args, shown)) return false;
      }
    }
    return true;
  }
}

sealed class _Piece {
  const _Piece();
}

final class _Text extends _Piece {
  const _Text(this.text);
  final String text;
}

final class _Arg extends _Piece {
  const _Arg(this.name);
  final String name;
}

final class _Plural extends _Piece {
  const _Plural(this.name, this.cases);
  final String name;

  /// By the category Intl.pluralLogic takes: `zero` … `other`.
  final Map<String, List<_Piece>> cases;
}

final class _Select extends _Piece {
  const _Select(this.name, this.cases);
  final String name;
  final Map<String, List<_Piece>> cases;
}

/// The plural cases gen-l10n takes, and the argument of Intl.pluralLogic
/// each goes to: `=1` and `one` are the same one, and in a message with
/// both the later wins.
const Map<String, String> _pluralCases = {
  '=0': 'zero',
  '=1': 'one',
  '=2': 'two',
  'zero': 'zero',
  'one': 'one',
  'two': 'two',
  'few': 'few',
  'many': 'many',
  'other': 'other',
};

/// Reads a message the way gen-l10n's lexer and grammar do
/// (flutter_tools' message_parser.dart): outside braces everything is text;
/// inside them, space between the parts is passed over, a name is letters,
/// digits and underscores, and a case's own words are a message again.
class _Reader {
  _Reader(this._s);

  final String _s;
  int _at = 0;
  final Set<String> names = {};

  static final RegExp _name = RegExp(r'[a-zA-Z0-9|_]+');
  static final RegExp _digits = RegExp(r'[0-9]+');
  static final RegExp _space = RegExp(r'\s+');

  List<_Piece> message({required bool top}) {
    final List<_Piece> pieces = [];
    final StringBuffer text = StringBuffer();
    while (_at < _s.length) {
      final String c = _s[_at];
      if (c == '{') {
        if (text.isNotEmpty) {
          pieces.add(_Text(text.toString()));
          text.clear();
        }
        _at++;
        pieces.add(_expression());
        continue;
      }
      if (c == '}') {
        if (top) throw const FormatException('a } with no { before it');
        break;
      }
      text.write(c);
      _at++;
    }
    if (text.isNotEmpty) pieces.add(_Text(text.toString()));
    return pieces;
  }

  _Piece _expression() {
    final String name = _token(_name, 'a placeholder');
    names.add(name);
    if (_take('}')) return _Arg(name);
    if (!_take(',')) throw FormatException('expected , or } after $name');
    final String kind = _token(_name, 'plural or select');
    if (kind != 'plural' && kind != 'select') {
      throw FormatException('$kind is neither plural nor select');
    }
    if (!_take(',')) throw FormatException('expected , after $kind');
    final Map<String, List<_Piece>> cases = {};
    while (!_take('}')) {
      final String key;
      if (kind == 'plural' && _take('=')) {
        key = '=${_token(_digits, 'a number after =')}';
      } else {
        key = _token(_name, 'a case');
      }
      if (!_take('{')) throw FormatException('expected { after $key');
      final List<_Piece> words = message(top: false);
      if (!_take('}')) throw FormatException('the case $key is not closed');
      if (kind == 'plural') {
        final String? category = _pluralCases[key];
        if (category == null) {
          throw FormatException('$key is not a plural case');
        }
        cases[category] = words;
      } else {
        cases[key] = words;
      }
    }
    if (!cases.containsKey('other')) {
      throw FormatException('$name has no other case');
    }
    return kind == 'plural' ? _Plural(name, cases) : _Select(name, cases);
  }

  /// Passes over space, then takes [what] if it is next.
  bool _take(String what) {
    _skipSpace();
    if (_s.startsWith(what, _at)) {
      _at += what.length;
      return true;
    }
    return false;
  }

  String _token(RegExp pattern, String expected) {
    _skipSpace();
    final Match? m = pattern.matchAsPrefix(_s, _at);
    if (m == null) throw FormatException('expected $expected at $_at');
    _at = m.end;
    return m.group(0)!;
  }

  void _skipSpace() {
    final Match? m = _space.matchAsPrefix(_s, _at);
    if (m != null) _at = m.end;
  }
}

/// Draws again whatever reads the app's words when a newer remote document
/// is taken up: `context.l10n` depends on it (lib/l10n/l10n.dart), so the
/// server's words for a screen reach it without the whole app being built
/// again. Placed once, above the navigator (main.dart); a widget pumped on
/// its own under test has none, and needs none.
class RemoteWordsScope extends InheritedNotifier<ValueNotifier<int>> {
  RemoteWordsScope({super.key, required super.child})
    : super(notifier: Remote.revision);

  /// Makes [context] depend on the document in use.
  static void watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RemoteWordsScope>();
}
