/// Explore without an end: after the shelves, the whole bank in the day's
/// order — the same on every phone, turning with the day, never chosen for
/// the reader — in a mosaic that goes on for as long as the reader scrolls.
/// Its bands take every shape the page has: one card across, two side by
/// side, a tall one beside two, two and two out of step, and the cover's
/// own, a large card three fifths of the page beside two small ones, each
/// on the left or on the right. Which shape comes next is drawn by lot, the
/// same lot on every phone for the day and the subject in view: never the
/// same shape twice in a row, and the large ones in turn on either side, so
/// the eye goes down the page in a zigzag. A card read already is left out,
/// and one about a place reaches only the readers who live there, as on
/// every shelf. Under a cover (lib/explore/blocks/core/cover_block.dart),
/// the cards the cover laid are left out too, and the feed does not open
/// in the cover's own shape: a page never shows the same mosaic of the same
/// cards twice. The films are cards like the others (lib/data/
/// video_cards.dart), each a tap from playing out of its box.
///
/// The shapes give each box its width and its type; its question gives it
/// its height. A box stands as tall as its question set whole, never less
/// than two lines of it, and the cards of a band are chosen so its two
/// columns come out level: the tall box, and the large one, take the
/// longest question of the three, long enough to stand as tall as the two
/// beside it. No box is drawn tall and left half empty under a question
/// that ends halfway down it.
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
import '../../../data/video_cards.dart';
import '../../../models/pill.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/scaled_text.dart';
import '../../../widgets/video_card.dart' show VideoCardHero, videoHeroTag;
import '../../explore_block.dart';
import 'feed_cap.dart';
import 'layout.dart';
import 'shelves.dart';

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
  coverRight,

  /// Four, two in each column and out of step: each column's two as tall
  /// as their questions, the two columns level at the foot.
  staggered;

  /// How many cards it holds.
  int get boxes => switch (this) {
    across => 1,
    pair => 2,
    staggered => 4,
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

/// The cover's own shapes: what the feed does not open with under a cover.
const Set<FeedShape> kCoverShapes = {FeedShape.coverLeft, FeedShape.coverRight};

/// How many bands make the feed's first round: what it shows when it is
/// not the last section.
const int kFeedRound = 6;

/// How many of the cards waiting their turn a band is chosen from: the
/// first of them always, the others for how their heights go together.
const int kFeedLookAhead = 10;

/// The order the feed's bands take, by lot: the same on every phone for the
/// same [seed] (the day and the subject in view), different from one day to
/// the next.
///
/// A shape is never the one before it again; a band with a large card puts
/// it on the other side from the last one that had one; one card across
/// comes at most once in four bands. Two side by side come up most, as the
/// breath between the large ones.
class FeedPattern {
  FeedPattern(String seed, {this.notFirst = const {}})
    : _state = stableHash('feed-shapes:$seed') | 1;

  int _state;
  final List<FeedShape> _shapes = [];

  /// Shapes the first band never takes: the cover's, under a cover.
  final Set<FeedShape> notFirst;

  /// How often each shape is drawn, against the others.
  static const Map<FeedShape, int> _weights = {
    FeedShape.pair: 6,
    FeedShape.coverLeft: 4,
    FeedShape.coverRight: 4,
    FeedShape.tallLeft: 3,
    FeedShape.tallRight: 3,
    FeedShape.staggered: 4,
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
            !(s == FeedShape.across && acrossLately) &&
            !(_shapes.isEmpty && notFirst.contains(s)))
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

/// The least step between two columns out of step, so it reads as meant.
const double kFeedStep = 24;

/// How the boxes of the feed measure on a page [across] points wide, less
/// its margins.
class FeedGrid {
  FeedGrid(this.across) : unit = math.max(0, (across - kFeedSpacing) / 2);

  /// The page's width, less its margins.
  final double across;

  /// Half the page: a column's width, and a row's height, in the bands of
  /// two columns.
  final double unit;

  /// The boxes of a band of [shape] as the canvas drew them, in the order
  /// its cards are laid: the large one, where there is one, first. Each
  /// gives its box the width it stands at and the type it is set in
  /// ([feedLook]); the box's height is its question's ([FeedDeal.band]).
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
      case FeedShape.staggered:
        return [
          Rect.fromLTWH(0, 0, unit, unit),
          Rect.fromLTWH(0, unit + gap, unit, unit),
          Rect.fromLTWH(right, 0, unit, unit),
          Rect.fromLTWH(right, unit + gap, unit, unit),
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

  /// How tall a band of [shape] is as the canvas drew it.
  double heightOf(FeedShape shape) =>
      rectsOf(shape).map((r) => r.bottom).reduce(math.max);

  /// The columns of a band of [shape], each the boxes of [rectsOf] stacked
  /// in it from the top: the large box alone in its column, the two beside
  /// it one above the other; out of step, two and two.
  static List<List<int>> columnsOf(FeedShape shape) => switch (shape.boxes) {
    1 => const [
      [0],
    ],
    2 => const [
      [0],
      [1],
    ],
    3 => const [
      [0],
      [1, 2],
    ],
    _ => const [
      [0, 1],
      [2, 3],
    ],
  };
}

/// How a box of the feed draws its card: as its size on the canvas says,
/// except that a tall box sets its question no larger than a box a third
/// shorter would, so a question in a narrow column reads as lines, not as a
/// word to a line. And never in small print: a question is set at the top
/// of its box's type, a headline to stop the thumb, as the cover sets its
/// small tiles, and its box stands as tall as that takes.
TileLook feedLook(Size box) {
  final TileLook look = box.height > box.width * 1.5
      ? TileLook.forBox(Size(box.width, box.width * 1.45))
      : TileLook.forBox(box);
  return look.withMin(math.max(look.min, math.max(look.max - 2, 12.5)));
}

/// One band of the feed as it is laid: its shape, its cards, the box each
/// stands in and how each is drawn.
@immutable
class FeedLaid {
  const FeedLaid({
    required this.shape,
    required this.cards,
    required this.boxes,
    required this.looks,
    required this.clean,
    required this.score,
  });

  /// The shape it was laid in.
  final FeedShape shape;

  /// Its cards, in its boxes' order: the large one, where there is one,
  /// first.
  final List<Pill> cards;

  /// Where each card stands in the band, as tall as its question.
  final List<Rect> boxes;

  /// How each is drawn: as its box on the canvas ([feedLook]).
  final List<TileLook> looks;

  /// Whether it came out as the shape should: its columns level without a
  /// box left emptier under its question than [feedSpare] lets it, and two
  /// and two out of step by a clear step ([kFeedStep]).
  final bool clean;

  /// What the band costs the eye, the less the better: the room left under
  /// its questions, and how far down the cards waiting it reached.
  final double score;

  /// How tall the band stands.
  double get height => boxes.fold(0, (h, r) => math.max(h, r.bottom));
}

/// The most room a box [height] tall may leave under its question, past
/// the least a card stands, for its column to come out level with the
/// other: any more and it reads as a card that ends halfway down.
double feedSpare(double height) => (height * 0.15).clamp(12, 28);

/// How tall a box [width] wide, drawn as [look], stands with [pill]'s
/// question set whole at the top of the look's type: its height in the
/// feed, so a card is as tall as its question and no taller.
///
/// Measured as [ScaledText] sets it — at the reader's text size and in
/// their direction, the type no larger than lets the longest word keep to
/// its line — in the room the tile's head and foot leave ([TileBody]), and
/// a point over, for the fractions a paragraph is laid out in.
double feedNeed(
  BuildContext context,
  Pill pill,
  double width,
  TileLook look, {
  bool read = false,
}) => _measure(context, pill, width, look, read: read, least: false);

/// The least a box [width] wide, drawn as [look], stands: two lines of
/// question at the top of its type, so a question of one line is a card
/// and not a strip.
double feedLeast(
  BuildContext context,
  Pill pill,
  double width,
  TileLook look, {
  bool read = false,
}) => _measure(context, pill, width, look, read: read, least: true);

/// What [feedNeed] and [feedLeast] found, by card, box and text size: a
/// band weighs the same few cards against each other many times over.
final Map<String, double> _measured = {};

/// How tall a line of a tile's head or foot stands, by its style and the
/// text size.
final Map<String, double> _lines = {};

double _measure(
  BuildContext context,
  Pill pill,
  double width,
  TileLook look, {
  required bool read,
  required bool least,
}) {
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  final TextDirection direction = Directionality.of(context);
  // The least a box stands is the same for every card in it, but for the
  // line to keep in the foot of a card read.
  final bool own = !least || (look.foot && read);
  final String key =
      '${own ? pill.id : '*'}|$least|${width.toStringAsFixed(1)}|'
      '${look.min}|${look.max}|${look.lineHeight}|${look.padding}|'
      '${look.icon}|${look.tick}|${look.label ? look.labelSize : 0}|'
      '${look.questionGap}|${look.foot}|${look.footLines}|$read|'
      '${scaler.scale(10)}|$direction';
  final double? known = _measured[key];
  if (known != null) return known;

  // A line of the head or the foot is the same height on every card: its
  // colour is the card's, its metrics are the style's.
  double lineOf(TextStyle style) =>
      _lines['${style.fontFamily}|${style.fontSize}|${style.fontWeight}|'
          '${style.letterSpacing}|${style.height}|${scaler.scale(10)}'] ??= () {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: 'Ag', style: style),
          textDirection: direction,
          textScaler: scaler,
        )..layout();
        final double height = painter.height;
        painter.dispose();
        return height;
      }();

  // Everything but the question, as the tile lays it out: the margins, the
  // head, the room under the head (and over the foot), the foot.
  final double inner = math.max(0, width - look.padding * 2);
  double frame = look.padding * 2;
  frame += math.max(
    math.max(look.icon, look.tick),
    look.label ? lineOf(look.labelStyle(pill)) : 0,
  );
  frame += look.questionGap * (look.foot ? 2 : 1);
  if (look.foot) {
    if (footSaysMove(pill, read)) {
      final TextPainter move = TextPainter(
        text: TextSpan(text: pill.barMove, style: look.moveStyle(pill)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: look.footLines,
      )..layout(maxWidth: inner);
      frame += move.height;
      move.dispose();
    } else {
      frame += lineOf(look.minutesStyle(pill));
    }
  }

  final double size = least
      ? look.max
      : ScaledText.sizeFor(
          pill.question,
          styleFor: (size) => look.questionStyle(pill, size),
          min: look.min,
          max: look.max,
          width: inner,
          scaler: scaler,
          direction: direction,
        );
  final TextPainter question = TextPainter(
    text: TextSpan(
      text: least ? 'Ag\nAg' : pill.question,
      style: look.questionStyle(pill, size),
    ),
    textDirection: direction,
    textScaler: scaler,
  )..layout(maxWidth: inner);
  final double height = frame + question.height + 1;
  question.dispose();
  if (_measured.length > 6000) _measured.clear();
  return _measured[key] = height;
}

/// The feed's cards as they are laid, band after band. A band is laid the
/// first time it is built and stays as it was laid, so a reader who
/// scrolls back finds what they left.
///
/// A band always holds the first card waiting, so the feed keeps to the
/// day's order; the rest of it is chosen among the next few cards waiting
/// ([kFeedLookAhead]) for how their heights go together, so the band's two
/// columns come out level and no box is left emptier under its question
/// than [feedSpare] lets it. A shape that no choice fills so is laid as
/// two side by side instead, or as one card across.
class FeedDeal {
  FeedDeal(
    this.pool, {
    required this.skip,
    String seed = '',
    Set<FeedShape> notFirst = const {},
  }) : pattern = FeedPattern(seed, notFirst: notFirst);

  /// The cards, in the day's order.
  final List<Pill> pool;

  /// The shapes its bands take, in turn.
  final FeedPattern pattern;

  /// The shape of band [index]: the one it was laid in, or, for a band not
  /// laid yet, the one drawn for it.
  FeedShape shapeAt(int index) =>
      index < bands.length ? bands[index].shape : pattern.shapeAt(index);

  /// Whether a card is not for this feed: read already, or about a place
  /// the reader does not live in.
  final bool Function(Pill pill) skip;

  int _next = 0;

  /// The cards taken from the pool and not laid yet, in order.
  final List<Pill> _waiting = [];

  /// The bands laid so far.
  final List<FeedLaid> bands = [];

  /// Every card laid so far, in the order laid: the cards a tap opens among.
  final List<Pill> laid = [];

  /// Whether a card of the pool is left that the feed could still lay.
  bool get hasAny {
    if (bands.isNotEmpty || _waiting.isNotEmpty) return true;
    return pool.skip(_next).any((p) => !skip(p));
  }

  /// The band at [index], laid now if it is the first time it is asked
  /// for (and every band before it, in turn); null once the pool is spent.
  FeedLaid? band(
    BuildContext context,
    int index,
    FeedGrid grid, {
    required bool Function(Pill pill) isRead,
  }) {
    while (bands.length <= index) {
      while (_waiting.length < kFeedLookAhead && _next < pool.length) {
        final Pill pill = pool[_next++];
        if (!skip(pill)) _waiting.add(pill);
      }
      if (_waiting.isEmpty) return null;
      final List<Pill> window = _waiting.take(kFeedLookAhead).toList();
      final FeedShape drawn = pattern.shapeAt(bands.length);
      // The shape drawn; where no choice of cards fills it cleanly, two and
      // two out of step, whose two columns of two come out level the most
      // easily, then two side by side, then one across. Failing all,
      // whichever came out best.
      FeedLaid? chosen;
      FeedLaid? best;
      for (final FeedShape shape in [
        drawn,
        if (drawn != FeedShape.staggered && drawn.boxes > 1)
          FeedShape.staggered,
        if (drawn != FeedShape.pair && drawn.boxes > 1) FeedShape.pair,
        if (drawn.boxes > 1) FeedShape.across,
      ]) {
        final FeedLaid? tried = _lay(context, shape, grid, window, isRead);
        if (tried == null) continue;
        if (tried.clean) {
          chosen = tried;
          break;
        }
        if (best == null || tried.score < best.score) best = tried;
      }
      chosen ??= best;
      if (chosen == null) return null;
      // Laid in the order a reader meets them, top to bottom and then left
      // to right: the order a swipe from one opened card to the next takes.
      final List<int> met = List<int>.generate(chosen.cards.length, (i) => i)
        ..sort((a, b) {
          final Rect x = chosen!.boxes[a], y = chosen.boxes[b];
          final int byTop = x.top.compareTo(y.top);
          return byTop != 0 ? byTop : x.left.compareTo(y.left);
        });
      for (final int i in met) {
        _waiting.remove(chosen.cards[i]);
        laid.add(chosen.cards[i]);
      }
      bands.add(chosen);
    }
    return bands[index];
  }

  /// [shape] laid with the first card of [window] and others of it: the
  /// choice that leaves the least room under its questions, reaching the
  /// least far down the cards waiting. Null when [window] holds too few
  /// cards for the shape.
  ///
  /// Each box is as tall as its question asks ([feedNeed]), never less than
  /// [feedLeast]; the column that comes out shorter shares what it lacks
  /// among its boxes. In a shape with a large box, the large box takes the
  /// longest question of the three. Two and two out of step are out of step
  /// by a clear step: level, they are two pairs, and a few points apart,
  /// a grid drawn carelessly.
  FeedLaid? _lay(
    BuildContext context,
    FeedShape shape,
    FeedGrid grid,
    List<Pill> window,
    bool Function(Pill pill) isRead,
  ) {
    final List<Rect> canvas = grid.rectsOf(shape);
    final int count = canvas.length;
    if (window.length < count) return null;
    final List<TileLook> looks = [
      for (final Rect r in canvas) feedLook(r.size),
    ];
    final List<List<int>> columns = FeedGrid.columnsOf(shape);
    // What each card asks of each box, and what it stands in it at the
    // least: measured once here, then only added up.
    final int n = window.length;
    final List<List<double>> needs = [
      for (final Pill pill in window)
        [
          for (int b = 0; b < count; b++)
            feedNeed(
              context,
              pill,
              canvas[b].width,
              looks[b],
              read: isRead(pill),
            ),
        ],
    ];
    final List<List<double>> stand = [
      for (int c = 0; c < n; c++)
        [
          for (int b = 0; b < count; b++)
            math.max(
              needs[c][b],
              feedLeast(
                context,
                window[c],
                canvas[b].width,
                looks[b],
                read: isRead(window[c]),
              ),
            ),
        ],
    ];
    final List<List<int>> picks = switch (count) {
      1 => [
        [0],
      ],
      2 => [
        for (int j = 1; j < n; j++) [0, j],
      ],
      3 => [
        // The first card in the large box, two others beside it.
        for (int i = 1; i < n; i++)
          for (int j = i + 1; j < n; j++) [0, i, j],
        // Another in the large box, the first card beside it on top.
        for (int k = 1; k < n; k++)
          for (int j = 1; j < n; j++)
            if (j != k) [k, 0, j],
      ],
      // The first card at the top of the left column, the earlier of the
      // other column's two on top of it.
      _ => [
        for (int i = 1; i < n; i++)
          for (int j = 1; j < n; j++)
            for (int k = j + 1; k < n; k++)
              if (i != j && i != k) [0, i, j, k],
      ],
    };

    List<double>? bestHeights;
    List<int>? bestPick;
    bool bestClean = false;
    double bestScore = double.infinity;
    for (final List<int> pick in picks) {
      if (count == 3) {
        final int longest = window[pick[0]].question.length;
        if (window[pick[1]].question.length > longest ||
            window[pick[2]].question.length > longest) {
          continue;
        }
      }
      final List<double> stands = [
        for (int b = 0; b < count; b++) stand[pick[b]][b],
      ];
      final List<double> sums = [
        for (final List<int> column in columns)
          column.fold<double>(0, (s, b) => s + stands[b]) +
              kFeedSpacing * (column.length - 1),
      ];
      final double tallest = sums.reduce(math.max);
      final List<double> heights = List.of(stands);
      bool clean = true;
      double score = 0;
      for (int c = 0; c < columns.length; c++) {
        final double share = (tallest - sums[c]) / columns[c].length;
        for (final int b in columns[c]) {
          heights[b] = stands[b] + share;
          if (share > feedSpare(heights[b])) clean = false;
          score += heights[b] - needs[pick[b]][b];
        }
      }
      if (count == 4) {
        final double step = (heights[0] - heights[2]).abs();
        if (step < kFeedStep) clean = false;
      }
      // A card further down the cards waiting costs a little, so a band
      // reaches past the next ones only for a box that comes out fuller.
      for (final int i in pick) {
        score += 2.0 * i;
      }
      if ((clean && !bestClean) || (clean == bestClean && score < bestScore)) {
        bestClean = clean;
        bestScore = score;
        bestPick = pick;
        bestHeights = heights;
      }
    }
    if (bestPick == null || bestHeights == null) return null;

    final List<Rect> boxes = List<Rect>.filled(count, Rect.zero);
    for (final List<int> column in columns) {
      double top = 0;
      for (final int b in column) {
        boxes[b] = Rect.fromLTWH(
          canvas[b].left,
          top,
          canvas[b].width,
          bestHeights[b],
        );
        top += bestHeights[b] + kFeedSpacing;
      }
    }
    return FeedLaid(
      shape: shape,
      cards: [for (final int i in bestPick) window[i]],
      boxes: boxes,
      looks: looks,
      clean: bestClean,
      score: bestScore,
    );
  }
}

/// The feed's deal for [section] as [host] deals it now: the whole bank in
/// the day's order, less what is not for this reader and what a cover
/// higher on the page laid ([coverAbove]).
FeedDeal feedDeal(ExploreHost host, ExploreSection section) =>
    _dealFor(host, section, host.cardsFor(section), coverAbove(host));

FeedDeal _dealFor(
  ExploreHost host,
  ExploreSection section,
  List<Pill> pool,
  Set<String> cover,
) => FeedDeal(
  pool,
  skip: (p) =>
      host.isRead(p) ||
      !reachesReader(p, host.app.place) ||
      cover.contains(p.id),
  seed: feedSeed(host, section),
  notFirst: cover.isEmpty ? const {} : kCoverShapes,
);

/// The cards a cover higher on [host]'s page laid in this build: none on a
/// page without one.
Set<String> coverAbove(ExploreHost host) => {
  ...ExploreShelves.of(host).onCover,
};

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
      final FeedLaid? band = deal.band(context, i, grid, isRead: host.isRead);
      if (band == null) break;
      bands.add(
        FeedBand(
          host: host,
          section: section,
          deal: deal,
          band: band,
          index: i,
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

  /// Where the flow ends for today, on the free plan with an end set
  /// (feed_cap.dart): after the bands laid by the time the day's cards
  /// reached the number, so nothing on the page goes from under the
  /// reader. Null while there is no end.
  int? _endsAt;

  /// The deal, kept for as long as the day, the subject in view, the bank
  /// and the page's width and text size are the same: a newer Explore, or a
  /// card read, leaves the bands where they were. Its boxes are as tall as
  /// their questions at this width and this text size, and are laid again
  /// for another.
  FeedDeal _current() {
    final List<Pill> pool = widget.host.cardsFor(widget.section);
    final Set<String> cover = coverAbove(widget.host);
    final String key = [
      feedSeed(widget.host, widget.section),
      pool.length,
      for (final Pill p in pool.take(3)) p.id,
      _across(context).toStringAsFixed(1),
      MediaQuery.textScalerOf(context).scale(10),
      (cover.toList()..sort()).join(','),
    ].join('|');
    if (_deal == null || key != _dealtFor) {
      _dealtFor = key;
      _deal = _dealFor(widget.host, widget.section, pool, cover);
      _endsAt = null;
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
    if (host.app.exploreCapped) {
      _endsAt ??= deal.bands.length;
    } else {
      _endsAt = null;
    }
    final int? endsAt = _endsAt;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        if (i == 0) {
          if (title == null && line == null) return const SizedBox.shrink();
          return host.watch(
            section,
            SectionFrame(title: title, line: line, child: const SizedBox()),
          );
        }
        // The day's end of the flow, where the next band would have been.
        if (endsAt != null && i - 1 >= endsAt) {
          return i - 1 == endsAt ? FeedCapCard(app: host.app) : null;
        }
        final FeedLaid? band = deal.band(
          context,
          i - 1,
          grid,
          isRead: host.isRead,
        );
        if (band == null) return null;
        return FeedBand(
          key: ValueKey('feed-band-${i - 1}'),
          host: host,
          section: section,
          deal: deal,
          band: band,
          index: i - 1,
        );
      }),
    );
  }
}

/// One band of the feed, its cards in its boxes, each as tall as its
/// question.
class FeedBand extends StatelessWidget {
  const FeedBand({
    super.key,
    required this.host,
    required this.section,
    required this.deal,
    required this.band,
    required this.index,
  });

  final ExploreHost host;
  final ExploreSection section;
  final FeedDeal deal;

  /// The band, as it was laid.
  final FeedLaid band;

  /// Which band of the feed it is, the first 0.
  final int index;

  @override
  Widget build(BuildContext context) {
    for (final Pill pill in band.cards) {
      host.seen(section, pill);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : kFeedSpacing, 20, 0),
      child: SizedBox(
        height: band.height,
        child: Stack(
          children: [
            for (int b = 0; b < band.cards.length; b++)
              Positioned.fromRect(
                rect: band.boxes[b],
                child: GestureDetector(
                  key: ValueKey('explore-${band.cards[b].id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      host.open(section, List.of(deal.laid), band.cards[b]),
                  child: filmTile(
                    band.cards[b],
                    section,
                    BoxTile(
                      pill: band.cards[b],
                      box: band.boxes[b].size,
                      read: host.isRead(band.cards[b]),
                      look: band.looks[b],
                      // Every card in words, a drawn one too: its question
                      // in its colour, and the drawing for the card opened.
                      // Pictures shrunk into boxes of every shape, or cut
                      // to them, set beside cards in words, read as two
                      // kinds of card on one page.
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [tile], the tile of [pill] on [section]: one its film grows out of when
/// [pill] is a video card (the host plays it from there, videoHeroTag), as
/// it is otherwise.
Widget filmTile(Pill pill, ExploreSection section, Widget tile) {
  final VideoCard? film = videoCardOf(pill);
  if (film == null) return tile;
  return VideoCardHero(tag: videoHeroTag(film, section.id), child: tile);
}
