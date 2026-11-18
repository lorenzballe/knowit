import '../models/pill.dart';
import 'pill_bank.dart';
import 'pills_repository.dart' show dealableOn;
import 'topics.dart';

/// How many goals a reader can hold at once: enough for a person's few
/// real aims, few enough that each still has its shelf and its lean.
const int kMostGoals = 3;

/// What a reader wants to get better at, as a person: the goals they pick on
/// the first run (screens/goal_screen.dart), up to [kMostGoals], and can
/// change in Profile. Each gives Explore a shelf of its own, leans the mix
/// of the deals towards its subjects, and is what the coach writes towards.
///
/// A goal is the genres that are about it (Life's People, Decisions, Work
/// and career; Science's Spot bad science), the reasoning moves it trains,
/// and the subjects around it. A card counts for it when it is in one of
/// those genres, trains one of those moves or is about one of those
/// subjects, and is shown in that order: the genres first, as the closest
/// fit, then the moves, then the rest, each in an order of the day's own,
/// so the shelf is new every day.
///
/// The order is the order the goals are offered in: the aims a person
/// comes to an app like this with first (people, a business, money,
/// decisions), the wider ones after.
enum Goal {
  people(
    'people',
    {'life.people', 'life.relationships', 'life.ask_better_questions'},
    {Principle.confirmation, Principle.availability, Principle.anchoring},
    {'psychology', 'language', 'philosophy'},
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
  ),
  stress(
    'stress',
    {'life.handle_setbacks', 'life.meaning'},
    // A bad run tends back to the usual (regression), and what comes to
    // mind first is not what is likely (availability): the two moves that
    // take the most worry out of a week.
    {Principle.regression, Principle.availability},
    {'psychology', 'philosophy'},
  ),
  learn(
    'learn',
    {'life.learn_anything', 'life.time_and_attention', 'life.growth'},
    {},
    {'psychology', 'language'},
  ),
  nonsense(
    'nonsense',
    {
      'science.spot_bad_science',
      'science.read_a_study',
      'science.how_science_knows',
      'science.numbers_and_chance',
      'life.clear_thinking',
    },
    {
      Principle.sampling,
      Principle.confounding,
      Principle.multipleComparisons,
      Principle.survivorship,
      Principle.coincidence,
      Principle.simpson,
    },
    {'science', 'medicine'},
  ),
  health(
    'health',
    {'life.habits'},
    {},
    {'human_body', 'medicine', 'food', 'sport'},
  ),
  culture('culture', {}, {}, {
    'history',
    'art',
    'cinema',
    'music',
    'philosophy',
  }),
  world('world', {}, {}, {'science', 'space', 'nature', 'weird_facts'});

  const Goal(this.key, this.genres, this.moves, this.topics);

  /// How the goal is kept and sent: never changes.
  final String key;

  /// The genres about it, by id (lib/data/genres.dart).
  final Set<String> genres;

  /// The reasoning moves it trains.
  final Set<Principle> moves;

  /// The subjects around it, by key (lib/data/topics.dart).
  final Set<String> topics;

  /// The goal kept under [key], or null.
  static Goal? of(String? key) {
    for (final Goal g in Goal.values) {
      if (g.key == key) return g;
    }
    return null;
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
