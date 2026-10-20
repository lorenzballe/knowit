/// Blocks that show any cards, from any source, at every size: a row, a
/// grid, a mosaic, one across the page, a strip, a pair, a list, a small
/// deck, a slow procession and one card at the deck's own size.
///
/// Every tile draws a card as the app draws cards — the subject's colour,
/// its mark and name, the question set to its box with [ScaledText] — and
/// opens it as every shelf does. A box only takes a card whose question it
/// can set whole ([questionFits]): the block asks its source for more cards
/// than it has boxes, and a card too long for a small box waits for the
/// next block, rather than being cut.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../measure/screens.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/explore/first_shelves.dart' show ReadTick;
import '../../../widgets/pill_card.dart';
import '../../../widgets/pill_card_stack.dart' show kDeckMargin;
import '../../../widgets/scaled_text.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The card blocks, in the order docs/explore/core.md lists them.
const List<ExploreBlock> cardBlocks = [
  CarouselBlock(),
  GridBlock(),
  BentoBlock(),
  HeroBlock(),
  BannerBlock(),
  PairBlock(),
  ListBlock(),
  StackBlock(),
  TickerBlock(),
  SingleBlock(),
];

/// The page's width, less its two margins: what a block lays its cards
/// across.
double _across(BuildContext context) =>
    math.max(0, MediaQuery.sizeOf(context).width - 40);

/// The section in its frame: its own name and line, when it has them.
Widget _framed(ExploreHost host, ExploreSection section, Widget child) =>
    SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: child,
    );

/// The cards of [section] whose questions a box of [box] drawn as [look]
/// sets whole, at most [count] of them, from six times as many asked of
/// the source — measured in order, and no further than the [count]th that
/// fits.
List<Pill> _fitting(
  BuildContext context,
  ExploreHost host,
  ExploreSection section, {
  required int count,
  required Size box,
  required TileLook look,
}) {
  final List<Pill> out = [];
  for (final Pill pill in host.cardsFor(section, limit: count * 6)) {
    if (out.length == count) break;
    if (questionFits(context, pill, box, look, read: host.isRead(pill))) {
      out.add(pill);
    }
  }
  return out;
}

/// A card's tile, tapped open among [shelf], keyed as every card on
/// Explore is.
Widget _tap(
  ExploreHost host,
  ExploreSection section,
  List<Pill> shelf,
  Pill pill,
  Widget tile,
) => GestureDetector(
  key: ValueKey('explore-${pill.id}'),
  behavior: HitTestBehavior.opaque,
  onTap: () => host.open(section, shelf, pill),
  child: tile,
);

/// Says each of [pills] was shown, when it is built: what a block that
/// lays all its cards out at once puts on screen as it comes into view.
class _Shown extends StatelessWidget {
  const _Shown({
    required this.host,
    required this.section,
    required this.pills,
    required this.child,
  });

  final ExploreHost host;
  final ExploreSection section;
  final List<Pill> pills;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    for (final Pill pill in pills) {
      host.seen(section, pill);
    }
    return child;
  }
}

// ── carousel ────────────────────────────────────────────────────────────

/// A row of cards sideways, at one step: `size` `xs`, `s`, `m` (the
/// default, the small tile of the shelves further down), `l` (today's
/// shelf's) or `xl`. Ten cards unless the section says how many.
class CarouselBlock extends ExploreBlock with SectionLayout {
  const CarouselBlock();

  @override
  String get name => 'carousel';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final TileSize size = TileSize.named(section.size) ?? TileSize.m;
    final List<Pill> cards = _fitting(
      context,
      host,
      section,
      count: section.limit ?? 10,
      box: Size(size.width, size.height),
      look: TileLook.of(size),
    );
    if (cards.isEmpty) return null;
    return _framed(
      host,
      section,
      TileRow(
        size: size,
        pills: cards,
        isRead: host.isRead,
        onOpen: (shelf, pill) => host.open(section, shelf, pill),
        onShown: (pill) => host.seen(section, pill),
      ),
    );
  }
}

// ── grid ────────────────────────────────────────────────────────────────

/// The shapes a grid's tiles come in, by their height over their width.
const Map<String, double> kGridShapes = {
  'square': 1,
  'portrait': 1.5,
  'landscape': 0.72,
};

/// Cards in rows and columns: `columns` 2 (the default), 3 or 4, and
/// `shape` `square`, `portrait` (the default, half again as tall as wide)
/// or `landscape`. Two rows unless the section says how many cards.
class GridBlock extends ExploreBlock with SectionLayout {
  const GridBlock();

  @override
  String get name => 'grid';

  /// The gap between two tiles of a grid of [columns].
  static double gapFor(int columns) => columns == 2 ? 10 : 8;

  /// A tile of a grid of [columns] tiles of [shape] across [across] points.
  static Size tileFor(double across, int columns, String shape) {
    final double gap = gapFor(columns);
    final double width = (across - gap * (columns - 1)) / columns;
    return Size(width, width * (kGridShapes[shape] ?? 1.5));
  }

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Object? rawColumns = section.json['columns'];
    final int columns = rawColumns is num && rawColumns >= 2 && rawColumns <= 4
        ? rawColumns.toInt()
        : 2;
    final Object? rawShape = section.json['shape'];
    final String shape = rawShape is String && kGridShapes.containsKey(rawShape)
        ? rawShape
        : 'portrait';
    final Size tile = tileFor(_across(context), columns, shape);
    final List<Pill> fitting = _fitting(
      context,
      host,
      section,
      count: section.limit ?? columns * 2,
      box: tile,
      look: TileLook.forBox(tile),
    );
    if (fitting.isEmpty) return null;
    // Whole rows, once there is more than one: a grid that ends with a gap
    // in its last row reads as a card gone missing. Fewer than a row stand
    // as they are.
    final List<Pill> cards = fitting.length > columns
        ? fitting.take(fitting.length - fitting.length % columns).toList()
        : fitting;
    final double gap = gapFor(columns);
    return _framed(
      host,
      section,
      _Shown(
        host: host,
        section: section,
        pills: cards,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final Pill pill in cards)
                _tap(
                  host,
                  section,
                  cards,
                  pill,
                  BoxTile(pill: pill, box: tile, read: host.isRead(pill)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── bento ───────────────────────────────────────────────────────────────

/// One item of a mosaic: how many columns and rows it spans.
typedef BentoSpan = ({int columns, int rows});

/// Reads `"2x1"`: two columns, one row. Null for anything else, or a span
/// past [columns] or three rows.
BentoSpan? bentoSpan(Object? raw, int columns) {
  if (raw is! String) return null;
  final RegExpMatch? m = RegExp(r'^([1-4])x([1-3])$').firstMatch(raw);
  if (m == null) return null;
  final int c = int.parse(m.group(1)!), r = int.parse(m.group(2)!);
  if (c > columns) return null;
  return (columns: c, rows: r);
}

/// The mosaics a section that names no items gets, by its columns.
const Map<int, List<String>> kBentoDefaults = {
  2: ['2x1', '1x2', '1x1', '1x1'],
  3: ['2x2', '1x1', '1x1', '1x1', '2x1'],
  4: ['2x2', '2x1', '2x1', '4x1'],
};

/// Where each item of a mosaic sits: its column and row, packed in order,
/// each in the first place it fits, so the mosaic has no holes it could
/// fill.
List<({int column, int row})> packBento(List<BentoSpan> spans, int columns) {
  final List<List<bool>> taken = [];
  bool free(int row, int column, BentoSpan s) {
    for (int r = row; r < row + s.rows; r++) {
      for (int c = column; c < column + s.columns; c++) {
        if (r < taken.length && taken[r][c]) return false;
      }
    }
    return true;
  }

  final List<({int column, int row})> out = [];
  for (final BentoSpan s in spans) {
    for (int row = 0; ; row++) {
      int? at;
      for (int column = 0; column + s.columns <= columns; column++) {
        if (free(row, column, s)) {
          at = column;
          break;
        }
      }
      if (at == null) continue;
      while (taken.length < row + s.rows) {
        taken.add(List<bool>.filled(columns, false));
      }
      for (int r = row; r < row + s.rows; r++) {
        for (int c = at; c < at + s.columns; c++) {
          taken[r][c] = true;
        }
      }
      out.add((column: at, row: row));
      break;
    }
  }
  return out;
}

/// A mosaic: `columns` 2 to 4 (3 by default), and `items`, each `"CxR"` —
/// spanning C columns and R rows, up to all the columns and three rows —
/// laid in order, each where it first fits. A row is as tall as a column
/// is wide, times `ratio` (0.5 to 2). The smallest boxes are given the
/// shortest questions; a box no card fits is left out, and the mosaic packs
/// up without it.
class BentoBlock extends ExploreBlock with SectionLayout {
  const BentoBlock();

  @override
  String get name => 'bento';

  /// The gap between two boxes.
  static const double spacing = 8;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Object? rawColumns = section.json['columns'];
    final int columns = rawColumns is num && rawColumns >= 2 && rawColumns <= 4
        ? rawColumns.toInt()
        : 3;
    final Object? rawRatio = section.json['ratio'];
    final double ratio = rawRatio is num && rawRatio >= 0.5 && rawRatio <= 2
        ? rawRatio.toDouble()
        : 1;
    final Object? rawItems = section.json['items'];
    final List<BentoSpan> spans = [
      for (final Object? item
          in rawItems is List ? rawItems : kBentoDefaults[columns]!)
        ?bentoSpan(item, columns),
    ];
    if (spans.isEmpty) return null;
    final double unit = (_across(context) - spacing * (columns - 1)) / columns;
    final double rowHeight = unit * ratio;
    Size boxOf(BentoSpan s) => Size(
      unit * s.columns + spacing * (s.columns - 1),
      rowHeight * s.rows + spacing * (s.rows - 1),
    );
    final List<Pill> cards = host.cardsFor(section, limit: spans.length * 6);
    final List<Pill?> placed = fitCards(context, cards, [
      for (final s in spans) boxOf(s),
    ], isRead: host.isRead);
    final List<(BentoSpan, Pill)> items = [
      for (int i = 0; i < spans.length; i++)
        if (placed[i] case final Pill pill) (spans[i], pill),
    ];
    if (items.isEmpty) return null;
    final List<({int column, int row})> at = packBento([
      for (final (s, _) in items) s,
    ], columns);
    int rows = 0;
    for (int i = 0; i < items.length; i++) {
      rows = math.max(rows, at[i].row + items[i].$1.rows);
    }
    final List<Pill> shown = [for (final (_, p) in items) p];
    return _framed(
      host,
      section,
      _Shown(
        host: host,
        section: section,
        pills: shown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: rowHeight * rows + spacing * (rows - 1),
            child: Stack(
              children: [
                for (int i = 0; i < items.length; i++)
                  Positioned(
                    left: at[i].column * (unit + spacing),
                    top: at[i].row * (rowHeight + spacing),
                    child: _tap(
                      host,
                      section,
                      shown,
                      items[i].$2,
                      BoxTile(
                        pill: items[i].$2,
                        box: boxOf(items[i].$1),
                        read: host.isRead(items[i].$2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── hero ────────────────────────────────────────────────────────────────

/// How tall one card across the page is, by `size`.
const Map<String, double> kHeroHeights = {'m': 260, 'l': 340, 'xl': 420};

/// One card across the page, big: `size` `m`, `l` (the default) or `xl`.
class HeroBlock extends ExploreBlock with SectionLayout {
  const HeroBlock();

  @override
  String get name => 'hero';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Size box = Size(
      _across(context),
      kHeroHeights[section.size] ?? kHeroHeights['l']!,
    );
    final List<Pill> cards = _fitting(
      context,
      host,
      section,
      count: 1,
      box: box,
      look: TileLook.forBox(box),
    );
    if (cards.isEmpty) return null;
    final Pill pill = cards.single;
    return _framed(
      host,
      section,
      _Shown(
        host: host,
        section: section,
        pills: cards,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _tap(
            host,
            section,
            cards,
            pill,
            BoxTile(pill: pill, box: box, read: host.isRead(pill)),
          ),
        ),
      ),
    );
  }
}

// ── banner ──────────────────────────────────────────────────────────────

/// How tall a strip is, by `size`.
const Map<String, double> kBannerHeights = {'s': 96, 'm': 120, 'l': 148};

/// A card as a strip across the page: its mark and subject at one end, its
/// question beside them. `size` `s`, `m` (the default) or `l`; one strip,
/// or as many as `limit`, up to three.
class BannerBlock extends ExploreBlock with SectionLayout {
  const BannerBlock();

  @override
  String get name => 'banner';

  /// How a strip of [height] draws its question.
  static TileLook lookFor(double height) => TileLook(
    padding: 0,
    radius: 20,
    icon: 0,
    tick: 0,
    label: false,
    labelSize: 0,
    labelGap: 0,
    questionGap: 0,
    min: 11,
    max: height >= 140
        ? 22
        : height >= 110
        ? 19
        : 16.5,
    lineHeight: 1.15,
    spacing: (size) => -0.4 * size / 15,
    alignment: Alignment.centerLeft,
    foot: false,
  );

  /// The question's box in a strip [across] wide and [height] tall.
  static Size questionBox(double across, double height) =>
      Size(across - 32 - _BannerTile.side - 14, height - 28);

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final double height = kBannerHeights[section.size] ?? kBannerHeights['m']!;
    final double across = _across(context);
    final List<Pill> cards = _fitting(
      context,
      host,
      section,
      count: (section.limit ?? 1).clamp(1, 3),
      box: questionBox(across, height),
      look: lookFor(height),
    );
    if (cards.isEmpty) return null;
    return _framed(
      host,
      section,
      _Shown(
        host: host,
        section: section,
        pills: cards,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final Pill pill in cards)
                Padding(
                  padding: EdgeInsets.only(bottom: pill == cards.last ? 0 : 10),
                  child: _tap(
                    host,
                    section,
                    cards,
                    pill,
                    _BannerTile(
                      pill: pill,
                      height: height,
                      read: host.isRead(pill),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One strip: the card's colour end to end, its mark large at the start
/// with its subject under it, and the question set to the rest.
class _BannerTile extends StatelessWidget {
  const _BannerTile({
    required this.pill,
    required this.height,
    required this.read,
  });

  final Pill pill;
  final double height;
  final bool read;

  /// The column the mark stands in.
  static const double side = 44;

  @override
  Widget build(BuildContext context) {
    final TileLook look = BannerBlock.lookFor(height);
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: cardFace(context, pill.color, radius: look.radius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The mark level with the middle of the question, whatever its
          // length, and the tick of a card read under it.
          SizedBox(
            width: side,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SubjectIcon(subject: pill.topic, size: 24, ink: pill.ink),
                if (read) ...[
                  const SizedBox(height: 8),
                  ReadTick(pill: pill, color: pill.ink, size: 15),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ScaledText(
              text: pill.question,
              min: look.min,
              max: look.max,
              alignment: look.alignment,
              styleFor: (size) => look.questionStyle(pill, size),
            ),
          ),
        ],
      ),
    );
  }
}

// ── pair ────────────────────────────────────────────────────────────────

/// How tall the two of a pair are, by `size`.
const Map<String, double> kPairHeights = {'s': 160, 'm': 200, 'l': 250};

/// Two cards side by side, as tall as `size` says: `s`, `m` (the default)
/// or `l`. Without two cards to show it is not shown.
class PairBlock extends ExploreBlock with SectionLayout {
  const PairBlock();

  @override
  String get name => 'pair';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Size box = Size(
      (_across(context) - 10) / 2,
      kPairHeights[section.size] ?? kPairHeights['m']!,
    );
    final List<Pill> cards = _fitting(
      context,
      host,
      section,
      count: 2,
      box: box,
      look: TileLook.forBox(box),
    );
    if (cards.length < 2) return null;
    return _framed(
      host,
      section,
      _Shown(
        host: host,
        section: section,
        pills: cards,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final Pill pill in cards) ...[
                if (pill != cards.first) const SizedBox(width: 10),
                _tap(
                  host,
                  section,
                  cards,
                  pill,
                  BoxTile(pill: pill, box: box, read: host.isRead(pill)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── list ────────────────────────────────────────────────────────────────

/// How big the tile at the start of a row is, by `size`, and the question
/// beside it.
const Map<String, (double, double)> kListSizes = {
  's': (40, 13.5),
  'm': (52, 14.5),
  'l': (64, 16),
};

/// Rows, each a small tile of the card's colour with its mark, and the
/// whole question beside it, however many lines it takes. `size` `s`, `m`
/// (the default) or `l`; five rows unless the section says how many.
class ListBlock extends ExploreBlock with SectionLayout {
  const ListBlock();

  @override
  String get name => 'list';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = host.cardsFor(section, limit: section.limit ?? 5);
    if (cards.isEmpty) return null;
    final (double tile, double type) =
        kListSizes[section.size] ?? kListSizes['m']!;
    return _framed(
      host,
      section,
      _Shown(
        host: host,
        section: section,
        pills: cards,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final Pill pill in cards)
                Padding(
                  padding: EdgeInsets.only(bottom: pill == cards.last ? 0 : 8),
                  child: _tap(
                    host,
                    section,
                    cards,
                    pill,
                    _ListRow(
                      pill: pill,
                      tile: tile,
                      type: type,
                      read: host.isRead(pill),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of the list: the tile, the question whole, the subject under it.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.pill,
    required this.tile,
    required this.type,
    required this.read,
  });

  final Pill pill;
  final double tile;
  final double type;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: tile,
            height: tile,
            alignment: Alignment.center,
            decoration: cardFace(context, pill.color, radius: tile * 0.26),
            child: SubjectIcon(
              subject: pill.topic,
              size: tile * 0.36,
              ink: pill.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.question,
                    style: AppText.body(
                      size: type,
                      weight: FontWeight.w600,
                      height: 1.28,
                      color: context.p.ink.withValues(alpha: 0.93),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.subjectOf(pill.topic),
                          style: AppText.body(
                            size: 11,
                            weight: FontWeight.w500,
                            height: 1.1,
                            spacing: 0.3,
                            color: context.p.ink.withValues(alpha: 0.42),
                          ),
                        ),
                      ),
                      if (read) ...[
                        const SizedBox(width: 5),
                        ReadTick(
                          pill: pill,
                          color: context.p.ink.withValues(alpha: 0.5),
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── stack ───────────────────────────────────────────────────────────────

/// How big the card on top of a small deck is, by `size`.
const Map<String, Size> kStackSizes = {
  's': Size(200, 236),
  'm': Size(240, 284),
  'l': Size(276, 326),
};

/// A small deck to swipe through: the card on top, the next two showing
/// behind it, a swipe either way to the next or the one before, a tap to
/// open it. `size` `s`, `m` (the default) or `l`; eight cards unless the
/// section says how many.
class StackBlock extends ExploreBlock with SectionLayout {
  const StackBlock();

  @override
  String get name => 'stack';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Size box = kStackSizes[section.size] ?? kStackSizes['m']!;
    final Size fitted = Size(
      math.min(box.width, _across(context) - 24),
      box.height,
    );
    final List<Pill> cards = _fitting(
      context,
      host,
      section,
      count: section.limit ?? 8,
      box: fitted,
      look: TileLook.forBox(fitted),
    );
    if (cards.isEmpty) return null;
    return _framed(
      host,
      section,
      SmallDeck(
        key: ValueKey('stack-${section.id}'),
        cards: cards,
        box: fitted,
        isRead: host.isRead,
        onOpen: (pill) => host.open(section, cards, pill),
        onShown: (pill) => host.seen(section, pill),
      ),
    );
  }
}

/// A few cards in a pile, the top one swiped to the bottom of it.
class SmallDeck extends StatefulWidget {
  const SmallDeck({
    super.key,
    required this.cards,
    required this.box,
    required this.isRead,
    required this.onOpen,
    required this.onShown,
  });

  /// The cards, top first.
  final List<Pill> cards;

  /// The top card's size.
  final Size box;

  /// Whether the reader has read a card.
  final bool Function(Pill) isRead;

  /// The top card tapped.
  final ValueChanged<Pill> onOpen;

  /// A card come to the top, which is a card shown.
  final ValueChanged<Pill> onShown;

  @override
  State<SmallDeck> createState() => _SmallDeckState();
}

class _SmallDeckState extends State<SmallDeck>
    with SingleTickerProviderStateMixin {
  /// Which card is on top.
  int _top = 0;

  /// How far the top card has been pulled sideways.
  double _pull = 0;

  /// Carries a released card the rest of the way: off the deck, or back.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  double _from = 0, _to = 0;
  int _step = 0;

  /// How far a card of the pile behind sits from the one in front of it.
  static const double _fan = 12;

  @override
  void initState() {
    super.initState();
    _settle.addListener(() {
      setState(() {
        _pull =
            _from +
            (_to - _from) * Curves.easeOutCubic.transform(_settle.value);
      });
    });
    _settle.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      setState(() {
        if (_step != 0) _move(_step);
        _pull = 0;
        _step = 0;
      });
    });
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  int get _count => widget.cards.length;

  void _move(int by) {
    _top = (_top + by) % _count;
    if (_top < 0) _top += _count;
    HapticFeedback.selectionClick();
  }

  /// Sends the top card on, [by] one forward or back: carried off the deck
  /// and the next one risen, or at once when the reader asked for less
  /// motion.
  void _go(int by) {
    if (_count < 2) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _move(by);
        _pull = 0;
      });
      return;
    }
    _from = _pull;
    _to = -by * (widget.box.width + 40);
    _step = by;
    _settle.forward(from: 0);
  }

  void _release(DragEndDetails details) {
    final double speed = details.primaryVelocity ?? 0;
    final double threshold = widget.box.width * 0.28;
    if (_pull <= -threshold || speed < -600) return _go(1);
    if (_pull >= threshold || speed > 600) return _go(-1);
    _from = _pull;
    _to = 0;
    _step = 0;
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Size box = widget.box;
    final int behind = math.min(2, _count - 1);
    final Pill top = widget.cards[_top];
    widget.onShown(top);
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final List<Widget> layers = [
      // The cards behind stand a step to the right of the one in front and
      // a little smaller about their right edge, so each shows a strip of
      // itself beside it, as a pile held in the hand.
      for (int d = behind; d >= 1; d--)
        Positioned(
          left: d * _fan,
          top: 0,
          child: Transform.scale(
            scale: 1 - d * 0.06,
            alignment: Alignment.centerRight,
            child: CardDim(
              amount: context.p.isDark ? 0.32 * d : 0.36 * d,
              ground: context.p.surface,
              radius: TileLook.forBox(box).radius,
              child: BoxTile(
                pill: widget.cards[(_top + d) % _count],
                box: box,
                read: widget.isRead(widget.cards[(_top + d) % _count]),
              ),
            ),
          ),
        ),
      Positioned(
        left: 0,
        top: 0,
        child: Transform.translate(
          offset: Offset(_pull, 0),
          child: Transform.rotate(
            angle: calm ? 0 : _pull / box.width * 0.12,
            child: GestureDetector(
              key: ValueKey('explore-${top.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onOpen(top),
              onHorizontalDragUpdate: (d) =>
                  setState(() => _pull += d.primaryDelta ?? 0),
              onHorizontalDragEnd: _release,
              child: BoxTile(pill: top, box: box, read: widget.isRead(top)),
            ),
          ),
        ),
      ),
    ];
    return Semantics(
      container: true,
      label: l.cardOf(_top + 1, _count),
      customSemanticsActions: _count < 2
          ? null
          : {
              CustomSemanticsAction(label: l.next): () => _go(1),
              CustomSemanticsAction(label: l.storyPrevious): () => _go(-1),
            },
      child: Center(
        child: SizedBox(
          width: box.width + behind * _fan,
          height: box.height,
          child: Stack(clipBehavior: Clip.none, children: layers),
        ),
      ),
    );
  }
}

// ── ticker ──────────────────────────────────────────────────────────────

/// A row of cards that moves on by itself, slowly, round and round: `size`
/// `xs`, `s` (the default) or `m`. Still for a reader who asked for less
/// motion, still while a finger is on it and for a moment after, and still
/// while it is not on screen.
class TickerBlock extends ExploreBlock with SectionLayout {
  const TickerBlock();

  @override
  String get name => 'ticker';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final TileSize size = switch (TileSize.named(section.size)) {
      final TileSize named when named.index <= TileSize.m.index => named,
      _ => TileSize.s,
    };
    final List<Pill> cards = _fitting(
      context,
      host,
      section,
      count: section.limit ?? 12,
      box: Size(size.width, size.height),
      look: TileLook.of(size),
    );
    if (cards.isEmpty) return null;
    return _framed(
      host,
      section,
      Procession(
        key: ValueKey('ticker-${section.id}'),
        size: size,
        cards: cards,
        isRead: host.isRead,
        onOpen: (pill) => host.open(section, cards, pill),
        onShown: (pill) => host.seen(section, pill),
      ),
    );
  }
}

/// The ticker's row: tiles in a loop, carried left at a walking pace.
class Procession extends StatefulWidget {
  const Procession({
    super.key,
    required this.size,
    required this.cards,
    required this.isRead,
    required this.onOpen,
    required this.onShown,
  });

  /// The step of its tiles.
  final TileSize size;

  /// The cards, in the order they pass.
  final List<Pill> cards;

  /// Whether the reader has read a card.
  final bool Function(Pill) isRead;

  /// A tile tapped.
  final ValueChanged<Pill> onOpen;

  /// A tile built, which is a card shown.
  final ValueChanged<Pill> onShown;

  /// How fast the row moves, in points a second.
  static const double speed = 18;

  @override
  State<Procession> createState() => _ProcessionState();
}

class _ProcessionState extends State<Procession>
    with SingleTickerProviderStateMixin {
  final ScrollController _row = ScrollController();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  /// Until when it stays still after a finger let go of it.
  DateTime _restUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _held = false;

  ScreenPresence? _presence;
  ScrollPosition? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presence?.removeListener(_check);
    _presence = ScreenPresence.maybeOf(context)?..addListener(_check);
    _page?.removeListener(_check);
    _page = Scrollable.maybeOf(context)?.position?..addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _presence?.removeListener(_check);
    _page?.removeListener(_check);
    _ticker.dispose();
    _row.dispose();
    super.dispose();
  }

  /// Whether the row should be moving now: motion allowed, the screen in
  /// front, the row on it, and no finger on it.
  bool get _wanted {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return false;
    if (_presence != null && !_presence!.showing) return false;
    final RenderObject? self = context.findRenderObject();
    final ScrollableState? page = Scrollable.maybeOf(context);
    final RenderObject? window = page?.context.findRenderObject();
    if (self is RenderBox && window is RenderBox && self.hasSize) {
      if (!self.attached || !window.attached || !window.hasSize) return false;
      final double top = self.localToGlobal(Offset.zero, ancestor: window).dy;
      if (top > window.size.height || top + self.size.height < 0) return false;
    }
    return true;
  }

  void _check() {
    if (!mounted) return;
    final bool wanted = _wanted;
    if (wanted && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!wanted && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final double dt = _last == Duration.zero
        ? 0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_held || DateTime.now().isBefore(_restUntil) || !_row.hasClients) {
      return;
    }
    _row.jumpTo(_row.offset + Procession.speed * dt);
  }

  @override
  Widget build(BuildContext context) {
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final int n = widget.cards.length;
    return Listener(
      onPointerDown: (_) => _held = true,
      onPointerUp: (_) {
        _held = false;
        _restUntil = DateTime.now().add(const Duration(seconds: 2));
      },
      onPointerCancel: (_) {
        _held = false;
        _restUntil = DateTime.now().add(const Duration(seconds: 2));
      },
      child: SizedBox(
        height: widget.size.row,
        child: ListView.builder(
          controller: _row,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          // Round and round while it moves; still, it is the row it is.
          itemCount: calm ? n : null,
          itemBuilder: (context, i) {
            final Pill pill = widget.cards[i % n];
            widget.onShown(pill);
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                key: ValueKey('explore-${pill.id}-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onOpen(pill),
                child: CardTile(
                  pill: pill,
                  size: widget.size,
                  read: widget.isRead(pill),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── single ──────────────────────────────────────────────────────────────

/// One card at the deck's own size, its face as the deck shows it on Today:
/// a tap opens it to be read and answered.
class SingleBlock extends ExploreBlock with SectionLayout {
  const SingleBlock();

  @override
  String get name => 'single';

  /// The size of the deck's card on a screen of [screen]: the deck's width,
  /// and at most the deck's own proportion, short of filling the screen.
  static Size sizeFor(Size screen) {
    final double width = math.max(0, screen.width - kDeckMargin * 2);
    return Size(
      width,
      math.max(0, math.min(width * 1.82, screen.height - 250)),
    );
  }

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = host.cardsFor(section, limit: 1);
    if (cards.isEmpty) return null;
    final Pill pill = cards.single;
    final Size box = sizeFor(MediaQuery.sizeOf(context));
    return _framed(
      host,
      section,
      _Shown(
        host: host,
        section: section,
        pills: cards,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDeckMargin),
          child: GestureDetector(
            key: ValueKey('explore-${pill.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => host.open(section, cards, pill),
            child: SizedBox(
              width: box.width,
              height: box.height,
              // The face only: the card is read and answered in the
              // viewer it opens in, so nothing on it takes a touch here.
              child: IgnorePointer(
                child: PillCard(
                  pill: pill,
                  flipped: false,
                  home: host.app.place,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
