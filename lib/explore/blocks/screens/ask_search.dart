/// The search behind "Ask first" (140e): a question in the reader's words,
/// answered by the cards that share the most of them.
///
/// The app's own search (searchPills, and the server's `search`) finds the
/// query inside a card's text, whole: "pizza" finds the pizza card, and
/// "Why does the same coffee taste so different?" finds nothing, because no
/// card says it in those words. A field that invites a question has to read
/// one, so this one takes the words that carry the meaning — not "why",
/// "does", "the" — brings each to its stem, and ranks the cards by how many
/// of them they hold, a word in the question or the keywords counting for
/// more than one in the answer. A card has to hold at least half of them,
/// and every one of a question of one or two words.
///
/// The bank is English, so the words that are passed over are English
/// first; the commonest small words of the app's other languages are passed
/// over too, so a question typed in them still finds the cards its names
/// and numbers point at.
library;

import 'dart:math' as math;

import '../../../data/pill_bank.dart';
import '../../../models/pill.dart';

/// Words that carry no meaning of their own in a question.
const Set<String> kAskStopWords = {
  // English.
  'the', 'and', 'why', 'how', 'what', 'when', 'where', 'who', 'whom',
  'which', 'whose', 'does', 'did', 'done', 'doing', 'are', 'was', 'were',
  'been', 'being', 'have', 'has', 'had', 'for', 'with', 'from', 'that',
  'this', 'these', 'those', 'you', 'your', 'yours', 'can', 'could', 'would',
  'should', 'will', 'shall', 'may', 'might', 'must', 'its', 'not', 'but',
  'they', 'them', 'their', 'there', 'then', 'than', 'into', 'onto', 'about',
  'any', 'some', 'all', 'our', 'out', 'too', 'very', 'just', 'get', 'gets',
  'got', 'one', 'ones', 'really', 'actually', 'much', 'many', 'more', 'most',
  'other', 'such', 'only', 'also', 'each', 'every', 'his', 'her', 'hers',
  'him', 'she', 'own', 'same', 'way', 'ever',
  // Italian, Spanish, Portuguese, French.
  'che', 'chi', 'per', 'con', 'una', 'uno', 'del', 'della', 'dei', 'delle',
  'gli', 'perché', 'come', 'cosa', 'quando', 'dove', 'sono', 'non', 'nel',
  'nella', 'qué', 'por', 'para', 'los', 'las', 'como', 'cómo', 'porque',
  'que', 'quoi', 'pourquoi', 'comment', 'les', 'des', 'est', 'une', 'dans',
  'pour', 'avec', 'sur', 'qui', 'não', 'uma', 'com', 'dos', 'das', 'mais',
  // German and Dutch ("was" is English's too, "das" Portuguese's).
  'warum', 'wie', 'der', 'die', 'und', 'ist', 'ein', 'eine', 'nicht',
  'mit', 'für', 'waarom', 'hoe', 'wat', 'het', 'een', 'van', 'voor', 'niet',
  'met', 'zijn',
};

/// A word brought to its stem: lower case, accents off, the commonest
/// English endings taken away, and no more than six letters kept, so
/// "onions" meets "onion", "studies" meets "study" and "accurate" meets
/// "accuracy".
String askStem(String word) {
  String w = _plainLetters(word.toLowerCase());
  if (w.length > 4 && w.endsWith('ies')) {
    w = '${w.substring(0, w.length - 3)}y';
  } else if (w.length > 4 &&
      w.endsWith('es') &&
      RegExp(r'(s|x|z|ch|sh)es$').hasMatch(w)) {
    w = w.substring(0, w.length - 2);
  } else if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) {
    w = w.substring(0, w.length - 1);
  }
  if (w.length > 5 && w.endsWith('ing')) {
    w = w.substring(0, w.length - 3);
  } else if (w.length > 4 && w.endsWith('ed')) {
    w = w.substring(0, w.length - 2);
  }
  return w.length > 6 ? w.substring(0, 6) : w;
}

const Map<String, String> _accents = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'æ': 'ae',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ø': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ß': 'ss',
  'œ': 'oe',
  'ł': 'l',
  'ś': 's',
  'ż': 'z',
  'ź': 'z',
  'ć': 'c',
  'ń': 'n',
  'ę': 'e',
  'ą': 'a',
  'ğ': 'g',
  'ş': 's',
  'ı': 'i',
};

String _plainLetters(String word) {
  if (!word.runes.any((r) => r > 127)) return word;
  final StringBuffer out = StringBuffer();
  for (final String ch in word.split('')) {
    out.write(_accents[ch] ?? ch);
  }
  return out.toString();
}

final RegExp _wordPattern = RegExp(r'[\p{L}\p{N}]+%?', unicode: true);

/// The stems in [text], each once, in the order met.
List<String> askWords(String text) {
  final List<String> out = [];
  for (final RegExpMatch m in _wordPattern.allMatches(text)) {
    final String raw = m.group(0)!.toLowerCase();
    if (kAskStopWords.contains(raw)) continue;
    final bool figure = RegExp(r'^\d').hasMatch(raw);
    if (!figure && raw.length < 3) continue;
    final String stem = figure ? raw : askStem(raw);
    if (stem.length < (figure ? 1 : 3) || out.contains(stem)) continue;
    out.add(stem);
  }
  return out;
}

/// The bank's cards by the stems they hold, built once for a bank and kept
/// until the bank in use changes.
class _Index {
  _Index(this.cards) {
    for (int i = 0; i < cards.length; i++) {
      final Pill p = cards[i];
      void add(String text, int weight) {
        for (final String stem in askWords(text)) {
          final Map<int, int> on = _postings.putIfAbsent(stem, () => {});
          if ((on[i] ?? 0) < weight) on[i] = weight;
        }
      }

      add(p.answer, 1);
      add(p.barMove, 1);
      add(p.topic, 2);
      add(p.keywords.join(' '), 3);
      add(p.question, 3);
    }
    _stems = _postings.keys.toList()..sort();
  }

  final List<Pill> cards;
  final Map<String, Map<int, int>> _postings = {};
  late final List<String> _stems;

  /// Every card holding [stem], or a longer word it begins (a stem of four
  /// letters or more: "accura" holds "accurate" and "accuracy"), with the
  /// weight of the field it is in.
  Map<int, int> holding(String stem) {
    final Map<int, int> out = Map.of(_postings[stem] ?? const {});
    if (stem.length < 4) return out;
    int lo = 0, hi = _stems.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (_stems[mid].compareTo(stem) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    for (int i = lo; i < _stems.length && _stems[i].startsWith(stem); i++) {
      for (final MapEntry<int, int> e in _postings[_stems[i]]!.entries) {
        if ((out[e.key] ?? 0) < e.value) out[e.key] = e.value;
      }
    }
    return out;
  }
}

_Index? _index;
List<Pill>? _indexedFrom;

_Index _indexOf(List<Pill> cards) {
  if (_index == null || !identical(_indexedFrom, cards)) {
    _indexedFrom = cards;
    _index = _Index(cards);
  }
  return _index!;
}

/// The cards that answer [question], best first: from every card still
/// dealt (PillBank.live) unless [cards] says otherwise, kept to those that
/// pass [keep] — the reader's place and subject — and at most [limit].
///
/// A word few cards hold says more about which card is meant than a word
/// half the bank holds: "onion" is a better clue than "make". So each word
/// counts by how rare it is, as well as by where in the card it was found.
List<Pill> askCards(
  String question, {
  List<Pill>? cards,
  bool Function(Pill)? keep,
  int limit = 30,
}) {
  final List<String> stems = askWords(question);
  if (stems.isEmpty) return const [];
  final _Index index = _indexOf(cards ?? PillBank.live);
  final Map<int, int> held = {};
  final Map<int, double> weight = {};
  for (final String stem in stems) {
    final Map<int, int> holding = index.holding(stem);
    final double rare = math.log(1 + index.cards.length / (1 + holding.length));
    for (final MapEntry<int, int> e in holding.entries) {
      held[e.key] = (held[e.key] ?? 0) + 1;
      weight[e.key] = (weight[e.key] ?? 0) + e.value * rare;
    }
  }
  final int needed = stems.length <= 2 ? stems.length : (stems.length + 1) ~/ 2;
  final List<int> found =
      [
        for (final MapEntry<int, int> e in held.entries)
          if (e.value >= needed) e.key,
      ]..sort((a, b) {
        final int heavier = weight[b]!.compareTo(weight[a]!);
        if (heavier != 0) return heavier;
        final int more = held[b]!.compareTo(held[a]!);
        return more != 0 ? more : a.compareTo(b);
      });
  final List<Pill> out = [];
  for (final int i in found) {
    final Pill p = index.cards[i];
    if (keep != null && !keep(p)) continue;
    out.add(p);
    if (out.length >= limit) break;
  }
  return out;
}
