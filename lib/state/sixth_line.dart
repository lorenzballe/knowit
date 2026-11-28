/// What the card after the fifth says, on the free plan: one true thing a
/// day, from the reader's own state, and beside it what Astute+ would have
/// done with that day. The same sale every evening, word for word, was a
/// card the reader learnt to throw unread; a sentence about their own day
/// is one they read.
///
/// The rules, all here, where the tests hold them:
///
/// - **True tonight.** Each thing is read off the day as it was dealt and
///   answered: the cards of the five that came at random ([SixthKind.today])
///   and of tomorrow's five that will ([SixthKind.tomorrow]); a card missed
///   at 80% sure or more today ([SixthKind.sure]); cards the reader got
///   wrong that are back and waiting in Explore, where Astute+ would deal
///   them in the five, one a day ([SixthKind.misses]); a subject whose
///   answers have measured the reader a level above the one the free plan
///   deals them at ([SixthKind.level]). A thing that is not true tonight is
///   not said.
/// - **One a day.** Said once, it is the day's: the shelf and the deck say
///   the same, and a relaunch does too (AppState.sixthSaid).
/// - **Never what the last day said.** The kinds come round in a turn, and
///   each day says the first true one after the last day's.
library;

import '../data/pill_bank.dart' show PillBank;
import '../data/pills_repository.dart' show dateKey;
import '../data/topics.dart' show topicKeyForName;
import '../models/pill.dart';
import 'app_state.dart';
import 'journey_record.dart' show kSureFrom;

/// The things the card can say.
enum SixthKind {
  /// Tomorrow's five, how many at random.
  tomorrow,

  /// A card missed today at 80% sure or more.
  sure,

  /// Cards got wrong, back and waiting in Explore.
  misses,

  /// Today's five, how many came at random.
  today,

  /// A subject measured a level above the one the free plan deals.
  level,
}

/// One thing the card says, with what it is made of.
class SixthLine {
  const SixthLine(this.kind, {this.n = 0, this.of = 0, this.subject});

  final SixthKind kind;

  /// The count it says: cards at random, cards waiting, how sure (in
  /// percent), or a subject's answers right.
  final int n;

  /// For [SixthKind.level], the answers [n] is of.
  final int of;

  /// For [SixthKind.level], the subject's key.
  final String? subject;

  /// How it is kept for the day, beside the day: `date|kind`.
  String keptAs(DateTime day) => '${dateKey(day)}|${kind.name}';

  @override
  bool operator ==(Object other) =>
      other is SixthLine &&
      other.kind == kind &&
      other.n == n &&
      other.of == of &&
      other.subject == subject;

  @override
  int get hashCode => Object.hash(kind, n, of, subject);

  @override
  String toString() => 'SixthLine(${kind.name}, $n of $of, $subject)';
}

/// The turn the kinds come round in: the clearest first, and the ones that
/// are true most evenings far apart, so most weeks say all of them.
const List<SixthKind> kSixthTurn = [
  SixthKind.tomorrow,
  SixthKind.sure,
  SixthKind.misses,
  SixthKind.today,
  SixthKind.level,
];

/// What is true tonight for [app]'s reader, by kind.
Map<SixthKind, SixthLine> sixthLinesOf(AppState app) {
  final Map<SixthKind, SixthLine> out = {};
  final int tomorrow = app.randomTomorrow;
  if (tomorrow > 0) {
    out[SixthKind.tomorrow] = SixthLine(SixthKind.tomorrow, n: tomorrow);
  }
  final int today = app.randomToday;
  if (today > 0) out[SixthKind.today] = SixthLine(SixthKind.today, n: today);
  final String day = dateKey(app.today);
  int? sure;
  for (final Judgement j in app.judgements) {
    final int? c = j.confidence;
    if (j.on != day || j.correct || c == null || c < kSureFrom) continue;
    if (sure == null || c > sure) sure = c;
  }
  if (sure != null) out[SixthKind.sure] = SixthLine(SixthKind.sure, n: sure);
  final int misses = [
    for (final r in app.reviewsWaitingWithAnswers)
      if (r.last.stage == 0) r,
  ].length;
  if (misses > 0) {
    out[SixthKind.misses] = SixthLine(SixthKind.misses, n: misses);
  }
  final SixthLine? level = levelAboveOf(app);
  if (level != null) out[SixthKind.level] = level;
  return out;
}

/// The subject [app]'s answers measure a level above the one the free plan
/// deals it at, among the reader's subjects — the one with the most
/// answers, then the most right — and how its latest answers went; null
/// when there is none. The level is measured as Astute+ measures it
/// (AppState.measuredLevels): of a subject's latest [AppState.kLevelSample]
/// answers, once there are [AppState.kLevelFloor], three in four right is
/// solid, two in five or fewer is starting out, and between is some.
SixthLine? levelAboveOf(AppState app) {
  final Map<String, int> free = app.profile.levelsUnder(app.topicLevels);
  final Map<String, List<bool>> recent = {};
  for (final Judgement j in app.judgements.reversed) {
    final String? id = j.pillId;
    final String? topic = id == null ? null : PillBank.byId(id)?.topic;
    final String? key = topic == null ? null : topicKeyForName(topic);
    if (key == null) continue;
    final List<bool> list = recent.putIfAbsent(key, () => []);
    if (list.length < AppState.kLevelSample) list.add(j.correct);
  }
  SixthLine? best;
  for (final MapEntry<String, List<bool>> e in recent.entries) {
    final List<bool> run = e.value;
    if (run.length < AppState.kLevelFloor) continue;
    if (!app.pickedTopics.contains(e.key)) continue;
    final int right = run.where((c) => c).length;
    final double share = right / run.length;
    final int measured = share >= 0.75
        ? 2
        : share <= 0.4
        ? 0
        : 1;
    if (measured <= (free[e.key] ?? 0)) continue;
    final SixthLine line = SixthLine(
      SixthKind.level,
      n: right,
      of: run.length,
      subject: e.key,
    );
    if (best == null ||
        line.of > best.of ||
        (line.of == best.of && line.n > best.n)) {
      best = line;
    }
  }
  return best;
}

/// What the card says today: what it said earlier today, while that is
/// still true; otherwise the first true thing after what it said the last
/// day it spoke, in [kSixthTurn]. Null only on an evening with nothing true
/// to say, which a day on the free plan never is.
SixthLine? sixthLineOf(AppState app) {
  final Map<SixthKind, SixthLine> lines = sixthLinesOf(app);
  if (lines.isEmpty) return null;
  final List<String> said = (app.sixthSaid ?? '').split('|');
  final SixthKind? last = said.length == 2
      ? SixthKind.values.asNameMap()[said[1]]
      : null;
  if (last != null && said[0] == dateKey(app.today)) {
    final SixthLine? kept = lines[last];
    if (kept != null) return kept;
  }
  final int from = last == null ? -1 : kSixthTurn.indexOf(last);
  for (int step = 1; step <= kSixthTurn.length; step++) {
    final SixthKind kind = kSixthTurn[(from + step) % kSixthTurn.length];
    if (kind == last && said[0] != dateKey(app.today)) continue;
    final SixthLine? line = lines[kind];
    if (line != null) return line;
  }
  return lines.values.first;
}
