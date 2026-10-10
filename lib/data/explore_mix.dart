/// Explore under the shelves that were always there: one form per kind of
/// card, picked from the canvas's versions (131 to 141) and dealt from the
/// bank as it is.
///
/// Nothing on these shelves is written for them. A month's subject is a
/// subject the bank already holds, a bet is laid on a card's own answer, a
/// chart is unmasked by the card that drew it, an age on the ruler is the
/// age the card is tagged with. What the shelves add is only the way of
/// meeting a card: on its own, in a round, against a clock, as a bet.
///
/// Everything here is dealt the way the turning themes are (see
/// themed_shelves.dart): in the day's order, the same on every phone, and
/// afresh the next day. Explore narrows the pool to the subject chosen and
/// to cards not read before it calls in, and claims each card for one shelf
/// only, so no card is on the screen twice.
library;

import '../models/pill.dart';
import 'genres.dart';
import 'themed_shelves.dart';
import 'topics.dart';

/// Deals [count] cards from [fits] in the day's order for [salt], at most
/// [perTopic] from one subject unless that would leave the shelf short.
List<Pill> dealCards(
  Iterable<Pill> fits, {
  required String salt,
  required int day,
  int count = kThemeCards,
  int perTopic = 2,
}) {
  final keyed = [for (final p in fits) (shelfHash('$day:$salt:${p.id}'), p)]
    ..sort((a, b) => a.$1.compareTo(b.$1));
  final picked = <Pill>[];
  final perSubject = <String, int>{};
  for (final (_, p) in keyed) {
    if ((perSubject[p.topic] ?? 0) >= perTopic) continue;
    picked.add(p);
    perSubject[p.topic] = (perSubject[p.topic] ?? 0) + 1;
    if (picked.length == count) return picked;
  }
  // Narrowed to one subject, the rule would leave a shelf of two.
  for (final (_, p) in keyed) {
    if (picked.length == count) break;
    if (!picked.contains(p)) picked.add(p);
  }
  return picked;
}

// ── A month of one subject ───────────────────────────────────────────────

/// The subject of the month, round every subject but Thinking one month at a
/// time, from Pop culture in October 2026. Spread by hand like the theme
/// cycle, so two months running are never two of a kind: a science beside a
/// story, never two sciences.
const List<String> kMonthSubjects = [
  'pop_culture',
  'space',
  'food',
  'history',
  'music',
  'nature',
  'psychology',
  'sport',
  'art',
  'science',
  'economics',
  'cinema',
  'human_body',
  'language',
  'technology',
  'philosophy',
  'weird_facts',
  'medicine',
  'life',
];

/// The topic key the month on [on] belongs to. The same for everybody, and
/// it turns over on the first of the month.
String monthSubject(DateTime on) {
  final int months = (on.year - 2026) * 12 + on.month - 10;
  return kMonthSubjects[months % kMonthSubjects.length];
}

// ── True or false ────────────────────────────────────────────────────────

/// Whether the card asks true or false, and nothing else.
bool isTrueOrFalse(Pill p) => fitsTheme(ShelfTheme.trueOrFalse, p);

/// The side of a true-or-false card that is right: true for "True".
bool trueOrFalseAnswer(Pill p) {
  final c = p.challenge as PickOne;
  return c.options[c.correct].toLowerCase() == 'true';
}

/// The index of "True" or "False" among a true-or-false card's options, so a
/// commitment made on the shelf is recorded the way the card itself takes it.
int trueOrFalseIndex(Pill p, bool sayTrue) {
  final c = p.challenge as PickOne;
  return c.options.indexWhere(
    (o) => o.toLowerCase() == (sayTrue ? 'true' : 'false'),
  );
}

/// The claim inside a true-or-false question, without its "True or false:"
/// — what a round against the clock shows, where the two buttons already ask.
String claimOf(Pill p) {
  final String q = p.question.replaceFirst(
    RegExp(r'^\s*true or false\s*[:,.]\s*', caseSensitive: false),
    '',
  );
  if (q.isEmpty) return p.question;
  final String head = q[0].toUpperCase() + q.substring(1);
  return head.endsWith('?') ? '${head.substring(0, head.length - 1)}.' : head;
}

/// The day's sixty-second round: eight claims, the same for everybody who
/// has the same subject chosen. Dealt from every true-or-false card, read or
/// not, because it is a round to play rather than a shelf to find things on.
List<Pill> sixtySeconds(Iterable<Pill> bank, {required int day}) => dealCards(
  bank.where(isTrueOrFalse),
  salt: 'sixty',
  day: day,
  count: 8,
  perTopic: 1,
);

// ── Spot the false one ───────────────────────────────────────────────────

/// Four claims from true-or-false cards, three true and one false, in the
/// order they are shown: the game under the true-or-false shelf.
class SpotTheFalse {
  const SpotTheFalse(this.cards);

  final List<Pill> cards;

  /// The one claim of the four that is not true.
  Pill get falseOne => cards.firstWhere((p) => !trueOrFalseAnswer(p));
}

/// The day's four claims to spot the false one among, from [pool]: one
/// false and three true, each from a subject of its own where the pool has
/// four, so the set is a round of general knowledge rather than a quiz on
/// one subject. Where the false one sits among them turns with the day,
/// like everything else here. Null when the pool cannot make a set.
SpotTheFalse? spotTheFalse(Iterable<Pill> pool, {required int day}) {
  final List<Pill> claims = pool.where(isTrueOrFalse).toList();
  final List<Pill> lies = dealCards(
    claims.where((p) => !trueOrFalseAnswer(p)),
    salt: 'spot-false',
    day: day,
    count: 1,
  );
  if (lies.isEmpty) return null;
  final Pill lie = lies.first;
  final List<Pill> truths = claims.where(trueOrFalseAnswer).toList();
  List<Pill> others = dealCards(
    truths.where((p) => p.topic != lie.topic),
    salt: 'spot-true',
    day: day,
    count: 3,
    perTopic: 1,
  );
  // Narrowed to one subject, every claim is the false one's subject.
  if (others.length < 3) {
    others = dealCards(truths, salt: 'spot-true', day: day, count: 3);
  }
  if (others.length < 3) return null;
  return SpotTheFalse(
    [...others, lie]..sort(
      (a, b) =>
          shelfHash('$day:spot:${a.id}')
              .compareTo(shelfHash('$day:spot:${b.id}')),
    ),
  );
}

// ── Numbers to work out ──────────────────────────────────────────────────

/// A card whose answer is a share, from 0 to 100: what the slider, the range,
/// the halving and the comparison are played on.
class PercentCard {
  const PercentCard(this.pill, this.value, this.said);

  final Pill pill;

  /// The answer, in per cent.
  final double value;

  /// The answer as the card itself puts it: "About 13%", "21 per cent".
  final String said;
}

final RegExp _percentOption = RegExp(
  r'^(?:about|around|roughly|nearly|almost|just over|just under|over|under|'
  r'less than|more than|some)?\s*(\d+(?:\.\d+)?)\s?(?:%|per ?cent)',
  caseSensitive: false,
);

const Set<String> _percentUnits = {'%', 'percent', 'per cent'};

/// The card's answer as a share, or null when it is not one.
PercentCard? percentOf(Pill p) {
  switch (p.challenge) {
    case TypeNumber(:final answer, :final unit) ||
        Estimate(:final answer, :final unit):
      if (!_percentUnits.contains(unit.trim().toLowerCase())) return null;
      if (answer < 0 || answer > 100) return null;
      final String n = answer == answer.roundToDouble()
          ? '${answer.round()}'
          : '$answer';
      return PercentCard(p, answer.toDouble(), '$n%');
    case PickOne(:final options, :final correct):
      // Every option a share, or the card is about something else.
      if (options.length < 3) return null;
      final values = <double>[];
      for (final o in options) {
        final m = _percentOption.firstMatch(o.trim());
        if (m == null) return null;
        values.add(double.parse(m.group(1)!));
      }
      final double v = values[correct];
      if (v > 100) return null;
      return PercentCard(p, v, options[correct]);
    default:
      return null;
  }
}

/// Whether every option of a pick-one card is a figure: a number to reach,
/// where the three options are three amounts.
bool isNumberPick(Pill p) {
  final c = p.challenge;
  if (c is! PickOne || c.options.length != 3) return false;
  if (isTrueOrFalse(p)) return false;
  return c.options.every((o) => RegExp(r'\d').hasMatch(o) && o.length <= 26);
}

/// Two shares on one card, for "which is bigger?": far enough apart that
/// the answer is a thing worked out, not a coin toss.
typedef BiggerPair = (PercentCard, PercentCard);

List<BiggerPair> biggerPairs(
  List<PercentCard> cards, {
  required int day,
  int count = 3,
}) {
  final keyed = [
    for (final c in cards) (shelfHash('$day:bigger:${c.pill.id}'), c),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final List<PercentCard> left = [for (final (_, c) in keyed) c];
  final out = <BiggerPair>[];
  final used = <String>{};
  for (int i = 0; i < left.length && out.length < count; i++) {
    final a = left[i];
    if (used.contains(a.pill.id)) continue;
    for (int j = i + 1; j < left.length; j++) {
      final b = left[j];
      if (used.contains(b.pill.id) || b.pill.topic == a.pill.topic) continue;
      if ((a.value - b.value).abs() < 8) continue;
      out.add((a, b));
      used
        ..add(a.pill.id)
        ..add(b.pill.id);
      break;
    }
  }
  return out;
}

/// The ways a number is played on "Work it out", each named on its card.
enum WorkKind { pick, slide, closer, bigger, range, stake }

/// How many cards each way of playing puts on the row: two of each makes a
/// row of a dozen, every way met twice.
const int kWorkEach = 2;

/// Everything "Work it out" is played with on a day: the cards for each way
/// of playing, none of them in two, and the one row they are laid out on.
class WorkItOutDeal {
  const WorkItOutDeal({
    required this.pick,
    required this.slide,
    required this.closer,
    required this.bigger,
    required this.range,
    required this.stake,
    required this.row,
  });

  /// Three amounts to choose from.
  final List<Pill> pick;

  /// A share to set on a slider, then check.
  final List<PercentCard> slide;

  /// A share to close in on, more or less, three times.
  final List<PercentCard> closer;

  /// Two shares, and which is bigger.
  final List<BiggerPair> bigger;

  /// A share to bet a range on: narrow pays more.
  final List<PercentCard> range;

  /// Three amounts, and a stake on one of them.
  final List<Pill> stake;

  /// The row as the shelf lays it out: each place a way of playing and which
  /// of its cards, in the day's order.
  final List<(WorkKind, int)> row;

  Iterable<Pill> get cards => [
    ...pick,
    for (final c in slide) c.pill,
    for (final c in closer) c.pill,
    for (final (a, b) in bigger) ...[a.pill, b.pill],
    for (final c in range) c.pill,
    ...stake,
  ];

  bool get isEmpty =>
      pick.isEmpty &&
      slide.isEmpty &&
      closer.isEmpty &&
      bigger.isEmpty &&
      range.isEmpty &&
      stake.isEmpty;
}

WorkItOutDeal workItOut(Iterable<Pill> pool, {required int day}) {
  final List<PercentCard> shares = [for (final p in pool) ?percentOf(p)];
  List<PercentCard> take(String salt, int n, Set<String> used) {
    final picked = dealCards(
      shares.where((c) => !used.contains(c.pill.id)).map((c) => c.pill),
      salt: salt,
      day: day,
      count: n,
      perTopic: 1,
    );
    used.addAll(picked.map((p) => p.id));
    return [
      for (final p in picked) shares.firstWhere((c) => c.pill.id == p.id),
    ];
  }

  final used = <String>{};
  final slide = take('slide', kWorkEach, used);
  final closer = take('closer', kWorkEach, used);
  final range = take('range', kWorkEach, used);
  final bigger = biggerPairs(
    shares.where((c) => !used.contains(c.pill.id)).toList(),
    day: day,
    count: kWorkEach,
  );
  for (final (a, b) in bigger) {
    used
      ..add(a.pill.id)
      ..add(b.pill.id);
  }
  final List<Pill> amounts = pool
      .where((p) => !used.contains(p.id) && isNumberPick(p))
      .toList();
  final pick = dealCards(amounts, salt: 'pick', day: day, count: kWorkEach);
  used.addAll(pick.map((p) => p.id));
  final stake = dealCards(
    amounts.where((p) => !used.contains(p.id)),
    salt: 'stake',
    day: day,
    count: kWorkEach,
  );
  return WorkItOutDeal(
    pick: pick,
    slide: slide,
    closer: closer,
    bigger: bigger,
    range: range,
    stake: stake,
    row: workRow({
      WorkKind.pick: pick.length,
      WorkKind.slide: slide.length,
      WorkKind.closer: closer.length,
      WorkKind.bigger: bigger.length,
      WorkKind.range: range.length,
      WorkKind.stake: stake.length,
    }, day: day),
  );
}

/// The order the row is laid out in: a round of every way of playing, then
/// another, each round in an order drawn for the day. Shuffled whole, a row
/// could open on three bets in a row; a round at a time, the first cards the
/// reader sees are every kind there is. Never two of a kind side by side,
/// where the seam of two rounds would put them so. The same on every phone
/// all day, and a different row the next.
List<(WorkKind, int)> workRow(Map<WorkKind, int> counts, {required int day}) {
  final out = <(WorkKind, int)>[];
  for (int round = 0; ; round++) {
    final kinds = [
      for (final k in WorkKind.values)
        if ((counts[k] ?? 0) > round) k,
    ];
    if (kinds.isEmpty) return out;
    kinds.sort(
      (a, b) =>
          shelfHash('$day:work:$round:${a.name}')
              .compareTo(shelfHash('$day:work:$round:${b.name}')),
    );
    if (out.isNotEmpty && kinds.length > 1 && kinds.first == out.last.$1) {
      kinds.add(kinds.removeAt(0));
    }
    out.addAll([for (final k in kinds) (k, round)]);
  }
}

// ── Through time ─────────────────────────────────────────────────────────

/// The ages the bank's cards are set in, oldest first: the stops on the
/// ruler. A card tagged timeless is on no stop.
const List<String> kEras = [
  'ancient',
  'medieval',
  'early_modern',
  'nineteenth',
  'twentieth',
  'recent',
];

/// The cards set in [era], dealt for the day.
List<Pill> eraCards(Iterable<Pill> pool, String era, {required int day}) =>
    dealCards(
      pool.where((p) => p.era == era),
      salt: 'era-$era',
      day: day,
      count: 6,
    );

/// The year a card's question names, when it names one: "1529", "the
/// 1820s". Only the question, so the year is never the answer given away.
String? questionYear(Pill p) {
  final m = RegExp(r'\b(1[0-9]{3}|20[0-4][0-9])(s)?\b').firstMatch(p.question);
  if (m == null) return null;
  return '${m.group(1)}${m.group(2) ?? ''}';
}

/// The year each age after the ancient world begins with. An age runs up to
/// the next one's first year and stops short of it, so 1500 is the early
/// modern age's first year rather than the Middle Ages' last, and a year
/// before 500, however far back, is the ancient world's.
const Map<String, int> kEraFrom = {
  'medieval': 500,
  'early_modern': 1500,
  'nineteenth': 1800,
  'twentieth': 1900,
  'recent': 2000,
};

/// A year before Christ, as the ruler counts years: 1 BC is year 0 and 2 BC
/// is -1, so the distance from one year to another is a subtraction, across
/// the change of era too. There was no year 0 in the calendar; there is one
/// here, and it is 1 BC.
int yearBc(int n) => 1 - n;

/// The age [year] falls in.
String eraOfYear(int year) {
  String era = kEras.first;
  for (final MapEntry<String, int> e in kEraFrom.entries) {
    if (year >= e.value) era = e.key;
  }
  return era;
}

final RegExp _yearBc = RegExp(r'\b(\d{1,4})\s?(?:BCE|BC|B\.C\.)');
final RegExp _yearAd = RegExp(
  r'\b(?:AD|CE)\s?(\d{1,4})\b|\b(\d{1,4})\s?(?:AD|CE)\b',
);
final RegExp _yearOf = RegExp(r'\b(1[0-9]{3}|20[0-4][0-9])(s)?\b');

/// The years a card's question names, first named first, as the span they
/// cover: 1529 is 1529 to 1529, the 1820s are 1820 to 1829, the 1500s the
/// whole century, 2 BC is -1 (see [yearBc]). Only the question, like
/// [questionYear], so the year is never the answer given away. Null when
/// it names none.
(int, int)? yearsNamed(Pill p) {
  final String q = p.question;
  // Each kind of year where it is first named, and the earliest kept. A year
  // given with its era is found by two patterns at the same place; the
  // era's, looked for first, is the one kept.
  (int, int, int)? first;
  if (_yearBc.firstMatch(q) case final RegExpMatch m) {
    final int y = yearBc(int.parse(m.group(1)!));
    first = (m.start, y, y);
  }
  if (_yearAd.firstMatch(q) case final RegExpMatch m
      when first == null || m.start < first.$1) {
    final int y = int.parse(m.group(1) ?? m.group(2)!);
    first = (m.start, y, y);
  }
  if (_yearOf.firstMatch(q) case final RegExpMatch m
      when first == null || m.start < first.$1) {
    final int y = int.parse(m.group(1)!);
    // A decade is ten years, and a decade that is a round hundred, the
    // 1500s, is the century.
    final int to = m.group(2) == null ? y : y + (y % 100 == 0 ? 99 : 9);
    first = (m.start, y, to);
  }
  return first == null ? null : (first.$2, first.$3);
}

/// The year a card's question names as the card says it: "1529", "the
/// 1820s" as "1820s", "2 BC", "AD 393". What the ruler's cards show large.
String? yearSaid(Pill p) {
  final String? year = questionYear(p);
  final String q = p.question;
  final RegExpMatch? bc = _yearBc.firstMatch(q);
  final RegExpMatch? ad = _yearAd.firstMatch(q);
  final RegExpMatch? old = switch ((bc, ad)) {
    (final RegExpMatch b, final RegExpMatch a) => b.start < a.start ? b : a,
    (final RegExpMatch b, null) => b,
    (null, final RegExpMatch a) => a,
    _ => null,
  };
  if (old == null) return year;
  final RegExpMatch? four = _yearOf.firstMatch(q);
  if (four != null && four.start < old.start) return year;
  return old.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// How many years [year] is from what [p]'s question names, nothing when
/// it falls inside a decade or a century the question names; null when the
/// question names no year in [era], so a restoration in the 1990s does not
/// pull a Renaissance card to the front of the last century.
int? yearsAway(Pill p, int year, {required String era}) {
  final (int, int)? span = yearsNamed(p);
  if (span == null) return null;
  final (int from, int to) = span;
  if (eraOfYear(from) != era && eraOfYear(to) != era) return null;
  if (year < from) return from - year;
  if (year > to) return year - to;
  return 0;
}

/// The cards of an age in the order a year typed on the ruler puts them:
/// those whose question names a year in the age, nearest first, and then
/// the rest as they came. Where two are as near, the day decides, so the
/// same year is not the same two cards every day.
List<Pill> nearestToYear(
  List<Pill> cards,
  int year, {
  required String era,
  required int day,
}) {
  final named = <(int, int, Pill)>[];
  final rest = <Pill>[];
  for (final Pill p in cards) {
    final int? away = yearsAway(p, year, era: era);
    if (away == null) {
      rest.add(p);
    } else {
      named.add((away, shelfHash('$day:year:${p.id}'), p));
    }
  }
  named.sort((a, b) {
    final int nearer = a.$1.compareTo(b.$1);
    return nearer != 0 ? nearer : a.$2.compareTo(b.$2);
  });
  return [for (final (_, _, p) in named) p, ...rest];
}

// ── A few cards in a row ─────────────────────────────────────────────────

/// What a series is about. The moves are the app's own principles; the
/// strand is one of the bank's, met easy first and hard last.
enum SeriesKind { odds, studies, growth, anchors, retold, strand }

class Series {
  const Series(this.kind, this.cards, {this.strand = ''});

  final SeriesKind kind;
  final List<Pill> cards;

  /// For [SeriesKind.strand]: the strand's name.
  final String strand;

  String get key => kind == SeriesKind.strand ? 'strand' : kind.name;
}

const Map<SeriesKind, Set<Principle>> _seriesMoves = {
  SeriesKind.odds: {
    Principle.baseRate,
    Principle.conditional,
    Principle.independence,
    Principle.coincidence,
    Principle.conjunction,
  },
  SeriesKind.studies: {
    Principle.sampling,
    Principle.survivorship,
    Principle.confounding,
    Principle.multipleComparisons,
    Principle.regression,
    Principle.simpson,
  },
  SeriesKind.growth: {Principle.exponential},
  SeriesKind.anchors: {Principle.anchoring, Principle.availability},
};

int _rank(Pill p) => switch (p.difficulty) {
  Difficulty.easy => 0,
  Difficulty.medium => 1,
  Difficulty.hard => 2,
};

/// Three series for the day, round the six kinds: each a handful of cards
/// that only make the point together, easiest first.
List<Series> seriesOfTheDay(Iterable<Pill> pool, {required int day}) {
  final List<Pill> all = pool.toList();
  Series? build(SeriesKind kind) {
    final List<Pill> fits;
    String strand = '';
    switch (kind) {
      case SeriesKind.retold:
        fits = [
          for (final p in all)
            if (p.hook == 'misconception' &&
                const {'ancient', 'medieval', 'early_modern'}.contains(p.era))
              p,
        ];
      case SeriesKind.strand:
        final byStrand = <String, List<Pill>>{};
        for (final p in all) {
          if (p.strand.isEmpty) continue;
          byStrand.putIfAbsent(p.strand, () => []).add(p);
        }
        final strands =
            byStrand.keys.where((k) => byStrand[k]!.length >= 4).toList()..sort(
              (a, b) =>
                  shelfHash('$day:strand:$a')
                      .compareTo(shelfHash('$day:strand:$b')),
            );
        if (strands.isEmpty) return null;
        strand = strandLabel(strands.first);
        fits = byStrand[strands.first]!;
      default:
        final moves = _seriesMoves[kind]!;
        fits = [
          for (final p in all)
            if (moves.contains(p.principle)) p,
        ];
    }
    final int n = kind == SeriesKind.growth || kind == SeriesKind.retold
        ? 3
        : 4;
    final cards = dealCards(
      fits,
      salt: 'series-${kind.name}',
      day: day,
      count: n,
    )..sort((a, b) => _rank(a).compareTo(_rank(b)));
    if (cards.length < 3) return null;
    return Series(kind, cards, strand: strand);
  }

  const kinds = SeriesKind.values;
  final int start = (day * 3) % kinds.length;
  final out = <Series>[];
  final used = <String>{};
  for (int i = 0; i < kinds.length && out.length < 3; i++) {
    final s = build(kinds[(start + i) % kinds.length]);
    if (s == null || s.cards.any((p) => used.contains(p.id))) continue;
    used.addAll(s.cards.map((p) => p.id));
    out.add(s);
  }
  return out;
}

/// A strand's own name, from its id.
String strandLabel(String strandId) {
  final genre = genreById(genreIdOf(strandId));
  for (final s in genre?.strands ?? const <Strand>[]) {
    if (s.id == strandId) return s.label;
  }
  final tail = strandId.split('.').last.replaceAll('_', ' ');
  return tail.isEmpty ? strandId : tail[0].toUpperCase() + tail.substring(1);
}

/// The genre a card sits in, by name: where the move hides, on a shelf that
/// shows one move met in many places.
String genreLabel(Pill p) => genreById(p.genre)?.label ?? p.topic;

/// A name as it reads inside a sentence: "In physics", "In what makes it
/// valuable", but still "In AI" — a word whose second letter is a capital
/// is an acronym and keeps its first.
String inSentence(String name) {
  if (name.length < 2) return name;
  final String second = name[1];
  if (second.toUpperCase() == second && second.toLowerCase() != second) {
    return name;
  }
  return name[0].toLowerCase() + name.substring(1);
}

// ── Time to spare ────────────────────────────────────────────────────────

/// The tones a reader can ask for, and the minutes they have.
enum Tone { curious, serious, light, tough }

const List<int> kMinutesYouHave = [1, 5, 15];

bool _inTone(Tone tone, Pill p) => switch (tone) {
  Tone.curious => p.mood == 'wonder',
  Tone.serious => p.mood == 'sober' || p.mood == 'dark',
  Tone.light => p.mood == 'playful',
  Tone.tough => p.difficulty == Difficulty.hard,
};

/// About how long a card takes to read and think through: a minute for most,
/// three at the most.
int minutesFor(Pill p) {
  final int words = '${p.question} ${p.answer}'.split(RegExp(r'\s+')).length;
  return (words / 60).ceil().clamp(1, 3);
}

/// The cards for a tone and the minutes there are: dealt in the day's order
/// and kept while they fit, so five minutes is five minutes.
List<Pill> forTheTime(
  Iterable<Pill> pool, {
  required Tone tone,
  required int minutes,
  required int day,
}) {
  final candidates = dealCards(
    pool.where((p) => _inTone(tone, p)),
    salt: 'mood-${tone.name}',
    day: day,
    count: 24,
  );
  final out = <Pill>[];
  int spent = 0;
  for (final p in candidates) {
    final int m = minutesFor(p);
    if (spent + m > minutes) continue;
    out.add(p);
    spent += m;
    if (spent >= minutes || out.length >= 9) break;
  }
  return out;
}

// ── The front page ───────────────────────────────────────────────────────

/// Today's edition: one lead, two columns, three numbers, a correction and a
/// puzzle. The same for everybody, read or not, which is what it says on it.
class FrontPage {
  const FrontPage({
    required this.lead,
    required this.columns,
    required this.numbers,
    required this.correction,
    required this.puzzle,
  });

  final Pill lead;
  final List<Pill> columns;
  final List<Pill> numbers;
  final Pill? correction;
  final Pill? puzzle;

  List<Pill> get cards => [lead, ...columns, ...numbers, ?correction, ?puzzle];
}

FrontPage? frontPage(Iterable<Pill> bank, {required int day}) {
  final List<Pill> all = bank.toList();
  final used = <String>{};
  List<Pill> take(Iterable<Pill> fits, String salt, int n) {
    final picked = dealCards(
      fits.where((p) => !used.contains(p.id)),
      salt: 'front-$salt',
      day: day,
      count: n,
      perTopic: 1,
    );
    used.addAll(picked.map((p) => p.id));
    return picked;
  }

  final lead = take(
    all.where(
      (p) =>
          p.barMove.isNotEmpty &&
          p.difficulty != Difficulty.easy &&
          p.question.length <= 130,
    ),
    'lead',
    1,
  );
  if (lead.isEmpty) return null;
  final columns = take(
    all.where((p) => p.question.length <= 120 && p.topic != lead.first.topic),
    'columns',
    2,
  );
  final numbers = take(
    all.where((p) => p.hook == 'number' && shelfFigure(p) != null),
    'numbers',
    3,
  );
  final correction = take(
    all.where((p) => p.hook == 'misconception'),
    'correction',
    1,
  );
  final puzzle = take(
    all.where((p) => p.challenge is TypeNumber && p.question.length <= 140),
    'puzzle',
    1,
  );
  return FrontPage(
    lead: lead.first,
    columns: columns,
    numbers: numbers,
    correction: correction.firstOrNull,
    puzzle: puzzle.firstOrNull,
  );
}

// ── The rest of the shelves ──────────────────────────────────────────────

/// Unmask the chart: the cards whose chart tells the truth in its numbers
/// and a lie in its drawing, and whose honest view this shelf can draw.
bool canUnmask(Pill p) {
  final s = p.scene;
  if (s is! TrickScene) return false;
  return switch (s.trick) {
    TrickSceneKind.truncated ||
    TrickSceneKind.stretched ||
    TrickSceneKind.window ||
    TrickSceneKind.flipped ||
    TrickSceneKind.totals => true,
    _ => false,
  };
}

/// "What if it's true?": ideas and arguments that keep working after the
/// card is closed, each with the question it leaves the reader.
bool keepsWorking(Pill p) =>
    p.ask.isNotEmpty &&
    (p.abstraction == 'abstract' || p.hook == 'paradox') &&
    p.challenge is! TakeASide;

/// "How sure am I, and why?": the cards about how a mind gets to a belief.
bool asksHowSure(Pill p) =>
    p.challenge is TakeASide ||
    const {
      Principle.confirmation,
      Principle.reflection,
      Principle.anchoring,
      Principle.availability,
    }.contains(p.principle);

/// "Did you know?": cards with nothing to answer, met as a fact and judged
/// new or known.
bool isPlainRead(Pill p) =>
    p.challenge is NoChallenge && p.answer.isNotEmpty && !p.mature;

/// The first sentence or two of an answer, enough to know whether it was
/// known: the rest is the card.
String firstLines(String answer, {int max = 180}) {
  final String text = answer.trim();
  final RegExp end = RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9"“‘(])');
  final parts = text.split(end);
  var out = parts.first;
  if (out.length < 60 && parts.length > 1) out = '$out ${parts[1]}';
  if (out.length > max) {
    final cut = out.substring(0, max);
    final int space = cut.lastIndexOf(' ');
    out = '${cut.substring(0, space > 0 ? space : max)}…';
  }
  return out;
}

// ── The whole mix ────────────────────────────────────────────────────────

/// Everything under the shelves that were always there, dealt for one day,
/// one subject and one reader's unread pool. Each shelf claims its cards in
/// the order the screen shows them, so a card is on one shelf only.
class ExploreMix {
  const ExploreMix({
    required this.monthSubjectKey,
    required this.month,
    required this.sixty,
    required this.myths,
    required this.numbers,
    required this.trueFalse,
    required this.spot,
    required this.practical,
    required this.debates,
    required this.work,
    required this.eras,
    required this.eraPool,
    required this.stories,
    required this.sharpest,
    required this.didYouKnow,
    required this.compared,
    required this.seen,
    required this.sampling,
    required this.unmask,
    required this.series,
    required this.moodPool,
    required this.origins,
    required this.whatIf,
    required this.howSure,
    required this.front,
    required this.surprise,
  });

  final String monthSubjectKey;
  final List<Pill> month;
  final List<Pill> sixty;
  final ThemedShelf? myths;
  final ThemedShelf? numbers;
  final ThemedShelf? trueFalse;

  /// Three true claims and a false one, to spot under the true-or-false
  /// shelf; none of them is on it.
  final SpotTheFalse? spot;
  final ThemedShelf? practical;
  final ThemedShelf? debates;
  final WorkItOutDeal work;

  /// The ages with cards, oldest first.
  final List<(String, List<Pill>)> eras;

  /// For each age on the ruler, the day's cards and then every other card
  /// of the age no shelf holds: what a year typed on the ruler looks in,
  /// since six cards seldom name the year somebody was born.
  final Map<String, List<Pill>> eraPool;
  final ThemedShelf? stories;
  final ThemedShelf? sharpest;
  final List<Pill> didYouKnow;
  final List<Pill> compared;
  final ThemedShelf? seen;
  final List<Pill> sampling;
  final List<Pill> unmask;
  final List<Series> series;

  /// What "your mood, your minutes" deals from: what no shelf above took.
  final List<Pill> moodPool;
  final ThemedShelf? origins;
  final List<Pill> whatIf;
  final List<Pill> howSure;
  final FrontPage? front;

  /// What "surprise me" deals from: every card not read.
  final List<Pill> surprise;
}

/// The day's mix. [bank] is every card in the subject chosen, for the
/// shelves that are the same for everybody; [pool] is the ones not read and
/// not on today's shelf, for the shelves that are for finding things.
ExploreMix dealExploreMix({
  required List<Pill> bank,
  required List<Pill> pool,
  required int day,
  required DateTime on,
}) {
  final taken = <String>{};
  List<Pill> left() => pool.where((p) => !taken.contains(p.id)).toList();
  T claim<T>(T dealt) {
    switch (dealt) {
      case ThemedShelf(:final pills):
        taken.addAll(pills.map((p) => p.id));
      case List<Pill> pills:
        taken.addAll(pills.map((p) => p.id));
    }
    return dealt;
  }

  final String monthKey = monthSubject(on);
  final month = claim(
    dealCards(
      left().where((p) => subjectKeyOf(p) == monthKey),
      salt: 'month',
      day: day,
      perTopic: kThemeCards,
    ),
  );
  // The round is everybody's, read or not; the shelves below leave its eight
  // alone so no claim is met twice in a scroll.
  final sixty = sixtySeconds(bank, day: day);
  taken.addAll(sixty.map((p) => p.id));

  final myths = claim(dealTheme(ShelfTheme.myths, 0, left(), day));
  final numbers = claim(dealTheme(ShelfTheme.numbers, 0, left(), day));
  final trueFalse = claim(dealTheme(ShelfTheme.trueOrFalse, 0, left(), day));
  final spot = spotTheFalse(left(), day: day);
  taken.addAll([for (final p in spot?.cards ?? const <Pill>[]) p.id]);
  final practical = claim(dealTheme(ShelfTheme.practical, 0, left(), day));
  final debates = claim(dealTheme(ShelfTheme.debates, 0, left(), day));
  final work = workItOut(left(), day: day);
  taken.addAll(work.cards.map((p) => p.id));

  final eras = <(String, List<Pill>)>[];
  for (final era in kEras) {
    final cards = claim(eraCards(left(), era, day: day));
    if (cards.length >= 2) eras.add((era, cards));
  }

  final stories = claim(dealTheme(ShelfTheme.stories, 0, left(), day));
  final sharpest = claim(dealTheme(ShelfTheme.sharpest, 0, left(), day));
  final dyk = claim(
    dealCards(left().where(isPlainRead), salt: 'dyk', day: day),
  );
  final compared = claim(
    dealCards(
      left().where((p) => p.principle == Principle.counterfactual),
      salt: 'move-counterfactual',
      day: day,
    ),
  );
  final seen = claim(dealTheme(ShelfTheme.seen, 0, left(), day));
  final sampling = claim(
    dealCards(
      left().where((p) => p.principle == Principle.sampling),
      salt: 'move-sampling',
      day: day,
    ),
  );
  // Few charts play a trick, so a reader who has read them all still gets
  // them here: unmasking one is not reading it.
  final List<Pill> unmaskable = left().where(canUnmask).toList();
  final unmask = claim(
    dealCards(
      unmaskable.length >= 3 ? unmaskable : bank.where(canUnmask),
      salt: 'unmask',
      day: day,
      count: 6,
      perTopic: 1,
    ),
  );
  final series = seriesOfTheDay(left(), day: day);
  for (final s in series) {
    taken.addAll(s.cards.map((p) => p.id));
  }
  final List<Pill> moodPool = left();
  final origins = claim(dealTheme(ShelfTheme.origins, 0, left(), day));
  final whatIf = claim(
    dealCards(left().where(keepsWorking), salt: 'what-if', day: day, count: 6),
  );
  final howSure = claim(
    dealCards(left().where(asksHowSure), salt: 'how-sure', day: day, count: 6),
  );
  // Last, from what no shelf took: a year typed on the ruler reaches past the
  // day's cards for an age without showing a card twice on the page.
  final List<Pill> unshelved = left();
  final eraPool = {
    for (final (era, cards) in eras)
      era: [
        ...cards,
        ...unshelved.where((p) => p.era == era).toList()..sort(
          (a, b) =>
              shelfHash('$day:era-pool:${a.id}')
                  .compareTo(shelfHash('$day:era-pool:${b.id}')),
        ),
      ],
  };
  return ExploreMix(
    monthSubjectKey: monthKey,
    month: month,
    sixty: sixty,
    myths: myths,
    numbers: numbers,
    trueFalse: trueFalse,
    spot: spot,
    practical: practical,
    debates: debates,
    work: work,
    eras: eras,
    eraPool: eraPool,
    stories: stories,
    sharpest: sharpest,
    didYouKnow: dyk,
    compared: compared,
    seen: seen,
    sampling: sampling,
    unmask: unmask,
    series: series,
    moodPool: moodPool,
    origins: origins,
    whatIf: whatIf,
    howSure: howSure,
    front: frontPage(bank, day: day),
    surprise: pool,
  );
}

/// The topic key of a card, from the subject name it carries.
String subjectKeyOf(Pill p) => topicKeyForName(p.topic) ?? '';
