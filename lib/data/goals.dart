import '../models/pill.dart';
import 'pill_bank.dart';
import 'pills_repository.dart' show dealableOn;
import 'topics.dart';

/// What a reader wants to get better at, as a person: the goal they pick on
/// Explore ("What do you want to get better at?"). It gives Explore a shelf
/// of its own, leans the mix of the deals towards its subjects, and is what
/// the coach writes towards.
///
/// A goal is a few subjects and a few reasoning moves: a card counts for it
/// when it is about one of its subjects or trains one of its moves. The
/// cards that train a move come first, then the rest, each in an order of
/// the day's own, so the shelf is new every day.
enum Goal {
  decide(
    'decide',
    {'thinking', 'psychology'},
    {
      Principle.sunkCost,
      Principle.baseRate,
      Principle.anchoring,
      Principle.conjunction,
      Principle.counterfactual,
      Principle.reflection,
    },
  ),
  people(
    'people',
    {'psychology', 'language', 'philosophy'},
    {Principle.confirmation, Principle.availability, Principle.anchoring},
  ),
  business(
    'business',
    {'economics', 'technology'},
    {Principle.survivorship, Principle.exponential, Principle.sunkCost},
  ),
  money(
    'money',
    {'economics', 'maths'},
    {Principle.exponential, Principle.regression, Principle.independence},
  ),
  nonsense(
    'nonsense',
    {'science', 'medicine'},
    {
      Principle.sampling,
      Principle.confounding,
      Principle.multipleComparisons,
      Principle.survivorship,
      Principle.coincidence,
      Principle.simpson,
    },
  ),
  health('health', {'human_body', 'medicine', 'food', 'sport'}, {}),
  culture('culture', {'history', 'art', 'cinema', 'music', 'philosophy'}, {}),
  world('world', {'science', 'space', 'nature', 'weird_facts'}, {});

  const Goal(this.key, this.topics, this.moves);

  /// How the goal is kept and sent: never changes.
  final String key;

  /// The subjects it is about, by key (lib/data/topics.dart).
  final Set<String> topics;

  /// The reasoning moves it trains.
  final Set<Principle> moves;

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

  /// Whether [p] counts for the goal.
  bool fits(Pill p) =>
      moves.contains(p.principle) || topicNames.contains(p.topic);

  /// The goal's cards for [day] that [read] does not hold: those that train
  /// one of its moves first, then the rest, each in the day's own order;
  /// [count] at most.
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

    final List<Pill> pool = [
      for (final Pill p in PillBank.cards)
        if (fits(p) && !read.contains(p.id) && dealableOn(p, day)) p,
    ];
    pool.sort((a, b) {
      final int byMove =
          (moves.contains(a.principle) ? 0 : 1) -
          (moves.contains(b.principle) ? 0 : 1);
      return byMove != 0 ? byMove : mix(a.id).compareTo(mix(b.id));
    });
    return pool.take(count).toList();
  }
}
