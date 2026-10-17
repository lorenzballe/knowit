/// Explore under the shelves that were always there: one form per kind of
/// card, picked from the canvas's versions (131 to 141) and dealt from the
/// bank as it is.
///
/// Nothing on these shelves is written for them. A month's subject is a
/// subject the bank already holds, a bet is laid on a card's own answer, a
/// chart is unmasked by the card that drew it, a story is played from the
/// card's own words. What the shelves add is only the way of meeting a card: on its
/// own, in a round, against a clock, as a bet, a beat at a time.
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
/// Cards that pass [first] are dealt before any that do not, each lot in
/// the day's order.
List<Pill> dealCards(
  Iterable<Pill> fits, {
  required String salt,
  required int day,
  int count = kThemeCards,
  int perTopic = 2,
  bool Function(Pill)? first,
}) {
  if (count <= 0) return [];
  int ahead(Pill p) => first != null && first(p) ? 0 : 1;
  final keyed = [for (final p in fits) (shelfHash('$day:$salt:${p.id}'), p)]
    ..sort((a, b) {
      final int lot = ahead(a.$2).compareTo(ahead(b.$2));
      return lot != 0 ? lot : a.$1.compareTo(b.$1);
    });
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

// ── True stories ─────────────────────────────────────────────────────────

/// Whether a card tells a story Explore can play, a beat at a time: one
/// written with a story to play ([StoryScene]), or one whose hook is a
/// story that happened in an age of its own — not a timeless one, which is
/// a fable, nor a debate, whose answer is one side of an argument rather
/// than what happened next.
bool tellsAStory(Pill p) =>
    p.scene is StoryScene ||
    (p.hook == 'story' &&
        p.era.isNotEmpty &&
        p.era != 'timeless' &&
        p.challenge is! TakeASide);

/// The day's true stories, from [pool]: the ones written with a story to
/// play first, since they are the better telling, then the stories cards
/// tell in their answers, each lot in the day's order and at most two from
/// a subject. Null when the pool has too few to make a shelf.
ThemedShelf? trueStories(Iterable<Pill> pool, {required int day}) {
  final List<Pill> cards = dealCards(
    pool.where(tellsAStory),
    salt: 'stories',
    day: day,
    first: (p) => p.scene is StoryScene,
  );
  return cards.length < kThemeMinimum
      ? null
      : ThemedShelf(ShelfTheme.stories, 0, cards);
}

/// The most sentences of an answer a story plays, each a beat of its own.
const int kStoryAnswerBeats = 5;

/// Words that end with a full stop without ending a sentence.
final Set<String> _notAnEnd = {
  ...'Mr Mrs Ms Dr St Mt Jr Sr Prof Gen Col Lt Capt Sgt Rev Gov Sen Inc Co '
          'Ltd No vs etc approx c ca Vol Fig e.g i.e'
      .split(' '),
};

/// [text] a sentence at a time. A sentence ends at a full stop, a question
/// mark or an exclamation mark with a capital, a figure or an opening quote
/// after it — but not at an initial (the E. in Joseph E. Levine, the W.K.
/// in W.K. Kellogg) or a title (Dr., St.).
List<String> sentencesOf(String text) {
  final String t = text.trim();
  final List<String> out = [];
  int from = 0;
  for (final RegExpMatch m in RegExp(
    r'([.!?…])["”’)\]]*\s+(?=["“‘(\[]?[A-Z0-9])',
  ).allMatches(t)) {
    if (m.group(1) == '.') {
      final String word =
          RegExp(r'(\S+)$').firstMatch(t.substring(from, m.start))?.group(1) ??
          '';
      final String bare = word.replaceFirst(RegExp(r'^["“‘(\[]+'), '');
      if (RegExp(r'^(?:[A-Z]\.)*[A-Z]$').hasMatch(bare) ||
          _notAnEnd.contains(bare)) {
        continue;
      }
    }
    out.add(t.substring(from, m.end).trim());
    from = m.end;
  }
  if (from < t.length) out.add(t.substring(from).trim());
  return [
    for (final s in out)
      if (s.isNotEmpty) s,
  ];
}

/// A card's story as its own words tell it: the question, which is the
/// hook, then the answer a sentence at a time. An answer of more sentences
/// than [kStoryAnswerBeats] has its shortest neighbours joined, so no beat
/// is a scrap and none runs on.
List<String> toldBeats(Pill p) {
  final List<String> said = sentencesOf(p.answer);
  while (said.length > kStoryAnswerBeats) {
    int at = 0;
    for (int i = 1; i < said.length - 1; i++) {
      if (said[i].length + said[i + 1].length <
          said[at].length + said[at + 1].length) {
        at = i;
      }
    }
    said.replaceRange(at, at + 2, ['${said[at]} ${said[at + 1]}']);
  }
  return [p.question, ...said];
}

/// How many beats a card's story plays: the stops of a story written to be
/// played, or the hook and the sentences of a story told in its answer.
int storyBeatCount(Pill p) => switch (p.scene) {
  final StoryScene s => s.stops,
  _ => toldBeats(p).length,
};

/// How long a beat stays up when a story plays itself: long enough to read
/// it unhurried, a second and a half to find the words and a little over a
/// quarter of a second a word after that, never under three seconds nor
/// over twelve.
int beatMs(String text) {
  final int words = RegExp(r'\S+').allMatches(text).length;
  return (1500 + words * 280).clamp(3000, 12000);
}

/// How long a card's story takes, played through on its own, in whole
/// minutes and never less than one: what its tile on the shelf says.
int storyMinutes(Pill p) {
  final int ms = switch (p.scene) {
    final StoryScene s => [
      for (final b in s.scenes) beatMs('${b.fact} ${b.line}'),
      // The question waits for an answer, which takes about this long.
      beatMs('${s.ask} ${s.options.join(' ')}'),
      beatMs('${s.outcome.fact} ${s.outcome.line} ${s.why}'),
    ].fold(0, (a, b) => a + b),
    _ => toldBeats(p).fold(0, (a, b) => a + beatMs(b)),
  };
  return (ms / 60000).ceil().clamp(1, 99);
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

// ── A year a question names ─────────────────────────────────────────────

/// The year a card's question names, when it names one: "1529", "the
/// 1820s". Only the question, so the year is never the answer given away.
String? questionYear(Pill p) {
  final m = RegExp(r'\b(1[0-9]{3}|20[0-4][0-9])(s)?\b').firstMatch(p.question);
  if (m == null) return null;
  return '${m.group(1)}${m.group(2) ?? ''}';
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
/// turn, so a card is on one shelf only: mostly in the order the screen
/// shows them, but the true stories first, since few cards are written as
/// a story to play and no other shelf plays them, and Use it today with the
/// cards to read, though the screen keeps it for last.
class ExploreMix {
  const ExploreMix({
    required this.monthSubjectKey,
    required this.month,
    required this.sixty,
    required this.numbers,
    required this.trueFalse,
    required this.spot,
    required this.practical,
    required this.debates,
    required this.work,
    required this.stories,
    required this.sharpest,
    required this.didYouKnow,
    required this.compared,
    required this.sampling,
    required this.unmask,
    required this.series,
    required this.moodPool,
    required this.origins,
    required this.whatIf,
    required this.howSure,
    required this.surprise,
  });

  final String monthSubjectKey;
  final List<Pill> month;
  final List<Pill> sixty;
  final ThemedShelf? numbers;
  final ThemedShelf? trueFalse;

  /// Three true claims and a false one, to spot under the true-or-false
  /// shelf; none of them is on it.
  final SpotTheFalse? spot;
  final ThemedShelf? practical;
  final ThemedShelf? debates;
  final WorkItOutDeal work;

  /// The cards that tell a story, played a beat at a time: those written
  /// with a story to play first (see [trueStories]).
  final ThemedShelf? stories;
  final ThemedShelf? sharpest;
  final List<Pill> didYouKnow;
  final List<Pill> compared;
  final List<Pill> sampling;
  final List<Pill> unmask;
  final List<Series> series;

  /// What "your mood, your minutes" deals from: what no shelf above took.
  final List<Pill> moodPool;
  final ThemedShelf? origins;
  final List<Pill> whatIf;
  final List<Pill> howSure;

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

  // The round is everybody's, read or not; the shelves below leave its eight
  // alone so no claim is met twice in a scroll.
  final sixty = sixtySeconds(bank, day: day);
  taken.addAll(sixty.map((p) => p.id));
  // The stories before anything else: the few written as a story to play
  // are every one of them a card some other shelf could take, and none of
  // the others plays it.
  final stories = claim(trueStories(left(), day: day));

  final String monthKey = monthSubject(on);
  final month = claim(
    dealCards(
      left().where((p) => subjectKeyOf(p) == monthKey),
      salt: 'month',
      day: day,
      perTopic: kThemeCards,
    ),
  );
  final numbers = claim(dealTheme(ShelfTheme.numbers, 0, left(), day));
  final trueFalse = claim(dealTheme(ShelfTheme.trueOrFalse, 0, left(), day));
  final spot = spotTheFalse(left(), day: day);
  taken.addAll([for (final p in spot?.cards ?? const <Pill>[]) p.id]);
  final practical = claim(dealTheme(ShelfTheme.practical, 0, left(), day));
  final debates = claim(dealTheme(ShelfTheme.debates, 0, left(), day));
  final work = workItOut(left(), day: day);
  taken.addAll(work.cards.map((p) => p.id));

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
  return ExploreMix(
    monthSubjectKey: monthKey,
    month: month,
    sixty: sixty,
    numbers: numbers,
    trueFalse: trueFalse,
    spot: spot,
    practical: practical,
    debates: debates,
    work: work,
    stories: stories,
    sharpest: sharpest,
    didYouKnow: dyk,
    compared: compared,
    sampling: sampling,
    unmask: unmask,
    series: series,
    moodPool: moodPool,
    origins: origins,
    whatIf: whatIf,
    howSure: howSure,
    surprise: pool,
  );
}

/// The topic key of a card, from the subject name it carries.
String subjectKeyOf(Pill p) => topicKeyForName(p.topic) ?? '';
