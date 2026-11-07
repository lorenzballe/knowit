/// Explore without an end: after the shelves, the whole bank in the day's
/// order — the same on every phone, turning with the day, never chosen for
/// the reader — in a mosaic of two columns that goes on for as long as the
/// reader scrolls: one card across, two side by side, a tall one beside two,
/// two, two beside a tall one, two, and round again. A card read already is
/// left out, and one about a place reaches only the readers who live there,
/// as on every shelf.
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
import '../../../models/pill.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// One box of a band: where it sits in the band's two columns, and how many
/// columns and rows it spans.
typedef FeedBox = ({int column, int row, int columns, int rows});

/// The bands of the feed, in their turn.
const List<List<FeedBox>> kFeedBands = [
  // One card across.
  [(column: 0, row: 0, columns: 2, rows: 1)],
  // Two side by side.
  [
    (column: 0, row: 0, columns: 1, rows: 1),
    (column: 1, row: 0, columns: 1, rows: 1),
  ],
  // A tall one at the left, beside two.
  [
    (column: 0, row: 0, columns: 1, rows: 2),
    (column: 1, row: 0, columns: 1, rows: 1),
    (column: 1, row: 1, columns: 1, rows: 1),
  ],
  [
    (column: 0, row: 0, columns: 1, rows: 1),
    (column: 1, row: 0, columns: 1, rows: 1),
  ],
  // Two, beside a tall one at the right.
  [
    (column: 0, row: 0, columns: 1, rows: 1),
    (column: 0, row: 1, columns: 1, rows: 1),
    (column: 1, row: 0, columns: 1, rows: 2),
  ],
  [
    (column: 0, row: 0, columns: 1, rows: 1),
    (column: 1, row: 0, columns: 1, rows: 1),
  ],
];

/// The gap between two boxes, across and down.
const double kFeedSpacing = 8;

/// How the boxes of the feed measure on a page [across] points wide, less
/// its margins: a column and a row are as wide as each other.
class FeedGrid {
  FeedGrid(double across) : unit = math.max(0, (across - kFeedSpacing) / 2);

  /// A column's width, and a row's height.
  final double unit;

  /// The size of [box].
  Size sizeOf(FeedBox box) => Size(
    unit * box.columns + kFeedSpacing * (box.columns - 1),
    unit * box.rows + kFeedSpacing * (box.rows - 1),
  );

  /// Where [box] sits in its band.
  Offset offsetOf(FeedBox box) => Offset(
    box.column * (unit + kFeedSpacing),
    box.row * (unit + kFeedSpacing),
  );

  /// How tall [band] is.
  double heightOf(List<FeedBox> band) {
    final int rows = band.map((b) => b.row + b.rows).reduce(math.max);
    return unit * rows + kFeedSpacing * (rows - 1);
  }
}

/// How a box of the feed draws its card: as its size says, except that a
/// tall box sets its question no larger than a box a third shorter would,
/// so a question in a narrow column reads as lines, not as a word to a line.
TileLook feedLook(Size box) => box.height > box.width * 1.5
    ? TileLook.forBox(Size(box.width, box.width * 1.45))
    : TileLook.forBox(box);

/// The feed's cards as they are laid, band after band. A band is laid the
/// first time it is built and stays as it was laid, so a reader who
/// scrolls back finds what they left.
class FeedDeal {
  FeedDeal(this.pool, {required this.skip});

  /// The cards, in the day's order.
  final List<Pill> pool;

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
      final List<FeedBox> boxes = kFeedBands[bands.length % kFeedBands.length];
      List<Pill?>? placed;
      // A card that no box of the band holds whole, at the reader's text
      // size, gives way to the next, so the feed goes on rather than stop.
      for (int tries = 0; placed == null && tries < 40; tries++) {
        while (_waiting.length < boxes.length * 6 && _next < pool.length) {
          final Pill pill = pool[_next++];
          if (!skip(pill)) _waiting.add(pill);
        }
        if (_waiting.isEmpty) return null;
        final List<Pill?> fitted = fitCards(
          context,
          _waiting,
          [for (final FeedBox box in boxes) grid.sizeOf(box)],
          isRead: isRead,
          look: feedLook,
        );
        if (fitted.any((p) => p != null)) {
          placed = _longestInBiggest(context, fitted, boxes, grid, isRead);
        } else {
          _waiting.removeAt(0);
        }
      }
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
  List<FeedBox> boxes,
  FeedGrid grid,
  bool Function(Pill pill) isRead,
) {
  if (boxes.length < 2 || placed.any((p) => p == null)) return placed;
  int area(int i) => boxes[i].columns * boxes[i].rows;
  int big = 0;
  for (int i = 1; i < boxes.length; i++) {
    if (area(i) > area(big)) big = i;
  }
  if (List.generate(boxes.length, area).where((a) => a == area(big)).length >
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
  bool fits(int i) {
    final Size box = grid.sizeOf(boxes[i]);
    return questionFits(
      context,
      moved[i]!,
      box,
      feedLook(box),
      read: isRead(moved[i]!),
    );
  }

  return fits(big) && fits(longest) ? moved : placed;
}

/// The feed's deal for [section] as [host] deals it now: the whole bank in
/// the day's order, less what is not for this reader.
FeedDeal feedDeal(ExploreHost host, ExploreSection section) => FeedDeal(
  host.cardsFor(section),
  skip: (p) => host.isRead(p) || !reachesReader(p, host.app.place),
);

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
    for (int i = 0; i < kFeedBands.length; i++) {
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
      widget.host.subject ?? '',
      pool.length,
      for (final Pill p in pool.take(3)) p.id,
    ].join('|');
    if (_deal == null || key != _dealtFor) {
      _dealtFor = key;
      _deal = FeedDeal(
        pool,
        skip: (p) =>
            widget.host.isRead(p) || !reachesReader(p, widget.host.app.place),
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
    final List<FeedBox> boxes = kFeedBands[index % kFeedBands.length];
    for (final Pill? pill in cards) {
      if (pill != null) host.seen(section, pill);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : kFeedSpacing, 20, 0),
      child: SizedBox(
        height: grid.heightOf(boxes),
        child: Stack(
          children: [
            for (int b = 0; b < boxes.length; b++)
              if (cards[b] case final Pill pill)
                Positioned(
                  left: grid.offsetOf(boxes[b]).dx,
                  top: grid.offsetOf(boxes[b]).dy,
                  child: GestureDetector(
                    key: ValueKey('explore-${pill.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => host.open(section, List.of(deal.laid), pill),
                    child: BoxTile(
                      pill: pill,
                      box: grid.sizeOf(boxes[b]),
                      read: host.isRead(pill),
                      look: feedLook(grid.sizeOf(boxes[b])),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
