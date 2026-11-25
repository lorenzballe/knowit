/// Moments with a year, for the three challenges of time — In order, What
/// year? and Before or after? — read off the bank's own words: a card
/// whose question names, once, the year something happened ("In 1990
/// McDonald's stopped frying in beef fat…", "Chadwick's 1842 report…",
/// "the Arnolfini Portrait of 1434"). Nothing is written for the games:
/// the moment is the card's question, the year is the card's, and the
/// card is a tap away from the game.
///
/// A year counts only where the words around it say it is a date: "in
/// 1990", "of 1981", "October 2013", "a 1965 study". A year that bounds a
/// stretch ("since 1980", "before 1492", "by 2030"), a baseline ("than it
/// did in 1961"), a span ("1871–72", "the 1960s") or a title ("2001: A
/// Space Odyssey") does not. A true-or-false card lends its claim only
/// when the claim is true, so no game ever shows a false one as what
/// happened. Cards for grown-ups only and cards about a place are left
/// out, as on every shelf for everybody.
///
/// The rounds are dealt as everything on Explore is ([shelfHash]): the
/// same for everybody on the same day, afresh the next, and each round of
/// a day — a game played again — another.
library;

import '../models/pill.dart';
import 'explore_mix.dart' show claimOf, isTrueOrFalse, trueOrFalseAnswer;
import 'themed_shelves.dart' show shelfHash;

/// A moment: a card, the year it names, and its words either side of it.
class DatedLine {
  const DatedLine({
    required this.pill,
    required this.year,
    required this.before,
    required this.after,
    required this.statement,
  });

  final Pill pill;

  /// The year the card names.
  final int year;

  /// The card's words before the year, and after it.
  final String before;
  final String after;

  /// What happened, as a plain statement with its year taken out: what the
  /// games of time show until the year is told ("Phineas Gage later held a
  /// demanding job for years.").
  final String statement;

  /// The moment, its year in place.
  String get text => '$before$year$after';

  /// The moment with its year a gap: what the games show until it is told.
  String gapped(String gap) => '$before$gap$after';

  @override
  String toString() => 'DatedLine($year, ${pill.id})';
}

const String _months =
    'January|February|March|April|May|June|July|August|September|October|'
    'November|December';

final RegExp _year = RegExp(
  r'(?<![\d,.£$€#])\b(1[0-9]{3}|20[0-2][0-9])\b(?![\d,.]?\d)',
);

/// Words just before a year that make it a date.
final List<RegExp> _dateBefore = [
  RegExp(
    r'\b[Ii]n (?:(?:early|late|mid-?|the spring of|the summer of|'
    r'the autumn of|the fall of|the winter of|the year) )?'
    '(?:(?:$_months) )?'
    r'(?:\d{1,2} )?$',
  ),
  RegExp(r'\bof (?:(?:' + _months + r') )?$'),
  RegExp(r'\b(?:' + _months + r') (?:\d{1,2},? )?$'),
];

/// A year said as a thing's own ("a 1965 study", "Chadwick's 1842
/// report"): what comes before it, and the kinds of thing after it.
final RegExp _owner = RegExp(
  r"(?:\b(?:[Aa]n?|[Tt]he|[Hh]is|[Hh]er|[Ii]ts|[Tt]heir|[Tt]his|[Tt]hat)|"
  r"['’]s) $",
);
final RegExp _thing = RegExp(
  r'^ (?:[A-Za-z-]+ )?(?:study|studies|survey|trial|paper|report|experiment|'
  r'poll|census|election|law|act|ruling|verdict|speech|lecture|letter|film|'
  r'movie|album|single|song|novel|book|essay|edition|season|final|finals|'
  r'match|race|tournament|Olympics|Games|World Cup|championship|campaign|'
  r'rebrand|redesign|launch|mission|flight|landing|translation|lawsuit|case|'
  r'model|analysis|review|meta-analysis|guidelines|guideline|rules|rule|ban|'
  r'strike|crash|auction|sale|exhibition|show|record|treaty|decree|bill|'
  r'budget|reform|recall|outbreak|epidemic|pandemic|eruption|earthquake|'
  r'storm|hurricane|flood|fire|famine|war|revolution|protest|riot|'
  r'referendum|merger|deal|discovery|announcement|results|result|prize|'
  r'award|interview|broadcast|episode|poster|painting|portrait|photograph|'
  r'photo|map|patent|test|tests|audit|inquiry|investigation|hearing|'
  r'commission|conference|summit|meeting|debate|vote|cup|marathon|'
  r'expedition|voyage|visit|tour|concert|premiere|opening|blackout|heatwave|'
  r'drought|spill|collapse|scandal|hack|leak|attack|bombing|invasion|siege|'
  r'battle|coup|uprising|plague|catalogue|ranking|count|estimate|version|'
  r'update|decision|plan|proposal|policy|programme|program|project|scheme|'
  r'standard|definition)\b',
);

/// Words just before a year that make it a bound, a baseline or a span.
final RegExp _notBefore = RegExp(
  r'(?:\b(?:since|before|after|until|till|by|through|from|around|about|'
  r'circa|c\.|between|to|and|or|than|as of|as early as|as late as|up to|pre|'
  r'post|(?:have|has|had) been in|than in|than (?:it |they |we |he |she |'
  r'there )?(?:did|was|were|had|is|are) in|compared with|versus|vs\.?)\s*'
  '(?:(?:$_months) )?'
  r'(?:\d{1,2},? )?|[-–/])$',
);

/// Words just after a year that make it a span or a decade.
final RegExp _notAfter = RegExp(r'^(?:[-–/]\d|s\b|\s*(?:and|or|to|–|-)\s*\d)');

final Expando<_Read> _reads = Expando<_Read>('dated');

class _Read {
  const _Read(this.line);
  final DatedLine? line;
}

/// [pill] as a moment, or null when its question names no year as a date
/// — read once per card.
DatedLine? datedLineOf(Pill pill) =>
    (_reads[pill] ??= _Read(_read(pill))).line;

DatedLine? _read(Pill p) {
  if (p.mature || p.place != null) return null;
  String words = p.question;
  if (isTrueOrFalse(p)) {
    if (!trueOrFalseAnswer(p)) return null;
    words = claimOf(p);
  }
  final List<RegExpMatch> years = _year.allMatches(words).toList();
  if (years.length != 1) return null;
  final RegExpMatch m = years.single;
  final int year = int.parse(m.group(1)!);
  final String before = words.substring(0, m.start);
  final String after = words.substring(m.end);
  if (_notBefore.hasMatch(before) || _notAfter.hasMatch(after)) return null;
  final bool dated =
      _dateBefore.any((r) => r.hasMatch(before)) ||
      (_owner.hasMatch(before) && _thing.hasMatch(after));
  if (!dated) return null;
  final String? statement = statementOf(before, after);
  if (statement == null) return null;
  return DatedLine(
    pill: p,
    year: year,
    before: before,
    after: after,
    statement: statement,
  );
}

/// Where the year stands while a statement is made of the words round it.
const String _mark = '\u0000';

/// The moment as a plain statement, from the card's words [before] its
/// year and [after] it: the sentence that names the year, when it says
/// something rather than asks it, with the words that date it taken out —
/// "In 1990 McDonald's stopped frying in beef fat." becomes "McDonald's
/// stopped frying in beef fat." Null when the words make no clean
/// statement: the year in a question, said in a way not taken out, or a
/// sentence too short or too long to read at a glance.
String? statementOf(String before, String after) {
  final String words = '$before$_mark$after';
  final List<String> sentences = words.split(
    RegExp(r'(?<=[.?!])\s+(?=[A-Z0-9"“‘\u0000])'),
  );
  String? said;
  for (final String one in sentences) {
    if (one.contains(_mark)) said = one.trim();
  }
  if (said == null || !said.endsWith('.')) return null;
  const String season =
      r'(?:(?:early|late|mid-?|the spring of|the summer of|the autumn of|'
      r'the fall of|the winter of|the year) )?';
  final String month = '(?:(?:$_months) )?';
  const String day = r'(?:\d{1,2},? )?';
  String s = said
      // "In 1990, …" at the head of the sentence.
      .replaceFirst(
        RegExp('^[Ii]n $season$month$day$_mark,? '),
        '',
      )
      // "… in December 1996", "… of 1981", "… on 3 March 1979".
      .replaceFirst(
        RegExp(',? (?:in|of|on) $season$month$day$_mark'),
        '',
      )
      // "… March 3, 1979" with nothing before it.
      .replaceFirst(RegExp(' (?:$_months) (?:\\d{1,2},? )?$_mark'), '')
      // "a 1965 study", "Chadwick's 1842 report".
      .replaceFirst('$_mark ', '');
  if (s.contains(_mark)) return null;
  s = s
      // "an 1878 court case" without its year: "a court case".
      .replaceAllMapped(
        RegExp(r'\b([Aa])n (?=[bcdfgjklmnpqrstvwxyz])'),
        (m) => '${m[1]} ',
      )
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(' ,', ',')
      .replaceAll(',.', '.')
      .trim();
  if (s.length < 24 || s.length > 170) return null;
  if (RegExp(r'^[a-z]').hasMatch(s)) {
    s = s[0].toUpperCase() + s.substring(1);
  }
  // A statement left starting on a word that leans on what was taken out.
  if (RegExp(r'^(?:,|and |but |or |when |that )', caseSensitive: false)
          .hasMatch(s) ||
      // A place left alone at the head, its "In" gone with the year.
      RegExp(r'^[A-Z][a-z]+, ').hasMatch(s)) {
    return null;
  }
  return s;
}

/// The moments among [bank] no later than [latest]: a year still to come
/// is a plan, not a moment.
List<DatedLine> datedLines(Iterable<Pill> bank, {required int latest}) => [
  for (final Pill p in bank)
    if (datedLineOf(p) case final DatedLine d when d.year <= latest) d,
];

/// The three games of time.
enum TimeGame {
  /// Four moments, put in the order they happened.
  order(4, 'in-order'),

  /// Three moments, each missing its year, the year dialled in.
  year(3, 'what-year'),

  /// Six moments one after another, each before or after the one above.
  chain(6, 'before-after');

  const TimeGame(this.size, this.salt);

  /// How many moments a round has.
  final int size;

  /// What its deal is drawn with.
  final String salt;
}

/// The day's rounds of the three games of time, from [lines]: the same for
/// everybody given the same lines on the same day.
class TimeDeal {
  TimeDeal(this.lines, {required this.day});

  final List<DatedLine> lines;
  final int day;

  final Map<(TimeGame, int), List<DatedLine>> _rounds = {};

  /// Round [round] of [game] today, from 0: moments no other game's first
  /// round holds and none of its own earlier rounds held, while there are
  /// such; empty when the lines cannot make one.
  List<DatedLine> round(TimeGame game, int round) {
    final (TimeGame, int) key = (game, round);
    final List<DatedLine>? kept = _rounds[key];
    if (kept != null) return kept;
    final Set<String> taken = {
      // The first rounds are dealt in turn, so none shares a moment: one
      // game would tell another's years.
      for (final TimeGame g in TimeGame.values)
        if (g.index < game.index || (g != game && round > 0))
          for (final DatedLine d in this.round(g, 0)) d.pill.id,
      for (int r = 0; r < round; r++)
        for (final DatedLine d in this.round(game, r)) d.pill.id,
    };
    List<DatedLine> dealt = _deal(game, round, taken);
    // A long day of play: the moments start over.
    if (dealt.length < game.size) dealt = _deal(game, round, const {});
    return _rounds[key] = dealt.length < game.size ? const [] : dealt;
  }

  List<DatedLine> _deal(TimeGame game, int round, Set<String> taken) {
    final List<(int, DatedLine)> keyed = [
      for (final DatedLine d in lines)
        if (!taken.contains(d.pill.id))
          (shelfHash('$day:${game.salt}:$round:${d.pill.id}'), d),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final List<DatedLine> order = [for (final (_, d) in keyed) d];
    // The strictest round there is, then less strict: every subject
    // apart before two of one; and for a chain, each moment near enough
    // the one before to be a question.
    for (final bool apart in const [true, false]) {
      final List<DatedLine> got = switch (game) {
        TimeGame.chain => _chain(order, game.size, apart: apart),
        _ => _spread(order, game.size, apart: apart, gap: _gapOf(game)),
      };
      if (got.length == game.size) return got;
    }
    return _spread(order, game.size, apart: false, gap: 1);
  }

  static int _gapOf(TimeGame game) => switch (game) {
    // Four in order: far enough apart that the order is a thing known or
    // worked out, never a coin tossed between two years side by side.
    TimeGame.order => 5,
    // Three years to dial: no two in one decade.
    _ => 10,
  };

  /// [size] moments from [order], in it, every two [gap] years apart at
  /// the least, and with [apart] each from a subject of its own.
  static List<DatedLine> _spread(
    List<DatedLine> order,
    int size, {
    required bool apart,
    required int gap,
  }) {
    final List<DatedLine> out = [];
    for (final DatedLine d in order) {
      if (out.any((o) => (o.year - d.year).abs() < gap)) continue;
      if (apart && out.any((o) => o.pill.topic == d.pill.topic)) continue;
      out.add(d);
      if (out.length == size) break;
    }
    return out;
  }

  /// A chain of [size] moments from [order]: each a year or more from the
  /// one before it and at most a lifetime away, so before or after is
  /// worth asking; with [apart] each from a subject of its own.
  static List<DatedLine> _chain(
    List<DatedLine> order,
    int size, {
    required bool apart,
  }) {
    final List<DatedLine> out = [];
    for (int tries = 0; tries < 3 && out.length < size; tries++) {
      out.clear();
      for (final DatedLine d in order.skip(tries)) {
        if (out.any((o) => o.pill.id == d.pill.id || o.year == d.year)) {
          continue;
        }
        if (apart && out.any((o) => o.pill.topic == d.pill.topic)) continue;
        if (out.isNotEmpty) {
          final int gap = (out.last.year - d.year).abs();
          if (gap < 2 || gap > 80) continue;
        }
        out.add(d);
        if (out.length == size) break;
      }
    }
    return out.length == size ? out : const [];
  }
}

/// The points a year dialled at [guess] scores against [year], out of
/// ten: all ten for the year itself, none from as far off as a fifth of
/// the time since it — at the least ten years — so a date from the Middle
/// Ages is as fair a guess as one from last decade. [now] is this year.
int yearPoints(int guess, int year, {required int now}) {
  final int off = (guess - year).abs();
  if (off == 0) return 10;
  final double reach = ((now - year) / 5).clamp(10, 200).toDouble();
  final double left = 1 - off / reach;
  return left <= 0 ? 0 : (left * 10).floor().clamp(0, 9);
}
