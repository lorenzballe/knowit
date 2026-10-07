/// `sort`: sort the pile.
///
/// A short deck of slips, each one a thing the reader has an opinion about —
/// a word Swift wanted dead, a "fact" about goldfish, an event older or
/// younger than the pyramids — and two named piles to throw them on. The
/// reader swipes each slip left or right (or taps the pile), the slip turns
/// over to say where it really belongs in one line, and at the end the piles
/// settle with the wrong calls carried across to where they belong.
///
/// The teaching is in the wrong calls: a card of this kind is worth making
/// only when some of the slips sit in the pile most people would not guess.
///
/// JSON fields:
///
/// - `type`: `"sort"`.
/// - `left`, `right`: the two piles' names, a word or two each ("Dead",
///   "Alive"). Up to 12 characters. Swiping left puts a slip on `left`.
/// - `tag` (optional): the small line at the head of every slip, where the
///   slips come from ("The Tatler · No. 230"). Up to 26 characters.
/// - `items`: 4 to 8 slips, read in this order, each with:
///   - `text`: the thing itself, set large ("Bamboozle"). Up to 22 characters.
///   - `note` (optional): a line under it that says what it is, so the
///     reader judges the thing rather than guesses the word. Up to 70.
///   - `pile`: `"left"` or `"right"`, where it truly belongs.
///   - `verdict`: the one line on the back of the slip, the reason it is
///     where it is. Up to 84 characters.
///   Both piles must get at least one slip.
///
/// ```json
/// {
///   "type": "sort",
///   "left": "Dead",
///   "right": "Alive",
///   "tag": "The Tatler · No. 230",
///   "items": [
///     {"text": "Mobb", "note": "Short for mobile vulgus, the fickle crowd.",
///      "pile": "right", "verdict": "Mob is the plain word now."},
///     {"text": "Pozz", "note": "Short for positive, as in sure.",
///      "pile": "left", "verdict": "Nobody has been pozz of anything since."},
///     {"text": "Banter", "note": "A new word for teasing talk.",
///      "pile": "right", "verdict": "In every dictionary, and every pub."},
///     {"text": "Hipps", "note": "Short for hypochondria: low spirits.",
///      "pile": "left", "verdict": "Nobody gets the hipps any more."}
///   ]
/// }
/// ```
library;

import '../scene.dart';

/// Which pile: the one a left swipe makes, or the one a right swipe makes.
enum SortSide { left, right }

/// One slip of the deck.
class SortItem {
  final String text;
  final String note;
  final SortSide pile;
  final String verdict;
  const SortItem({
    required this.text,
    required this.note,
    required this.pile,
    required this.verdict,
  });
}

/// Swipe things into two piles.
class SortScene extends Scene {
  final String left;
  final String right;
  final String tag;
  final List<SortItem> items;

  const SortScene(
    super.raw, {
    required this.left,
    required this.right,
    required this.tag,
    required this.items,
  });

  /// The name of [side]'s pile.
  String nameOf(SortSide side) => side == SortSide.left ? left : right;

  static SortScene parse(Map<String, Object?> raw, Object? id) {
    String need(Map m, String k, String where) {
      final v = m[k];
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('$where.$k must be a non-empty string', id);
      }
      return v.trim();
    }

    final list = raw['items'];
    if (list is! List || list.length < 2) {
      throw FormatException('scene.items needs at least two slips', id);
    }
    final items = <SortItem>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final where = 'scene.items[$i]';
      if (m is! Map) throw FormatException('$where is not an object', id);
      final pile = switch (m['pile']) {
        'left' => SortSide.left,
        'right' => SortSide.right,
        _ => throw FormatException('$where.pile must be "left" or "right"', id),
      };
      items.add(
        SortItem(
          text: need(m, 'text', where),
          note: m['note'] is String ? (m['note'] as String).trim() : '',
          pile: pile,
          verdict: need(m, 'verdict', where),
        ),
      );
    }
    // A pile nobody can be right about is a deck with one answer.
    for (final side in SortSide.values) {
      if (!items.any((it) => it.pile == side)) {
        throw FormatException(
          'scene.items: no slip in the ${side.name} pile',
          id,
        );
      }
    }
    return SortScene(
      raw,
      left: need(raw, 'left', 'scene'),
      right: need(raw, 'right', 'scene'),
      tag: raw['tag'] is String ? (raw['tag'] as String).trim() : '',
      items: items,
    );
  }
}
