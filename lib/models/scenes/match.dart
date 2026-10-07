/// `match`: pair them up.
///
/// Two short columns. On the left, ideas the reader has heard of (a bias, a
/// statistical trap, a business model); on the right, the everyday things
/// they explain, shuffled. The reader draws a line from each idea to the
/// thing it explains, by dragging from one to the other or by tapping one
/// and then its partner. Matching is the reasoning move: to pair "anchoring"
/// with the "was $400" tag the reader has to see the mechanism in the
/// situation, which is exactly the skill the card is teaching.
///
/// When every item has a partner the reader locks it in. The wrong lines
/// let go, the right column slides until every item sits beside its true
/// partner, and the lines redraw straight: a tangle becomes a ladder. Each
/// rung then has one line of explanation, and the pair the writer marks as
/// the one most people miss is the one held up first.
///
/// JSON fields:
///
/// - `type`: `"match"`.
/// - `leftTitle` (string, ≤ 16 chars): the small heading over the left
///   column ("Bias", "The trap").
/// - `rightTitle` (string, ≤ 18 chars): the heading over the right column
///   ("Where it gets you").
/// - `pairs` (3 to 5): each `{left, right, note, missed?}`, in true pairs.
///   - `left` (string, ≤ 24 chars, no word over 13): the idea, set large in
///     the serif ("Anchoring").
///   - `right` (string, ≤ 56 chars): what it explains, in plain words
///     ("The 'was $400' tag that makes $199 feel cheap").
///   - `note` (string, ≤ 90 chars): one line on why they belong together,
///     shown under the ladder when the pair is picked.
///   - `missed` (bool, optional): the pair most people get wrong. At most
///     one; the reveal opens on it.
/// - `order` (list of ints, optional): the order the right column is first
///   shown in, as pair indices from top to bottom. It must be a reordering
///   of `0..n-1`. Without it a fixed shuffle is used in which no item starts
///   beside its partner.
///
/// Example:
///
/// ```json
/// {
///   "type": "match",
///   "leftTitle": "Bias",
///   "rightTitle": "Where it gets you",
///   "pairs": [
///     {"left": "Anchoring",
///      "right": "The 'was $400' tag that makes $199 feel cheap",
///      "note": "The first number you see becomes the ruler for every one after it.",
///      "missed": true},
///     {"left": "Sunk cost",
///      "right": "Sitting through a bad film because the ticket was paid",
///      "note": "The money is gone either way. Only the next two hours are still yours."},
///     {"left": "Availability",
///      "right": "Fearing the flight more than the drive to the airport",
///      "note": "Crashes make the news; car deaths are too common to."}
///   ]
/// }
/// ```
library;

import '../scene.dart';

/// One true pair: an idea and what it explains.
class MatchScenePair {
  final String left;
  final String right;
  final String note;
  final bool missed;
  const MatchScenePair(this.left, this.right, this.note, this.missed);
}

/// Pair them up.
class MatchScene extends Scene {
  final String leftTitle;
  final String rightTitle;

  /// In true pairs: left item `i` belongs with right item `i`.
  final List<MatchScenePair> pairs;

  /// Pair indices in the order the right column is first shown, top first.
  final List<int> order;

  const MatchScene(
    super.raw, {
    required this.leftTitle,
    required this.rightTitle,
    required this.pairs,
    required this.order,
  });

  /// A fixed shuffle for each size in which nothing starts beside its
  /// partner, so the reader never begins with a free answer.
  static const matchSceneDefaultOrders = {
    3: [2, 0, 1],
    4: [2, 0, 3, 1],
    5: [3, 0, 4, 1, 2],
  };

  static MatchScene parse(Map<String, Object?> raw, Object? id) {
    String text(Map<Object?, Object?> m, String k, String where) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      throw FormatException('$where.$k must be a non-empty string', id);
    }

    final list = raw['pairs'];
    if (list is! List || list.length < 3 || list.length > 5) {
      throw FormatException('scene.pairs: between 3 and 5', id);
    }
    final pairs = <MatchScenePair>[];
    for (final m in list) {
      if (m is! Map) {
        throw FormatException('scene.pairs: each is {left, right, note}', id);
      }
      final missed = m['missed'];
      if (missed != null && missed is! bool) {
        throw FormatException('scene.pairs.missed must be true or false', id);
      }
      pairs.add(
        MatchScenePair(
          text(m, 'left', 'scene.pairs'),
          text(m, 'right', 'scene.pairs'),
          text(m, 'note', 'scene.pairs'),
          missed == true,
        ),
      );
    }
    if (pairs.where((p) => p.missed).length > 1) {
      throw FormatException('scene.pairs: at most one is missed', id);
    }
    String side(String k) => text(raw, k, 'scene');
    if (pairs.map((p) => p.left).toSet().length != pairs.length ||
        pairs.map((p) => p.right).toSet().length != pairs.length) {
      throw FormatException('scene.pairs: two items share a text', id);
    }

    final n = pairs.length;
    var order = matchSceneDefaultOrders[n]!;
    final given = raw['order'];
    if (given != null) {
      if (given is! List ||
          given.length != n ||
          given.any((v) => v is! int) ||
          given.toSet().length != n ||
          given.any((v) => (v as int) < 0 || v >= n)) {
        throw FormatException('scene.order: a reordering of 0..${n - 1}', id);
      }
      order = given.cast<int>();
    }
    return MatchScene(
      raw,
      leftTitle: side('leftTitle'),
      rightTitle: side('rightTitle'),
      pairs: pairs,
      order: List.unmodifiable(order),
    );
  }

  /// The pair the reveal opens on: the one the writer marked as most
  /// missed, else the first the reader got wrong, else the first.
  int focusFor(Map<int, int> guess) {
    final marked = pairs.indexWhere((p) => p.missed);
    if (marked >= 0) return marked;
    for (var i = 0; i < pairs.length; i++) {
      if (guess[i] != i) return i;
    }
    return 0;
  }
}
