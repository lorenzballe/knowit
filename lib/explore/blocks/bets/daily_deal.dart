/// The day's challenges, dealt from the date alone: Today's five at the top
/// of Explore for every subject, five cards each from another subject, and
/// Today's three at the top of each subject's page, three of that subject.
/// The same on every phone that holds the same cards, whatever its reader
/// has read: nothing here looks at the reader.
///
/// Each subject's cards stand round a circle, each at a place drawn from its
/// own id, and the day starts somewhere on it: the subject's three are the
/// first three cards after the start, and the fourth is the subject's card
/// in Today's five, on the days the five come to it. So the two never share
/// a card, a card added to the bank moves a day's cards only when it lands
/// among them, and a phone a bank behind deals what the others deal. The
/// start moves by the golden ratio from one day to the next, round the
/// whole circle, so it comes back near a card only after many days: about
/// a sixth as many days as the subject has cards.
library;

import '../../../data/explore_mix.dart' show subjectKeyOf;
import '../../../data/pill_bank.dart';
import '../../../data/pills_repository.dart' show dateKey;
import '../../../data/topics.dart';
import '../../../models/pill.dart';
import 'answers.dart';
import 'deal.dart' show answerOf;

/// How a card of the day's challenges is played.
enum DailyKind {
  /// One of two or three options, tapped and locked in.
  pick,

  /// A share from 0 to 100%, set on the track and locked in.
  share,
}

/// How [p] is played among the day's challenges, or null when it is not one
/// they can ask: a pick of two or three options, or a share the card has
/// typed or estimated. Not a card for grown-ups, whose page is its own, or
/// about a place, since the challenges are everybody's.
DailyKind? dailyKindOf(Pill p) {
  if (p.mature || p.web != null || p.isAboutAPlace || p.book != null) {
    return null;
  }
  switch (p.challenge) {
    case PickOne(:final options):
      return options.length >= 2 && options.length <= 3 ? DailyKind.pick : null;
    case TypeNumber() || Estimate():
      final BetAnswer? a = answerOf(p);
      return a != null && a.share && !a.isPick ? DailyKind.share : null;
    case NoChallenge() || TakeASide() || PageJudged():
      return null;
  }
}

/// The two games: the five on Explore for every subject, and each
/// subject's three.
enum DailyGameKind { five, three }

/// One of the day's games: which, on which day, for which subject.
class DailyGame {
  const DailyGame._(this.kind, this.day, this.subject);

  /// Today's five on [day].
  factory DailyGame.five(String day) =>
      DailyGame._(DailyGameKind.five, day, null);

  /// Today's three of [subject] (a key: `science`) on [day].
  factory DailyGame.three(String day, String subject) =>
      DailyGame._(DailyGameKind.three, day, subject);

  final DailyGameKind kind;

  /// The day, `yyyy-mm-dd` on the phone's calendar.
  final String day;

  /// The subject's key, for a subject's three.
  final String? subject;

  /// How many cards it asks.
  int get size => kind == DailyGameKind.five ? 5 : 3;

  /// The most it can score: a hundred a card.
  int get max => size * 100;

  /// What the server calls the game: `five` or `three`.
  String get name => kind.name;

  /// What the phone keeps the game's score under, beside the day:
  /// `five`, or `three-science`.
  String get id => subject == null ? name : '$name-$subject';

  /// The name the counts of everybody who played [ids] today are kept
  /// under (functions/src/daily.ts, gameKey): the day, the game and the
  /// cards, so two phones that were dealt different cards — one a bank
  /// behind — are never counted as one game.
  String keyFor(Iterable<String> ids) =>
      '$day~$name~${(ids.toList()..sort()).join(',')}';
}

/// The first day the days are counted from.
final DateTime _epoch = DateTime.utc(2026, 1, 1);

/// How far the start moves round each subject's circle from one day to the
/// next: the golden ratio's fraction, the step that leaves the fewest days
/// between two starts that fall close together.
const double _step = 0.6180339887498949;

/// [date] as a day number: days since the first of January 2026 on the
/// calendar, whatever the clocks did in between.
int dailyDayOf(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays;

/// The deal of the day's challenges.
abstract final class DailyDeal {
  static List<Pill>? _bank;
  static final Map<String, List<(double, Pill)>> _circles = {};
  static List<String>? _order;

  /// [subject]'s cards that can be played, round its circle: each at a
  /// place drawn from its id, in the order of their places. Worked out once
  /// for a bank.
  static List<(double, Pill)> _circle(String subject, List<Pill> bank) {
    if (!identical(bank, _bank)) {
      _bank = bank;
      _circles.clear();
    }
    return _circles[subject] ??= [
      for (final Pill p in bank)
        if (subjectKeyOf(p) == subject && dailyKindOf(p) != null)
          (betUnit('daily:${p.id}'), p),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
  }

  /// The subjects in the order Today's five comes to them: fixed, so every
  /// subject comes round as often as every other.
  static List<String> get _subjects => _order ??= kTopics.keys.toList()
    ..sort(
      (a, b) =>
          betUnit('daily-subject:$a').compareTo(betUnit('daily-subject:$b')),
    );

  /// The first [count] of [subject]'s cards after [date]'s start on its
  /// circle; fewer when it has fewer.
  static List<Pill> run(
    String subject,
    DateTime date,
    int count, {
    List<Pill>? bank,
  }) {
    final List<(double, Pill)> circle = _circle(
      subject,
      bank ?? PillBank.cards,
    );
    if (circle.isEmpty) return const [];
    final double turn =
        dailyDayOf(date) * _step + betUnit('daily-start:$subject');
    final double start = turn - turn.floorToDouble();
    int at = circle.indexWhere((c) => c.$1 >= start);
    if (at < 0) at = 0;
    return [
      for (int k = 0; k < count && k < circle.length; k++)
        circle[(at + k) % circle.length].$2,
    ];
  }

  /// Today's three of [subject] on [date]: the first three after the day's
  /// start. Fewer than three only for a subject without them.
  static List<Pill> three(DateTime date, String subject, {List<Pill>? bank}) =>
      run(subject, date, 3, bank: bank);

  /// Today's five on [date]: five subjects in their turn, five a day round
  /// the subjects, and from each its fourth card of the day, never one of
  /// its own three. A subject with too few cards gives its turn to the next.
  static List<Pill> five(DateTime date, {List<Pill>? bank}) {
    final List<String> order = _subjects;
    final int n = order.length;
    final int from = 5 * dailyDayOf(date);
    final List<Pill> out = [];
    for (int k = 0; out.length < 5 && k < n; k++) {
      final String subject = order[((from + k) % n + n) % n];
      final List<Pill> run = DailyDeal.run(subject, date, 4, bank: bank);
      if (run.length == 4) out.add(run[3]);
    }
    return out;
  }

  /// The day's key for [date] on the phone's calendar: `yyyy-mm-dd`.
  static String dayOf(DateTime date) => dateKey(date);
}
