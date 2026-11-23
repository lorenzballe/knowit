/// Explore without an end: after the shelves, the whole bank in the day's
/// order — the same on every phone, turning with the day, never chosen for
/// the reader — in a mosaic that goes on for as long as the reader scrolls.
/// Its bands take every shape the page has: one card across, two side by
/// side, a tall one beside two, and the cover's own, a large card three
/// fifths of the page beside two small ones, each on the left or on the
/// right. Which shape comes next is drawn by lot, the same lot on every
/// phone for the day and the subject in view: never the same shape twice in
/// a row, and the large ones in turn on either side, so the eye goes down
/// the page in a zigzag. A card read already is left out, and one about a
/// place reaches only the readers who live there, as on every shelf.
///
/// Standing last, the feed is drawn as a sliver of its own
/// ([EndlessBlock]), built a band at a time as each band comes near the
/// screen, so six thousand cards cost what the screen shows. Anywhere else
/// it is drawn as its first round of bands, since a section after an
/// endless one could never be reached.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/local_cards.dart' show reachesReader;
import '../../../data/pills_repository.dart' show dateKey, stableHash;
import '../../../models/pill.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The shapes a band of the feed takes.
enum FeedShape {
  /// One card across the page.
  across,

  /// Two side by side.
  pair,

  /// A tall one at the left, beside two.
  tallLeft,

  /// Two, beside a tall one at the right.
  tallRight,

  /// As the cover lays a group: a large card three fifths of the page at
  /// the left, two small ones one above the other beside it.
  coverLeft,

  /// The same, the large card at the right.
  coverRight;

  /// How many cards it holds.
  int get boxes => switch (this) {
    across => 1,
    pair => 2,
    _ => 3,
  };

  /// The side its large card stands on, for a shape with one: -1 the left,
  /// 1 the right, 0 none.
  int get side => switch (this) {
    tallLeft || coverLeft => -1,
    tallRight || coverRight => 1,
    _ => 0,
  };
}

/// How many bands make the feed's first round: what it shows when it is
/// not the last section.
const int kFeedRound = 6;

/// The order the feed's bands take, by lot: the same on every phone for the
/// same [seed] (the day and the subject in view), different from one day to
/// the next.
///
/// A shape is never the one before it again; a band with a large card puts
/// it on the other side from the last one that had one; one card across
/// comes at most once in four bands. Two side by side come up most, as the
/// breath between the large ones.
class FeedPattern {
  FeedPattern(String seed) : _state = stableHash('feed-shapes:$seed') | 1;

  int _state;
  final List<FeedShape> _shapes = [];

  /// How often each shape is drawn, against the others.
  static const Map<FeedShape, int> _weights = {
    FeedShape.pair: 6,
    FeedShape.coverLeft: 4,
    FeedShape.coverRight: 4,
    FeedShape.tallLeft: 3,
    FeedShape.tallRight: 3,
    FeedShape.across: 2,
  };

  /// The shape of band [index], the first 0.
  FeedShape shapeAt(int index) {
    while (_shapes.length <= index) {
      _shapes.add(_draw());
    }
    return _shapes[index];
  }

  FeedShape _draw() {
    final FeedShape? last = _shapes.isEmpty ? null : _shapes.last;
    int lastSide = 0;
    for (final FeedShape s in _shapes.reversed) {
      if (s.side != 0) {
        lastSide = s.side;
        break;
      }
    }
    final int tail = math.min(3, _shapes.length);
    final bool acrossLately = _shapes
        .sublist(_shapes.length - tail)
        .contains(FeedShape.across);
    final List<FeedShape> open = [
      for (final FeedShape s in FeedShape.values)
        if (s != last &&
            !(s.side != 0 && s.side == lastSide) &&
            !(s == FeedShape.across && acrossLately))
          s,
    ];
    final int total = open.fold(0, (n, s) => n + _weights[s]!);
    int ticket = _next() % total;
    for (final FeedShape s in open) {
      ticket -= _weights[s]!;
      if (ticket < 0) return s;
    }
    return open.last;
  }

  /// The next number of the lot: xorshift, the same on every platform.
  int _next() {
    int x = _state;
    x ^= (x << 13) & 0x7FFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0x7FFFFFFF;
    _state = x & 0x7FFFFFFF;
    if (_state == 0) _state = 1;
    return _state;
  }
}

/// The gap between two boxes, across and down.
const double kFeedSpacing = 8;

/// How the boxes of the feed measure on a page [across] points wide, less
/// its margins.
class FeedGrid {
  FeedGrid(this.across) : unit = math.max(0, (across - kFeedSpacing) / 2);

  /// The page's width, less its margins.
  final double across;

  /// Half the page: a column's width, and a row's height, in the bands of
  /// two columns.
  final double unit;

  /// The boxes of a band of [shape], in the order its cards are laid: the
  /// large one, where there is one, first.
  List<Rect> rectsOf(FeedShape shape) {
    const double gap = kFeedSpacing;
    final double right = unit + gap;
    switch (shape) {
      case FeedShape.across:
        return [Rect.fromLTWH(0, 0, across, unit)];
      case FeedShape.pair:
        return [
          Rect.fromLTWH(0, 0, unit, unit),
          Rect.fromLTWH(right, 0, unit, unit),
        ];
      case FeedShape.tallLeft:
        return [
          Rect.fromLTWH(0, 0, unit, unit * 2 + gap),
          Rect.fromLTWH(right, 0, unit, unit),
          Rect.fromLTWH(right, unit + gap, unit, unit),
        ];
      case FeedShape.tallRight:
        return [
          Rect.fromLTWH(right, 0, unit, unit * 2 + gap),
          Rect.fromLTWH(0, 0, unit, unit),
          Rect.fromLTWH(0, unit + gap, unit, unit),
        ];
      case FeedShape.coverLeft:
      case FeedShape.coverRight:
        // The cover's measures (lib/explore/blocks/core/cover_block.dart):
        // the large card three fifths of the page and as tall as a card on
        // a shelf of that width, the two small ones sharing its height.
        final double large = math.max(0, (across - gap) * 3 / 5);
        final double small = math.max(0, across - gap - large);
        final double tall = large / WebThumbs.shelfAspect;
        final double short = math.max(0, (tall - gap) / 2);
        final bool left = shape == FeedShape.coverLeft;
        final double bigX = left ? 0 : small + gap;
        final double smallX = left ? large + gap : 0;
        return [
          Rect.fromLTWH(bigX, 0, large, tall),
          Rect.fromLTWH(smallX, 0, small, short),
          Rect.fromLTWH(smallX, short + gap, small, short),
        ];
    }
  }

  /// How tall a band of [shape] is.
  double heightOf(FeedShape shape) =>
      rectsOf(shape).map((r) => r.bottom).reduce(math.max);
}

/// How a box of the feed draws its card: as its size says, except that a
/// tall box sets its question no larger than a box a third shorter would,
/// so a question in a narrow column reads as lines, not as a word to a line.
/// And never in small print: a question is set near the top of its box's
/// type, a headline to stop the thumb, as the cover sets its small tiles,
/// or it waits for a box that holds it so.
TileLook feedLook(Size box) {
  final TileLook look = box.height > box.width * 1.5
      ? TileLook.forBox(Size(box.width, box.width * 1.45))
      : TileLook.forBox(box);
  return look.withMin(math.max(look.min, math.max(look.max - 2, 12.5)));
}

/// The feed's cards as they are laid, band after band. A band is laid the
/// first time it is built and stays as it was laid, so a reader who
/// scrolls back finds what they left.
class FeedDeal {
  FeedDeal(this.pool, {required this.skip, String seed = ''})
    : pattern = FeedPattern(seed);

  /// The cards, in the day's order.
  final List<Pill> pool;

  /// The shapes its bands take, in turn.
  final FeedPattern pattern;

  /// The shape of band [index]: the one drawn for it, or the one it was
  /// laid in instead.
  FeedShape shapeAt(int index) => _instead[index] ?? pattern.shapeAt(index);

  /// The bands laid in another shape than the one drawn, by index.
  final Map<int, FeedShape> _instead = {};

  /// Whether a card is not for this feed: read already, or about a place
  /// the reader does not live in.
  final bool Function(Pill pill) skip;

  int _next = 0;

  /// The cards taken from the pool and not laid yet, in order: a card too
  /// long for this band's boxes waits for the next band.
  final List<Pill> _waiting = [];

  /// The bands laid so far, each its cards in its boxes' order (null where
  /// no card fitted).
  final List<List<Pill?>> bands = [];

  /// Every card laid so far, in the order laid: the cards a tap opens among.
  final List<Pill> laid = [];

  /// Whether a card of the pool is left that the feed could still lay.
  bool get hasAny {
    if (bands.isNotEmpty || _waiting.isNotEmpty) return true;
    return pool.skip(_next).any((p) => !skip(p));
  }

  /// The band at [index], laid now if it is the first time it is asked
  /// for (and every band before it, in turn); null once the pool is spent.
  List<Pill?>? band(
    BuildContext context,
    int index,
    FeedGrid grid, {
    required bool Function(Pill pill) isRead,
  }) {
    while (bands.length <= index) {
      final int at = bands.length;
      final FeedShape drawn = pattern.shapeAt(at);
      // The shape drawn, and where its boxes cannot all be filled at the
      // reader's text size (a question too long for every small box), a
      // shape of fewer boxes: never a band with a hole in it.
      final List<FeedShape> shapes = [
        drawn,
        if (drawn.boxes > 2) FeedShape.pair,
        if (drawn.boxes > 1) FeedShape.across,
      ];
      List<Pill?>? placed;
      FeedShape used = drawn;
      // A card that no box of the band holds whole, at the reader's text
      // size, gives way to the next, so the feed goes on rather than stop.
      for (int tries = 0; placed == null && tries < 40; tries++) {
        while (_waiting.length < drawn.boxes * 14 && _next < pool.length) {
          final Pill pill = pool[_next++];
          if (!skip(pill)) _waiting.add(pill);
        }
        if (_waiting.isEmpty) return null;
        List<Pill?>? partly;
        FeedShape? partlyShape;
        for (final FeedShape shape in shapes) {
          final List<Size> boxes = [
            for (final Rect r in grid.rectsOf(shape)) r.size,
          ];
          final List<Pill?> fitted = fitCards(
            context,
            _waiting,
            boxes,
            isRead: isRead,
            look: feedLook,
          );
          if (!fitted.contains(null)) {
            placed = _longestInBiggest(context, fitted, boxes, isRead);
            used = shape;
            break;
          }
          if (partly == null && fitted.any((p) => p != null)) {
            partly = fitted;
            partlyShape = shape;
          }
        }
        if (placed == null && partly != null) {
          used = partlyShape!;
          placed = _longestInBiggest(context, partly, [
            for (final Rect r in grid.rectsOf(used)) r.size,
          ], isRead);
        }
        if (placed == null) _waiting.removeAt(0);
      }
      if (used != drawn) _instead[at] = used;
      if (placed == null) return null;
      for (final Pill? pill in placed) {
        if (pill == null) continue;
        _waiting.remove(pill);
        laid.add(pill);
      }
      bands.add(placed);
    }
    return bands[index];
  }
}

/// [placed], with the longest question of the band in its biggest box, when
/// one box is bigger than the rest: a tall box filled by a question long
/// enough to fill it. The cards stay where they were when the reader's text
/// size would not let the two that change places both be set whole.
List<Pill?> _longestInBiggest(
  BuildContext context,
  List<Pill?> placed,
  List<Size> boxes,
  bool Function(Pill pill) isRead,
) {
  if (boxes.length < 2 || placed.any((p) => p == null)) return placed;
  double area(int i) => boxes[i].width * boxes[i].height;
  int big = 0;
  for (int i = 1; i < boxes.length; i++) {
    if (area(i) > area(big)) big = i;
  }
  if (List.generate(
        boxes.length,
        area,
      ).where((a) => (a - area(big)).abs() < 0.5).length >
      1) {
    return placed;
  }
  int longest = 0;
  for (int i = 1; i < placed.length; i++) {
    if (placed[i]!.question.length > placed[longest]!.question.length) {
      longest = i;
    }
  }
  if (longest == big) return placed;
  final List<Pill?> moved = List.of(placed)
    ..[big] = placed[longest]
    ..[longest] = placed[big];
  bool fits(int i) => questionFits(
    context,
    moved[i]!,
    boxes[i],
    feedLook(boxes[i]),
    read: isRead(moved[i]!),
  );

  return fits(big) && fits(longest) ? moved : placed;
}

/// The feed's deal for [section] as [host] deals it now: the whole bank in
/// the day's order, less what is not for this reader.
FeedDeal feedDeal(ExploreHost host, ExploreSection section) => FeedDeal(
  host.cardsFor(section),
  skip: (p) => host.isRead(p) || !reachesReader(p, host.app.place),
  seed: feedSeed(host, section),
);

/// What the lot of the feed's shapes is drawn by: the day, the section and
/// the subject in view, so the same page has the same shapes on every phone
/// all day, and another page, or tomorrow, others.
String feedSeed(ExploreHost host, ExploreSection section) =>
    '${dateKey(host.app.today)}|${section.id}|${host.subject ?? ''}';

/// The feed: see the library's own words.
class FeedBlock extends ExploreBlock
    with SectionLayout
    implements EndlessBlock {
  const FeedBlock();

  @override
  String get name => 'feed';

  /// Away from the end of the page, its first round of bands.
  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final FeedDeal deal = feedDeal(host, section);
    if (!deal.hasAny) return null;
    final FeedGrid grid = FeedGrid(_across(context));
    final List<Widget> bands = [];
    for (int i = 0; i < kFeedRound; i++) {
      final List<Pill?>? cards = deal.band(
        context,
        i,
        grid,
        isRead: host.isRead,
      );
      if (cards == null) break;
      bands.add(
        FeedBand(
          host: host,
          section: section,
          deal: deal,
          grid: grid,
          index: i,
          cards: cards,
        ),
      );
    }
    if (bands.isEmpty) return null;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Column(children: bands),
    );
  }

  @override
  Widget sliver(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) => FeedSliver(
    key: ValueKey('feed-${section.id}'),
    host: host,
    section: section,
  );
}

double _across(BuildContext context) =>
    math.max(0, MediaQuery.sizeOf(context).width - 40);

/// The feed standing last: its name and line, then its bands, each built
/// as it comes near the screen, for as long as the bank has cards.
class FeedSliver extends StatefulWidget {
  const FeedSliver({super.key, required this.host, required this.section});

  /// What the feed is drawn for, and with.
  final ExploreHost host;

  /// The feed's section.
  final ExploreSection section;

  @override
  State<FeedSliver> createState() => _FeedSliverState();
}

class _FeedSliverState extends State<FeedSliver> {
  FeedDeal? _deal;
  String? _dealtFor;

  /// The deal, kept for as long as the day, the subject in view and the
  /// bank are the same: a newer Explore, or a card read, leaves the bands
  /// where they were.
  FeedDeal _current() {
    final List<Pill> pool = widget.host.cardsFor(widget.section);
    final String key = [
      feedSeed(widget.host, widget.section),
      pool.length,
      for (final Pill p in pool.take(3)) p.id,
    ].join('|');
    if (_deal == null || key != _dealtFor) {
      _dealtFor = key;
      _deal = FeedDeal(
        pool,
        skip: (p) =>
            widget.host.isRead(p) || !reachesReader(p, widget.host.app.place),
        seed: feedSeed(widget.host, widget.section),
      );
    }
    return _deal!;
  }

  @override
  Widget build(BuildContext context) {
    final ExploreHost host = widget.host;
    final ExploreSection section = widget.section;
    final FeedDeal deal = _current();
    final FeedGrid grid = FeedGrid(_across(context));
    final String? title = section.title(host.language);
    final String? line = section.subtitle(host.language);
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        if (i == 0) {
          if (title == null && line == null) return const SizedBox.shrink();
          return host.watch(
            section,
            SectionFrame(title: title, line: line, child: const SizedBox()),
          );
        }
        final List<Pill?>? cards = deal.band(
          context,
          i - 1,
          grid,
          isRead: host.isRead,
        );
        if (cards == null) return null;
        return FeedBand(
          key: ValueKey('feed-band-${i - 1}'),
          host: host,
          section: section,
          deal: deal,
          grid: grid,
          index: i - 1,
          cards: cards,
        );
      }),
    );
  }
}

/// One band of the feed, its cards in its boxes.
class FeedBand extends StatelessWidget {
  const FeedBand({
    super.key,
    required this.host,
    required this.section,
    required this.deal,
    required this.grid,
    required this.index,
    required this.cards,
  });

  final ExploreHost host;
  final ExploreSection section;
  final FeedDeal deal;
  final FeedGrid grid;

  /// Which band of the feed it is, the first 0.
  final int index;

  /// Its cards, in its boxes' order.
  final List<Pill?> cards;

  @override
  Widget build(BuildContext context) {
    final List<Rect> boxes = grid.rectsOf(deal.shapeAt(index));
    for (final Pill? pill in cards) {
      if (pill != null) host.seen(section, pill);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : kFeedSpacing, 20, 0),
      child: SizedBox(
        height: grid.heightOf(deal.shapeAt(index)),
        child: Stack(
          children: [
            for (int b = 0; b < boxes.length; b++)
              if (cards[b] case final Pill pill)
                Positioned(
                  left: boxes[b].left,
                  top: boxes[b].top,
                  child: GestureDetector(
                    key: ValueKey('explore-${pill.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => host.open(section, List.of(deal.laid), pill),
                    child: BoxTile(
                      pill: pill,
                      box: boxes[b].size,
                      read: host.isRead(pill),
                      look: feedLook(boxes[b].size),
                      // Every card in words, a drawn one too: its question
                      // in its colour, and the drawing for the card opened.
                      // Pictures shrunk into boxes of every shape, or cut
                      // to them, set beside cards in words, read as two
                      // kinds of card on one page.
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
