/// Why one of today's cards is in front of the reader: the one reason its
/// front says, under its head, and the facts behind it that the sheet
/// shows when the line is tapped (lib/widgets/why_sheet.dart).
///
/// Every reason is one the deal weighed (lib/data/daily.dart), read from
/// the same facts the deal read them from: a card or a move come due again
/// on the review ladder, a move the reader keeps getting wrong, the goals
/// they picked, the cards they liked (on Astute+, where the deal leans by
/// them), their level in the subject, the subjects they kept on, where they
/// live, and on the free plan chance. Nothing is said that the deal did not
/// weigh, so the line is never flattery: a card dealt at random says so.
library;

import '../models/pill.dart';
import '../state/app_state.dart';
import 'goals.dart';
import 'pill_bank.dart';
import 'pills_repository.dart' show dateKey;
import 'skill_levels.dart' show skillMarkOf;
import 'skills.dart';
import 'topics.dart' show topicKeyForName;

/// The one reason a card gives, the most telling first.
enum WhyKind {
  /// A move the reader has met at least twice and got wrong more often than
  /// right, back in a card that came due.
  missing,

  /// A card, or the move it trains, come due again on the review ladder.
  again,

  /// The reader's own card that their Sunday adds to the day.
  sunday,

  /// It trains one of the skills the reader put in focus in What to learn
  /// (lib/data/skill_levels.dart): the line says which.
  skill,

  /// About one of the goals the reader picked: in one of its genres, or
  /// training one of its moves.
  goal,

  /// Like cards the reader liked: the same genre. On Astute+ only, where
  /// the deal leans by what was liked card by card.
  liked,

  /// A hard question, as the reader is strong in its subject.
  hard,

  /// A question at the reader's level in its subject.
  level,

  /// A card that tells rather than asks, for a reader starting out in its
  /// subject.
  gentle,

  /// From one of the subjects the reader kept on.
  subject,

  /// About where the reader lives. The card says so itself (placeLineOf), so
  /// no second line is drawn.
  place,

  /// Dealt at random from the reader's subjects, on the free plan.
  random,
}

/// The reader's level in a subject as the deal reads it.
enum WhyLevel {
  starting,
  some,
  strong;

  static WhyLevel of(int? level) => switch (level) {
    0 => starting,
    2 => strong,
    _ => some,
  };
}

/// Why [pill] is in front of the reader today, and what the sheet shows.
class CardWhy {
  const CardWhy({
    required this.kind,
    required this.pill,
    required this.level,
    this.goal,
    this.skill,
    this.liked = 0,
    this.mastery,
    this.lastMet,
  });

  final WhyKind kind;
  final Pill pill;

  /// The reader's level in the card's subject, as the deal read it.
  final WhyLevel level;

  /// The goal the card is about, when it is about one of the reader's.
  final Goal? goal;

  /// The skill in focus the card trains most closely, when it trains one.
  final Skill? skill;

  /// How many cards the reader liked are like it (the same genre), where
  /// the deal leans by them; 0 otherwise.
  final int liked;

  /// How the reader is doing on the move the card trains; null on a card
  /// that trains none.
  final Mastery? mastery;

  /// Days since the reader last answered a card training the same move;
  /// null when they never have, or the day was not kept.
  final int? lastMet;

  /// Whether the card came at random, where the day has cards that do.
  bool get random => kind == WhyKind.random;
}

/// Why [pill], one of today's cards, is there. [sunday] when it is the one
/// more of the reader's own their Sunday gives.
CardWhy whyOf(AppState app, Pill pill, {bool sunday = false}) {
  final Principle move = pill.principle;
  final Mastery? mastery = move.isReal ? app.masteryOf(move) : null;
  final String? subject = topicKeyForName(pill.topic);
  final WhyLevel level = WhyLevel.of(
    subject == null ? null : app.dealtLevels[subject],
  );
  final Goal? goal = _goalOf(app, pill);
  final Skill? skill = skillMarkOf(pill, app.skills);
  final int liked = app.isPlus ? _likedLike(app, pill) : 0;
  final int? lastMet = move.isReal ? _lastMet(app, move) : null;

  CardWhy said(WhyKind kind) => CardWhy(
    kind: kind,
    pill: pill,
    level: level,
    goal: goal,
    skill: skill,
    liked: liked,
    mastery: mastery,
    lastMet: lastMet,
  );

  if (app.reviewIdsToday.contains(pill.id)) {
    return said(
      mastery != null && mastery.isWeak ? WhyKind.missing : WhyKind.again,
    );
  }
  // The card about where the reader lives is never one of their own (Deal):
  // it is there because of where they live, on either plan.
  if (pill.place != null && !app.ownIdsToday.contains(pill.id)) {
    return said(WhyKind.place);
  }
  if (!app.isPlus && !app.ownIdsToday.contains(pill.id)) {
    return said(WhyKind.random);
  }
  if (sunday) return said(WhyKind.sunday);
  if (skill != null) return said(WhyKind.skill);
  if (goal != null) return said(WhyKind.goal);
  if (liked > 0) return said(WhyKind.liked);
  if (pill.asksSomething) {
    return said(
      level == WhyLevel.strong && pill.difficulty == Difficulty.hard
          ? WhyKind.hard
          : WhyKind.level,
    );
  }
  if (level == WhyLevel.starting) return said(WhyKind.gentle);
  return said(WhyKind.subject);
}

/// The reader's goal [pill] is about: in one of its genres, or training one
/// of its moves. A card only about one of a goal's subjects is not named for
/// it, as Explore does not name it either (Goal.bestFor).
Goal? _goalOf(AppState app, Pill pill) {
  Goal? best;
  int bestFit = 2;
  for (final String key in app.goals) {
    final Goal? g = Goal.of(key);
    final int? fit = g?.fitOf(pill);
    if (g != null && fit != null && fit < bestFit) {
      best = g;
      bestFit = fit;
    }
  }
  return best;
}

/// How many cards the reader liked share [pill]'s genre.
int _likedLike(AppState app, Pill pill) {
  if (pill.genre.isEmpty) return 0;
  int n = 0;
  for (final String id in app.likedIds) {
    if (id == pill.id) continue;
    if (PillBank.byId(id)?.genre == pill.genre) n++;
  }
  return n;
}

/// Days since the reader last answered a card training [move], from the
/// judgements that kept their card and day.
int? _lastMet(AppState app, Principle move) {
  for (final Judgement j in app.judgements.reversed) {
    final String? id = j.pillId;
    final String? on = j.on;
    if (id == null || on == null) continue;
    if (PillBank.byId(id)?.principle != move) continue;
    final DateTime? day = DateTime.tryParse(on);
    if (day == null) return null;
    final DateTime today = DateTime.parse(dateKey(app.today));
    return today.difference(day).inDays.clamp(0, 9999);
  }
  return null;
}
