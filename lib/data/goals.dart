import '../models/pill.dart';
import 'pill_bank.dart';
import 'pills_repository.dart' show dealableOn;
import 'topics.dart';

/// How many goals a reader can hold at once: enough for a person's few
/// real aims, few enough that each still has its shelf and its lean.
const int kMostGoals = 3;

/// Where a reader wants to be sharper: the places in a life where being
/// astute pays, picked on the first run (screens/goal_screen.dart), up to
/// [kMostGoals], and changed in Profile. Not what they want to improve:
/// they came to Astute to be sharper, and that is every card. Where is what
/// the app could not know: money, work, people, the news, health, the
/// day's decisions.
///
/// Each gives Explore a shelf of its own, leans the mix of the deals towards
/// its subjects, is what the coach writes towards, and names itself on the
/// back of a card that belongs to it ("Useful for: Money and shopping").
///
/// An area is the genres that are about it (Life's People, Economics' Spot
/// a bad deal, Science's Spot bad science), the reasoning moves it trains,
/// and the subjects around it. A card counts for it when it is in one of
/// those genres, trains one of those moves or is about one of those
/// subjects, and is shown in that order: the genres first, as the closest
/// fit, then the moves, then the rest, each in an order of the day's own,
/// so the shelf is new every day.
///
/// The order is the order they are offered in: where being fooled costs the
/// most first.
enum Goal {
  money(
    'money',
    {
      'life.money_and_time',
      'economics.your_money_decisions',
      'economics.spot_a_bad_deal',
      'economics.money_and_banks',
      'economics.everyday_costs',
      'economics.read_money_news',
    },
    {Principle.exponential, Principle.regression, Principle.independence},
    {'economics', 'maths'},
  ),
  business(
    'business',
    {
      'life.work_and_career',
      'economics.think_in_incentives',
      'economics.pricing_tricks',
      'economics.markets_and_hype',
      'economics.work_and_wages',
    },
    {Principle.survivorship, Principle.exponential, Principle.sunkCost},
    {'economics', 'technology'},
  ),
  people(
    'people',
    {'life.people', 'life.relationships', 'life.ask_better_questions'},
    {Principle.confirmation, Principle.availability, Principle.anchoring},
    {'psychology', 'language', 'philosophy'},
  ),
  news(
    'news',
    {
      'science.spot_bad_science',
      'science.read_a_study',
      'science.numbers_and_chance',
      'science.how_science_knows',
      'economics.read_money_news',
    },
    {
      Principle.sampling,
      Principle.confounding,
      Principle.multipleComparisons,
      Principle.coincidence,
      Principle.simpson,
    },
    {'science', 'technology'},
  ),
  health(
    'health',
    {
      'life.habits',
      'food.food_claims',
      'food.eat_smarter',
      'medicine.judge_a_treatment',
      'medicine.medical_myths',
    },
    {},
    {'human_body', 'medicine', 'food', 'sport'},
  ),
  decide(
    'decide',
    {'life.decisions', 'life.clear_thinking', 'economics.your_money_decisions'},
    {
      Principle.sunkCost,
      Principle.baseRate,
      Principle.anchoring,
      Principle.conjunction,
      Principle.counterfactual,
      Principle.reflection,
    },
    {'thinking', 'psychology'},
  );

  const Goal(this.key, this.genres, this.moves, this.topics);

  /// How the goal is kept and sent: never changes.
  final String key;

  /// The genres about it, by id (lib/data/genres.dart).
  final Set<String> genres;

  /// The reasoning moves it trains.
  final Set<Principle> moves;

  /// The subjects around it, by key (lib/data/topics.dart).
  final Set<String> topics;

  /// The area kept under [key], or null. Spotting nonsense, a goal a
  /// build before offered, is the news; the others it offered (general
  /// knowledge, the world, calm, learning) are no area of this one.
  static Goal? of(String? key) {
    final String? k = key == 'nonsense' ? 'news' : key;
    for (final Goal g in Goal.values) {
      if (g.key == k) return g;
    }
    return null;
  }

  /// The area [p] pays off in, when it is one of the area's own (in its
  /// genres, or training one of its moves): the closest, and of two as
  /// close the first offered. A card that is only about one of an area's
  /// subjects is not named for it.
  static Goal? bestFor(Pill p) {
    Goal? best;
    int bestFit = 2;
    for (final Goal g in Goal.values) {
      final int? fit = g.fitOf(p);
      if (fit != null && fit < bestFit) {
        best = g;
        bestFit = fit;
        if (fit == 0) break;
      }
    }
    return best;
  }

  /// The names of its subjects, as the cards carry them.
  Set<String> get topicNames => {
    for (final String t in topics)
      if (kTopics[t] case final style?) style.name,
  };

  /// How close [p] comes to the goal: 0 in one of its genres, 1 training
  /// one of its moves, 2 about one of its subjects, null not at all.
  int? fitOf(Pill p) {
    if (genres.contains(p.genre)) return 0;
    if (moves.contains(p.principle)) return 1;
    if (topicNames.contains(p.topic)) return 2;
    return null;
  }

  /// Whether [p] counts for the goal.
  bool fits(Pill p) => fitOf(p) != null;

  /// The goal's cards for [day] that [read] does not hold, the closest
  /// first, each kind in the day's own order; [count] at most.
  List<Pill> cardsFor(DateTime day, Set<String> read, {int count = 10}) {
    final int seed = DateTime(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime(2026)).inDays;
    int mix(String id) {
      var h = 0x811c9dc5 ^ seed;
      for (final int c in id.codeUnits) {
        h ^= c;
        h = (h * 0x01000193) & 0xffffffff;
      }
      return h;
    }

    final List<(int, int, Pill)> pool = [
      for (final Pill p in PillBank.cards)
        if (!read.contains(p.id) && dealableOn(p, day))
          if (fitOf(p) case final int fit) (fit, mix(p.id), p),
    ];
    pool.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.compareTo(b.$2));
    return [for (final (_, _, p) in pool.take(count)) p];
  }
}
